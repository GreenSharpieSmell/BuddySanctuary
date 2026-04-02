extends GutTest

## test_name_generator.gd
## GUT tests for the NameGenerator class.

const NAMES_DIR := "res://data/names"


# ---------------------------------------------------------------------------
# 1. All three lists load with entries
# ---------------------------------------------------------------------------

func test_loads_name_lists() -> void:
	var gen := NameGenerator.new()
	gen.load_names(NAMES_DIR)

	assert_gt(gen.first_name_count(), 0, "first_names should have at least one entry")
	assert_gt(gen.middle_name_count(), 0, "middle_names should have at least one entry")
	assert_gt(gen.last_name_count(), 0, "last_names should have at least one entry")


# ---------------------------------------------------------------------------
# 2. generate() returns exactly three space-separated parts
# ---------------------------------------------------------------------------

func test_generate_returns_three_part_name() -> void:
	var gen := NameGenerator.new()
	gen.load_names(NAMES_DIR)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var name: String = gen.generate(rng)
	var parts: PackedStringArray = name.split(" ")

	assert_eq(parts.size(), 3, "generated name should have exactly 3 parts")


# ---------------------------------------------------------------------------
# 3. Same seed produces the same name (deterministic)
# ---------------------------------------------------------------------------

func test_deterministic_with_same_seed() -> void:
	var gen := NameGenerator.new()
	gen.load_names(NAMES_DIR)

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 12345
	var name_a: String = gen.generate(rng_a)

	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 12345
	var name_b: String = gen.generate(rng_b)

	assert_eq(name_a, name_b, "same seed should produce the same name")


# ---------------------------------------------------------------------------
# 4. Different seeds produce different names (extremely likely)
# ---------------------------------------------------------------------------

func test_different_seeds_different_names() -> void:
	var gen := NameGenerator.new()
	gen.load_names(NAMES_DIR)

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 1

	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 99999

	var name_a: String = gen.generate(rng_a)
	var name_b: String = gen.generate(rng_b)

	assert_ne(name_a, name_b, "different seeds should (almost certainly) produce different names")
