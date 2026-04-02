extends GutTest

## test_buddy_data.gd
## GUT tests for the BuddyData resource class.


# ---------------------------------------------------------------------------
# 1. Create a buddy and verify all identity fields
# ---------------------------------------------------------------------------

func test_create_buddy_data() -> void:
	var buddy := BuddyData.new()
	buddy.id = "buddy_001"
	buddy.species = "blob"
	buddy.rarity = BuddyData.Rarity.UNCOMMON
	buddy.shiny = true
	buddy.buddy_name = "Glimmer"

	assert_eq(buddy.id, "buddy_001", "id should be buddy_001")
	assert_eq(buddy.species, "blob", "species should be blob")
	assert_eq(buddy.rarity, BuddyData.Rarity.UNCOMMON, "rarity should be UNCOMMON")
	assert_true(buddy.shiny, "shiny should be true")
	assert_eq(buddy.buddy_name, "Glimmer", "buddy_name should be Glimmer")


# ---------------------------------------------------------------------------
# 2. Appearance fields — body / eyes / mouth index+rarity, colors
# ---------------------------------------------------------------------------

func test_appearance_fields() -> void:
	var buddy := BuddyData.new()
	buddy.appearance.body_index = 3
	buddy.appearance.body_rarity = BuddyData.Rarity.RARE
	buddy.appearance.eyes_index = 1
	buddy.appearance.eyes_rarity = BuddyData.Rarity.UNCOMMON
	buddy.appearance.mouth_index = 2
	buddy.appearance.mouth_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.color_primary = Color(1.0, 0.0, 0.0)
	buddy.appearance.color_secondary = Color(0.0, 0.0, 1.0)

	assert_eq(buddy.appearance.body_index, 3, "body_index should be 3")
	assert_eq(buddy.appearance.body_rarity, BuddyData.Rarity.RARE, "body_rarity should be RARE")
	assert_eq(buddy.appearance.eyes_index, 1, "eyes_index should be 1")
	assert_eq(buddy.appearance.eyes_rarity, BuddyData.Rarity.UNCOMMON, "eyes_rarity should be UNCOMMON")
	assert_eq(buddy.appearance.mouth_index, 2, "mouth_index should be 2")
	assert_eq(buddy.appearance.mouth_rarity, BuddyData.Rarity.COMMON, "mouth_rarity should be COMMON")
	assert_eq(buddy.appearance.color_primary, Color(1.0, 0.0, 0.0), "color_primary should be red")
	assert_eq(buddy.appearance.color_secondary, Color(0.0, 0.0, 1.0), "color_secondary should be blue")


# ---------------------------------------------------------------------------
# 3. Accessory slots default to -1 (all 5 slots empty)
# ---------------------------------------------------------------------------

func test_accessory_slots_default_empty() -> void:
	var buddy := BuddyData.new()
	assert_eq(buddy.appearance.accessory_indices.size(), 5, "should have 5 accessory slots")
	for i in range(5):
		assert_eq(
			buddy.appearance.accessory_indices[i],
			-1,
			"accessory slot %d should default to -1" % i
		)


# ---------------------------------------------------------------------------
# 4. Personality traits can be set and read back
# ---------------------------------------------------------------------------

func test_personality_range() -> void:
	var buddy := BuddyData.new()
	buddy.personality.curiosity = 0.9
	buddy.personality.shyness = 0.1
	buddy.personality.energy = 0.75
	buddy.personality.warmth = 0.3
	buddy.personality.social = 0.6

	assert_almost_eq(buddy.personality.curiosity, 0.9, 0.0001, "curiosity should be 0.9")
	assert_almost_eq(buddy.personality.shyness, 0.1, 0.0001, "shyness should be 0.1")
	assert_almost_eq(buddy.personality.energy, 0.75, 0.0001, "energy should be 0.75")
	assert_almost_eq(buddy.personality.warmth, 0.3, 0.0001, "warmth should be 0.3")
	assert_almost_eq(buddy.personality.social, 0.6, 0.0001, "social should be 0.6")


# ---------------------------------------------------------------------------
# 5. Happiness floor: can't drop below 0.5, can rise above
# ---------------------------------------------------------------------------

func test_happiness_floor() -> void:
	var buddy := BuddyData.new()

	# Default value
	assert_almost_eq(buddy.happiness, 0.5, 0.0001, "default happiness should be 0.5")

	# Setting below floor should clamp to 0.5
	buddy.happiness = 0.0
	assert_almost_eq(buddy.happiness, 0.5, 0.0001, "happiness should not drop below 0.5")

	buddy.happiness = -10.0
	assert_almost_eq(buddy.happiness, 0.5, 0.0001, "happiness should clamp to floor even for large negatives")

	# Setting above floor is allowed
	buddy.happiness = 0.8
	assert_almost_eq(buddy.happiness, 0.8, 0.0001, "happiness of 0.8 should be stored")

	buddy.happiness = 1.0
	assert_almost_eq(buddy.happiness, 1.0, 0.0001, "happiness of 1.0 should be stored")


# ---------------------------------------------------------------------------
# 6. get_overall_rarity returns the rarest equipped part
# ---------------------------------------------------------------------------

func test_overall_rarity_is_rarest_part() -> void:
	var buddy := BuddyData.new()
	buddy.appearance.body_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.eyes_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.mouth_rarity = BuddyData.Rarity.LEGENDARY

	# Accessories all -1 (unequipped)
	assert_eq(
		buddy.get_overall_rarity(),
		BuddyData.Rarity.LEGENDARY,
		"overall rarity should be LEGENDARY (mouth)"
	)

	# Add an EPIC accessory — still capped by LEGENDARY mouth
	buddy.appearance.accessory_indices[0] = 5
	buddy.appearance.accessory_rarities[0] = BuddyData.Rarity.EPIC
	assert_eq(
		buddy.get_overall_rarity(),
		BuddyData.Rarity.LEGENDARY,
		"overall rarity should still be LEGENDARY"
	)

	# All slots common, no accessories → should be COMMON
	var buddy2 := BuddyData.new()
	buddy2.appearance.body_rarity = BuddyData.Rarity.COMMON
	buddy2.appearance.eyes_rarity = BuddyData.Rarity.COMMON
	buddy2.appearance.mouth_rarity = BuddyData.Rarity.COMMON
	assert_eq(
		buddy2.get_overall_rarity(),
		BuddyData.Rarity.COMMON,
		"all-common buddy should return COMMON"
	)


# ---------------------------------------------------------------------------
# 7. Default state and zone
# ---------------------------------------------------------------------------

func test_state_default() -> void:
	var buddy := BuddyData.new()
	assert_eq(buddy.state, BuddyData.State.IDLE, "default state should be IDLE")
	assert_eq(buddy.current_zone, "meadow", "default current_zone should be meadow")


# ---------------------------------------------------------------------------
# 8. Round-trip serialization: to_dict → from_dict preserves all fields
# ---------------------------------------------------------------------------

func test_to_dict_and_from_dict() -> void:
	# Build a fully-populated buddy
	var original := BuddyData.new()
	original.id = "rt_001"
	original.species = "blobfish"
	original.rarity = BuddyData.Rarity.EPIC
	original.shiny = true
	original.buddy_name = "Roundtrip"

	original.appearance.body_index = 7
	original.appearance.body_rarity = BuddyData.Rarity.RARE
	original.appearance.eyes_index = 2
	original.appearance.eyes_rarity = BuddyData.Rarity.UNCOMMON
	original.appearance.mouth_index = 4
	original.appearance.mouth_rarity = BuddyData.Rarity.COMMON
	original.appearance.accessory_indices[0] = 3
	original.appearance.accessory_rarities[0] = BuddyData.Rarity.EPIC
	original.appearance.color_primary = Color(0.5, 0.25, 0.75)
	original.appearance.color_secondary = Color(0.1, 0.9, 0.4)

	original.personality.curiosity = 0.8
	original.personality.shyness = 0.2
	original.personality.energy = 0.6
	original.personality.warmth = 0.4
	original.personality.social = 0.7

	original.preferred_zone = "cave"
	original.preferred_furniture = ["log", "mushroom"]
	original.current_zone = "forest"
	original.state = BuddyData.State.WANDERING
	original.happiness = 0.9

	# Serialize
	var d: Dictionary = original.to_dict()

	# Deserialize
	var restored: BuddyData = BuddyData.from_dict(d)

	# Identity
	assert_eq(restored.id, "rt_001", "id round-trip")
	assert_eq(restored.species, "blobfish", "species round-trip")
	assert_eq(restored.rarity, BuddyData.Rarity.EPIC, "rarity round-trip")
	assert_true(restored.shiny, "shiny round-trip")
	assert_eq(restored.buddy_name, "Roundtrip", "buddy_name round-trip")

	# Appearance
	assert_eq(restored.appearance.body_index, 7, "body_index round-trip")
	assert_eq(restored.appearance.body_rarity, BuddyData.Rarity.RARE, "body_rarity round-trip")
	assert_eq(restored.appearance.eyes_index, 2, "eyes_index round-trip")
	assert_eq(restored.appearance.eyes_rarity, BuddyData.Rarity.UNCOMMON, "eyes_rarity round-trip")
	assert_eq(restored.appearance.mouth_index, 4, "mouth_index round-trip")
	assert_eq(restored.appearance.mouth_rarity, BuddyData.Rarity.COMMON, "mouth_rarity round-trip")
	assert_eq(restored.appearance.accessory_indices[0], 3, "accessory index [0] round-trip")
	assert_eq(restored.appearance.accessory_rarities[0], BuddyData.Rarity.EPIC, "accessory rarity [0] round-trip")
	assert_eq(restored.appearance.accessory_indices[1], -1, "accessory index [1] still -1")

	# Colors (compare channel-by-channel with epsilon)
	assert_almost_eq(restored.appearance.color_primary.r, 0.5, 0.001, "color_primary.r round-trip")
	assert_almost_eq(restored.appearance.color_primary.g, 0.25, 0.001, "color_primary.g round-trip")
	assert_almost_eq(restored.appearance.color_primary.b, 0.75, 0.001, "color_primary.b round-trip")
	assert_almost_eq(restored.appearance.color_secondary.r, 0.1, 0.001, "color_secondary.r round-trip")
	assert_almost_eq(restored.appearance.color_secondary.g, 0.9, 0.001, "color_secondary.g round-trip")
	assert_almost_eq(restored.appearance.color_secondary.b, 0.4, 0.001, "color_secondary.b round-trip")

	# Personality
	assert_almost_eq(restored.personality.curiosity, 0.8, 0.0001, "curiosity round-trip")
	assert_almost_eq(restored.personality.shyness, 0.2, 0.0001, "shyness round-trip")
	assert_almost_eq(restored.personality.energy, 0.6, 0.0001, "energy round-trip")
	assert_almost_eq(restored.personality.warmth, 0.4, 0.0001, "warmth round-trip")
	assert_almost_eq(restored.personality.social, 0.7, 0.0001, "social round-trip")

	# Preferences & state
	assert_eq(restored.preferred_zone, "cave", "preferred_zone round-trip")
	assert_eq(restored.preferred_furniture, ["log", "mushroom"], "preferred_furniture round-trip")
	assert_eq(restored.current_zone, "forest", "current_zone round-trip")
	assert_eq(restored.state, BuddyData.State.WANDERING, "state round-trip")
	assert_almost_eq(restored.happiness, 0.9, 0.0001, "happiness round-trip")
