extends GutTest

## test_part_pool.gd
## GUT tests for PartPool — JSON loading and rarity-weighted picks.

const PARTS_DIR := "res://data/parts"


# ---------------------------------------------------------------------------
# 1. Load bodies — verify count > 0
# ---------------------------------------------------------------------------

func test_load_bodies() -> void:
	var pool := PartPool.new()
	pool.load_from_directory(PARTS_DIR)

	assert_gt(pool.body_count(), 0, "body_count() should be > 0 after loading")


# ---------------------------------------------------------------------------
# 2. Loaded body has "anchors" dict with all 7 required keys
# ---------------------------------------------------------------------------

func test_body_has_anchors() -> void:
	var pool := PartPool.new()
	pool.load_from_directory(PARTS_DIR)

	var body: Dictionary = pool.get_body(0)
	assert_true(body.has("anchors"), "body should have 'anchors' key")

	var anchors: Dictionary = body["anchors"]
	var required_keys := ["eyes", "mouth", "acc_head", "acc_neck", "acc_held", "acc_back", "acc_feet"]
	for key in required_keys:
		assert_true(anchors.has(key), "anchors should have key '%s'" % key)


# ---------------------------------------------------------------------------
# 3. rarity_from_string converts all 5 rarity strings correctly
# ---------------------------------------------------------------------------

func test_rarity_string_to_enum() -> void:
	assert_eq(
		PartPool.rarity_from_string("common"),
		BuddyData.Rarity.COMMON,
		"'common' should map to COMMON"
	)
	assert_eq(
		PartPool.rarity_from_string("uncommon"),
		BuddyData.Rarity.UNCOMMON,
		"'uncommon' should map to UNCOMMON"
	)
	assert_eq(
		PartPool.rarity_from_string("rare"),
		BuddyData.Rarity.RARE,
		"'rare' should map to RARE"
	)
	assert_eq(
		PartPool.rarity_from_string("epic"),
		BuddyData.Rarity.EPIC,
		"'epic' should map to EPIC"
	)
	assert_eq(
		PartPool.rarity_from_string("legendary"),
		BuddyData.Rarity.LEGENDARY,
		"'legendary' should map to LEGENDARY"
	)


# ---------------------------------------------------------------------------
# 4. Weighted rarity pick — common should appear most often over 100 picks
# ---------------------------------------------------------------------------

func test_weighted_rarity_pick() -> void:
	var pool := PartPool.new()
	pool.load_from_directory(PARTS_DIR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var common_count: int = 0
	for _i in range(100):
		var part: Dictionary = pool.pick_random_part("eyes", rng)
		if part.get("rarity") == BuddyData.Rarity.COMMON:
			common_count += 1

	# Common weight is 60/(60+25+1) = ~70% of total. Over 100 picks, expect well over 50%.
	assert_gt(common_count, 40, "common should appear most often (got %d/100)" % common_count)


# ---------------------------------------------------------------------------
# 5. Accessory slot pick returns a valid dict with "id" and "rarity"
# ---------------------------------------------------------------------------

func test_accessory_slot_pick() -> void:
	var pool := PartPool.new()
	pool.load_from_directory(PARTS_DIR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99

	var acc: Dictionary = pool.pick_random_accessory("head", rng)
	assert_false(acc.is_empty(), "pick_random_accessory('head') should return a non-empty dict")
	assert_true(acc.has("id"),     "accessory should have 'id' key")
	assert_true(acc.has("rarity"), "accessory should have 'rarity' key")


# ---------------------------------------------------------------------------
# 6. pick_random_accessory_or_empty returns null at least once in 50 tries
# ---------------------------------------------------------------------------

func test_accessory_can_be_empty() -> void:
	var pool := PartPool.new()
	pool.load_from_directory(PARTS_DIR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var null_count: int = 0
	for _i in range(50):
		var result = pool.pick_random_accessory_or_empty("head", rng)
		if result == null:
			null_count += 1

	assert_gt(null_count, 0, "at least one null (empty slot) expected in 50 picks (got %d)" % null_count)
