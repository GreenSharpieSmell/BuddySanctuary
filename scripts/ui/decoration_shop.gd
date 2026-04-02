class_name DecorationShop
extends PanelContainer

## DecorationShop — lets the player browse, buy, and place decorations using stardust.
## Toggle open/closed via toggle(). Entering placement mode hides the panel; a left-click
## in the viewport places the selected decoration and clears placement mode.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal decoration_placed(deco_id: String, zone_id: String, position: Vector2)


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var item_list: VBoxContainer  = %ItemList
@onready var stardust_label: Label     = %StardustLabel


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _placing_deco_id: String = ""

## The zone to place into. Set by the owner scene before toggling open.
var current_zone_id: String = "meadow"


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	hide()
	Sanctuary.progression.stardust_changed.connect(_on_stardust_changed)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Toggle the shop panel. Refreshes content when shown.
func toggle() -> void:
	if visible:
		hide()
	else:
		_refresh()
		show()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _refresh() -> void:
	stardust_label.text = "Stardust: %d" % Sanctuary.progression.stardust

	# Clear old buttons
	for child in item_list.get_children():
		child.queue_free()

	var decorations: Array[Dictionary] = Sanctuary.zone_manager.get_available_decorations()
	for deco in decorations:
		var deco_id: String   = deco.get("id", "")
		var name_str: String  = deco.get("name", deco_id)
		var cost: int         = deco.get("cost", 0)

		var btn := Button.new()
		btn.text = "%s — %d stardust" % [name_str, cost]
		btn.disabled = Sanctuary.progression.stardust < cost

		# Capture deco_id in closure
		var captured_id := deco_id
		btn.pressed.connect(func() -> void: _on_buy(captured_id))

		item_list.add_child(btn)


func _on_buy(deco_id: String) -> void:
	_placing_deco_id = deco_id
	hide()  # Enter placement mode — shop is hidden while player clicks


# ---------------------------------------------------------------------------
# Input — placement mode
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _placing_deco_id.is_empty():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var click_pos: Vector2 = mb.position

			var success: bool = Sanctuary.buy_decoration(_placing_deco_id, current_zone_id, click_pos)
			if success:
				decoration_placed.emit(_placing_deco_id, current_zone_id, click_pos)

			_placing_deco_id = ""
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_stardust_changed(_new_amount: int) -> void:
	if visible:
		_refresh()
