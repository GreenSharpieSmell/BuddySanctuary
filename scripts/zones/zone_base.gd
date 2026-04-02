class_name ZoneBase
extends Node2D

## ZoneBase — template for all side-scroll zone scenes.
## Manages buddy population, decoration placement, and click interaction
## within a depth band running across the zone width.


# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

@export var zone_id: String = "meadow"


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var background: ParallaxBackground = $ParallaxBackground
@onready var buddy_container: Node2D        = $BuddyContainer
@onready var decoration_container: Node2D   = $DecorationContainer


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BUDDY_SCENE:        PackedScene = preload("res://scenes/buddy/buddy.tscn")
const DEPTH_BAND_TOP:     float       = 300.0
const DEPTH_BAND_BOTTOM:  float       = 600.0
const ZONE_WIDTH:         float       = 1920.0


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _buddy_sprites: Dictionary = {}  # buddy_id (String) -> BuddySprite node


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_populate_buddies()
	_populate_decorations()


# ---------------------------------------------------------------------------
# Buddy population
# ---------------------------------------------------------------------------

func _populate_buddies() -> void:
	# Clear any previously spawned sprites
	for child in buddy_container.get_children():
		child.queue_free()
	_buddy_sprites.clear()

	var buddies: Array[BuddyData] = Sanctuary.buddy_roster.get_buddies_in_zone(zone_id)
	for buddy_data in buddies:
		_spawn_buddy(buddy_data)


func _spawn_buddy(buddy_data: BuddyData) -> void:
	var buddy_node: BuddySprite = BUDDY_SCENE.instantiate()
	buddy_container.add_child(buddy_node)

	# Random starting position within the depth band
	var x: float = Sanctuary.rng.randf_range(64.0, ZONE_WIDTH - 64.0)
	var y: float = Sanctuary.rng.randf_range(DEPTH_BAND_TOP, DEPTH_BAND_BOTTOM)
	buddy_node.position = Vector2(x, y)

	buddy_node.setup(buddy_data, Sanctuary.buddy_creator._part_pool)
	buddy_node.clicked.connect(_on_buddy_clicked)

	_buddy_sprites[buddy_data.id] = buddy_node


# ---------------------------------------------------------------------------
# Decoration population
# ---------------------------------------------------------------------------

func _populate_decorations() -> void:
	# Clear any previously placed decorations
	for child in decoration_container.get_children():
		child.queue_free()

	var decorations: Array = Sanctuary.zone_manager.get_decorations_in_zone(zone_id)
	for entry in decorations:
		var sprite := Sprite2D.new()
		decoration_container.add_child(sprite)

		var pos: Vector2 = entry.get("position", Vector2.ZERO)
		sprite.position = pos
		sprite.z_index  = int(pos.y)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_buddy_clicked(buddy_data: BuddyData) -> void:
	print("Clicked: %s (%s)" % [buddy_data.buddy_name, buddy_data.species])
