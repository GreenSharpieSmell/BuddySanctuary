extends PanelContainer

## BuddyInfoCard — shows details for a clicked buddy in the bottom-right corner.
## Emits expedition_requested and rename_requested when the corresponding buttons are pressed.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal expedition_requested(buddy: BuddyData)
signal rename_requested(buddy: BuddyData)


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var name_label: Label = $VBox/NameLabel
@onready var species_label: Label = $VBox/SpeciesLabel
@onready var rarity_label: Label = $VBox/RarityLabel
@onready var personality_label: Label = $VBox/PersonalityLabel
@onready var happiness_bar: ProgressBar = $VBox/HappinessBar
@onready var expedition_btn: Button = $VBox/Buttons/ExpeditionBtn
@onready var rename_btn: Button = $VBox/Buttons/RenameBtn
@onready var close_btn: Button = $VBox/Buttons/CloseBtn


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _current_buddy: BuddyData = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	expedition_btn.pressed.connect(_on_expedition_pressed)
	rename_btn.pressed.connect(_on_rename_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	visible = false


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Populate and show the card for the given buddy.
func show_buddy(buddy: BuddyData) -> void:
	_current_buddy = buddy

	name_label.text = buddy.buddy_name

	# Capitalize first letter of species string
	var sp: String = buddy.species
	species_label.text = sp.capitalize()

	# Rarity: enum key name, plus SHINY badge when applicable
	var rarity_name: String = BuddyData.Rarity.keys()[buddy.rarity]
	if buddy.shiny:
		rarity_name += " (SHINY)"
	rarity_label.text = rarity_name

	# Personality as percentages
	var p := buddy.personality
	personality_label.text = (
		"Curiosity %d%%  Shyness %d%%  Energy %d%%\nWarmth %d%%  Social %d%%" % [
			int(p.curiosity * 100),
			int(p.shyness * 100),
			int(p.energy * 100),
			int(p.warmth * 100),
			int(p.social * 100),
		]
	)

	happiness_bar.value = buddy.happiness

	# Disable expedition button if the buddy is already on expedition
	expedition_btn.disabled = (buddy.state == BuddyData.State.EXPEDITION)

	visible = true


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_expedition_pressed() -> void:
	if _current_buddy != null:
		expedition_requested.emit(_current_buddy)


func _on_rename_pressed() -> void:
	if _current_buddy != null:
		rename_requested.emit(_current_buddy)


func _on_close_pressed() -> void:
	visible = false
	_current_buddy = null
