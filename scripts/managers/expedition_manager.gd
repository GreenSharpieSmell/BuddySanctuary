class_name ExpeditionManager
extends RefCounted

## ExpeditionManager — sends buddies on timed expeditions, rolls results on return.
## Tracks active slots, computes duration from energy, and serializes state for save/load.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal expedition_completed(result: Dictionary)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BASE_DURATION_MIN: float = 300.0   # 5 minutes
const BASE_DURATION_MAX: float = 900.0   # 15 minutes
const ENERGY_SPEED_FACTOR: float = 0.5   # high energy reduces duration by up to 50%

const PROB_BLOB: float = 0.45
const PROB_CLAUDE: float = 0.05
const PROB_DECORATION: float = 0.10
# nice_walk fills the remainder: 0.40

const CURIOSITY_BONUS: float = 0.05      # adds up to 5% to blob/claude discovery chance

const STARDUST_MIN: int = 10
const STARDUST_MAX: int = 30
const STARDUST_NICE_WALK_BONUS: int = 20


# ---------------------------------------------------------------------------
# Inner class
# ---------------------------------------------------------------------------

class ExpeditionEntry:
	var buddy_id: String = ""
	var buddy_ref: BuddyData = null  # live reference; null after restore from save
	var departure_time: float = 0.0  # unix timestamp (Time.get_unix_time_from_system())
	var duration: float = 0.0        # seconds until expedition completes


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var max_slots: int = 1
var _active_expeditions: Array = []  # Array of ExpeditionEntry


# ---------------------------------------------------------------------------
# Sending
# ---------------------------------------------------------------------------

## Send a buddy on an expedition.
## Returns false if the slot limit is reached or the buddy is already on expedition.
func send_on_expedition(buddy: BuddyData) -> bool:
	if _active_expeditions.size() >= max_slots:
		return false

	for entry in _active_expeditions:
		if entry.buddy_id == buddy.id:
			return false

	var e := ExpeditionEntry.new()
	e.buddy_id = buddy.id
	e.buddy_ref = buddy
	e.departure_time = Time.get_unix_time_from_system()
	e.duration = calculate_duration(buddy)

	buddy.state = BuddyData.State.EXPEDITION
	_active_expeditions.append(e)
	return true


## Calculate expedition duration based on buddy energy.
## High energy shortens the trip by up to ENERGY_SPEED_FACTOR of the base average.
func calculate_duration(buddy: BuddyData) -> float:
	var base: float = (BASE_DURATION_MIN + BASE_DURATION_MAX) / 2.0
	var reduction: float = buddy.personality.energy * ENERGY_SPEED_FACTOR
	return base * (1.0 - reduction)


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

## Number of currently active expeditions.
func active_count() -> int:
	return _active_expeditions.size()


# ---------------------------------------------------------------------------
# Tick / completion
# ---------------------------------------------------------------------------

## Check all active expeditions against current time.
## Completed ones: sets buddy state to IDLE, rolls result, emits signal, removes entry.
## Returns an Array of result Dictionaries for every expedition that just completed.
func check_completed(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var now: float = Time.get_unix_time_from_system()
	var completed: Array[Dictionary] = []
	var remaining: Array = []

	for entry in _active_expeditions:
		if now >= entry.departure_time + entry.duration:
			if entry.buddy_ref != null:
				entry.buddy_ref.state = BuddyData.State.IDLE
			var result: Dictionary = roll_result(entry.buddy_ref, rng)
			result["buddy_id"] = entry.buddy_id
			expedition_completed.emit(result)
			completed.append(result)
		else:
			remaining.append(entry)

	_active_expeditions = remaining
	return completed


# ---------------------------------------------------------------------------
# Result rolling
# ---------------------------------------------------------------------------

## Roll an expedition result for the given buddy.
## buddy may be null (restored from save without reconnect) — curiosity falls back to 0.
func roll_result(buddy: BuddyData, rng: RandomNumberGenerator) -> Dictionary:
	var curiosity: float = 0.0
	if buddy != null:
		curiosity = buddy.personality.curiosity

	# Curiosity scales the bonus linearly: max bonus when curiosity == 1.0
	var bonus: float = curiosity * CURIOSITY_BONUS

	var adjusted_blob: float  = PROB_BLOB   + bonus
	var adjusted_claude: float = PROB_CLAUDE + bonus
	# Decoration and nice_walk absorb the shift so total stays 1.0
	var adjusted_decoration: float = PROB_DECORATION
	# nice_walk = 1.0 - blob - claude - decoration (always the remainder)

	var roll: float = rng.randf()
	var result_type: String

	if roll < adjusted_blob:
		result_type = "blob"
	elif roll < adjusted_blob + adjusted_claude:
		result_type = "claude_buddy"
	elif roll < adjusted_blob + adjusted_claude + adjusted_decoration:
		result_type = "decoration"
	else:
		result_type = "nice_walk"

	var stardust: int = rng.randi_range(STARDUST_MIN, STARDUST_MAX)
	if result_type == "nice_walk":
		stardust += STARDUST_NICE_WALK_BONUS

	return {
		"type": result_type,
		"stardust": stardust,
	}


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize active expeditions to an array of dictionaries.
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _active_expeditions:
		result.append({
			"buddy_id": entry.buddy_id,
			"departure_time": entry.departure_time,
			"duration": entry.duration,
		})
	return result


## Rebuild active expeditions from saved data, reconnecting buddy_refs from a roster.
## Entries whose buddy_id is not found in the roster are restored with buddy_ref = null.
func load_from_array(arr: Array, roster: BuddyRoster) -> void:
	_active_expeditions.clear()
	for dict in arr:
		var e := ExpeditionEntry.new()
		e.buddy_id = dict.get("buddy_id", "")
		e.departure_time = dict.get("departure_time", 0.0)
		e.duration = dict.get("duration", 0.0)
		e.buddy_ref = roster.get_buddy(e.buddy_id)  # null if not found
		_active_expeditions.append(e)
