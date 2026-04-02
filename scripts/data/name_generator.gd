class_name NameGenerator
extends RefCounted

## NameGenerator — loads curated name lists from JSON and assembles random
## three-part names ("First Middle Last").
## Pure data utility; no scene, no autoload dependency.


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

var _first_names: Array[String] = []
var _middle_names: Array[String] = []
var _last_names: Array[String] = []


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Loads all three name list JSON files from the given directory path.
## Expected files: first_names.json, middle_names.json, last_names.json
## Each file must contain a flat JSON array of strings.
func load_names(directory: String) -> void:
	_first_names = _load_name_file(directory.path_join("first_names.json"))
	_middle_names = _load_name_file(directory.path_join("middle_names.json"))
	_last_names = _load_name_file(directory.path_join("last_names.json"))


## Returns a random three-part name in "First Middle Last" format.
## Requires load_names() to have been called first with non-empty lists.
func generate(rng: RandomNumberGenerator) -> String:
	var first: String = _first_names[rng.randi() % _first_names.size()]
	var middle: String = _middle_names[rng.randi() % _middle_names.size()]
	var last: String = _last_names[rng.randi() % _last_names.size()]
	return "%s %s %s" % [first, middle, last]


func first_name_count() -> int:
	return _first_names.size()


func middle_name_count() -> int:
	return _middle_names.size()


func last_name_count() -> int:
	return _last_names.size()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _load_name_file(path: String) -> Array[String]:
	var result: Array[String] = []

	if not FileAccess.file_exists(path):
		push_warning("NameGenerator: file not found: %s" % path)
		return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("NameGenerator: could not open: %s" % path)
		return result

	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(raw_text)
	if err != OK:
		push_warning("NameGenerator: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return result

	var parsed = json.get_data()
	if not parsed is Array:
		push_warning("NameGenerator: expected Array in %s, got %s" % [path, typeof(parsed)])
		return result

	for entry in parsed:
		result.append(str(entry))

	return result
