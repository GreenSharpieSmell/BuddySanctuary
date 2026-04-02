extends GutTest

## test_zone_manager.gd
## GUT tests for ZoneManager — zone unlocks, decoration placement, expedition slots.

const ZONES_PATH       := "res://data/zones.json"
const DECORATIONS_PATH := "res://data/decorations.json"


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

func _make_manager() -> ZoneManager:
	var zm := ZoneManager.new()
	zm.load_data(ZONES_PATH, DECORATIONS_PATH)
	return zm


# ---------------------------------------------------------------------------
# 1. test_meadow_unlocked_by_default
# ---------------------------------------------------------------------------

func test_meadow_unlocked_by_default() -> void:
	var zm := _make_manager()
	assert_true(zm.is_zone_unlocked("meadow"), "meadow should be unlocked by default")


# ---------------------------------------------------------------------------
# 2. test_burrow_locked_initially
# ---------------------------------------------------------------------------

func test_burrow_locked_initially() -> void:
	var zm := _make_manager()
	assert_false(zm.is_zone_unlocked("burrow"), "burrow should be locked initially")


# ---------------------------------------------------------------------------
# 3. test_unlock_zone_at_milestone — check_unlocks(10): burrow unlocked, pond NOT
# ---------------------------------------------------------------------------

func test_unlock_zone_at_milestone() -> void:
	var zm := _make_manager()
	zm.check_unlocks(10)

	assert_true(zm.is_zone_unlocked("burrow"), "burrow should unlock at 10 buddies")
	assert_false(zm.is_zone_unlocked("pond"), "pond should not unlock at 10 buddies")


# ---------------------------------------------------------------------------
# 4. test_unlock_multiple_zones — check_unlocks(25): burrow + pond, NOT mushroom_grotto
# ---------------------------------------------------------------------------

func test_unlock_multiple_zones() -> void:
	var zm := _make_manager()
	zm.check_unlocks(25)

	assert_true(zm.is_zone_unlocked("burrow"), "burrow should unlock at 25 buddies")
	assert_true(zm.is_zone_unlocked("pond"), "pond should unlock at 25 buddies")
	assert_false(zm.is_zone_unlocked("mushroom_grotto"), "mushroom_grotto should not unlock at 25 buddies")


# ---------------------------------------------------------------------------
# 5. test_get_unlocked_zones — check_unlocks(20): meadow, burrow, pond
# ---------------------------------------------------------------------------

func test_get_unlocked_zones() -> void:
	var zm := _make_manager()
	zm.check_unlocks(20)

	var unlocked := zm.get_unlocked_zone_ids()
	assert_true(unlocked.has("meadow"), "unlocked list should contain meadow")
	assert_true(unlocked.has("burrow"), "unlocked list should contain burrow")
	assert_true(unlocked.has("pond"),   "unlocked list should contain pond")


# ---------------------------------------------------------------------------
# 6. test_place_decoration — place one, verify get_decorations returns it
# ---------------------------------------------------------------------------

func test_place_decoration() -> void:
	var zm := _make_manager()
	zm.place_decoration("meadow", "cushion", Vector2(3.0, 7.0))

	var placed := zm.get_decorations_in_zone("meadow")
	assert_eq(placed.size(), 1, "should have one placed decoration in meadow")
	assert_eq(placed[0]["id"], "cushion", "placed decoration id should be 'cushion'")
	assert_eq(placed[0]["position"], Vector2(3.0, 7.0), "placed decoration position should match")


# ---------------------------------------------------------------------------
# 7. test_remove_decoration — place then remove, verify empty
# ---------------------------------------------------------------------------

func test_remove_decoration() -> void:
	var zm := _make_manager()
	zm.place_decoration("meadow", "lamp", Vector2(1.0, 2.0))
	zm.remove_decoration("meadow", 0)

	var placed := zm.get_decorations_in_zone("meadow")
	assert_eq(placed.size(), 0, "decorations list should be empty after removal")


# ---------------------------------------------------------------------------
# 8. test_available_decorations_filtered_by_unlock — only meadow decos initially
# ---------------------------------------------------------------------------

func test_available_decorations_filtered_by_unlock() -> void:
	var zm := _make_manager()
	var available := zm.get_available_decorations()

	# Verify every returned decoration belongs to meadow
	for deco in available:
		assert_eq(
			deco["unlock_zone"],
			"meadow",
			"only meadow decorations should be available when only meadow is unlocked"
		)

	# Spot-check: cushion should be present, blanket (burrow) should not
	var ids: Array = []
	for deco in available:
		ids.append(deco["id"])

	assert_true(ids.has("cushion"), "cushion (meadow) should be available")
	assert_false(ids.has("blanket"), "blanket (burrow) should not be available")


# ---------------------------------------------------------------------------
# 9. test_zone_data_has_name
# ---------------------------------------------------------------------------

func test_zone_data_has_name() -> void:
	var zm := _make_manager()
	var data := zm.get_zone_data("meadow")
	assert_eq(data["name"], "The Meadow", "meadow zone name should be 'The Meadow'")


# ---------------------------------------------------------------------------
# 10. test_signal_on_zone_unlock
# ---------------------------------------------------------------------------

func test_signal_on_zone_unlock() -> void:
	var zm := _make_manager()
	watch_signals(zm)

	zm.check_unlocks(10)

	assert_signal_emitted_with_parameters(
		zm,
		"zone_unlocked",
		["burrow"],
		"zone_unlocked should fire with 'burrow'"
	)


# ---------------------------------------------------------------------------
# 11. test_expedition_slots_scale_with_zones
# ---------------------------------------------------------------------------

func test_expedition_slots_scale_with_zones() -> void:
	var zm := _make_manager()

	# Only meadow unlocked: 1 slot
	assert_eq(zm.get_expedition_slots(), 1, "should have 1 expedition slot with only meadow")

	# Unlock burrow: 2 slots
	zm.check_unlocks(10)
	assert_eq(zm.get_expedition_slots(), 2, "should have 2 expedition slots after burrow unlocks")

	# Unlock all zones: caps at MAX_EXPEDITION_SLOTS (5)
	zm.check_unlocks(999)
	assert_eq(
		zm.get_expedition_slots(),
		ZoneManager.MAX_EXPEDITION_SLOTS,
		"expedition slots should cap at MAX_EXPEDITION_SLOTS"
	)


# ---------------------------------------------------------------------------
# 12. test_to_dict_and_from_dict — round-trip with unlocks + placed decorations
# ---------------------------------------------------------------------------

func test_to_dict_and_from_dict() -> void:
	var zm := _make_manager()
	zm.check_unlocks(20)  # unlocks meadow, burrow, pond
	zm.place_decoration("meadow", "cushion", Vector2(4.0, 2.0))
	zm.place_decoration("burrow", "blanket", Vector2(1.5, 3.5))

	var d := zm.to_dict()

	# Restore into a fresh manager (with defs loaded)
	var zm2 := _make_manager()
	zm2.load_from_dict(d)

	# Zones survived round-trip
	assert_true(zm2.is_zone_unlocked("meadow"), "meadow should survive round-trip")
	assert_true(zm2.is_zone_unlocked("burrow"), "burrow should survive round-trip")
	assert_true(zm2.is_zone_unlocked("pond"),   "pond should survive round-trip")
	assert_false(zm2.is_zone_unlocked("mushroom_grotto"), "mushroom_grotto should not be unlocked after round-trip")

	# Decorations survived round-trip
	var meadow_decos := zm2.get_decorations_in_zone("meadow")
	assert_eq(meadow_decos.size(), 1, "meadow should have 1 decoration after round-trip")
	assert_eq(meadow_decos[0]["id"], "cushion", "meadow deco id should be 'cushion' after round-trip")
	assert_eq(meadow_decos[0]["position"], Vector2(4.0, 2.0), "meadow deco position should survive round-trip")

	var burrow_decos := zm2.get_decorations_in_zone("burrow")
	assert_eq(burrow_decos.size(), 1, "burrow should have 1 decoration after round-trip")
	assert_eq(burrow_decos[0]["id"], "blanket", "burrow deco id should be 'blanket' after round-trip")
	assert_eq(burrow_decos[0]["position"], Vector2(1.5, 3.5), "burrow deco position should survive round-trip")
