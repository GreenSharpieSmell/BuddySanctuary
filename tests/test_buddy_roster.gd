extends GutTest

## test_buddy_roster.gd
## GUT tests for BuddyRoster — buddy collection management.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_buddy(id: String, name: String, zone: String = "meadow", state: BuddyData.State = BuddyData.State.IDLE) -> BuddyData:
	var buddy := BuddyData.new()
	buddy.id = id
	buddy.buddy_name = name
	buddy.current_zone = zone
	buddy.state = state
	return buddy


# ---------------------------------------------------------------------------
# 1. Roster starts empty
# ---------------------------------------------------------------------------

func test_starts_empty() -> void:
	var roster := BuddyRoster.new()
	assert_eq(roster.count(), 0, "new roster should have count 0")


# ---------------------------------------------------------------------------
# 2. add_buddy increments count
# ---------------------------------------------------------------------------

func test_add_buddy() -> void:
	var roster := BuddyRoster.new()
	roster.add_buddy(_make_buddy("b1", "Bloop"))
	assert_eq(roster.count(), 1, "count should be 1 after adding one buddy")


# ---------------------------------------------------------------------------
# 3. get_buddy returns the correct buddy by id
# ---------------------------------------------------------------------------

func test_get_buddy_by_id() -> void:
	var roster := BuddyRoster.new()
	roster.add_buddy(_make_buddy("test_1", "Glimmer"))
	var found: BuddyData = roster.get_buddy("test_1")
	assert_not_null(found, "get_buddy should return a non-null result for 'test_1'")
	assert_eq(found.buddy_name, "Glimmer", "retrieved buddy should have name 'Glimmer'")


# ---------------------------------------------------------------------------
# 4. get_buddies_in_zone filters by zone (excludes EXPEDITION)
# ---------------------------------------------------------------------------

func test_get_buddies_in_zone() -> void:
	var roster := BuddyRoster.new()
	roster.add_buddy(_make_buddy("b1", "Alpha",  "meadow"))
	roster.add_buddy(_make_buddy("b2", "Beta",   "meadow"))
	roster.add_buddy(_make_buddy("b3", "Gamma",  "burrow"))

	var meadow_buddies: Array[BuddyData] = roster.get_buddies_in_zone("meadow")
	assert_eq(meadow_buddies.size(), 2, "meadow should contain 2 buddies")

	var burrow_buddies: Array[BuddyData] = roster.get_buddies_in_zone("burrow")
	assert_eq(burrow_buddies.size(), 1, "burrow should contain 1 buddy")


# ---------------------------------------------------------------------------
# 5. get_available_for_expedition excludes EXPEDITION-state buddies
# ---------------------------------------------------------------------------

func test_get_available_for_expedition() -> void:
	var roster := BuddyRoster.new()
	roster.add_buddy(_make_buddy("b1", "Idle",   "meadow", BuddyData.State.IDLE))
	roster.add_buddy(_make_buddy("b2", "Quester", "meadow", BuddyData.State.EXPEDITION))

	var available: Array[BuddyData] = roster.get_available_for_expedition()
	assert_eq(available.size(), 1, "only 1 buddy should be available (the non-EXPEDITION one)")
	assert_eq(available[0].buddy_name, "Idle", "the available buddy should be 'Idle'")


# ---------------------------------------------------------------------------
# 6. to_array / load_from_array round-trip preserves data
# ---------------------------------------------------------------------------

func test_to_array_and_from_array() -> void:
	var original_roster := BuddyRoster.new()
	var buddy_a := _make_buddy("rt_1", "Roundtrip", "cave", BuddyData.State.WANDERING)
	buddy_a.happiness = 0.9
	original_roster.add_buddy(buddy_a)
	original_roster.add_buddy(_make_buddy("rt_2", "Persist", "meadow"))

	var arr: Array[Dictionary] = original_roster.to_array()
	assert_eq(arr.size(), 2, "to_array should produce 2 entries")

	var restored_roster := BuddyRoster.new()
	restored_roster.load_from_array(arr)
	assert_eq(restored_roster.count(), 2, "restored roster should have 2 buddies")

	var restored_a: BuddyData = restored_roster.get_buddy("rt_1")
	assert_not_null(restored_a, "buddy 'rt_1' should exist after round-trip")
	assert_eq(restored_a.buddy_name, "Roundtrip", "buddy_name should survive round-trip")
	assert_eq(restored_a.current_zone, "cave", "current_zone should survive round-trip")
	assert_eq(restored_a.state, BuddyData.State.WANDERING, "state should survive round-trip")
	assert_almost_eq(restored_a.happiness, 0.9, 0.0001, "happiness should survive round-trip")


# ---------------------------------------------------------------------------
# 7. buddy_added signal fires when a buddy is added
# ---------------------------------------------------------------------------

func test_signal_on_buddy_added() -> void:
	var roster := BuddyRoster.new()
	watch_signals(roster)

	var buddy := _make_buddy("sig_1", "Sparky")
	roster.add_buddy(buddy)

	assert_signal_emitted(roster, "buddy_added", "buddy_added signal should fire after add_buddy")
	assert_signal_emitted_with_parameters(roster, "buddy_added", [buddy], "buddy_added should carry the added buddy")
