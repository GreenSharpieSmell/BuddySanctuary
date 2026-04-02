class_name ZoneManager
extends RefCounted

## ZoneManager — tracks unlocked zones, decoration placements, and zone unlock milestones.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal zone_unlocked(zone_id: String)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const MAX_EXPEDITION_SLOTS := 5


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

var _zone_defs: Array[Dictionary] = []
var _decoration_defs: Array[Dictionary] = []
var _unlocked_zones: Array[String] = []
var _placed_decorations: Dictionary = {}  # zone_id (String) -> Array of {id, position}


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

## Load zone and decoration definitions from JSON files.
## Initialises unlocked zones to ["meadow"].
func load_data(zones_path: String, decorations_path: String) -> void:
	_zone_defs = _load_json_array(zones_path, "zones")
	_decoration_defs = _load_json_array(decorations_path, "decorations")
	_unlocked_zones = ["meadow"]


func _load_json_array(path: String, key: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ZoneManager: could not open file: " + path)
		return []
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary or not parsed.has(key):
		push_error("ZoneManager: malformed JSON at " + path)
		return []

	var result: Array[Dictionary] = []
	for item in parsed[key]:
		result.append(item)
	return result


# ---------------------------------------------------------------------------
# Zone queries
# ---------------------------------------------------------------------------

## Returns true if the given zone has been unlocked.
func is_zone_unlocked(zone_id: String) -> bool:
	return _unlocked_zones.has(zone_id)


## Unlock every zone whose unlock_at threshold is met by buddy_count.
## Emits zone_unlocked for each newly unlocked zone (in definition order).
func check_unlocks(buddy_count: int) -> void:
	for zone in _zone_defs:
		var zid: String = zone["id"]
		if not _unlocked_zones.has(zid) and buddy_count >= zone["unlock_at"]:
			_unlocked_zones.append(zid)
			zone_unlocked.emit(zid)


## Returns all currently unlocked zone ids.
func get_unlocked_zone_ids() -> Array[String]:
	var result: Array[String] = []
	for zid in _unlocked_zones:
		result.append(zid)
	return result


## Returns the zone definition dictionary for the given id.
## Returns an empty dictionary if not found.
func get_zone_data(zone_id: String) -> Dictionary:
	for zone in _zone_defs:
		if zone["id"] == zone_id:
			return zone
	return {}


# ---------------------------------------------------------------------------
# Decoration placement
# ---------------------------------------------------------------------------

## Place a decoration in a zone at the given position.
func place_decoration(zone_id: String, deco_id: String, position: Vector2) -> void:
	if not _placed_decorations.has(zone_id):
		_placed_decorations[zone_id] = []
	_placed_decorations[zone_id].append({"id": deco_id, "position": position})


## Remove a placed decoration from a zone by index.
func remove_decoration(zone_id: String, index: int) -> void:
	if not _placed_decorations.has(zone_id):
		return
	var list: Array = _placed_decorations[zone_id]
	if index >= 0 and index < list.size():
		list.remove_at(index)


## Returns all placed decorations in the given zone.
func get_decorations_in_zone(zone_id: String) -> Array:
	if not _placed_decorations.has(zone_id):
		return []
	return _placed_decorations[zone_id]


# ---------------------------------------------------------------------------
# Decoration definitions
# ---------------------------------------------------------------------------

## Returns decoration definitions available in currently unlocked zones.
func get_available_decorations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for deco in _decoration_defs:
		if _unlocked_zones.has(deco["unlock_zone"]):
			result.append(deco)
	return result


## Look up a decoration definition by id. Returns an empty dictionary if not found.
func get_decoration_def(deco_id: String) -> Dictionary:
	for deco in _decoration_defs:
		if deco["id"] == deco_id:
			return deco
	return {}


# ---------------------------------------------------------------------------
# Expedition slots
# ---------------------------------------------------------------------------

## Returns how many expedition slots are available.
## Scales with number of unlocked zones, capped at MAX_EXPEDITION_SLOTS.
func get_expedition_slots() -> int:
	return mini(_unlocked_zones.size(), MAX_EXPEDITION_SLOTS)


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize unlocked zones and placed decorations to a dictionary.
## Vector2 positions are stored as [x, y] arrays.
func to_dict() -> Dictionary:
	var placed: Dictionary = {}
	for zone_id in _placed_decorations:
		var entries: Array = []
		for entry in _placed_decorations[zone_id]:
			entries.append({
				"id": entry["id"],
				"position": [entry["position"].x, entry["position"].y]
			})
		placed[zone_id] = entries

	return {
		"unlocked_zones": _unlocked_zones.duplicate(),
		"placed_decorations": placed
	}


## Restore state from a serialized dictionary.
func load_from_dict(dict: Dictionary) -> void:
	if dict.has("unlocked_zones"):
		_unlocked_zones.clear()
		for zid in dict["unlocked_zones"]:
			_unlocked_zones.append(zid)

	_placed_decorations.clear()
	if dict.has("placed_decorations"):
		for zone_id in dict["placed_decorations"]:
			var entries: Array = []
			for entry in dict["placed_decorations"][zone_id]:
				var pos_arr: Array = entry["position"]
				entries.append({
					"id": entry["id"],
					"position": Vector2(pos_arr[0], pos_arr[1])
				})
			_placed_decorations[zone_id] = entries
