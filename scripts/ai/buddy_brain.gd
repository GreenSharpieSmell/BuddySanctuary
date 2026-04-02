class_name BuddyBrain
extends RefCounted

## BuddyBrain — personality-driven AI state machine.
## Pure logic: no scene tree, no nodes. Driven by tick() from BuddySprite._process().
## All randomness goes through the RNG passed to tick() — keeps behaviour deterministic
## when the same seed is used.


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum Action { IDLE, WANDERING, SLEEPING, PLAYING, INSPECTING, CHATTING, FLEEING }


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BASE_SPEED:       float = 30.0   # pixels/sec at energy 0
const SPEED_PER_ENERGY: float = 70.0   # additional pixels/sec per energy 1.0
const IDLE_BASE_TIME:   float = 3.0    # seconds before idle → wander
const CROWD_RADIUS:     float = 100.0  # pixels — proximity considered "crowded"
const CROWD_THRESHOLD:  int   = 3      # buddies within radius = crowded


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var buddy_data: BuddyData
var current_action: Action = Action.IDLE
var move_speed: float = BASE_SPEED
var target_position: Vector2 = Vector2.ZERO

var _idle_timer:     float = 0.0
var _action_timer:   float = 0.0
var _idle_threshold: float = IDLE_BASE_TIME


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialise the brain from a BuddyData.  Call once after instancing.
func setup(buddy: BuddyData) -> void:
	buddy_data = buddy
	var energy: float = buddy.personality.energy
	move_speed       = BASE_SPEED + energy * SPEED_PER_ENERGY
	_idle_threshold  = IDLE_BASE_TIME + (1.0 - energy) * 5.0


# ---------------------------------------------------------------------------
# Tick
# ---------------------------------------------------------------------------

## Advance the state machine by delta seconds.
## Pass the shared RNG so all randomness is deterministic with the same seed.
func tick(delta: float, rng: RandomNumberGenerator) -> void:
	_action_timer += delta

	match current_action:
		Action.IDLE:
			_tick_idle(delta, rng)

		Action.WANDERING:
			# Wander for 2–6 random seconds then return to IDLE.
			if _action_timer >= rng.randf_range(2.0, 6.0):
				_enter_idle(rng)

		Action.SLEEPING:
			# Sleep for 5–15 random seconds then return to IDLE.
			if _action_timer >= rng.randf_range(5.0, 15.0):
				_enter_idle(rng)

		_:
			# PLAYING, INSPECTING, CHATTING, FLEEING — default 3 s then IDLE.
			if _action_timer >= 3.0:
				_enter_idle(rng)


# ---------------------------------------------------------------------------
# Decision helpers
# ---------------------------------------------------------------------------

## Returns true when this buddy wants to stay away from the given position
## because it is too crowded.
func should_avoid_position(pos: Vector2, nearby_count: int) -> bool:
	# pos is accepted as a parameter but the decision only depends on personality
	# and nearby_count — the position itself is not needed for the current logic.
	@warning_ignore("unused_parameter")
	var _unused := pos
	return buddy_data.personality.shyness >= 0.5 and nearby_count >= CROWD_THRESHOLD


## Return a wander target close to the nearest buddy when this buddy is social.
## Returns null if social < 0.5 or the positions array is empty.
func pick_target_near_buddies(current_pos: Vector2, buddy_positions: Array[Vector2]) -> Variant:
	if buddy_data.personality.social < 0.5:
		return null
	if buddy_positions.is_empty():
		return null

	# Find the closest buddy.
	var closest: Vector2 = buddy_positions[0]
	var closest_dist_sq: float = current_pos.distance_squared_to(closest)
	for bp in buddy_positions:
		var d: float = current_pos.distance_squared_to(bp)
		if d < closest_dist_sq:
			closest_dist_sq = d
			closest = bp

	return closest + Vector2(20.0, 0.0)


## Return the first decoration in the array whose id is in preferred_furniture.
## Returns null if no match is found.
func pick_liked_decoration(decorations: Array) -> Variant:
	for deco in decorations:
		var deco_id: String = deco.get("id", "")
		if buddy_data.preferred_furniture.has(deco_id):
			return deco
	return null


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _enter_idle(rng: RandomNumberGenerator) -> void:
	current_action  = Action.IDLE
	_idle_timer     = 0.0
	_action_timer   = 0.0
	# Recalculate threshold with a small random variance.
	var energy: float = buddy_data.personality.energy
	_idle_threshold = IDLE_BASE_TIME + (1.0 - energy) * 5.0 + rng.randf_range(-0.5, 0.5)
	_idle_threshold = maxf(_idle_threshold, 0.5)


func _tick_idle(delta: float, rng: RandomNumberGenerator) -> void:
	_idle_timer += delta
	if _idle_timer >= _idle_threshold:
		current_action = Action.WANDERING
		_idle_timer    = 0.0
		_action_timer  = 0.0
		# Recalculate threshold for the *next* IDLE stint.
		var energy: float = buddy_data.personality.energy
		_idle_threshold = IDLE_BASE_TIME + (1.0 - energy) * 5.0 + rng.randf_range(-0.5, 0.5)
		_idle_threshold = maxf(_idle_threshold, 0.5)
