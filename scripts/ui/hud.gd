extends CanvasLayer

## HUD — top-of-screen display for stardust, buddy count, and current zone name.
## Connects to Sanctuary.progression.stardust_changed and Sanctuary.buddy_roster.buddy_added.


# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------

@onready var stardust_label: Label = $TopBar/StardustLabel
@onready var buddy_count_label: Label = $TopBar/BuddyCountLabel
@onready var zone_label: Label = $TopBar/ZoneLabel


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	Sanctuary.progression.stardust_changed.connect(_on_stardust_changed)
	Sanctuary.buddy_roster.buddy_added.connect(_on_buddy_added)
	_update_display()


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Update the zone name label.
func set_zone_name(zone_name: String) -> void:
	zone_label.text = zone_name


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _update_display() -> void:
	stardust_label.text = "Stardust: %d" % Sanctuary.progression.stardust
	buddy_count_label.text = "Buddies: %d" % Sanctuary.buddy_roster.count()


func _on_stardust_changed(_new_amount: int) -> void:
	_update_display()


func _on_buddy_added(_buddy: BuddyData) -> void:
	_update_display()
