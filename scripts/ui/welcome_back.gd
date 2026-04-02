extends CanvasLayer

## WelcomeBack — shown when the player returns after being offline.
## Call show_recap() with offline catch-up data to display the panel.


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var panel: PanelContainer = $Panel
@onready var message_label: RichTextLabel = $Panel/VBox/Message
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	panel.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Display the offline recap panel.
## elapsed_seconds   — total time away in seconds
## stardust_earned   — stardust accumulated while offline
## new_buddies       — list of buddy_ids that joined while away
## completed_expeditions — list of Dicts with keys: buddy_id, result_type
func show_recap(
		elapsed_seconds: float,
		stardust_earned: int,
		new_buddies: Array,
		completed_expeditions: Array
) -> void:
	message_label.text = _build_text(
		elapsed_seconds, stardust_earned, new_buddies, completed_expeditions
	)
	panel.visible = true


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _build_text(
		elapsed_seconds: float,
		stardust_earned: int,
		new_buddies: Array,
		completed_expeditions: Array
) -> String:
	var text := "[center][b]Welcome back![/b][/center]\n\n"

	# Time-away line
	var total_minutes := int(elapsed_seconds / 60.0)
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	if hours >= 1:
		text += "You were away for %dh %dm.\n\n" % [hours, minutes]
	else:
		text += "You were away for %dm.\n\n" % minutes

	# Activity summary header
	text += "While you were gone...\n"
	text += "  +%d stardust collected\n" % stardust_earned

	# Completed expeditions
	for exp in completed_expeditions:
		var buddy_id: String = exp.get("buddy_id", "A buddy")
		var result_type: String = exp.get("result_type", "")
		match result_type:
			"blob":
				text += "  %s came back from vacation with a new friend!\n" % buddy_id
			"claude_buddy":
				text += "  %s met a rare buddy on vacation!\n" % buddy_id
			"decoration":
				text += "  %s found a cute trinket!\n" % buddy_id
			_:
				text += "  %s had a lovely time.\n" % buddy_id

	# New buddies
	if new_buddies.size() > 0:
		text += "\n%d new buddies joined the sanctuary!" % new_buddies.size()

	return text


func _on_continue_pressed() -> void:
	panel.visible = false
