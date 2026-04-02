extends PanelContainer

## ExpeditionPanel — shows active expeditions with countdown timers.
## Toggle visibility via toggle(). Refreshes every frame while visible.


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var slot_container: VBoxContainer = $VBox/SlotContainer
@onready var available_label: Label = $VBox/AvailableLabel


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		_refresh()


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Toggle panel visibility. Refreshes display when opening.
func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _refresh() -> void:
	var em := Sanctuary.expedition_manager
	var active: int = em.active_count()
	var max_slots: int = em.max_slots

	available_label.text = "Expedition Slots: %d / %d" % [active, max_slots]

	# Clear previous slot entries
	for child in slot_container.get_children():
		child.queue_free()

	# Rebuild slot entries from current expedition data
	var now: float = Time.get_unix_time_from_system()
	for entry_dict in em.to_array():
		var buddy_id: String = entry_dict.get("buddy_id", "???")
		var departure: float = entry_dict.get("departure_time", now)
		var duration: float = entry_dict.get("duration", 0.0)
		var remaining: float = maxf(0.0, (departure + duration) - now)

		var slot_label := Label.new()
		slot_label.text = "%s — %ds remaining" % [buddy_id, int(remaining)]
		slot_container.add_child(slot_label)
