class_name BuddySprite
extends Node2D

## BuddySprite — paper doll visual assembly for a single buddy.
## Assembles Sprite2D children at body anchor points, applies colors,
## handles click interaction, and runs basic pet-reaction animations.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal clicked(buddy_data: BuddyData)


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var body_sprite:     Sprite2D      = $Body
@onready var body_accent:     Sprite2D      = $BodyAccent
@onready var eyes_sprite:     Sprite2D      = $Eyes
@onready var mouth_sprite:    Sprite2D      = $Mouth
@onready var acc_head:        Sprite2D      = $AccHead
@onready var acc_neck:        Sprite2D      = $AccNeck
@onready var acc_held:        Sprite2D      = $AccHeld
@onready var acc_back:        Sprite2D      = $AccBack
@onready var acc_feet:        Sprite2D      = $AccFeet
@onready var click_area:      Area2D        = $ClickArea
@onready var heart_particles: GPUParticles2D = $HeartParticles
@onready var shiny_shimmer:   GPUParticles2D = $ShinyShimmer


# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

var buddy_data: BuddyData
var _part_pool: PartPool
var brain := BuddyBrain.new()


# ---------------------------------------------------------------------------
# Depth sorting constants
# ---------------------------------------------------------------------------

const DEPTH_SCALE_MIN: float = 0.7   # back of depth band — smaller
const DEPTH_SCALE_MAX: float = 1.0   # front — full size
const DEPTH_Y_MIN:     float = 300.0 # y position = back
const DEPTH_Y_MAX:     float = 600.0 # y position = front

# Accessory slot names in the same order as appearance.accessory_indices
const ACCESSORY_SLOTS: Array[String] = ["head", "neck", "held", "back", "feet"]


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialise the sprite from a BuddyData and a loaded PartPool.
## Call this immediately after instancing the scene.
func setup(data: BuddyData, part_pool: PartPool) -> void:
	buddy_data = data
	_part_pool  = part_pool
	brain.setup(data)
	_assemble_appearance()
	_update_depth_sort()
	shiny_shimmer.emitting  = data.shiny
	heart_particles.emitting = false


# ---------------------------------------------------------------------------
# Appearance assembly
# ---------------------------------------------------------------------------

func _assemble_appearance() -> void:
	if buddy_data.species != "blob":
		_assemble_claude_species()
		return

	var ap: BuddyData.BuddyAppearance = buddy_data.appearance

	# Body
	var body_def: Dictionary = _part_pool.get_body(ap.body_index)
	var body_tex: Texture2D = _load_texture(body_def.get("texture", ""))
	body_sprite.texture  = body_tex
	body_sprite.modulate = ap.color_primary

	# Accent layer — same texture, secondary color at reduced opacity
	body_accent.texture  = body_tex
	var accent_color: Color  = ap.color_secondary
	accent_color.a           = 0.3
	body_accent.modulate     = accent_color

	var anchors: Dictionary = body_def.get("anchors", {})

	# Eyes
	var eyes_def: Dictionary = _part_pool.get_eyes(ap.eyes_index)
	eyes_sprite.texture  = _load_texture(eyes_def.get("texture", ""))
	eyes_sprite.position = _anchor_to_position(anchors, "eyes")
	eyes_sprite.visible  = true

	# Mouth
	var mouth_def: Dictionary = _part_pool.get_mouth(ap.mouth_index)
	mouth_sprite.texture  = _load_texture(mouth_def.get("texture", ""))
	mouth_sprite.position = _anchor_to_position(anchors, "mouth")
	mouth_sprite.visible  = true

	# Accessories (5 slots in ACCESSORY_SLOTS order)
	var acc_sprites: Array[Sprite2D] = [acc_head, acc_neck, acc_held, acc_back, acc_feet]
	for i in range(ACCESSORY_SLOTS.size()):
		var sprite: Sprite2D = acc_sprites[i]
		var slot_name: String = ACCESSORY_SLOTS[i]
		var acc_index: int    = ap.accessory_indices[i]

		if acc_index >= 0:
			var acc_def: Dictionary = _part_pool.get_accessory(slot_name, acc_index)
			sprite.texture  = _load_texture(acc_def.get("texture", ""))
			sprite.position = _anchor_to_position(anchors, "acc_" + slot_name)
			sprite.visible  = true
		else:
			sprite.visible = false


func _assemble_claude_species() -> void:
	var tex_path: String = "res://assets/sprites/claude_species/%s.png" % buddy_data.species
	body_sprite.texture  = _load_texture(tex_path)
	body_sprite.modulate = Color.WHITE

	# Hide all non-body parts — claude species are single-sprite
	body_accent.visible  = false
	eyes_sprite.visible  = false
	mouth_sprite.visible = false
	acc_head.visible     = false
	acc_neck.visible     = false
	acc_held.visible     = false
	acc_back.visible     = false
	acc_feet.visible     = false


# ---------------------------------------------------------------------------
# Depth sorting
# ---------------------------------------------------------------------------

func _update_depth_sort() -> void:
	var t: float  = clampf(
		(position.y - DEPTH_Y_MIN) / (DEPTH_Y_MAX - DEPTH_Y_MIN),
		0.0, 1.0
	)
	var s: float  = lerpf(DEPTH_SCALE_MIN, DEPTH_SCALE_MAX, t)
	scale         = Vector2(s, s)
	z_index       = int(position.y)


# ---------------------------------------------------------------------------
# Input / interaction
# ---------------------------------------------------------------------------

func _ready() -> void:
	click_area.input_event.connect(_on_click)


func _process(delta: float) -> void:
	if buddy_data == null:
		return

	brain.tick(delta, Sanctuary.rng)

	if brain.current_action == BuddyBrain.Action.WANDERING:
		# Pick a new target when we have none or have reached the current one.
		if brain.target_position == Vector2.ZERO or \
				position.distance_to(brain.target_position) < 5.0:
			var tx: float = Sanctuary.rng.randf_range(64.0, ZoneBase.ZONE_WIDTH - 64.0)
			var ty: float = Sanctuary.rng.randf_range(
				ZoneBase.DEPTH_BAND_TOP, ZoneBase.DEPTH_BAND_BOTTOM
			)
			brain.target_position = Vector2(tx, ty)

		# Move toward target.
		var direction: Vector2 = (brain.target_position - position).normalized()
		position += direction * brain.move_speed * delta

		# Flip horizontal sprite based on movement direction.
		if direction.x != 0.0:
			body_sprite.flip_h = direction.x < 0.0

		# Clamp to depth band.
		position.y = clampf(position.y, ZoneBase.DEPTH_BAND_TOP, ZoneBase.DEPTH_BAND_BOTTOM)

	_update_depth_sort()


func _on_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_show_pet_reaction()
			clicked.emit(buddy_data)


func _show_pet_reaction() -> void:
	# Boost happiness (floor enforced by BuddyData property setter)
	buddy_data.happiness = minf(buddy_data.happiness + 0.05, 1.0)

	# Heart particles burst
	heart_particles.emitting = true

	# Quick wiggle tween
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 5.0,  0.08)
	tween.tween_property(self, "rotation_degrees", -5.0, 0.10)
	tween.tween_property(self, "rotation_degrees", 0.0,  0.08)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Converts an anchor array [x, y] from the body definition into a local
## Vector2 position for a child sprite.  Anchors are authored as pixel
## coords in a 64x64 canvas (top-left origin), but Godot centres sprites,
## so we shift by half the body size.
func _anchor_to_position(anchors: Dictionary, key: String) -> Vector2:
	if not anchors.has(key):
		return Vector2.ZERO
	var arr: Array = anchors[key]
	# Body sprites are 64x64, centered by Godot → origin is at (32, 32).
	# Anchor values are authored relative to the top-left corner, so subtract
	# the center offset to get the correct child-sprite local position.
	return Vector2(float(arr[0]) - 32.0, float(arr[1]) - 32.0)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path)
	return null
