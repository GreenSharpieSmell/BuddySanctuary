class_name BuddyCreator
extends RefCounted

## BuddyCreator — assembles complete BuddyData instances.
## Handles both blob generation (paper doll system) and Claude species generation.
## Call load_data() once before any create_* methods.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const SHINY_CHANCE: float = 0.01
const PERSONALITY_VARIANCE: float = 0.15

const ACCESSORY_SLOT_NAMES: Array = ["head", "neck", "held", "back", "feet"]

## Maps dominant personality trait name to preferred zone.
const ZONE_FOR_TRAIT: Dictionary = {
	"warmth":    "meadow",
	"shyness":   "burrow",
	"social":    "pond",
	"curiosity": "mushroom_grotto",
	"energy":    "canopy",
}

## Maps personality trait name to preferred furniture IDs.
const FURNITURE_FOR_TRAIT: Dictionary = {
	"warmth":    ["cozy_rug", "fireplace", "soft_cushion"],
	"shyness":   ["small_nook", "curtain_den", "potted_plant"],
	"social":    ["long_bench", "picnic_table", "swing"],
	"curiosity": ["bookshelf", "telescope", "puzzle_box"],
	"energy":    ["climbing_post", "wheel", "bounce_pad"],
}


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _part_pool: PartPool = PartPool.new()
var _name_gen: NameGenerator = NameGenerator.new()
var _claude_species: Array[Dictionary] = []
var _next_id: int = 0


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

## Initializes PartPool, NameGenerator, and loads Claude species JSON.
## Must be called before any create_* methods.
func load_data(parts_dir: String, names_dir: String, species_path: String) -> void:
	_part_pool.load_from_directory(parts_dir)
	_name_gen.load_names(names_dir)
	_load_claude_species(species_path)


func _load_claude_species(path: String) -> void:
	_claude_species.clear()

	if not FileAccess.file_exists(path):
		push_error("BuddyCreator: species file not found: %s" % path)
		return

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("BuddyCreator: could not open: %s" % path)
		return

	var text: String = f.get_as_text()
	f.close()

	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("BuddyCreator: JSON parse error in %s — %s" % [path, json.get_error_message()])
		return

	var data = json.get_data()
	if not (data is Dictionary) or not data.has("species"):
		push_error("BuddyCreator: %s missing 'species' key" % path)
		return

	for entry in data["species"]:
		_claude_species.append(entry)


# ---------------------------------------------------------------------------
# Blob creation (paper doll)
# ---------------------------------------------------------------------------

## Assembles a full blob buddy using the paper doll system.
func create_blob(rng: RandomNumberGenerator) -> BuddyData:
	var buddy := BuddyData.new()

	# Identity
	buddy.id = _generate_id()
	buddy.species = "blob"
	buddy.buddy_name = _name_gen.generate(rng)
	buddy.shiny = rng.randf() < SHINY_CHANCE

	# Core parts
	var body_part: Dictionary = _part_pool.pick_random_part("bodies", rng)
	buddy.appearance.body_index = body_part.get("_index", 0)
	buddy.appearance.body_rarity = body_part.get("rarity", BuddyData.Rarity.COMMON)

	var eyes_part: Dictionary = _part_pool.pick_random_part("eyes", rng)
	buddy.appearance.eyes_index = eyes_part.get("_index", 0)
	buddy.appearance.eyes_rarity = eyes_part.get("rarity", BuddyData.Rarity.COMMON)

	var mouth_part: Dictionary = _part_pool.pick_random_part("mouths", rng)
	buddy.appearance.mouth_index = mouth_part.get("_index", 0)
	buddy.appearance.mouth_rarity = mouth_part.get("rarity", BuddyData.Rarity.COMMON)

	# Accessories — one per slot, 50% chance each
	for i in range(ACCESSORY_SLOT_NAMES.size()):
		var slot: String = ACCESSORY_SLOT_NAMES[i]
		var acc = _part_pool.pick_random_accessory_or_empty(slot, rng)
		if acc == null:
			buddy.appearance.accessory_indices[i] = -1
			buddy.appearance.accessory_rarities[i] = BuddyData.Rarity.COMMON
		else:
			buddy.appearance.accessory_indices[i] = acc.get("_index", 0)
			buddy.appearance.accessory_rarities[i] = acc.get("rarity", BuddyData.Rarity.COMMON)

	# Colors — random RGB
	buddy.appearance.color_primary = Color(rng.randf(), rng.randf(), rng.randf())
	buddy.appearance.color_secondary = Color(rng.randf(), rng.randf(), rng.randf())

	# Personality — 5 traits from 0.2–0.7, then one promoted to 0.7–1.0
	_generate_blob_personality(buddy.personality, rng)

	# Preferences derived from dominant trait
	_derive_preferences(buddy)

	# Overall rarity from equipped parts
	buddy.rarity = buddy.get_overall_rarity()

	return buddy


func _generate_blob_personality(personality: BuddyData.BuddyPersonality, rng: RandomNumberGenerator) -> void:
	# Roll all 5 traits in the 0.2–0.7 range
	personality.curiosity = rng.randf_range(0.2, 0.7)
	personality.shyness   = rng.randf_range(0.2, 0.7)
	personality.energy    = rng.randf_range(0.2, 0.7)
	personality.warmth    = rng.randf_range(0.2, 0.7)
	personality.social    = rng.randf_range(0.2, 0.7)

	# Promote one trait to be dominant (0.7–1.0)
	var dominant_idx: int = rng.randi() % 5
	var dominant_value: float = rng.randf_range(0.7, 1.0)
	match dominant_idx:
		0: personality.curiosity = dominant_value
		1: personality.shyness   = dominant_value
		2: personality.energy    = dominant_value
		3: personality.warmth    = dominant_value
		4: personality.social    = dominant_value


# ---------------------------------------------------------------------------
# Claude species creation
# ---------------------------------------------------------------------------

## Creates a buddy from a random Claude species with a fixed rarity.
func create_claude_buddy(rng: RandomNumberGenerator, rarity: BuddyData.Rarity) -> BuddyData:
	var buddy := BuddyData.new()

	# Pick a random species entry
	var species_entry: Dictionary = _claude_species[rng.randi() % _claude_species.size()]

	# Identity
	buddy.id = _generate_id()
	buddy.species = species_entry.get("id", "unknown")
	buddy.rarity = rarity
	buddy.shiny = rng.randf() < SHINY_CHANCE
	buddy.buddy_name = _name_gen.generate(rng)

	# Personality from archetype + variance
	var archetype: Dictionary = species_entry.get("personality", {})
	_generate_claude_personality(buddy.personality, archetype, rng)

	# Preferences derived from dominant trait
	_derive_preferences(buddy)

	return buddy


func _generate_claude_personality(
	personality: BuddyData.BuddyPersonality,
	archetype: Dictionary,
	rng: RandomNumberGenerator
) -> void:
	# Apply archetype values with +/- PERSONALITY_VARIANCE jitter, clamped to 0.0–1.0
	personality.curiosity = clampf(
		archetype.get("curiosity", 0.5) + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE),
		0.0, 1.0
	)
	personality.shyness = clampf(
		archetype.get("shyness", 0.5) + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE),
		0.0, 1.0
	)
	personality.energy = clampf(
		archetype.get("energy", 0.5) + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE),
		0.0, 1.0
	)
	personality.warmth = clampf(
		archetype.get("warmth", 0.5) + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE),
		0.0, 1.0
	)
	personality.social = clampf(
		archetype.get("social", 0.5) + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE),
		0.0, 1.0
	)


# ---------------------------------------------------------------------------
# Preference derivation
# ---------------------------------------------------------------------------

## Finds the dominant personality trait and maps it to zone + furniture prefs.
func _derive_preferences(buddy: BuddyData) -> void:
	var dominant_trait: String = _dominant_trait(buddy.personality)
	buddy.preferred_zone = ZONE_FOR_TRAIT.get(dominant_trait, "meadow")

	var furniture: Array = FURNITURE_FOR_TRAIT.get(dominant_trait, [])
	buddy.preferred_furniture.clear()
	for item in furniture:
		buddy.preferred_furniture.append(str(item))


## Returns the name of the personality trait with the highest value.
func _dominant_trait(personality: BuddyData.BuddyPersonality) -> String:
	var traits: Dictionary = {
		"curiosity": personality.curiosity,
		"shyness":   personality.shyness,
		"energy":    personality.energy,
		"warmth":    personality.warmth,
		"social":    personality.social,
	}

	var best_name: String = "warmth"
	var best_value: float = -1.0
	for trait_name in traits.keys():
		if traits[trait_name] > best_value:
			best_value = traits[trait_name]
			best_name = trait_name

	return best_name


# ---------------------------------------------------------------------------
# ID generation
# ---------------------------------------------------------------------------

func _generate_id() -> String:
	var timestamp: int = Time.get_ticks_msec()
	_next_id += 1
	return "buddy_%d_%d" % [timestamp, _next_id]
