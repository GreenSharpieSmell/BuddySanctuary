class_name SaveManager
extends RefCounted

## SaveManager — JSON save/load and offline catch-up calculation.
## Single save slot written to save_path as a JSON file.


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var save_path: String = "user://buddy_sanctuary_save.json"


# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

## Persist all game state to the save file.
func save_game(
	roster: BuddyRoster,
	zone_mgr: ZoneManager,
	progression: ProgressionManager,
	expeditions: ExpeditionManager,
) -> void:
	var data := {
		"last_played": Time.get_unix_time_from_system(),
		"buddy_roster": roster.to_array(),
		"zones": zone_mgr.to_dict(),
		"progression": progression.to_dict(),
		"expeditions": expeditions.to_array(),
	}
	var json_string := JSON.stringify(data, "  ")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------

## Load game state into the provided managers.
## Returns false if no save file exists or the file cannot be parsed.
func load_game(
	roster: BuddyRoster,
	zone_mgr: ZoneManager,
	progression: ProgressionManager,
	expeditions: ExpeditionManager,
) -> bool:
	if not FileAccess.file_exists(save_path):
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	var err  := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SaveManager: failed to parse save file at " + save_path)
		return false

	var data: Dictionary = json.data

	roster.load_from_array(data.get("buddy_roster", []))
	zone_mgr.load_from_dict(data.get("zones", {}))
	progression.load_from_dict(data.get("progression", {}))
	expeditions.load_from_array(data.get("expeditions", []), roster)

	return true


# ---------------------------------------------------------------------------
# Last-played timestamp
# ---------------------------------------------------------------------------

## Return the last_played unix timestamp from the save file, or 0.0 if none.
func get_last_played() -> float:
	if not FileAccess.file_exists(save_path):
		return 0.0

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return 0.0

	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	return data.get("last_played", 0.0)


# ---------------------------------------------------------------------------
# Offline catch-up
# ---------------------------------------------------------------------------

## Calculate passive gains that accrued while the game was closed.
## Uses ProgressionManager's formula: buddy_count * elapsed_seconds / 60.0 * 1.
## Returns {"stardust_earned": int, "elapsed_seconds": float}.
func calculate_offline_catchup(elapsed_seconds: float, buddy_count: int) -> Dictionary:
	var pm       := ProgressionManager.new()
	var stardust := pm.calculate_passive_stardust(buddy_count, elapsed_seconds)
	return {
		"stardust_earned": stardust,
		"elapsed_seconds": elapsed_seconds,
	}
