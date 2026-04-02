extends GutTest

## test_progression_manager.gd
## GUT tests for ProgressionManager — stardust economy, passive trickle, milestones.


# ---------------------------------------------------------------------------
# 1. Starts with zero stardust
# ---------------------------------------------------------------------------

func test_starts_with_zero_stardust() -> void:
	var pm := ProgressionManager.new()
	assert_eq(pm.stardust, 0, "stardust should start at 0")


# ---------------------------------------------------------------------------
# 2. earn_stardust adds to balance
# ---------------------------------------------------------------------------

func test_earn_stardust() -> void:
	var pm := ProgressionManager.new()
	pm.earn_stardust(100)
	assert_eq(pm.stardust, 100, "stardust should be 100 after earning 100")


# ---------------------------------------------------------------------------
# 3. spend_stardust deducts and returns true when funds are sufficient
# ---------------------------------------------------------------------------

func test_spend_stardust() -> void:
	var pm := ProgressionManager.new()
	pm.earn_stardust(100)
	var result: bool = pm.spend_stardust(60)
	assert_true(result, "spend_stardust should return true when funds are sufficient")
	assert_eq(pm.stardust, 40, "stardust should be 40 after spending 60 from 100")


# ---------------------------------------------------------------------------
# 4. spend_stardust returns false and leaves balance unchanged when overspending
# ---------------------------------------------------------------------------

func test_cannot_overspend() -> void:
	var pm := ProgressionManager.new()
	pm.earn_stardust(50)
	var result: bool = pm.spend_stardust(100)
	assert_false(result, "spend_stardust should return false when funds are insufficient")
	assert_eq(pm.stardust, 50, "stardust should remain 50 after a failed spend")


# ---------------------------------------------------------------------------
# 5. calculate_passive_stardust returns correct trickle amount
# ---------------------------------------------------------------------------

func test_passive_stardust_trickle() -> void:
	var pm := ProgressionManager.new()
	# 5 buddies * (120s / 60s) * 1 stardust/buddy/min = 10
	var amount: int = pm.calculate_passive_stardust(5, 120.0)
	assert_eq(amount, 10, "5 buddies over 120 seconds should yield 10 stardust")


# ---------------------------------------------------------------------------
# 6. record_buddy_found increments total_buddies_found
# ---------------------------------------------------------------------------

func test_total_buddies_tracking() -> void:
	var pm := ProgressionManager.new()
	pm.record_buddy_found()
	pm.record_buddy_found()
	assert_eq(pm.total_buddies_found, 2, "total_buddies_found should be 2 after two records")


# ---------------------------------------------------------------------------
# 7. to_dict / load_from_dict round-trip preserves state
# ---------------------------------------------------------------------------

func test_to_dict_and_from_dict() -> void:
	var original := ProgressionManager.new()
	original.earn_stardust(250)
	original.record_buddy_found()
	original.record_buddy_found()
	original.record_buddy_found()

	var dict: Dictionary = original.to_dict()
	assert_eq(dict["stardust"], 250, "to_dict should include stardust value")
	assert_eq(dict["total_buddies_found"], 3, "to_dict should include total_buddies_found value")

	var restored := ProgressionManager.new()
	restored.load_from_dict(dict)
	assert_eq(restored.stardust, 250, "stardust should survive round-trip")
	assert_eq(restored.total_buddies_found, 3, "total_buddies_found should survive round-trip")
