extends Node

## Sanctuary — main autoload singleton.
## Wires all game managers together and acts as the central access point
## for buddy roster, zones, expeditions, progression, and save state.
## This is a stub — managers will be attached as tasks are completed.

# Managers (populated in later tasks)
var buddy_roster = null
var zone_manager = null
var expedition_manager = null
var progression_manager = null
var save_manager = null


func _ready() -> void:
	print("[Sanctuary] Autoload ready.")
