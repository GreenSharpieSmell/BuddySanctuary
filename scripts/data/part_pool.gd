class_name PartPool
extends RefCounted

## PartPool — loads part definitions from JSON files and performs
## rarity-weighted random picks for buddy creation.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const RARITY_WEIGHTS: Dictionary = {
	BuddyData.Rarity.COMMON:    60.0,
	BuddyData.Rarity.UNCOMMON:  25.0,
	BuddyData.Rarity.RARE:      10.0,
	BuddyData.Rarity.EPIC:       4.0,
	BuddyData.Rarity.LEGENDARY:  1.0,
}

const ACCESSORY_EQUIP_CHANCE: float = 0.5


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

var _bodies:     Array[Dictionary] = []
var _eyes:       Array[Dictionary] = []
var _mouths:     Array[Dictionary] = []
var _accessories: Dictionary = {}  # slot_name -> Array[Dictionary]


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

## Loads all 4 JSON files from the given directory path.
## Expected files: bodies.json, eyes.json, mouths.json, accessories.json
func load_from_directory(path: String) -> void:
	_bodies  = _load_flat_pool(path.path_join("bodies.json"))
	_eyes    = _load_flat_pool(path.path_join("eyes.json"))
	_mouths  = _load_flat_pool(path.path_join("mouths.json"))
	_accessories = _load_accessory_pool(path.path_join("accessories.json"))


func _load_flat_pool(file_path: String) -> Array[Dictionary]:
	var raw: Array = _read_json_array(file_path, "parts")
	var result: Array[Dictionary] = []
	for i in range(raw.size()):
		var part: Dictionary = raw[i]
		part["_index"] = i
		part["rarity"] = rarity_from_string(part.get("rarity", "common"))
		result.append(part)
	return result


func _load_accessory_pool(file_path: String) -> Dictionary:
	var text: String = _read_file(file_path)
	if text.is_empty():
		return {}

	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("PartPool: failed to parse %s — %s" % [file_path, json.get_error_message()])
		return {}

	var data = json.get_data()
	if not (data is Dictionary) or not data.has("slots"):
		push_error("PartPool: %s missing 'slots' key" % file_path)
		return {}

	var result: Dictionary = {}
	var slots: Dictionary = data["slots"]
	for slot_name in slots.keys():
		var raw: Array = slots[slot_name]
		var arr: Array[Dictionary] = []
		for i in range(raw.size()):
			var part: Dictionary = raw[i]
			part["_index"] = i
			part["rarity"] = rarity_from_string(part.get("rarity", "common"))
			arr.append(part)
		result[slot_name] = arr
	return result


func _read_json_array(file_path: String, array_key: String) -> Array:
	var text: String = _read_file(file_path)
	if text.is_empty():
		return []

	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("PartPool: failed to parse %s — %s" % [file_path, json.get_error_message()])
		return []

	var data = json.get_data()
	if not (data is Dictionary) or not data.has(array_key):
		push_error("PartPool: %s missing '%s' key" % [file_path, array_key])
		return []

	return data[array_key]


func _read_file(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		push_error("PartPool: file not found: %s" % file_path)
		return ""
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		push_error("PartPool: could not open: %s" % file_path)
		return ""
	var text: String = f.get_as_text()
	f.close()
	return text


# ---------------------------------------------------------------------------
# Body accessors
# ---------------------------------------------------------------------------

func body_count() -> int:
	return _bodies.size()


func get_body(index: int) -> Dictionary:
	return _bodies[index]


# ---------------------------------------------------------------------------
# Weighted random picks
# ---------------------------------------------------------------------------

## Rarity-weighted pick from "bodies", "eyes", or "mouths" pool.
func pick_random_part(pool_name: String, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array[Dictionary]
	match pool_name:
		"bodies":
			pool = _bodies
		"eyes":
			pool = _eyes
		"mouths":
			pool = _mouths
		_:
			push_error("PartPool: unknown pool '%s'" % pool_name)
			return {}

	return _weighted_pick(pool, rng)


## Rarity-weighted pick from a named accessory slot.
func pick_random_accessory(slot_name: String, rng: RandomNumberGenerator) -> Dictionary:
	if not _accessories.has(slot_name):
		push_error("PartPool: unknown accessory slot '%s'" % slot_name)
		return {}
	var pool: Array[Dictionary] = _accessories[slot_name]
	return _weighted_pick(pool, rng)


## 50% chance returns null (empty slot). Otherwise picks a rarity-weighted
## accessory from the given slot.
func pick_random_accessory_or_empty(slot_name: String, rng: RandomNumberGenerator) -> Variant:
	if rng.randf() < ACCESSORY_EQUIP_CHANCE:
		return null
	return pick_random_accessory(slot_name, rng)


## Core weighted-pick algorithm.
## Groups pool entries by rarity, rolls to select a rarity tier,
## then picks uniformly within that tier.
func _weighted_pick(pool: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	if pool.is_empty():
		return {}

	# Group by rarity
	var groups: Dictionary = {}  # BuddyData.Rarity -> Array[Dictionary]
	for part in pool:
		var r: BuddyData.Rarity = part["rarity"]
		if not groups.has(r):
			groups[r] = []
		groups[r].append(part)

	# Sum weights for present rarities only
	var total_weight: float = 0.0
	for r in groups.keys():
		total_weight += RARITY_WEIGHTS[r]

	# Roll
	var roll: float = rng.randf() * total_weight

	# Walk cumulative sums to select rarity tier
	var cumulative: float = 0.0
	var chosen_rarity: BuddyData.Rarity = groups.keys()[0]
	for r in groups.keys():
		cumulative += RARITY_WEIGHTS[r]
		if roll <= cumulative:
			chosen_rarity = r
			break

	# Uniform pick within tier
	var tier: Array = groups[chosen_rarity]
	return tier[rng.randi() % tier.size()]


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

## Converts a rarity string to the BuddyData.Rarity enum value.
static func rarity_from_string(s: String) -> BuddyData.Rarity:
	match s.to_lower():
		"common":
			return BuddyData.Rarity.COMMON
		"uncommon":
			return BuddyData.Rarity.UNCOMMON
		"rare":
			return BuddyData.Rarity.RARE
		"epic":
			return BuddyData.Rarity.EPIC
		"legendary":
			return BuddyData.Rarity.LEGENDARY
		_:
			push_warning("PartPool: unknown rarity string '%s', defaulting to COMMON" % s)
			return BuddyData.Rarity.COMMON
