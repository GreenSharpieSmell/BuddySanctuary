class_name BuddyRoster
extends RefCounted

## BuddyRoster — owns and manages all buddy instances.
## Central access point for the buddy collection.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal buddy_added(buddy: BuddyData)


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

var _buddies: Dictionary = {}  # id (String) -> BuddyData


# ---------------------------------------------------------------------------
# Mutation
# ---------------------------------------------------------------------------

## Add a buddy to the roster and emit buddy_added.
func add_buddy(buddy: BuddyData) -> void:
	_buddies[buddy.id] = buddy
	buddy_added.emit(buddy)


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

## Look up a buddy by id. Returns null if not found.
func get_buddy(id: String) -> BuddyData:
	return _buddies.get(id, null)


## Total number of buddies in the roster.
func count() -> int:
	return _buddies.size()


## All buddies as an array (unordered).
func get_all() -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		result.append(buddy)
	return result


## Buddies currently in the given zone, excluding those on EXPEDITION.
func get_buddies_in_zone(zone_id: String) -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		if buddy.current_zone == zone_id and buddy.state != BuddyData.State.EXPEDITION:
			result.append(buddy)
	return result


## Buddies available for an expedition (not currently on EXPEDITION).
func get_available_for_expedition() -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		if buddy.state != BuddyData.State.EXPEDITION:
			result.append(buddy)
	return result


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize all buddies to an array of dictionaries.
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buddy in _buddies.values():
		result.append(buddy.to_dict())
	return result


## Clear the roster and rebuild it from an array of dictionaries.
func load_from_array(arr: Array) -> void:
	_buddies.clear()
	for dict in arr:
		var buddy: BuddyData = BuddyData.from_dict(dict)
		_buddies[buddy.id] = buddy
