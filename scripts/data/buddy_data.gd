class_name BuddyData
extends Resource

## BuddyData — core data class representing a single buddy.
## Pure data: no visuals, no behavior.
## Used by BuddyCreator, BuddyRoster, SaveManager, BuddySprite, and BuddyBrain.


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum State { IDLE, WANDERING, SLEEPING, PLAYING, EXPEDITION }


# ---------------------------------------------------------------------------
# Inner class: BuddyAppearance
# ---------------------------------------------------------------------------

class BuddyAppearance:
	var body_index: int = 0
	var body_rarity: BuddyData.Rarity = BuddyData.Rarity.COMMON

	var eyes_index: int = 0
	var eyes_rarity: BuddyData.Rarity = BuddyData.Rarity.COMMON

	var mouth_index: int = 0
	var mouth_rarity: BuddyData.Rarity = BuddyData.Rarity.COMMON

	# 5 accessory slots; -1 means empty
	var accessory_indices: Array[int] = [-1, -1, -1, -1, -1]
	# Rarity only matters when the corresponding index != -1
	var accessory_rarities: Array = [
		BuddyData.Rarity.COMMON,
		BuddyData.Rarity.COMMON,
		BuddyData.Rarity.COMMON,
		BuddyData.Rarity.COMMON,
		BuddyData.Rarity.COMMON,
	]

	var color_primary: Color = Color.WHITE
	var color_secondary: Color = Color.WHITE

	func to_dict() -> Dictionary:
		return {
			"body_index": body_index,
			"body_rarity": body_rarity,
			"eyes_index": eyes_index,
			"eyes_rarity": eyes_rarity,
			"mouth_index": mouth_index,
			"mouth_rarity": mouth_rarity,
			"accessory_indices": accessory_indices.duplicate(),
			"accessory_rarities": accessory_rarities.duplicate(),
			"color_primary": [color_primary.r, color_primary.g, color_primary.b],
			"color_secondary": [color_secondary.r, color_secondary.g, color_secondary.b],
		}

	static func from_dict(dict: Dictionary) -> BuddyData.BuddyAppearance:
		var a := BuddyData.BuddyAppearance.new()
		a.body_index = dict.get("body_index", 0)
		a.body_rarity = dict.get("body_rarity", BuddyData.Rarity.COMMON)
		a.eyes_index = dict.get("eyes_index", 0)
		a.eyes_rarity = dict.get("eyes_rarity", BuddyData.Rarity.COMMON)
		a.mouth_index = dict.get("mouth_index", 0)
		a.mouth_rarity = dict.get("mouth_rarity", BuddyData.Rarity.COMMON)

		if dict.has("accessory_indices"):
			var raw: Array = dict["accessory_indices"]
			a.accessory_indices.clear()
			for v in raw:
				a.accessory_indices.append(int(v))

		if dict.has("accessory_rarities"):
			a.accessory_rarities = dict["accessory_rarities"].duplicate()

		if dict.has("color_primary"):
			var c: Array = dict["color_primary"]
			a.color_primary = Color(c[0], c[1], c[2])

		if dict.has("color_secondary"):
			var c: Array = dict["color_secondary"]
			a.color_secondary = Color(c[0], c[1], c[2])

		return a


# ---------------------------------------------------------------------------
# Inner class: BuddyPersonality
# ---------------------------------------------------------------------------

class BuddyPersonality:
	var curiosity: float = 0.5
	var shyness: float = 0.5
	var energy: float = 0.5
	var warmth: float = 0.5
	var social: float = 0.5

	func to_dict() -> Dictionary:
		return {
			"curiosity": curiosity,
			"shyness": shyness,
			"energy": energy,
			"warmth": warmth,
			"social": social,
		}

	static func from_dict(dict: Dictionary) -> BuddyData.BuddyPersonality:
		var p := BuddyData.BuddyPersonality.new()
		p.curiosity = dict.get("curiosity", 0.5)
		p.shyness = dict.get("shyness", 0.5)
		p.energy = dict.get("energy", 0.5)
		p.warmth = dict.get("warmth", 0.5)
		p.social = dict.get("social", 0.5)
		return p


# ---------------------------------------------------------------------------
# Identity fields
# ---------------------------------------------------------------------------

var id: String = ""
var species: String = "blob"
var rarity: Rarity = Rarity.COMMON
var shiny: bool = false
var buddy_name: String = ""


# ---------------------------------------------------------------------------
# Appearance and Personality
# ---------------------------------------------------------------------------

var appearance: BuddyAppearance = BuddyAppearance.new()
var personality: BuddyPersonality = BuddyPersonality.new()


# ---------------------------------------------------------------------------
# Preferences
# ---------------------------------------------------------------------------

var preferred_zone: String = "meadow"
var preferred_furniture: Array[String] = []


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var current_zone: String = "meadow"
var state: State = State.IDLE

## happiness has a floor of 0.5 — it can never drop below 0.5.
var _happiness: float = 0.5

var happiness: float:
	get:
		return _happiness
	set(value):
		_happiness = maxf(0.5, value)


# ---------------------------------------------------------------------------
# Methods
# ---------------------------------------------------------------------------

## Returns the rarest Rarity among all equipped parts.
## Accessories with index == -1 are skipped.
func get_overall_rarity() -> Rarity:
	var best: Rarity = appearance.body_rarity
	if appearance.eyes_rarity > best:
		best = appearance.eyes_rarity
	if appearance.mouth_rarity > best:
		best = appearance.mouth_rarity
	for i in range(appearance.accessory_indices.size()):
		if appearance.accessory_indices[i] != -1:
			var ar: Rarity = appearance.accessory_rarities[i]
			if ar > best:
				best = ar
	return best


## Serialize all fields to a Dictionary for JSON save.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"species": species,
		"rarity": rarity,
		"shiny": shiny,
		"buddy_name": buddy_name,
		"appearance": appearance.to_dict(),
		"personality": personality.to_dict(),
		"preferred_zone": preferred_zone,
		"preferred_furniture": preferred_furniture.duplicate(),
		"current_zone": current_zone,
		"state": state,
		"happiness": happiness,
	}


## Deserialize a BuddyData from a Dictionary (produced by to_dict).
static func from_dict(dict: Dictionary) -> BuddyData:
	var b := BuddyData.new()
	b.id = dict.get("id", "")
	b.species = dict.get("species", "blob")
	b.rarity = dict.get("rarity", BuddyData.Rarity.COMMON)
	b.shiny = dict.get("shiny", false)
	b.buddy_name = dict.get("buddy_name", "")

	if dict.has("appearance"):
		b.appearance = BuddyData.BuddyAppearance.from_dict(dict["appearance"])

	if dict.has("personality"):
		b.personality = BuddyData.BuddyPersonality.from_dict(dict["personality"])

	b.preferred_zone = dict.get("preferred_zone", "meadow")

	if dict.has("preferred_furniture"):
		b.preferred_furniture.clear()
		for item in dict["preferred_furniture"]:
			b.preferred_furniture.append(str(item))

	b.current_zone = dict.get("current_zone", "meadow")
	b.state = dict.get("state", BuddyData.State.IDLE)
	b.happiness = dict.get("happiness", 0.5)  # goes through property setter → enforces floor

	return b
