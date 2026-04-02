extends GutTest

## test_expedition_manager.gd
## GUT tests for ExpeditionManager — slots, duration, result rolling, serialization.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_buddy(id: String, energy: float = 0.5, curiosity: float = 0.5) -> BuddyData:
	var b := BuddyData.new()
	b.id = id
	b.buddy_name = "Buddy_" + id
	b.personality.energy = energy
	b.personality.curiosity = curiosity
	b.state = BuddyData.State.IDLE
	return b


func _make_rng(seed_value: int = 12345) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# ---------------------------------------------------------------------------
# 1. Send one buddy — state changes to EXPEDITION, active_count == 1
# ---------------------------------------------------------------------------

func test_send_buddy_on_expedition() -> void:
	var em := ExpeditionManager.new()
	var buddy := _make_buddy("b001")

	var ok: bool = em.send_on_expedition(buddy)

	assert_true(ok, "send_on_expedition should return true for a valid send")
	assert_eq(buddy.state, BuddyData.State.EXPEDITION,
		"buddy state should be EXPEDITION after sending")
	assert_eq(em.active_count(), 1, "active_count should be 1 after one send")


# ---------------------------------------------------------------------------
# 2. Cannot exceed max_slots
# ---------------------------------------------------------------------------

func test_cannot_exceed_max_slots() -> void:
	var em := ExpeditionManager.new()
	em.max_slots = 2

	var b1 := _make_buddy("b001")
	var b2 := _make_buddy("b002")
	var b3 := _make_buddy("b003")

	assert_true(em.send_on_expedition(b1), "first send should succeed")
	assert_true(em.send_on_expedition(b2), "second send should succeed")
	var third: bool = em.send_on_expedition(b3)
	assert_false(third, "third send should fail when max_slots is 2")
	assert_eq(em.active_count(), 2, "active_count should remain 2")
	assert_eq(b3.state, BuddyData.State.IDLE, "rejected buddy should remain IDLE")


# ---------------------------------------------------------------------------
# 3. High energy returns faster (shorter duration)
# ---------------------------------------------------------------------------

func test_high_energy_returns_faster() -> void:
	var em := ExpeditionManager.new()
	var lazy_buddy  := _make_buddy("lazy",  0.1)
	var peppy_buddy := _make_buddy("peppy", 0.9)

	var dur_lazy:  float = em.calculate_duration(lazy_buddy)
	var dur_peppy: float = em.calculate_duration(peppy_buddy)

	assert_true(dur_peppy < dur_lazy,
		"high-energy buddy should have shorter duration than low-energy buddy")


# ---------------------------------------------------------------------------
# 4. Roll distribution over 1000 samples is within wide margins
# ---------------------------------------------------------------------------

func test_roll_expedition_result() -> void:
	var em := ExpeditionManager.new()
	var rng := _make_rng(42)
	var buddy := _make_buddy("tester", 0.5, 0.0)  # curiosity 0 → no bonus

	var counts: Dictionary = {"blob": 0, "claude_buddy": 0, "decoration": 0, "nice_walk": 0}
	var rolls: int = 1000

	for i in range(rolls):
		var result: Dictionary = em.roll_result(buddy, rng)
		counts[result["type"]] += 1

	# Wide margins: expected ±20 percentage points
	var blob_pct:    float = counts["blob"]       / float(rolls)
	var claude_pct:  float = counts["claude_buddy"] / float(rolls)
	var deco_pct:    float = counts["decoration"] / float(rolls)
	var walk_pct:    float = counts["nice_walk"]  / float(rolls)

	assert_true(blob_pct   >= 0.25 and blob_pct   <= 0.65,
		"blob rate should be roughly 45%% (got %.2f)" % blob_pct)
	assert_true(claude_pct >= 0.00 and claude_pct <= 0.25,
		"claude rate should be roughly 5%% (got %.2f)" % claude_pct)
	assert_true(deco_pct   >= 0.00 and deco_pct   <= 0.30,
		"decoration rate should be roughly 10%% (got %.2f)" % deco_pct)
	assert_true(walk_pct   >= 0.20 and walk_pct   <= 0.60,
		"nice_walk rate should be roughly 40%% (got %.2f)" % walk_pct)


# ---------------------------------------------------------------------------
# 5. check_completed returns finished expeditions and buddy returns to IDLE
# ---------------------------------------------------------------------------

func test_check_returns_completed_expeditions() -> void:
	var em := ExpeditionManager.new()
	var rng := _make_rng()
	var buddy := _make_buddy("b001")

	em.send_on_expedition(buddy)

	# Reach into the entry and back-date departure so the expedition is already done
	var entry = em._active_expeditions[0]
	entry.departure_time = Time.get_unix_time_from_system() - entry.duration - 1.0

	var results: Array = em.check_completed(rng)

	assert_eq(results.size(), 1, "one expedition should complete")
	assert_eq(results[0]["buddy_id"], "b001", "result should carry the buddy_id")
	assert_true(results[0].has("type"), "result should have a type field")
	assert_true(results[0].has("stardust"), "result should have a stardust field")
	assert_eq(buddy.state, BuddyData.State.IDLE, "buddy should be IDLE after return")
	assert_eq(em.active_count(), 0, "active_count should be 0 after completion")


# ---------------------------------------------------------------------------
# 6. Stardust is always > 0 regardless of roll type
# ---------------------------------------------------------------------------

func test_stardust_always_earned() -> void:
	var em := ExpeditionManager.new()
	var rng := _make_rng(99)
	var buddy := _make_buddy("b001")

	for i in range(200):
		var result: Dictionary = em.roll_result(buddy, rng)
		assert_true(result["stardust"] > 0,
			"stardust should always be > 0 (got %d for type %s)" % [result["stardust"], result["type"]])


# ---------------------------------------------------------------------------
# 7. to_array / load_from_array preserves buddy_id
# ---------------------------------------------------------------------------

func test_to_array_and_from_array() -> void:
	var em := ExpeditionManager.new()
	var buddy := _make_buddy("b_persist", 0.5, 0.5)

	em.send_on_expedition(buddy)

	var arr: Array = em.to_array()
	assert_eq(arr.size(), 1, "serialized array should have one entry")
	assert_eq(arr[0]["buddy_id"], "b_persist", "buddy_id should be preserved in serialized form")
	assert_true(arr[0].has("departure_time"), "departure_time should be present")
	assert_true(arr[0].has("duration"), "duration should be present")

	# Restore into a fresh manager using a roster that contains the buddy
	var roster := BuddyRoster.new()
	roster.add_buddy(buddy)

	var em2 := ExpeditionManager.new()
	em2.load_from_array(arr, roster)

	assert_eq(em2.active_count(), 1, "restored manager should have 1 active expedition")
	var restored_entry = em2._active_expeditions[0]
	assert_eq(restored_entry.buddy_id, "b_persist", "buddy_id should survive round-trip")
	assert_eq(restored_entry.buddy_ref, buddy, "buddy_ref should be reconnected from roster")
