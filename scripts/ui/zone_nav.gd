class_name ZoneNav
extends CanvasLayer

## ZoneNav — arrow buttons and zone name label for navigating between unlocked zones.
## Emits zone_changed(zone_id) when the player moves to a different zone.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal zone_changed(zone_id: String)


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var left_arrow: Button = $LeftArrow
@onready var right_arrow: Button = $RightArrow
@onready var zone_name: Label   = $ZoneName


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _zone_ids: Array[String] = []
var _current_index: int = 0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	left_arrow.pressed.connect(_go_left)
	right_arrow.pressed.connect(_go_right)
	Sanctuary.zone_manager.zone_unlocked.connect(_on_zone_unlocked)
	_refresh_zones()


# ---------------------------------------------------------------------------
# Zone list management
# ---------------------------------------------------------------------------

func _refresh_zones() -> void:
	_zone_ids = Sanctuary.zone_manager.get_unlocked_zone_ids()
	# Clamp index in case zones were removed (shouldn't happen, but safe)
	_current_index = clampi(_current_index, 0, maxi(0, _zone_ids.size() - 1))
	_update_display()


func _update_display() -> void:
	if _zone_ids.is_empty():
		zone_name.text = ""
		left_arrow.visible = false
		right_arrow.visible = false
		return

	var zone_data: Dictionary = Sanctuary.zone_manager.get_zone_data(_zone_ids[_current_index])
	zone_name.text = zone_data.get("name", _zone_ids[_current_index])

	left_arrow.visible  = _current_index > 0
	right_arrow.visible = _current_index < _zone_ids.size() - 1


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

func _go_left() -> void:
	if _current_index <= 0:
		return
	_current_index -= 1
	_update_display()
	zone_changed.emit(_zone_ids[_current_index])


func _go_right() -> void:
	if _current_index >= _zone_ids.size() - 1:
		return
	_current_index += 1
	_update_display()
	zone_changed.emit(_zone_ids[_current_index])


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_zone_unlocked(_zone_id: String) -> void:
	_refresh_zones()
