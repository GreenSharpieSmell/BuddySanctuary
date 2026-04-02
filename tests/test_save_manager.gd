extends GutTest

## test_save_manager.gd
## GUT tests for SaveManager — JSON round-trip, offline catch-up, timestamp.

const ZONES_PATH       := "res://data/zones.json"
const DECORATIONS_PATH := "res://data/decorations.json"
const TEST_SAVE_PATH   := "user://test_save.json"


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

var sm: SaveManager

func before_each() -> void:
	sm = SaveManager.new()
	sm.save_path = TEST_SAVE_PATH


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


# ---------------------------------------------------------------------------
# 1. test_save_and_load_round_trip
# ---------------------------------------------------------------------------

func test_save_and_load_round_trip() -> void:
	# Build source state.
	var roster := BuddyRoster.new()
	var buddy  := BuddyData.new()
	buddy.id         = "test_1"
	buddy.buddy_name = "Roundtrip Blob"
	roster.add_buddy(buddy)

	var zone_mgr := ZoneManager.new()
	zone_mgr.load_data(ZONES_PATH, DECORATIONS_PATH)

	var prog := ProgressionManager.new()
	prog.earn_stardust(250)

	var exp_mgr := ExpeditionManager.new()

	# Save.
	sm.save_game(roster, zone_mgr, prog, exp_mgr)
	assert_true(
		FileAccess.file_exists(TEST_SAVE_PATH),
		"save file should exist after save_game"
	)

	# Load into fresh managers.
	var r2 := BuddyRoster.new()
	var z2 := ZoneManager.new()
	z2.load_data(ZONES_PATH, DECORATIONS_PATH)
	var p2 := ProgressionManager.new()
	var e2 := ExpeditionManager.new()

	var success := sm.load_game(r2, z2, p2, e2)
	assert_true(success, "load_game should return true on success")
	assert_eq(r2.count(), 1, "roster should have 1 buddy after load")
	assert_eq(
		r2.get_buddy("test_1").buddy_name,
		"Roundtrip Blob",
		"buddy name should survive round-trip"
	)
	assert_eq(p2.stardust, 250, "stardust should survive round-trip")


# ---------------------------------------------------------------------------
# 2. test_offline_catchup_stardust
# ---------------------------------------------------------------------------

func test_offline_catchup_stardust() -> void:
	# 5 buddies × 60 minutes × 1 stardust/buddy/min = 300
	var catchup := sm.calculate_offline_catchup(3600.0, 5)
	assert_eq(catchup.stardust_earned, 300, "5 buddies over 3600s should earn 300 stardust")
	assert_eq(catchup.elapsed_seconds, 3600.0, "elapsed_seconds should be echoed back")


# ---------------------------------------------------------------------------
# 3. test_offline_catchup_expeditions
# ---------------------------------------------------------------------------

func test_offline_catchup_expeditions() -> void:
	# Set up an expedition that departed 1 hour ago with a short duration.
	var exp_mgr := ExpeditionManager.new()
	var buddy   := BuddyData.new()
	buddy.id = "b1"
	buddy.personality.energy = 0.5
	exp_mgr.send_on_expedition(buddy)

	# Rewind departure time so the expedition is well past due.
	exp_mgr._active_expeditions[0].departure_time = (
		Time.get_unix_time_from_system() - 3600.0
	)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var completed := exp_mgr.check_completed(rng)
	assert_eq(completed.size(), 1, "expedition should complete during offline time")


# ---------------------------------------------------------------------------
# 4. test_no_save_file_returns_false
# ---------------------------------------------------------------------------

func test_no_save_file_returns_false() -> void:
	var r := BuddyRoster.new()
	var z := ZoneManager.new()
	z.load_data(ZONES_PATH, DECORATIONS_PATH)
	var p := ProgressionManager.new()
	var e := ExpeditionManager.new()

	var success := sm.load_game(r, z, p, e)
	assert_false(success, "load_game should return false when no save file exists")


# ---------------------------------------------------------------------------
# 5. test_last_played_timestamp_saved
# ---------------------------------------------------------------------------

func test_last_played_timestamp_saved() -> void:
	var roster   := BuddyRoster.new()
	var zone_mgr := ZoneManager.new()
	zone_mgr.load_data(ZONES_PATH, DECORATIONS_PATH)
	var prog    := ProgressionManager.new()
	var exp_mgr := ExpeditionManager.new()

	sm.save_game(roster, zone_mgr, prog, exp_mgr)

	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data

	assert_has(data, "last_played", "save file should contain last_played key")
	assert_gt(data["last_played"], 0.0, "last_played should be a positive timestamp")
