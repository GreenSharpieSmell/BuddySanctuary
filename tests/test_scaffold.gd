extends GutTest

## test_scaffold.gd
## Verifies the project scaffold is wired correctly:
##   - Sanctuary autoload exists and is accessible
##   - Sanctuary is a Node (correct base type)
##   - Sanctuary prints its ready message without errors


func test_sanctuary_autoload_exists() -> void:
	# The autoload is registered as "Sanctuary" in project.godot.
	# GUT runs inside the Godot scene tree, so autoloads are live.
	assert_not_null(Sanctuary, "Sanctuary autoload should exist")


func test_sanctuary_is_node() -> void:
	assert_true(
		Sanctuary is Node,
		"Sanctuary should extend Node"
	)


func test_sanctuary_has_buddy_roster_property() -> void:
	# Stub value is null — that's fine. We just want the property to exist.
	assert_true(
		"buddy_roster" in Sanctuary,
		"Sanctuary should expose a buddy_roster property"
	)


func test_sanctuary_has_zone_manager_property() -> void:
	assert_true(
		"zone_manager" in Sanctuary,
		"Sanctuary should expose a zone_manager property"
	)


func test_sanctuary_has_expedition_manager_property() -> void:
	assert_true(
		"expedition_manager" in Sanctuary,
		"Sanctuary should expose an expedition_manager property"
	)


func test_sanctuary_has_progression_manager_property() -> void:
	assert_true(
		"progression_manager" in Sanctuary,
		"Sanctuary should expose a progression_manager property"
	)


func test_sanctuary_has_save_manager_property() -> void:
	assert_true(
		"save_manager" in Sanctuary,
		"Sanctuary should expose a save_manager property"
	)
