extends Node2D

## Main — coordinates zone swapping and wires all UI events together.
## Loaded as the root scene. Holds references to all UI panels and the active zone.


# ---------------------------------------------------------------------------
# Zone scene map (add entries here as new zones are built)
# ---------------------------------------------------------------------------

const ZONE_SCENES := {
	"meadow": preload("res://scenes/zones/meadow.tscn"),
}


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var camera: Camera2D              = $Camera2D
@onready var hud: CanvasLayer              = $HUD
@onready var zone_nav: ZoneNav             = $ZoneNav
@onready var buddy_info_card: PanelContainer = $BuddyInfoCard
@onready var expedition_panel: PanelContainer = $ExpeditionPanel
@onready var decoration_shop: DecorationShop  = $DecorationShop
@onready var welcome_back: CanvasLayer       = $WelcomeBack


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _current_zone: ZoneBase = null
var _panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Grab the meadow node that's already a child in main.tscn
	_current_zone = $Meadow

	# Zone navigation
	zone_nav.zone_changed.connect(_on_zone_changed)

	# Buddy info card signals
	buddy_info_card.expedition_requested.connect(_on_expedition_requested)

	# Wire zone's buddy-clicked into our info card handler
	_connect_zone_clicks()

	# Set initial HUD zone name
	_update_hud_zone_name()

	# Show welcome-back screen if offline catchup data is waiting
	if Sanctuary.has_pending_catchup():
		var catchup: Dictionary = Sanctuary.consume_pending_catchup()
		welcome_back.show_recap(
			catchup.get("elapsed_seconds", 0.0),
			catchup.get("stardust_earned", 0),
			catchup.get("new_buddies", []),
			catchup.get("completed_expeditions", [])
		)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

const ZOOM_MIN := 0.5
const ZOOM_MAX := 3.0
const ZOOM_STEP := 0.1

func _input(event: InputEvent) -> void:
	# Scroll wheel zoom
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_camera(ZOOM_STEP)
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_camera(-ZOOM_STEP)
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_panning = true
				_pan_start = event.position
		else:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_panning = false

	# Click-drag pan
	if event is InputEventMouseMotion and _panning:
		var delta: Vector2 = event.position - _pan_start
		_pan_start = event.position
		camera.position -= delta / camera.zoom
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		# Don't capture shortcuts while a text field is focused
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner is LineEdit or focus_owner is TextEdit:
			return

		match event.keycode:
			KEY_ESCAPE:
				Sanctuary.save_game()
				get_tree().quit()
			KEY_E:
				expedition_panel.toggle()
				get_viewport().set_input_as_handled()
			KEY_S:
				decoration_shop.current_zone_id = _current_zone.zone_id if _current_zone else "meadow"
				decoration_shop.toggle()
				get_viewport().set_input_as_handled()


func _zoom_camera(step: float) -> void:
	var new_zoom := clampf(camera.zoom.x + step, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)


# ---------------------------------------------------------------------------
# Zone management
# ---------------------------------------------------------------------------

func _on_zone_changed(zone_id: String) -> void:
	# Remove old zone
	if _current_zone != null:
		_current_zone.queue_free()
		_current_zone = null

	# Load and add new zone
	if ZONE_SCENES.has(zone_id):
		var packed: PackedScene = ZONE_SCENES[zone_id]
		var new_zone: ZoneBase = packed.instantiate()
		add_child(new_zone)
		move_child(new_zone, 0)   # keep zone behind UI CanvasLayers
		_current_zone = new_zone
		_connect_zone_clicks()
	else:
		push_warning("Main: no scene registered for zone_id '%s'" % zone_id)

	# Keep decoration shop pointed at the active zone
	if decoration_shop != null and _current_zone != null:
		decoration_shop.current_zone_id = _current_zone.zone_id

	_update_hud_zone_name()


func _connect_zone_clicks() -> void:
	if _current_zone == null:
		return
	if not _current_zone.buddy_clicked.is_connected(_show_info_card):
		_current_zone.buddy_clicked.connect(_show_info_card)


# ---------------------------------------------------------------------------
# Buddy info card
# ---------------------------------------------------------------------------

func _show_info_card(buddy_data: BuddyData) -> void:
	buddy_info_card.show_buddy(buddy_data)


func _on_expedition_requested(buddy: BuddyData) -> void:
	var success: bool = Sanctuary.send_on_expedition(buddy)
	if success:
		# Refresh the card so the expedition button disables correctly
		buddy_info_card.show_buddy(buddy)
	else:
		push_warning("Main: expedition slots full or buddy already on expedition.")


# ---------------------------------------------------------------------------
# HUD helpers
# ---------------------------------------------------------------------------

func _update_hud_zone_name() -> void:
	if _current_zone == null:
		return
	var zone_data: Dictionary = Sanctuary.zone_manager.get_zone_data(_current_zone.zone_id)
	var display_name: String = zone_data.get("name", _current_zone.zone_id)
	hud.set_zone_name(display_name)
