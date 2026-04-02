extends GutTest

## test_buddy_brain.gd
## GUT tests for BuddyBrain — personality-driven AI state machine.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_buddy(energy: float, shyness: float, social: float, warmth: float) -> BuddyData:
	var b := BuddyData.new()
	b.id         = "test_buddy"
	b.buddy_name = "Tester"
	b.personality.energy   = energy
	b.personality.shyness  = shyness
	b.personality.social   = social
	b.personality.warmth   = warmth
	return b


func _make_rng(seed_val: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


# ---------------------------------------------------------------------------
# 1. test_idle_buddy_eventually_wanders
#    High-energy buddy (0.8) ticked 100 × 0.1s = 10 s should leave IDLE.
# ---------------------------------------------------------------------------

func test_idle_buddy_eventually_wanders() -> void:
	var buddy: BuddyData = _make_buddy(0.8, 0.3, 0.5, 0.5)
	var brain := BuddyBrain.new()
	brain.setup(buddy)
	var rng := _make_rng(42)

	assert_eq(brain.current_action, BuddyBrain.Action.IDLE, "should start IDLE")

	var changed := false
	for _i in range(100):
		brain.tick(0.1, rng)
		if brain.current_action != BuddyBrain.Action.IDLE:
			changed = true
			break

	assert_true(changed, "high-energy buddy should leave IDLE within 10 seconds of ticking")


# ---------------------------------------------------------------------------
# 2. test_shy_buddy_avoids_crowds
#    Shyness 0.9, 5 buddies nearby — should_avoid_position returns true.
# ---------------------------------------------------------------------------

func test_shy_buddy_avoids_crowds() -> void:
	var buddy: BuddyData = _make_buddy(0.5, 0.9, 0.5, 0.5)
	var brain := BuddyBrain.new()
	brain.setup(buddy)

	var result: bool = brain.should_avoid_position(Vector2(200, 200), 5)
	assert_true(result, "shy buddy with 5 nearby should want to avoid the crowd")


# ---------------------------------------------------------------------------
# 3. test_social_buddy_seeks_others
#    Social 0.9, non-empty positions array — should return a non-null target.
# ---------------------------------------------------------------------------

func test_social_buddy_seeks_others() -> void:
	var buddy: BuddyData = _make_buddy(0.5, 0.3, 0.9, 0.5)
	var brain := BuddyBrain.new()
	brain.setup(buddy)

	var positions: Array[Vector2] = [
		Vector2(300.0, 400.0),
		Vector2(500.0, 200.0),
	]
	var target: Variant = brain.pick_target_near_buddies(Vector2(100.0, 100.0), positions)
	assert_not_null(target, "social buddy should return a non-null target position")


# ---------------------------------------------------------------------------
# 4. test_warm_buddy_seeks_decoration
#    Warmth 0.9, preferred_furniture = ["lamp","cushion"].
#    Decoration array includes a lamp entry — should return that entry.
# ---------------------------------------------------------------------------

func test_warm_buddy_seeks_decoration() -> void:
	var buddy: BuddyData = _make_buddy(0.5, 0.3, 0.5, 0.9)
	buddy.preferred_furniture.clear()
	buddy.preferred_furniture.append("lamp")
	buddy.preferred_furniture.append("cushion")

	var brain := BuddyBrain.new()
	brain.setup(buddy)

	var decorations: Array = [
		{"id": "bench",   "position": Vector2(100.0, 200.0)},
		{"id": "lamp",    "position": Vector2(300.0, 400.0)},
		{"id": "fountain","position": Vector2(500.0, 200.0)},
	]

	var result: Variant = brain.pick_liked_decoration(decorations)
	assert_not_null(result, "warm buddy should find its preferred decoration")
	assert_eq(result["id"], "lamp", "should return the lamp entry")


# ---------------------------------------------------------------------------
# 5. test_movement_speed_scales_with_energy
#    energy=0.9 brain should have a higher move_speed than energy=0.1 brain.
# ---------------------------------------------------------------------------

func test_movement_speed_scales_with_energy() -> void:
	var buddy_slow: BuddyData = _make_buddy(0.1, 0.5, 0.5, 0.5)
	var brain_slow := BuddyBrain.new()
	brain_slow.setup(buddy_slow)

	var buddy_fast: BuddyData = _make_buddy(0.9, 0.5, 0.5, 0.5)
	var brain_fast := BuddyBrain.new()
	brain_fast.setup(buddy_fast)

	assert_gt(
		brain_fast.move_speed,
		brain_slow.move_speed,
		"high-energy buddy should move faster than low-energy buddy"
	)
