extends Node

## Sanctuary — main autoload singleton.
## Central hub wiring all managers together: roster, zones, expeditions, progression, saves.
## Access via Sanctuary.buddy_roster, Sanctuary.zone_manager, etc.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const AUTOSAVE_INTERVAL: float = 180.0       # 3 minutes
const PASSIVE_STARDUST_INTERVAL: float = 60.0 # 1 minute


# ---------------------------------------------------------------------------
# Public manager references
# ---------------------------------------------------------------------------

var buddy_roster: BuddyRoster = BuddyRoster.new()
var zone_manager: ZoneManager = ZoneManager.new()
var progression: ProgressionManager = ProgressionManager.new()
var expedition_manager: ExpeditionManager = ExpeditionManager.new()
var save_manager: SaveManager = SaveManager.new()
var buddy_creator: BuddyCreator = BuddyCreator.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ---------------------------------------------------------------------------
# Private timers / offline catch-up
# ---------------------------------------------------------------------------

var _autosave_timer: float = 0.0
var _passive_stardust_timer: float = 0.0

## Filled by _handle_offline_catchup(); consumed once by main.gd to show WelcomeBack.
var _pending_catchup: Dictionary = {}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	rng.randomize()

	# Load static data
	zone_manager.load_data("res://data/zones.json", "res://data/decorations.json")
	buddy_creator.load_data("res://data/parts", "res://data/names", "res://data/claude_species.json")

	# Restore save or start fresh
	var had_save: bool = save_manager.load_game(
		buddy_roster, zone_manager, progression, expedition_manager
	)
	if had_save:
		_handle_offline_catchup()
	else:
		_start_new_game()

	# Wire signals
	buddy_roster.buddy_added.connect(_on_buddy_added)
	zone_manager.zone_unlocked.connect(_on_zone_unlocked)

	print("[Sanctuary] Ready. Buddies: %d | Stardust: %d" % [
		buddy_roster.count(), progression.stardust
	])


func _process(delta: float) -> void:
	# Autosave
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

	# Passive stardust
	_passive_stardust_timer += delta
	if _passive_stardust_timer >= PASSIVE_STARDUST_INTERVAL:
		_passive_stardust_timer = 0.0
		var earned: int = progression.calculate_passive_stardust(
			buddy_roster.count(), PASSIVE_STARDUST_INTERVAL
		)
		if earned > 0:
			progression.earn_stardust(earned)

	# Expedition returns
	var results: Array[Dictionary] = expedition_manager.check_completed(rng)
	for result in results:
		_handle_expedition_result(result)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# ---------------------------------------------------------------------------
# Public actions
# ---------------------------------------------------------------------------

## Persist current game state to disk.
func save_game() -> void:
	save_manager.save_game(buddy_roster, zone_manager, progression, expedition_manager)


## Send a buddy on an expedition. Returns false if slots are full or buddy is unavailable.
func send_on_expedition(buddy: BuddyData) -> bool:
	expedition_manager.max_slots = zone_manager.get_expedition_slots()
	return expedition_manager.send_on_expedition(buddy)


## Buy and place a decoration. Returns false if the decoration doesn't exist or stardust
## is insufficient.
func buy_decoration(deco_id: String, zone_id: String, position: Vector2) -> bool:
	var deco_def: Dictionary = zone_manager.get_decoration_def(deco_id)
	if deco_def.is_empty():
		return false

	var cost: int = deco_def.get("cost", 0)
	if not progression.spend_stardust(cost):
		return false

	zone_manager.place_decoration(zone_id, deco_id, position)
	return true


# ---------------------------------------------------------------------------
# New game / offline catch-up
# ---------------------------------------------------------------------------

func _start_new_game() -> void:
	var starter: BuddyData = buddy_creator.create_blob(rng)
	buddy_roster.add_buddy(starter)
	progression.record_buddy_found()
	print("[Sanctuary] New game started. Starter buddy: %s" % starter.buddy_name)


func _handle_offline_catchup() -> void:
	var last_played: float = save_manager.get_last_played()
	if last_played <= 0.0:
		return

	var now: float = Time.get_unix_time_from_system()
	var elapsed: float = now - last_played

	if elapsed <= 0.0:
		return

	var catchup: Dictionary = save_manager.calculate_offline_catchup(
		elapsed, buddy_roster.count()
	)
	var earned: int = catchup.get("stardust_earned", 0)
	if earned > 0:
		progression.earn_stardust(earned)
		print("[Sanctuary] Offline catch-up: %.0fs elapsed, +%d stardust." % [elapsed, earned])

	# Resolve any expeditions that completed while offline
	var completed: Array[Dictionary] = expedition_manager.check_completed(rng)
	var new_buddy_names: Array = []
	for result in completed:
		_handle_expedition_result(result)
		if result.get("type", "") in ["blob", "claude_buddy"]:
			# The last buddy added is the new one
			var all_buddies := buddy_roster.get_all()
			if all_buddies.size() > 0:
				new_buddy_names.append(all_buddies[-1].buddy_name)

	# Store for main.gd to display via WelcomeBack — only if meaningful time elapsed
	if elapsed >= 60.0:
		_pending_catchup = {
			"elapsed_seconds": elapsed,
			"stardust_earned": earned,
			"new_buddies": new_buddy_names,
			"completed_expeditions": completed,
		}


## Returns true if there is unseen offline catch-up data waiting to be shown.
func has_pending_catchup() -> bool:
	return not _pending_catchup.is_empty()


## Return and clear the pending catch-up data. Call once from main.gd _ready().
func consume_pending_catchup() -> Dictionary:
	var data := _pending_catchup.duplicate()
	_pending_catchup = {}
	return data


# ---------------------------------------------------------------------------
# Expedition result handling
# ---------------------------------------------------------------------------

func _handle_expedition_result(result: Dictionary) -> void:
	# Always earn stardust from the expedition
	var stardust: int = result.get("stardust", 0)
	if stardust > 0:
		progression.earn_stardust(stardust)

	var result_type: String = result.get("type", "nice_walk")
	match result_type:
		"blob":
			var new_buddy: BuddyData = buddy_creator.create_blob(rng)
			buddy_roster.add_buddy(new_buddy)
			progression.record_buddy_found()

		"claude_buddy":
			var rarity: BuddyData.Rarity = _roll_claude_rarity()
			var new_buddy: BuddyData = buddy_creator.create_claude_buddy(rng, rarity)
			if rng.randf() < 0.01:
				new_buddy.shiny = true
			buddy_roster.add_buddy(new_buddy)
			progression.record_buddy_found()

		"decoration":
			pass  # Future: grant free decoration item

		"nice_walk":
			pass  # Future: happiness boost to returning buddy


func _roll_claude_rarity() -> BuddyData.Rarity:
	var roll: float = rng.randf()
	if roll < 0.60:
		return BuddyData.Rarity.COMMON
	elif roll < 0.85:
		return BuddyData.Rarity.UNCOMMON
	elif roll < 0.95:
		return BuddyData.Rarity.RARE
	elif roll < 0.99:
		return BuddyData.Rarity.EPIC
	else:
		return BuddyData.Rarity.LEGENDARY


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_buddy_added(_buddy: BuddyData) -> void:
	zone_manager.check_unlocks(buddy_roster.count())


func _on_zone_unlocked(_zone_id: String) -> void:
	expedition_manager.max_slots = zone_manager.get_expedition_slots()
