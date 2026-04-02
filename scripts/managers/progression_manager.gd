class_name ProgressionManager
extends RefCounted

## ProgressionManager — tracks stardust currency and milestone progress.
## Standalone manager with no dependencies on other classes.


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal stardust_changed(new_amount: int)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const STARDUST_PER_BUDDY_PER_MINUTE: int = 1


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var stardust: int = 0
var total_buddies_found: int = 0


# ---------------------------------------------------------------------------
# Stardust economy
# ---------------------------------------------------------------------------

## Add stardust and notify listeners.
func earn_stardust(amount: int) -> void:
	stardust += amount
	stardust_changed.emit(stardust)


## Attempt to spend stardust. Returns true and deducts if funds are sufficient;
## returns false and leaves stardust unchanged if not.
func spend_stardust(amount: int) -> bool:
	if stardust < amount:
		return false
	stardust -= amount
	stardust_changed.emit(stardust)
	return true


## Calculate how much passive stardust buddy_count buddies would generate
## over elapsed_seconds seconds.
func calculate_passive_stardust(buddy_count: int, elapsed_seconds: float) -> int:
	return int(buddy_count * (elapsed_seconds / 60.0) * STARDUST_PER_BUDDY_PER_MINUTE)


# ---------------------------------------------------------------------------
# Milestone tracking
# ---------------------------------------------------------------------------

## Increment the all-time buddy discovery counter.
func record_buddy_found() -> void:
	total_buddies_found += 1


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serialize state to a dictionary.
func to_dict() -> Dictionary:
	return {
		"stardust": stardust,
		"total_buddies_found": total_buddies_found,
	}


## Restore state from a dictionary.
func load_from_dict(dict: Dictionary) -> void:
	stardust = dict.get("stardust", 0)
	total_buddies_found = dict.get("total_buddies_found", 0)
