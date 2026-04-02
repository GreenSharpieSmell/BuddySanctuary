extends GutTest

## test_buddy_creator.gd
## GUT tests for BuddyCreator — blob paper doll assembly and Claude species generation.

const PARTS_DIR    := "res://data/parts"
const NAMES_DIR    := "res://data/names"
const SPECIES_PATH := "res://data/claude_species.json"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_creator() -> BuddyCreator:
	var creator := BuddyCreator.new()
	creator.load_data(PARTS_DIR, NAMES_DIR, SPECIES_PATH)
	return creator


func _make_rng(seed_val: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


# ---------------------------------------------------------------------------
# 1. test_create_blob — species, id, name, and core part indices
# ---------------------------------------------------------------------------

func test_create_blob() -> void:
	var creator := _make_creator()
	var rng := _make_rng(1)
	var buddy: BuddyData = creator.create_blob(rng)

	assert_eq(buddy.species, "blob", "blob species should be 'blob'")
	assert_false(buddy.id.is_empty(), "blob id should not be empty")
	assert_false(buddy.buddy_name.is_empty(), "blob name should not be empty")
	assert_gte(buddy.appearance.body_index,  0, "body_index should be >= 0")
	assert_gte(buddy.appearance.eyes_index,  0, "eyes_index should be >= 0")
	assert_gte(buddy.appearance.mouth_index, 0, "mouth_index should be >= 0")


# ---------------------------------------------------------------------------
# 2. test_blob_has_random_colors — at least one non-white color
# ---------------------------------------------------------------------------

func test_blob_has_random_colors() -> void:
	var creator := _make_creator()
	var rng := _make_rng(42)
	var buddy: BuddyData = creator.create_blob(rng)

	var primary_is_white: bool  = buddy.appearance.color_primary  == Color.WHITE
	var secondary_is_white: bool = buddy.appearance.color_secondary == Color.WHITE

	assert_false(
		primary_is_white and secondary_is_white,
		"at least one color should differ from pure white"
	)


# ---------------------------------------------------------------------------
# 3. test_blob_has_personality_with_dominant_trait — at least one trait >= 0.7
# ---------------------------------------------------------------------------

func test_blob_has_personality_with_dominant_trait() -> void:
	var creator := _make_creator()
	var rng := _make_rng(7)
	var buddy: BuddyData = creator.create_blob(rng)
	var p: BuddyData.BuddyPersonality = buddy.personality

	var has_dominant: bool = (
		p.curiosity >= 0.7 or
		p.shyness   >= 0.7 or
		p.energy    >= 0.7 or
		p.warmth    >= 0.7 or
		p.social    >= 0.7
	)

	assert_true(has_dominant, "blob should have at least one personality trait >= 0.7")


# ---------------------------------------------------------------------------
# 4. test_blob_rarity_from_parts — rarity matches get_overall_rarity()
# ---------------------------------------------------------------------------

func test_blob_rarity_from_parts() -> void:
	var creator := _make_creator()
	var rng := _make_rng(99)
	var buddy: BuddyData = creator.create_blob(rng)

	assert_eq(
		buddy.rarity,
		buddy.get_overall_rarity(),
		"buddy.rarity should equal get_overall_rarity()"
	)


# ---------------------------------------------------------------------------
# 5. test_blob_shiny_chance — at least one shiny in 500 buddies
# ---------------------------------------------------------------------------

func test_blob_shiny_chance() -> void:
	var creator := _make_creator()
	var rng := _make_rng(555)

	var shiny_found: bool = false
	for _i in range(500):
		var buddy: BuddyData = creator.create_blob(rng)
		if buddy.shiny:
			shiny_found = true
			break

	assert_true(shiny_found, "at least one shiny buddy expected in 500 rolls (1% chance)")


# ---------------------------------------------------------------------------
# 6. test_create_claude_buddy — non-blob species, rarity matches parameter
# ---------------------------------------------------------------------------

func test_create_claude_buddy() -> void:
	var creator := _make_creator()
	var rng := _make_rng(200)
	var buddy: BuddyData = creator.create_claude_buddy(rng, BuddyData.Rarity.RARE)

	assert_ne(buddy.species, "blob", "claude buddy species should not be 'blob'")
	assert_eq(buddy.rarity, BuddyData.Rarity.RARE, "rarity should match the parameter passed in")


# ---------------------------------------------------------------------------
# 7. test_claude_buddy_personality_has_variance — different seeds → different personalities
# ---------------------------------------------------------------------------

func test_claude_buddy_personality_has_variance() -> void:
	var creator := _make_creator()

	var rng_a := _make_rng(1000)
	var buddy_a: BuddyData = creator.create_claude_buddy(rng_a, BuddyData.Rarity.COMMON)

	var rng_b := _make_rng(9999)
	var buddy_b: BuddyData = creator.create_claude_buddy(rng_b, BuddyData.Rarity.COMMON)

	# At least one trait must differ between the two buddies
	var traits_differ: bool = (
		buddy_a.personality.curiosity != buddy_b.personality.curiosity or
		buddy_a.personality.shyness   != buddy_b.personality.shyness   or
		buddy_a.personality.energy    != buddy_b.personality.energy    or
		buddy_a.personality.warmth    != buddy_b.personality.warmth    or
		buddy_a.personality.social    != buddy_b.personality.social
	)

	assert_true(traits_differ, "two claude buddies with different seeds should differ in at least one trait")


# ---------------------------------------------------------------------------
# 8. test_preferences_derived_from_personality — zone and furniture are populated
# ---------------------------------------------------------------------------

func test_preferences_derived_from_personality() -> void:
	var creator := _make_creator()
	var rng := _make_rng(333)
	var buddy: BuddyData = creator.create_blob(rng)

	assert_false(buddy.preferred_zone.is_empty(), "preferred_zone should not be empty")
	assert_gt(buddy.preferred_furniture.size(), 0, "preferred_furniture should not be empty")


# ---------------------------------------------------------------------------
# 9. test_deterministic_blob_creation — same seed → same name, body_index, personality
# ---------------------------------------------------------------------------

func test_deterministic_blob_creation() -> void:
	var creator := _make_creator()

	var rng_a := _make_rng(77777)
	var buddy_a: BuddyData = creator.create_blob(rng_a)

	# Fresh creator to reset _next_id so IDs also match (same counter start)
	var creator_b := _make_creator()
	var rng_b := _make_rng(77777)
	var buddy_b: BuddyData = creator_b.create_blob(rng_b)

	assert_eq(buddy_a.buddy_name,               buddy_b.buddy_name,               "same seed should produce same name")
	assert_eq(buddy_a.appearance.body_index,    buddy_b.appearance.body_index,    "same seed should produce same body_index")
	assert_eq(buddy_a.personality.curiosity,    buddy_b.personality.curiosity,    "same seed should produce same curiosity")
	assert_eq(buddy_a.personality.energy,       buddy_b.personality.energy,       "same seed should produce same energy")
