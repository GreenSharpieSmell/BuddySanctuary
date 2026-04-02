# Buddy Sanctuary Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete cozy idle collector in Godot 4 where procedurally generated buddies wander a growing sanctuary, go on relaxing vacations, and live happily without any punishment mechanics.

**Architecture:** Data-driven with shared systems. A `Sanctuary` autoload singleton manages all game state (buddy roster, zones, expeditions, progression, saves). Zone scenes are dumb viewers that render the current state. A standalone `BuddyCreator` handles procedural buddy generation via a modular paper doll system with anchor points. All game logic lives in the data layer — visuals query it.

**Tech Stack:** Godot 4.4+ (GDScript), GUT 9.x (testing), JSON (data files + save), Krita (art, not part of build)

**Spec:** `docs/superpowers/specs/2026-04-02-buddy-sanctuary-design.md`

---

## File Structure

```
buddy_sanctuary/
├── project.godot                          # Godot project config
├── addons/gut/                            # GUT testing addon
├── assets/
│   ├── sprites/
│   │   ├── bodies/                        # Grayscale body PNGs
│   │   ├── eyes/                          # Eye part PNGs
│   │   ├── mouths/                        # Mouth part PNGs
│   │   ├── accessories/                   # head/, neck/, held/, back/, feet/
│   │   └── claude_species/                # Pre-drawn species sprites
│   ├── environments/placeholder/          # Free itch.io zone backgrounds
│   ├── ui/                                # UI element art
│   └── particles/                         # Heart, sparkle, shimmer textures
├── data/
│   ├── parts/
│   │   ├── bodies.json                    # Body pool: texture paths + anchor points + rarity
│   │   ├── eyes.json                      # Eye pool: texture paths + rarity
│   │   ├── mouths.json                    # Mouth pool: texture paths + rarity
│   │   └── accessories.json               # 5 accessory pools: texture paths + rarity
│   ├── claude_species.json                # 18 species: sprite paths + personality archetypes
│   ├── zones.json                         # Zone definitions + unlock milestones
│   ├── decorations.json                   # Decoration catalog: cost, zone_unlock, type
│   └── names/
│       ├── first_names.json               # ["Blobbert", "Snoozy", ...]
│       ├── middle_names.json              # ["Von", "The", ...]
│       └── last_names.json                # ["Squishington", "Wobble", ...]
├── scripts/
│   ├── autoload/sanctuary.gd              # Main singleton — wires all managers
│   ├── data/
│   │   ├── buddy_data.gd                  # BuddyData Resource class
│   │   ├── part_pool.gd                   # Load part definitions, rarity-weighted picks
│   │   ├── buddy_creator.gd               # Paper doll assembly, color, personality, name
│   │   └── name_generator.gd              # Load name lists, assemble random names
│   ├── managers/
│   │   ├── buddy_roster.gd                # Owns all BuddyData instances
│   │   ├── zone_manager.gd                # Zone state, decoration placement, unlocks
│   │   ├── expedition_manager.gd          # Expedition timers, result rolls, slots
│   │   ├── progression_manager.gd         # Stardust, milestone tracking
│   │   └── save_manager.gd                # JSON save/load, offline catch-up
│   ├── ai/buddy_brain.gd                  # AI state machine + personality behaviors
│   ├── ui/
│   │   ├── buddy_info_card.gd             # Click-to-inspect popup
│   │   ├── zone_nav.gd                    # Zone navigation arrows + map widget
│   │   ├── decoration_shop.gd             # Buy + place decorations
│   │   ├── expedition_panel.gd            # Send buddies, track timers
│   │   ├── hud.gd                         # Stardust + buddy count display
│   │   └── welcome_back.gd                # Offline catch-up recap screen
│   └── zones/
│       ├── zone_base.gd                   # Base zone scene script
│       └── buddy_sprite.gd                # Visual buddy node (paper doll render)
├── scenes/
│   ├── main.tscn                          # Entry point — loads zone + UI
│   ├── buddy/buddy.tscn                   # Buddy scene template
│   ├── zones/
│   │   ├── zone_base.tscn                 # Template zone (parallax + depth band)
│   │   └── meadow.tscn                    # Starter zone
│   └── ui/
│       ├── buddy_info_card.tscn
│       ├── zone_nav.tscn
│       ├── decoration_shop.tscn
│       ├── expedition_panel.tscn
│       ├── hud.tscn
│       └── welcome_back.tscn
└── tests/
    ├── test_buddy_data.gd
    ├── test_part_pool.gd
    ├── test_buddy_creator.gd
    ├── test_name_generator.gd
    ├── test_buddy_roster.gd
    ├── test_zone_manager.gd
    ├── test_expedition_manager.gd
    ├── test_progression_manager.gd
    ├── test_save_manager.gd
    └── test_buddy_brain.gd
```

---

## Task 1: Project Scaffold + GUT Setup

**Files:**
- Create: `project.godot`
- Create: `scripts/autoload/sanctuary.gd` (stub)
- Create: `tests/test_scaffold.gd`

This sets up the bare Godot project, installs GUT for testing, and verifies everything runs.

- [ ] **Step 1: Create Godot project**

Open a terminal in `D:\Claude Dev\GitHub\Buddy Sanctuary\` and create the project file:

```ini
; project.godot
[gd_resource type="Resource" script_class="ProjectSettings"]

config_version=5

[application]
config/name="Buddy Sanctuary"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.4")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[autoload]
Sanctuary="*res://scripts/autoload/sanctuary.gd"
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p assets/{sprites/{bodies,eyes,mouths,accessories/{head,neck,held,back,feet},claude_species},environments/placeholder,ui,particles}
mkdir -p data/{parts,names}
mkdir -p scripts/{autoload,data,managers,ai,ui,zones}
mkdir -p scenes/{buddy,zones,ui}
mkdir -p tests
```

- [ ] **Step 3: Install GUT testing addon**

```bash
# Download GUT 9.x from GitHub releases
cd addons
git clone --depth 1 --branch v9.3.0 https://github.com/bitwes/Gut.git gut
# Remove .git from addon to avoid submodule issues
rm -rf gut/.git
```

Enable in project settings by adding to `project.godot`:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 4: Create sanctuary autoload stub**

```gdscript
# scripts/autoload/sanctuary.gd
extends Node

func _ready() -> void:
	print("Sanctuary autoload initialized")
```

- [ ] **Step 5: Create main scene stub**

```
# scenes/main.tscn — create as a Node2D scene
# Just a root Node2D named "Main" for now
```

Minimal `scenes/main.tscn`:
```ini
[gd_scene format=3]

[node name="Main" type="Node2D"]
```

- [ ] **Step 6: Write scaffold test to verify GUT works**

```gdscript
# tests/test_scaffold.gd
extends GutTest

func test_sanctuary_exists() -> void:
	# Verify the project loads and basic GDScript works
	assert_not_null(Sanctuary, "Sanctuary autoload should exist")

func test_basic_math() -> void:
	# Sanity check that GUT is wired correctly
	assert_eq(2 + 2, 4, "Math should work")
```

- [ ] **Step 7: Run tests**

Run: Open Godot editor → GUT tab → Run All Tests
Expected: 2 tests PASS

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: project scaffold with Godot 4.4 + GUT testing"
```

---

## Task 2: Buddy Data Model

**Files:**
- Create: `scripts/data/buddy_data.gd`
- Create: `tests/test_buddy_data.gd`

The core data class that represents a single buddy. Pure data — no visuals, no behavior.

- [ ] **Step 1: Write failing tests for BuddyData**

```gdscript
# tests/test_buddy_data.gd
extends GutTest

func test_create_buddy_data() -> void:
	var buddy := BuddyData.new()
	buddy.id = "buddy_001"
	buddy.species = "blob"
	buddy.rarity = BuddyData.Rarity.COMMON
	buddy.shiny = false
	buddy.buddy_name = "Blobbert Von Squish"
	assert_eq(buddy.id, "buddy_001")
	assert_eq(buddy.species, "blob")
	assert_eq(buddy.rarity, BuddyData.Rarity.COMMON)
	assert_eq(buddy.shiny, false)
	assert_eq(buddy.buddy_name, "Blobbert Von Squish")

func test_appearance_fields() -> void:
	var buddy := BuddyData.new()
	buddy.appearance.body_index = 3
	buddy.appearance.body_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.eyes_index = 7
	buddy.appearance.eyes_rarity = BuddyData.Rarity.RARE
	buddy.appearance.mouth_index = 2
	buddy.appearance.mouth_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.color_primary = Color(1.0, 0.3, 0.8)
	buddy.appearance.color_secondary = Color(0.2, 0.9, 0.1)
	assert_eq(buddy.appearance.body_index, 3)
	assert_eq(buddy.appearance.eyes_rarity, BuddyData.Rarity.RARE)
	assert_eq(buddy.appearance.color_primary, Color(1.0, 0.3, 0.8))

func test_accessory_slots_default_empty() -> void:
	var buddy := BuddyData.new()
	for i in range(5):
		assert_eq(buddy.appearance.accessory_indices[i], -1,
			"Accessory slot %d should default to -1 (empty)" % i)

func test_personality_range() -> void:
	var buddy := BuddyData.new()
	buddy.personality.curiosity = 0.8
	buddy.personality.shyness = 0.2
	buddy.personality.energy = 0.5
	buddy.personality.warmth = 0.9
	buddy.personality.social = 0.1
	assert_eq(buddy.personality.curiosity, 0.8)
	assert_eq(buddy.personality.social, 0.1)

func test_happiness_floor() -> void:
	var buddy := BuddyData.new()
	assert_eq(buddy.happiness, 0.5, "Happiness should default to 0.5 (content)")
	buddy.happiness = 0.3
	assert_eq(buddy.happiness, 0.5, "Happiness should never drop below 0.5")
	buddy.happiness = 0.9
	assert_eq(buddy.happiness, 0.9, "Happiness can rise above 0.5")

func test_overall_rarity_is_rarest_part() -> void:
	var buddy := BuddyData.new()
	buddy.appearance.body_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.eyes_rarity = BuddyData.Rarity.COMMON
	buddy.appearance.mouth_rarity = BuddyData.Rarity.LEGENDARY
	# All accessories empty (rarity COMMON by default, ignored when index == -1)
	assert_eq(buddy.get_overall_rarity(), BuddyData.Rarity.LEGENDARY,
		"Overall rarity should be the rarest equipped part")

func test_state_default() -> void:
	var buddy := BuddyData.new()
	assert_eq(buddy.state, BuddyData.State.IDLE)
	assert_eq(buddy.current_zone, "meadow")

func test_to_dict_and_from_dict() -> void:
	var buddy := BuddyData.new()
	buddy.id = "test_123"
	buddy.species = "blob"
	buddy.rarity = BuddyData.Rarity.RARE
	buddy.shiny = true
	buddy.buddy_name = "Sparkle McFluff"
	buddy.personality.curiosity = 0.7
	buddy.appearance.body_index = 5
	buddy.appearance.color_primary = Color(0.5, 0.5, 0.5)

	var dict := buddy.to_dict()
	var restored := BuddyData.from_dict(dict)

	assert_eq(restored.id, "test_123")
	assert_eq(restored.species, "blob")
	assert_eq(restored.rarity, BuddyData.Rarity.RARE)
	assert_eq(restored.shiny, true)
	assert_eq(restored.buddy_name, "Sparkle McFluff")
	assert_almost_eq(restored.personality.curiosity, 0.7, 0.001)
	assert_eq(restored.appearance.body_index, 5)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_buddy_data.gd`
Expected: All tests FAIL (BuddyData class doesn't exist yet)

- [ ] **Step 3: Implement BuddyData**

```gdscript
# scripts/data/buddy_data.gd
class_name BuddyData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum State { IDLE, WANDERING, SLEEPING, PLAYING, EXPEDITION }

# --- Identity ---
@export var id: String = ""
@export var species: String = "blob"  # "blob" or one of 18 claude species
@export var rarity: Rarity = Rarity.COMMON
@export var shiny: bool = false
@export var buddy_name: String = ""

# --- Appearance ---
var appearance := BuddyAppearance.new()

# --- Personality ---
var personality := BuddyPersonality.new()

# --- Preferences (derived from personality) ---
var preferred_zone: String = "meadow"
var preferred_furniture: Array[String] = []

# --- State ---
var current_zone: String = "meadow"
var state: State = State.IDLE
var _happiness: float = 0.5

var happiness: float:
	get:
		return _happiness
	set(value):
		_happiness = maxf(0.5, value)  # Content is the floor


func get_overall_rarity() -> Rarity:
	var best: Rarity = Rarity.COMMON
	# Check body, eyes, mouth
	best = _max_rarity(best, appearance.body_rarity)
	best = _max_rarity(best, appearance.eyes_rarity)
	best = _max_rarity(best, appearance.mouth_rarity)
	# Check equipped accessories (skip empty slots where index == -1)
	for i in range(5):
		if appearance.accessory_indices[i] != -1:
			best = _max_rarity(best, appearance.accessory_rarities[i])
	return best


func _max_rarity(a: Rarity, b: Rarity) -> Rarity:
	return a if a > b else b


func to_dict() -> Dictionary:
	return {
		"id": id,
		"species": species,
		"rarity": rarity,
		"shiny": shiny,
		"buddy_name": buddy_name,
		"happiness": _happiness,
		"current_zone": current_zone,
		"state": state,
		"preferred_zone": preferred_zone,
		"preferred_furniture": preferred_furniture,
		"appearance": appearance.to_dict(),
		"personality": personality.to_dict(),
	}


static func from_dict(dict: Dictionary) -> BuddyData:
	var buddy := BuddyData.new()
	buddy.id = dict.get("id", "")
	buddy.species = dict.get("species", "blob")
	buddy.rarity = dict.get("rarity", Rarity.COMMON) as Rarity
	buddy.shiny = dict.get("shiny", false)
	buddy.buddy_name = dict.get("buddy_name", "")
	buddy._happiness = dict.get("happiness", 0.5)
	buddy.current_zone = dict.get("current_zone", "meadow")
	buddy.state = dict.get("state", State.IDLE) as State
	buddy.preferred_zone = dict.get("preferred_zone", "meadow")
	buddy.preferred_furniture = Array(
		dict.get("preferred_furniture", []), TYPE_STRING, "", null
	)
	if dict.has("appearance"):
		buddy.appearance = BuddyAppearance.from_dict(dict["appearance"])
	if dict.has("personality"):
		buddy.personality = BuddyPersonality.from_dict(dict["personality"])
	return buddy


# --- Inner Classes ---

class BuddyAppearance:
	var body_index: int = 0
	var body_rarity: Rarity = Rarity.COMMON
	var eyes_index: int = 0
	var eyes_rarity: Rarity = Rarity.COMMON
	var mouth_index: int = 0
	var mouth_rarity: Rarity = Rarity.COMMON
	var accessory_indices: Array[int] = [-1, -1, -1, -1, -1]
	var accessory_rarities: Array[Rarity] = [
		Rarity.COMMON, Rarity.COMMON, Rarity.COMMON, Rarity.COMMON, Rarity.COMMON
	]
	var color_primary: Color = Color.WHITE
	var color_secondary: Color = Color.WHITE

	func to_dict() -> Dictionary:
		return {
			"body_index": body_index,
			"body_rarity": body_rarity,
			"eyes_index": eyes_index,
			"eyes_rarity": eyes_rarity,
			"mouth_index": mouth_index,
			"mouth_rarity": mouth_rarity,
			"accessory_indices": accessory_indices,
			"accessory_rarities": accessory_rarities,
			"color_primary": [color_primary.r, color_primary.g, color_primary.b],
			"color_secondary": [color_secondary.r, color_secondary.g, color_secondary.b],
		}

	static func from_dict(dict: Dictionary) -> BuddyAppearance:
		var app := BuddyAppearance.new()
		app.body_index = dict.get("body_index", 0)
		app.body_rarity = dict.get("body_rarity", Rarity.COMMON) as Rarity
		app.eyes_index = dict.get("eyes_index", 0)
		app.eyes_rarity = dict.get("eyes_rarity", Rarity.COMMON) as Rarity
		app.mouth_index = dict.get("mouth_index", 0)
		app.mouth_rarity = dict.get("mouth_rarity", Rarity.COMMON) as Rarity
		app.accessory_indices = Array(
			dict.get("accessory_indices", [-1, -1, -1, -1, -1]), TYPE_INT, "", null
		)
		app.accessory_rarities = Array(
			dict.get("accessory_rarities", [0, 0, 0, 0, 0]), TYPE_INT, "", null
		)
		var cp: Array = dict.get("color_primary", [1, 1, 1])
		app.color_primary = Color(cp[0], cp[1], cp[2])
		var cs: Array = dict.get("color_secondary", [1, 1, 1])
		app.color_secondary = Color(cs[0], cs[1], cs[2])
		return app


class BuddyPersonality:
	var curiosity: float = 0.5
	var shyness: float = 0.5
	var energy: float = 0.5
	var warmth: float = 0.5
	var social: float = 0.5

	func to_dict() -> Dictionary:
		return {
			"curiosity": curiosity,
			"shyness": shyness,
			"energy": energy,
			"warmth": warmth,
			"social": social,
		}

	static func from_dict(dict: Dictionary) -> BuddyPersonality:
		var p := BuddyPersonality.new()
		p.curiosity = dict.get("curiosity", 0.5)
		p.shyness = dict.get("shyness", 0.5)
		p.energy = dict.get("energy", 0.5)
		p.warmth = dict.get("warmth", 0.5)
		p.social = dict.get("social", 0.5)
		return p
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_buddy_data.gd`
Expected: All 8 tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/data/buddy_data.gd tests/test_buddy_data.gd
git commit -m "feat: BuddyData resource — identity, appearance, personality, serialization"
```

---

## Task 3: Part Pool System

**Files:**
- Create: `scripts/data/part_pool.gd`
- Create: `data/parts/bodies.json`
- Create: `data/parts/eyes.json`
- Create: `data/parts/mouths.json`
- Create: `data/parts/accessories.json`
- Create: `tests/test_part_pool.gd`

Loads part definitions from JSON, performs rarity-weighted random picks. This is the randomizer engine behind buddy creation.

- [ ] **Step 1: Create placeholder part data files**

```json
// data/parts/bodies.json
{
  "parts": [
    {
      "id": "round_blobby",
      "texture": "res://assets/sprites/bodies/round_blobby.png",
      "rarity": "common",
      "anchors": {
        "eyes": [32, 18],
        "mouth": [32, 28],
        "acc_head": [32, 8],
        "acc_neck": [32, 24],
        "acc_held": [28, 32],
        "acc_back": [32, 20],
        "acc_feet": [32, 44]
      }
    },
    {
      "id": "tall_noodle",
      "texture": "res://assets/sprites/bodies/tall_noodle.png",
      "rarity": "common",
      "anchors": {
        "eyes": [32, 12],
        "mouth": [32, 18],
        "acc_head": [32, 4],
        "acc_neck": [32, 14],
        "acc_held": [24, 28],
        "acc_back": [32, 16],
        "acc_feet": [32, 48]
      }
    },
    {
      "id": "spiky_star",
      "texture": "res://assets/sprites/bodies/spiky_star.png",
      "rarity": "uncommon",
      "anchors": {
        "eyes": [32, 20],
        "mouth": [32, 30],
        "acc_head": [32, 6],
        "acc_neck": [32, 26],
        "acc_held": [20, 32],
        "acc_back": [32, 22],
        "acc_feet": [32, 46]
      }
    }
  ]
}
```

```json
// data/parts/eyes.json
{
  "parts": [
    {"id": "dot_eyes", "texture": "res://assets/sprites/eyes/dot_eyes.png", "rarity": "common"},
    {"id": "big_sparkly", "texture": "res://assets/sprites/eyes/big_sparkly.png", "rarity": "uncommon"},
    {"id": "heart_eyes", "texture": "res://assets/sprites/eyes/heart_eyes.png", "rarity": "legendary"}
  ]
}
```

```json
// data/parts/mouths.json
{
  "parts": [
    {"id": "simple_smile", "texture": "res://assets/sprites/mouths/simple_smile.png", "rarity": "common"},
    {"id": "cat_mouth", "texture": "res://assets/sprites/mouths/cat_mouth.png", "rarity": "uncommon"},
    {"id": "derp", "texture": "res://assets/sprites/mouths/derp.png", "rarity": "common"}
  ]
}
```

```json
// data/parts/accessories.json
{
  "slots": {
    "head": [
      {"id": "tiny_hat", "texture": "res://assets/sprites/accessories/head/tiny_hat.png", "rarity": "common"},
      {"id": "crown", "texture": "res://assets/sprites/accessories/head/crown.png", "rarity": "epic"}
    ],
    "neck": [
      {"id": "red_scarf", "texture": "res://assets/sprites/accessories/neck/red_scarf.png", "rarity": "common"},
      {"id": "bow_tie", "texture": "res://assets/sprites/accessories/neck/bow_tie.png", "rarity": "uncommon"}
    ],
    "held": [
      {"id": "balloon", "texture": "res://assets/sprites/accessories/held/balloon.png", "rarity": "uncommon"},
      {"id": "tiny_flag", "texture": "res://assets/sprites/accessories/held/tiny_flag.png", "rarity": "common"}
    ],
    "back": [
      {"id": "tiny_wings", "texture": "res://assets/sprites/accessories/back/tiny_wings.png", "rarity": "rare"},
      {"id": "cape", "texture": "res://assets/sprites/accessories/back/cape.png", "rarity": "uncommon"}
    ],
    "feet": [
      {"id": "puddle", "texture": "res://assets/sprites/accessories/feet/puddle.png", "rarity": "common"},
      {"id": "sparkle_trail", "texture": "res://assets/sprites/accessories/feet/sparkle_trail.png", "rarity": "rare"}
    ]
  }
}
```

- [ ] **Step 2: Write failing tests**

```gdscript
# tests/test_part_pool.gd
extends GutTest

var pool: PartPool

func before_each() -> void:
	pool = PartPool.new()

func test_load_bodies() -> void:
	pool.load_from_directory("res://data/parts")
	assert_gt(pool.body_count(), 0, "Should load at least one body")

func test_body_has_anchors() -> void:
	pool.load_from_directory("res://data/parts")
	var body := pool.get_body(0)
	assert_has(body, "anchors", "Body should have anchor points")
	assert_has(body.anchors, "eyes", "Body anchors should include eyes")
	assert_has(body.anchors, "mouth", "Body anchors should include mouth")
	assert_has(body.anchors, "acc_head", "Body anchors should include acc_head")

func test_rarity_string_to_enum() -> void:
	assert_eq(PartPool.rarity_from_string("common"), BuddyData.Rarity.COMMON)
	assert_eq(PartPool.rarity_from_string("uncommon"), BuddyData.Rarity.UNCOMMON)
	assert_eq(PartPool.rarity_from_string("rare"), BuddyData.Rarity.RARE)
	assert_eq(PartPool.rarity_from_string("epic"), BuddyData.Rarity.EPIC)
	assert_eq(PartPool.rarity_from_string("legendary"), BuddyData.Rarity.LEGENDARY)

func test_weighted_rarity_pick() -> void:
	# Seed RNG for deterministic test
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	pool.load_from_directory("res://data/parts")

	# Pick 100 eyes — should get a distribution
	var picks := {}
	for i in range(100):
		var result := pool.pick_random_part("eyes", rng)
		var r_name := BuddyData.Rarity.keys()[result.rarity]
		picks[r_name] = picks.get(r_name, 0) + 1

	# Common should appear most often (we have common + uncommon + legendary eyes)
	assert_gt(picks.get("COMMON", 0), 0, "Should pick some common parts")

func test_accessory_slot_pick() -> void:
	pool.load_from_directory("res://data/parts")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var result := pool.pick_random_accessory("head", rng)
	assert_has(result, "id", "Accessory pick should have an id")
	assert_has(result, "rarity", "Accessory pick should have a rarity")

func test_accessory_can_be_empty() -> void:
	# 50% chance of empty — with enough tries we should see at least one empty
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	pool.load_from_directory("res://data/parts")
	var saw_empty := false
	for i in range(50):
		var result := pool.pick_random_accessory_or_empty("head", rng)
		if result == null:
			saw_empty = true
			break
	assert_true(saw_empty, "Should sometimes roll an empty accessory slot")
```

- [ ] **Step 3: Run tests to verify they fail**

Run: GUT → Run `test_part_pool.gd`
Expected: All tests FAIL

- [ ] **Step 4: Implement PartPool**

```gdscript
# scripts/data/part_pool.gd
class_name PartPool
extends RefCounted

# Rarity weights: common 60%, uncommon 25%, rare 10%, epic 4%, legendary 1%
const RARITY_WEIGHTS := {
	BuddyData.Rarity.COMMON: 60.0,
	BuddyData.Rarity.UNCOMMON: 25.0,
	BuddyData.Rarity.RARE: 10.0,
	BuddyData.Rarity.EPIC: 4.0,
	BuddyData.Rarity.LEGENDARY: 1.0,
}

const ACCESSORY_EQUIP_CHANCE := 0.5

var _bodies: Array[Dictionary] = []
var _eyes: Array[Dictionary] = []
var _mouths: Array[Dictionary] = []
var _accessories: Dictionary = {}  # slot_name -> Array[Dictionary]


func load_from_directory(path: String) -> void:
	_bodies = _load_parts(path + "/bodies.json")
	_eyes = _load_parts(path + "/eyes.json")
	_mouths = _load_parts(path + "/mouths.json")
	_load_accessories(path + "/accessories.json")


func _load_parts(file_path: String) -> Array[Dictionary]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("PartPool: could not open %s" % file_path)
		return []
	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	var result: Array[Dictionary] = []
	for entry in data.get("parts", []):
		entry["rarity"] = rarity_from_string(entry.get("rarity", "common"))
		result.append(entry)
	return result


func _load_accessories(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("PartPool: could not open %s" % file_path)
		return
	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	for slot_name in data.get("slots", {}).keys():
		var parts: Array[Dictionary] = []
		for entry in data["slots"][slot_name]:
			entry["rarity"] = rarity_from_string(entry.get("rarity", "common"))
			parts.append(entry)
		_accessories[slot_name] = parts


func body_count() -> int:
	return _bodies.size()


func get_body(index: int) -> Dictionary:
	return _bodies[index]


func pick_random_part(pool_name: String, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array[Dictionary]
	match pool_name:
		"bodies": pool = _bodies
		"eyes": pool = _eyes
		"mouths": pool = _mouths
		_:
			push_error("Unknown part pool: %s" % pool_name)
			return {}
	return _weighted_pick(pool, rng)


func pick_random_accessory(slot_name: String, rng: RandomNumberGenerator) -> Dictionary:
	if not _accessories.has(slot_name):
		push_error("Unknown accessory slot: %s" % slot_name)
		return {}
	return _weighted_pick(_accessories[slot_name], rng)


func pick_random_accessory_or_empty(
	slot_name: String, rng: RandomNumberGenerator
) -> Variant:
	if rng.randf() > ACCESSORY_EQUIP_CHANCE:
		return null  # Empty slot
	return pick_random_accessory(slot_name, rng)


func _weighted_pick(
	pool: Array[Dictionary], rng: RandomNumberGenerator
) -> Dictionary:
	# Group parts by rarity, then pick rarity first, then random within rarity
	var by_rarity := {}
	for part in pool:
		var r: BuddyData.Rarity = part["rarity"]
		if not by_rarity.has(r):
			by_rarity[r] = []
		by_rarity[r].append(part)

	# Build weighted list of available rarities only
	var total_weight := 0.0
	var available: Array[Dictionary] = []  # [{rarity, weight, parts}]
	for r in by_rarity.keys():
		var w: float = RARITY_WEIGHTS[r]
		available.append({"rarity": r, "weight": w, "parts": by_rarity[r]})
		total_weight += w

	# Roll
	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for entry in available:
		cumulative += entry["weight"]
		if roll <= cumulative:
			var parts: Array = entry["parts"]
			return parts[rng.randi() % parts.size()]

	# Fallback (shouldn't happen)
	return pool[0]


static func rarity_from_string(s: String) -> BuddyData.Rarity:
	match s.to_lower():
		"common": return BuddyData.Rarity.COMMON
		"uncommon": return BuddyData.Rarity.UNCOMMON
		"rare": return BuddyData.Rarity.RARE
		"epic": return BuddyData.Rarity.EPIC
		"legendary": return BuddyData.Rarity.LEGENDARY
		_: return BuddyData.Rarity.COMMON
```

- [ ] **Step 5: Run tests to verify they pass**

Run: GUT → Run `test_part_pool.gd`
Expected: All 6 tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/data/part_pool.gd data/parts/ tests/test_part_pool.gd
git commit -m "feat: PartPool — load part definitions from JSON, rarity-weighted picks"
```

---

## Task 4: Name Generator

**Files:**
- Create: `scripts/data/name_generator.gd`
- Create: `data/names/first_names.json`
- Create: `data/names/middle_names.json`
- Create: `data/names/last_names.json`
- Create: `tests/test_name_generator.gd`

Loads user-curated name lists and assembles random three-part names.

- [ ] **Step 1: Create starter name lists**

```json
// data/names/first_names.json
["Blobbert", "Snoozy", "Wiggles", "Pebble", "Mochi", "Sprout", "Niblet",
 "Pudge", "Flicker", "Doodle", "Squish", "Tumble", "Fizz", "Noodle", "Pip"]
```

```json
// data/names/middle_names.json
["Von", "The", "De", "El", "Mc", "O'", "Le", "Van", "Del", "La"]
```

```json
// data/names/last_names.json
["Squishington", "Wobble", "Fluffkins", "Bumble", "Puffsworth", "Snuggleworth",
 "Waddleton", "Glimmer", "Driftwood", "Moonbeam", "Puddlejump", "Starfall"]
```

- [ ] **Step 2: Write failing tests**

```gdscript
# tests/test_name_generator.gd
extends GutTest

var gen: NameGenerator

func before_each() -> void:
	gen = NameGenerator.new()
	gen.load_names("res://data/names")

func test_loads_name_lists() -> void:
	assert_gt(gen.first_name_count(), 0, "Should load first names")
	assert_gt(gen.middle_name_count(), 0, "Should load middle names")
	assert_gt(gen.last_name_count(), 0, "Should load last names")

func test_generate_returns_three_part_name() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var name_str := gen.generate(rng)
	var parts := name_str.split(" ")
	assert_eq(parts.size(), 3, "Name should have three parts: first middle last")

func test_deterministic_with_same_seed() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 100
	var name1 := gen.generate(rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 100
	var name2 := gen.generate(rng2)

	assert_eq(name1, name2, "Same seed should produce same name")

func test_different_seeds_different_names() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 1
	var name1 := gen.generate(rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 9999
	var name2 := gen.generate(rng2)

	# Not guaranteed but extremely likely with different seeds
	assert_ne(name1, name2, "Different seeds should usually produce different names")
```

- [ ] **Step 3: Run tests to verify they fail**

Run: GUT → Run `test_name_generator.gd`
Expected: All tests FAIL

- [ ] **Step 4: Implement NameGenerator**

```gdscript
# scripts/data/name_generator.gd
class_name NameGenerator
extends RefCounted

var _first_names: Array[String] = []
var _middle_names: Array[String] = []
var _last_names: Array[String] = []


func load_names(directory: String) -> void:
	_first_names = _load_list(directory + "/first_names.json")
	_middle_names = _load_list(directory + "/middle_names.json")
	_last_names = _load_list(directory + "/last_names.json")


func _load_list(file_path: String) -> Array[String]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("NameGenerator: could not open %s" % file_path)
		return []
	var json := JSON.new()
	json.parse(file.get_as_text())
	var result: Array[String] = []
	for entry in json.data:
		result.append(str(entry))
	return result


func generate(rng: RandomNumberGenerator) -> String:
	var first := _first_names[rng.randi() % _first_names.size()]
	var middle := _middle_names[rng.randi() % _middle_names.size()]
	var last := _last_names[rng.randi() % _last_names.size()]
	return "%s %s %s" % [first, middle, last]


func first_name_count() -> int:
	return _first_names.size()


func middle_name_count() -> int:
	return _middle_names.size()


func last_name_count() -> int:
	return _last_names.size()
```

- [ ] **Step 5: Run tests to verify they pass**

Run: GUT → Run `test_name_generator.gd`
Expected: All 4 tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/data/name_generator.gd data/names/ tests/test_name_generator.gd
git commit -m "feat: NameGenerator — load curated name lists, assemble random three-part names"
```

---

## Task 5: Buddy Creator

**Files:**
- Create: `scripts/data/buddy_creator.gd`
- Create: `data/claude_species.json`
- Create: `tests/test_buddy_creator.gd`

The factory that assembles complete buddies. Uses PartPool + NameGenerator. Handles both blob generation (paper doll) and Claude species generation.

- [ ] **Step 1: Create Claude species data**

```json
// data/claude_species.json
{
  "species": [
    {"id": "axolotl", "texture": "res://assets/sprites/claude_species/axolotl.png",
     "personality": {"curiosity": 0.5, "shyness": 0.2, "energy": 0.5, "warmth": 0.8, "social": 0.8}},
    {"id": "blob", "texture": "res://assets/sprites/claude_species/blob.png",
     "personality": {"curiosity": 0.5, "shyness": 0.5, "energy": 0.4, "warmth": 0.6, "social": 0.5}},
    {"id": "cactus", "texture": "res://assets/sprites/claude_species/cactus.png",
     "personality": {"curiosity": 0.4, "shyness": 0.5, "energy": 0.3, "warmth": 0.8, "social": 0.2}},
    {"id": "capybara", "texture": "res://assets/sprites/claude_species/capybara.png",
     "personality": {"curiosity": 0.5, "shyness": 0.3, "energy": 0.2, "warmth": 0.6, "social": 0.8}},
    {"id": "cat", "texture": "res://assets/sprites/claude_species/cat.png",
     "personality": {"curiosity": 0.6, "shyness": 0.8, "energy": 0.5, "warmth": 0.5, "social": 0.2}},
    {"id": "chonk", "texture": "res://assets/sprites/claude_species/chonk.png",
     "personality": {"curiosity": 0.4, "shyness": 0.4, "energy": 0.2, "warmth": 0.8, "social": 0.5}},
    {"id": "dragon", "texture": "res://assets/sprites/claude_species/dragon.png",
     "personality": {"curiosity": 0.8, "shyness": 0.2, "energy": 0.9, "warmth": 0.5, "social": 0.5}},
    {"id": "duck", "texture": "res://assets/sprites/claude_species/duck.png",
     "personality": {"curiosity": 0.5, "shyness": 0.3, "energy": 0.5, "warmth": 0.5, "social": 0.7}},
    {"id": "ghost", "texture": "res://assets/sprites/claude_species/ghost.png",
     "personality": {"curiosity": 0.8, "shyness": 0.8, "energy": 0.4, "warmth": 0.3, "social": 0.3}},
    {"id": "goose", "texture": "res://assets/sprites/claude_species/goose.png",
     "personality": {"curiosity": 0.7, "shyness": 0.1, "energy": 0.9, "warmth": 0.3, "social": 0.6}},
    {"id": "mushroom", "texture": "res://assets/sprites/claude_species/mushroom.png",
     "personality": {"curiosity": 0.3, "shyness": 0.8, "energy": 0.2, "warmth": 0.5, "social": 0.3}},
    {"id": "octopus", "texture": "res://assets/sprites/claude_species/octopus.png",
     "personality": {"curiosity": 0.9, "shyness": 0.3, "energy": 0.6, "warmth": 0.5, "social": 0.8}},
    {"id": "owl", "texture": "res://assets/sprites/claude_species/owl.png",
     "personality": {"curiosity": 0.8, "shyness": 0.5, "energy": 0.2, "warmth": 0.5, "social": 0.4}},
    {"id": "penguin", "texture": "res://assets/sprites/claude_species/penguin.png",
     "personality": {"curiosity": 0.5, "shyness": 0.3, "energy": 0.5, "warmth": 0.5, "social": 0.7}},
    {"id": "rabbit", "texture": "res://assets/sprites/claude_species/rabbit.png",
     "personality": {"curiosity": 0.8, "shyness": 0.3, "energy": 0.9, "warmth": 0.5, "social": 0.5}},
    {"id": "robot", "texture": "res://assets/sprites/claude_species/robot.png",
     "personality": {"curiosity": 0.5, "shyness": 0.4, "energy": 0.5, "warmth": 0.2, "social": 0.5}},
    {"id": "snail", "texture": "res://assets/sprites/claude_species/snail.png",
     "personality": {"curiosity": 0.2, "shyness": 0.5, "energy": 0.1, "warmth": 0.6, "social": 0.4}},
    {"id": "turtle", "texture": "res://assets/sprites/claude_species/turtle.png",
     "personality": {"curiosity": 0.4, "shyness": 0.4, "energy": 0.2, "warmth": 0.8, "social": 0.5}}
  ]
}
```

- [ ] **Step 2: Write failing tests**

```gdscript
# tests/test_buddy_creator.gd
extends GutTest

var creator: BuddyCreator

func before_each() -> void:
	creator = BuddyCreator.new()
	creator.load_data("res://data/parts", "res://data/names", "res://data/claude_species.json")

func test_create_blob() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_blob(rng)
	assert_eq(buddy.species, "blob")
	assert_ne(buddy.id, "", "Should have a generated id")
	assert_ne(buddy.buddy_name, "", "Should have a generated name")
	assert_gte(buddy.appearance.body_index, 0, "Should have a body")
	assert_gte(buddy.appearance.eyes_index, 0, "Should have eyes")
	assert_gte(buddy.appearance.mouth_index, 0, "Should have a mouth")

func test_blob_has_random_colors() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_blob(rng)
	# Colors should be valid (not default white)
	assert_true(
		buddy.appearance.color_primary != Color.WHITE
		or buddy.appearance.color_secondary != Color.WHITE,
		"At least one color should be non-white (random)"
	)

func test_blob_has_personality_with_dominant_trait() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_blob(rng)
	var p := buddy.personality
	var traits := [p.curiosity, p.shyness, p.energy, p.warmth, p.social]
	var max_trait := traits.max()
	assert_gte(max_trait, 0.7, "Should have at least one dominant trait >= 0.7")

func test_blob_rarity_from_parts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_blob(rng)
	# Overall rarity should match the rarest equipped part
	assert_eq(buddy.rarity, buddy.get_overall_rarity())

func test_blob_shiny_chance() -> void:
	# Generate many buddies — at least one should be shiny (1% chance)
	# With 500 rolls, probability of zero shiny = 0.99^500 ≈ 0.66%
	var saw_shiny := false
	for i in range(500):
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		var buddy := creator.create_blob(rng)
		if buddy.shiny:
			saw_shiny = true
			break
	assert_true(saw_shiny, "Should generate at least one shiny in 500 attempts")

func test_create_claude_buddy() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_claude_buddy(rng, BuddyData.Rarity.RARE)
	assert_ne(buddy.species, "blob", "Should be a claude species, not blob")
	assert_eq(buddy.rarity, BuddyData.Rarity.RARE)
	assert_ne(buddy.buddy_name, "")

func test_claude_buddy_personality_has_variance() -> void:
	# Two buddies of the same species should have slightly different personalities
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 1
	var buddy1 := creator.create_claude_buddy(rng1, BuddyData.Rarity.COMMON)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 9999
	var buddy2 := creator.create_claude_buddy(rng2, BuddyData.Rarity.COMMON)

	if buddy1.species == buddy2.species:
		# Same species — personalities should differ slightly
		var diff := absf(buddy1.personality.curiosity - buddy2.personality.curiosity)
		# Could be zero by chance, but at least one trait should differ
		var any_diff := (
			absf(buddy1.personality.curiosity - buddy2.personality.curiosity) > 0.01
			or absf(buddy1.personality.shyness - buddy2.personality.shyness) > 0.01
			or absf(buddy1.personality.energy - buddy2.personality.energy) > 0.01
		)
		assert_true(any_diff, "Same species should have personality variance")

func test_preferences_derived_from_personality() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := creator.create_blob(rng)
	assert_ne(buddy.preferred_zone, "", "Should have a preferred zone")
	assert_gt(buddy.preferred_furniture.size(), 0, "Should have preferred furniture")

func test_deterministic_blob_creation() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 777
	var buddy1 := creator.create_blob(rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 777
	var buddy2 := creator.create_blob(rng2)

	assert_eq(buddy1.buddy_name, buddy2.buddy_name)
	assert_eq(buddy1.appearance.body_index, buddy2.appearance.body_index)
	assert_eq(buddy1.personality.curiosity, buddy2.personality.curiosity)
```

- [ ] **Step 3: Run tests to verify they fail**

Run: GUT → Run `test_buddy_creator.gd`
Expected: All tests FAIL

- [ ] **Step 4: Implement BuddyCreator**

```gdscript
# scripts/data/buddy_creator.gd
class_name BuddyCreator
extends RefCounted

const SHINY_CHANCE := 0.01
const PERSONALITY_VARIANCE := 0.15  # +/- applied to archetype stats

# Zone preferences mapped from dominant personality trait
const ZONE_FOR_TRAIT := {
	"warmth": "meadow",
	"shyness": "burrow",
	"social": "pond",
	"curiosity": "mushroom_grotto",
	"energy": "canopy",
}

# Furniture preferences mapped from personality traits
const FURNITURE_FOR_TRAIT := {
	"warmth": ["lamp", "cushion", "campfire"],
	"shyness": ["bush", "blanket", "hiding_spot"],
	"social": ["bench", "table", "swing"],
	"curiosity": ["bookshelf", "telescope", "toy"],
	"energy": ["ball", "trampoline", "wheel"],
}

const ACCESSORY_SLOT_NAMES := ["head", "neck", "held", "back", "feet"]

var _part_pool := PartPool.new()
var _name_gen := NameGenerator.new()
var _claude_species: Array[Dictionary] = []
var _next_id := 0


func load_data(parts_dir: String, names_dir: String, species_path: String) -> void:
	_part_pool.load_from_directory(parts_dir)
	_name_gen.load_names(names_dir)
	_load_claude_species(species_path)


func _load_claude_species(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("BuddyCreator: could not open %s" % file_path)
		return
	var json := JSON.new()
	json.parse(file.get_as_text())
	_claude_species = []
	for entry in json.data.get("species", []):
		_claude_species.append(entry)


func create_blob(rng: RandomNumberGenerator) -> BuddyData:
	var buddy := BuddyData.new()
	buddy.id = _generate_id()
	buddy.species = "blob"
	buddy.buddy_name = _name_gen.generate(rng)
	buddy.shiny = rng.randf() < SHINY_CHANCE

	# Appearance — paper doll assembly
	var body_pick := _part_pool.pick_random_part("bodies", rng)
	buddy.appearance.body_index = _find_part_index("bodies", body_pick)
	buddy.appearance.body_rarity = body_pick["rarity"]

	var eyes_pick := _part_pool.pick_random_part("eyes", rng)
	buddy.appearance.eyes_index = _find_part_index("eyes", eyes_pick)
	buddy.appearance.eyes_rarity = eyes_pick["rarity"]

	var mouth_pick := _part_pool.pick_random_part("mouths", rng)
	buddy.appearance.mouth_index = _find_part_index("mouths", mouth_pick)
	buddy.appearance.mouth_rarity = mouth_pick["rarity"]

	# Accessories — each slot has 50% chance of being filled
	for i in range(5):
		var slot_name := ACCESSORY_SLOT_NAMES[i]
		var acc_pick = _part_pool.pick_random_accessory_or_empty(slot_name, rng)
		if acc_pick != null:
			buddy.appearance.accessory_indices[i] = _find_accessory_index(slot_name, acc_pick)
			buddy.appearance.accessory_rarities[i] = acc_pick["rarity"]

	# Colors — full RGB random, uncurated
	buddy.appearance.color_primary = Color(rng.randf(), rng.randf(), rng.randf())
	buddy.appearance.color_secondary = Color(rng.randf(), rng.randf(), rng.randf())

	# Personality — random with one dominant trait
	_generate_personality(buddy, rng)

	# Preferences derived from personality
	_derive_preferences(buddy)

	# Overall rarity from parts
	buddy.rarity = buddy.get_overall_rarity()

	return buddy


func create_claude_buddy(
	rng: RandomNumberGenerator, rarity: BuddyData.Rarity
) -> BuddyData:
	var buddy := BuddyData.new()
	buddy.id = _generate_id()
	buddy.rarity = rarity
	buddy.shiny = rng.randf() < SHINY_CHANCE
	buddy.buddy_name = _name_gen.generate(rng)

	# Pick a random species
	var species_data: Dictionary = _claude_species[rng.randi() % _claude_species.size()]
	buddy.species = species_data["id"]

	# Personality from archetype + variance
	var archetype: Dictionary = species_data["personality"]
	buddy.personality.curiosity = _vary(archetype["curiosity"], rng)
	buddy.personality.shyness = _vary(archetype["shyness"], rng)
	buddy.personality.energy = _vary(archetype["energy"], rng)
	buddy.personality.warmth = _vary(archetype["warmth"], rng)
	buddy.personality.social = _vary(archetype["social"], rng)

	_derive_preferences(buddy)

	return buddy


func _generate_id() -> String:
	_next_id += 1
	return "buddy_%d_%d" % [Time.get_unix_time_from_system(), _next_id]


func _generate_personality(buddy: BuddyData, rng: RandomNumberGenerator) -> void:
	# Roll 5 random values
	var traits := []
	for i in range(5):
		traits.append(rng.randf_range(0.2, 0.7))

	# Pick one to be dominant (>= 0.7)
	var dominant := rng.randi() % 5
	traits[dominant] = rng.randf_range(0.7, 1.0)

	buddy.personality.curiosity = traits[0]
	buddy.personality.shyness = traits[1]
	buddy.personality.energy = traits[2]
	buddy.personality.warmth = traits[3]
	buddy.personality.social = traits[4]


func _derive_preferences(buddy: BuddyData) -> void:
	# Find dominant personality trait
	var p := buddy.personality
	var trait_values := {
		"curiosity": p.curiosity,
		"shyness": p.shyness,
		"energy": p.energy,
		"warmth": p.warmth,
		"social": p.social,
	}
	var best_trait := "warmth"
	var best_val := 0.0
	for trait_name in trait_values:
		if trait_values[trait_name] > best_val:
			best_val = trait_values[trait_name]
			best_trait = trait_name

	buddy.preferred_zone = ZONE_FOR_TRAIT.get(best_trait, "meadow")
	buddy.preferred_furniture = Array(
		FURNITURE_FOR_TRAIT.get(best_trait, ["cushion"]), TYPE_STRING, "", null
	)


func _vary(base: float, rng: RandomNumberGenerator) -> float:
	return clampf(base + rng.randf_range(-PERSONALITY_VARIANCE, PERSONALITY_VARIANCE), 0.0, 1.0)


func _find_part_index(pool_name: String, part: Dictionary) -> int:
	# For now just return the index based on id lookup
	# This is simple enough that a linear scan is fine for ~20 parts
	var count := 0
	match pool_name:
		"bodies": count = _part_pool.body_count()
		_: count = 0
	# Since PartPool doesn't expose index lookup yet, store the index during pick
	# For MVP, use a simple hash of the id
	return part.get("_index", 0)


func _find_accessory_index(_slot_name: String, part: Dictionary) -> int:
	return part.get("_index", 0)
```

**Note:** The `_find_part_index` method needs PartPool to track indices. Add index tracking to PartPool:

Update `scripts/data/part_pool.gd` — in `_load_parts`, add `_index` to each entry:

```gdscript
# In _load_parts, after the for loop, add index:
func _load_parts(file_path: String) -> Array[Dictionary]:
	# ... existing loading code ...
	var result: Array[Dictionary] = []
	var idx := 0
	for entry in data.get("parts", []):
		entry["rarity"] = rarity_from_string(entry.get("rarity", "common"))
		entry["_index"] = idx
		result.append(entry)
		idx += 1
	return result
```

Same for `_load_accessories`:
```gdscript
# In _load_accessories, add index per slot:
for slot_name in data.get("slots", {}).keys():
	var parts: Array[Dictionary] = []
	var idx := 0
	for entry in data["slots"][slot_name]:
		entry["rarity"] = rarity_from_string(entry.get("rarity", "common"))
		entry["_index"] = idx
		parts.append(entry)
		idx += 1
	_accessories[slot_name] = parts
```

- [ ] **Step 5: Run tests to verify they pass**

Run: GUT → Run `test_buddy_creator.gd`
Expected: All 9 tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/data/buddy_creator.gd scripts/data/part_pool.gd data/claude_species.json tests/test_buddy_creator.gd
git commit -m "feat: BuddyCreator — paper doll blob assembly + Claude species generation"
```

---

## Task 6: Buddy Roster Manager

**Files:**
- Create: `scripts/managers/buddy_roster.gd`
- Create: `tests/test_buddy_roster.gd`

Owns and manages all buddy instances. Central access point for the buddy collection.

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_buddy_roster.gd
extends GutTest

var roster: BuddyRoster

func before_each() -> void:
	roster = BuddyRoster.new()

func test_starts_empty() -> void:
	assert_eq(roster.count(), 0)

func test_add_buddy() -> void:
	var buddy := BuddyData.new()
	buddy.id = "test_1"
	roster.add_buddy(buddy)
	assert_eq(roster.count(), 1)

func test_get_buddy_by_id() -> void:
	var buddy := BuddyData.new()
	buddy.id = "test_1"
	buddy.buddy_name = "Blobbert"
	roster.add_buddy(buddy)
	var found := roster.get_buddy("test_1")
	assert_eq(found.buddy_name, "Blobbert")

func test_get_buddies_in_zone() -> void:
	var b1 := BuddyData.new()
	b1.id = "b1"
	b1.current_zone = "meadow"
	var b2 := BuddyData.new()
	b2.id = "b2"
	b2.current_zone = "burrow"
	var b3 := BuddyData.new()
	b3.id = "b3"
	b3.current_zone = "meadow"
	roster.add_buddy(b1)
	roster.add_buddy(b2)
	roster.add_buddy(b3)
	var meadow_buddies := roster.get_buddies_in_zone("meadow")
	assert_eq(meadow_buddies.size(), 2)

func test_get_available_for_expedition() -> void:
	var b1 := BuddyData.new()
	b1.id = "b1"
	b1.state = BuddyData.State.IDLE
	var b2 := BuddyData.new()
	b2.id = "b2"
	b2.state = BuddyData.State.EXPEDITION
	roster.add_buddy(b1)
	roster.add_buddy(b2)
	var available := roster.get_available_for_expedition()
	assert_eq(available.size(), 1)
	assert_eq(available[0].id, "b1")

func test_to_array_and_from_array() -> void:
	var b1 := BuddyData.new()
	b1.id = "b1"
	b1.buddy_name = "Squish"
	roster.add_buddy(b1)
	var arr := roster.to_array()
	var restored := BuddyRoster.new()
	restored.load_from_array(arr)
	assert_eq(restored.count(), 1)
	assert_eq(restored.get_buddy("b1").buddy_name, "Squish")

func test_signal_on_buddy_added() -> void:
	watch_signals(roster)
	var buddy := BuddyData.new()
	buddy.id = "test_sig"
	roster.add_buddy(buddy)
	assert_signal_emitted(roster, "buddy_added")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_buddy_roster.gd`
Expected: All tests FAIL

- [ ] **Step 3: Implement BuddyRoster**

```gdscript
# scripts/managers/buddy_roster.gd
class_name BuddyRoster
extends RefCounted

signal buddy_added(buddy: BuddyData)

var _buddies: Dictionary = {}  # id -> BuddyData


func add_buddy(buddy: BuddyData) -> void:
	_buddies[buddy.id] = buddy
	buddy_added.emit(buddy)


func get_buddy(id: String) -> BuddyData:
	return _buddies.get(id)


func count() -> int:
	return _buddies.size()


func get_all() -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		result.append(buddy)
	return result


func get_buddies_in_zone(zone_id: String) -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		if buddy.current_zone == zone_id and buddy.state != BuddyData.State.EXPEDITION:
			result.append(buddy)
	return result


func get_available_for_expedition() -> Array[BuddyData]:
	var result: Array[BuddyData] = []
	for buddy in _buddies.values():
		if buddy.state != BuddyData.State.EXPEDITION:
			result.append(buddy)
	return result


func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buddy in _buddies.values():
		result.append(buddy.to_dict())
	return result


func load_from_array(arr: Array) -> void:
	_buddies.clear()
	for dict in arr:
		var buddy := BuddyData.from_dict(dict)
		_buddies[buddy.id] = buddy
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_buddy_roster.gd`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/managers/buddy_roster.gd tests/test_buddy_roster.gd
git commit -m "feat: BuddyRoster — manage buddy collection with zone/expedition queries"
```

---

## Task 7: Zone Manager

**Files:**
- Create: `scripts/managers/zone_manager.gd`
- Create: `data/zones.json`
- Create: `data/decorations.json`
- Create: `tests/test_zone_manager.gd`

Tracks unlocked zones, decoration placements, and zone unlock milestones.

- [ ] **Step 1: Create zone and decoration data**

```json
// data/zones.json
{
  "zones": [
    {"id": "meadow", "name": "The Meadow", "unlock_at": 0, "vibe": "warm"},
    {"id": "burrow", "name": "The Burrow", "unlock_at": 10, "vibe": "cozy"},
    {"id": "pond", "name": "The Pond", "unlock_at": 20, "vibe": "wet"},
    {"id": "mushroom_grotto", "name": "The Mushroom Grotto", "unlock_at": 35, "vibe": "mysterious"},
    {"id": "canopy", "name": "The Canopy", "unlock_at": 50, "vibe": "breezy"},
    {"id": "crystal_cave", "name": "The Crystal Cave", "unlock_at": 75, "vibe": "sparkly"}
  ]
}
```

```json
// data/decorations.json
{
  "decorations": [
    {"id": "cushion", "name": "Cozy Cushion", "cost": 50, "unlock_zone": "meadow", "type": "furniture", "behavior": "nap"},
    {"id": "lamp", "name": "Warm Lamp", "cost": 75, "unlock_zone": "meadow", "type": "furniture", "behavior": "bask"},
    {"id": "bush", "name": "Hiding Bush", "cost": 40, "unlock_zone": "meadow", "type": "furniture", "behavior": "hide"},
    {"id": "bench", "name": "Buddy Bench", "cost": 80, "unlock_zone": "meadow", "type": "furniture", "behavior": "sit"},
    {"id": "blanket", "name": "Snug Blanket", "cost": 60, "unlock_zone": "burrow", "type": "furniture", "behavior": "nap"},
    {"id": "mushroom_lamp", "name": "Mushroom Lamp", "cost": 100, "unlock_zone": "mushroom_grotto", "type": "furniture", "behavior": "bask"},
    {"id": "crystal_bench", "name": "Crystal Bench", "cost": 120, "unlock_zone": "crystal_cave", "type": "furniture", "behavior": "sit"},
    {"id": "ball", "name": "Bouncy Ball", "cost": 45, "unlock_zone": "meadow", "type": "toy", "behavior": "play"},
    {"id": "telescope", "name": "Tiny Telescope", "cost": 90, "unlock_zone": "canopy", "type": "furniture", "behavior": "inspect"},
    {"id": "lily_pad", "name": "Lily Pad Seat", "cost": 70, "unlock_zone": "pond", "type": "furniture", "behavior": "sit"}
  ]
}
```

- [ ] **Step 2: Write failing tests**

```gdscript
# tests/test_zone_manager.gd
extends GutTest

var zm: ZoneManager

func before_each() -> void:
	zm = ZoneManager.new()
	zm.load_data("res://data/zones.json", "res://data/decorations.json")

func test_meadow_unlocked_by_default() -> void:
	assert_true(zm.is_zone_unlocked("meadow"))

func test_burrow_locked_initially() -> void:
	assert_false(zm.is_zone_unlocked("burrow"))

func test_unlock_zone_at_milestone() -> void:
	zm.check_unlocks(10)
	assert_true(zm.is_zone_unlocked("burrow"))
	assert_false(zm.is_zone_unlocked("pond"))

func test_unlock_multiple_zones() -> void:
	zm.check_unlocks(25)
	assert_true(zm.is_zone_unlocked("burrow"))
	assert_true(zm.is_zone_unlocked("pond"))
	assert_false(zm.is_zone_unlocked("mushroom_grotto"))

func test_get_unlocked_zones() -> void:
	zm.check_unlocks(20)
	var unlocked := zm.get_unlocked_zone_ids()
	assert_has(unlocked, "meadow")
	assert_has(unlocked, "burrow")
	assert_has(unlocked, "pond")

func test_place_decoration() -> void:
	zm.place_decoration("meadow", "cushion", Vector2(100, 200))
	var placed := zm.get_decorations_in_zone("meadow")
	assert_eq(placed.size(), 1)
	assert_eq(placed[0].id, "cushion")
	assert_eq(placed[0].position, Vector2(100, 200))

func test_remove_decoration() -> void:
	zm.place_decoration("meadow", "cushion", Vector2(100, 200))
	zm.remove_decoration("meadow", 0)
	assert_eq(zm.get_decorations_in_zone("meadow").size(), 0)

func test_available_decorations_filtered_by_unlock() -> void:
	# Only meadow unlocked — should only see meadow decorations
	var available := zm.get_available_decorations()
	for deco in available:
		assert_eq(deco.unlock_zone, "meadow",
			"Only meadow decorations should be available initially")

func test_zone_data_has_name() -> void:
	var data := zm.get_zone_data("meadow")
	assert_eq(data.name, "The Meadow")

func test_signal_on_zone_unlock() -> void:
	watch_signals(zm)
	zm.check_unlocks(10)
	assert_signal_emitted(zm, "zone_unlocked")

func test_expedition_slots_scale_with_zones() -> void:
	assert_eq(zm.get_expedition_slots(), 1, "Start with 1 slot (meadow)")
	zm.check_unlocks(10)
	assert_eq(zm.get_expedition_slots(), 2, "Burrow unlock = 2 slots")
	zm.check_unlocks(50)
	assert_eq(zm.get_expedition_slots(), 5, "Canopy unlock = 5 slots (max)")

func test_to_dict_and_from_dict() -> void:
	zm.check_unlocks(10)
	zm.place_decoration("meadow", "cushion", Vector2(50, 100))
	var dict := zm.to_dict()
	var restored := ZoneManager.new()
	restored.load_data("res://data/zones.json", "res://data/decorations.json")
	restored.load_from_dict(dict)
	assert_true(restored.is_zone_unlocked("burrow"))
	assert_eq(restored.get_decorations_in_zone("meadow").size(), 1)
```

- [ ] **Step 3: Run tests to verify they fail**

Run: GUT → Run `test_zone_manager.gd`
Expected: All tests FAIL

- [ ] **Step 4: Implement ZoneManager**

```gdscript
# scripts/managers/zone_manager.gd
class_name ZoneManager
extends RefCounted

signal zone_unlocked(zone_id: String)

const MAX_EXPEDITION_SLOTS := 5

var _zone_defs: Array[Dictionary] = []      # From zones.json
var _decoration_defs: Array[Dictionary] = [] # From decorations.json
var _unlocked_zones: Array[String] = []
var _placed_decorations: Dictionary = {}     # zone_id -> Array of {id, position}


func load_data(zones_path: String, decorations_path: String) -> void:
	_zone_defs = _load_json_array(zones_path, "zones")
	_decoration_defs = _load_json_array(decorations_path, "decorations")

	# Meadow always unlocked
	_unlocked_zones = ["meadow"]
	_placed_decorations = {}


func _load_json_array(file_path: String, key: String) -> Array[Dictionary]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("ZoneManager: could not open %s" % file_path)
		return []
	var json := JSON.new()
	json.parse(file.get_as_text())
	var result: Array[Dictionary] = []
	for entry in json.data.get(key, []):
		result.append(entry)
	return result


func is_zone_unlocked(zone_id: String) -> bool:
	return zone_id in _unlocked_zones


func check_unlocks(buddy_count: int) -> void:
	for zone_def in _zone_defs:
		var zone_id: String = zone_def["id"]
		var threshold: int = zone_def["unlock_at"]
		if buddy_count >= threshold and zone_id not in _unlocked_zones:
			_unlocked_zones.append(zone_id)
			zone_unlocked.emit(zone_id)


func get_unlocked_zone_ids() -> Array[String]:
	return _unlocked_zones.duplicate()


func get_zone_data(zone_id: String) -> Dictionary:
	for zone_def in _zone_defs:
		if zone_def["id"] == zone_id:
			return zone_def
	return {}


func place_decoration(zone_id: String, deco_id: String, position: Vector2) -> void:
	if not _placed_decorations.has(zone_id):
		_placed_decorations[zone_id] = []
	_placed_decorations[zone_id].append({"id": deco_id, "position": position})


func remove_decoration(zone_id: String, index: int) -> void:
	if _placed_decorations.has(zone_id):
		if index >= 0 and index < _placed_decorations[zone_id].size():
			_placed_decorations[zone_id].remove_at(index)


func get_decorations_in_zone(zone_id: String) -> Array:
	return _placed_decorations.get(zone_id, [])


func get_available_decorations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for deco in _decoration_defs:
		if deco["unlock_zone"] in _unlocked_zones:
			result.append(deco)
	return result


func get_expedition_slots() -> int:
	return mini(_unlocked_zones.size(), MAX_EXPEDITION_SLOTS)


func get_decoration_def(deco_id: String) -> Dictionary:
	for deco in _decoration_defs:
		if deco["id"] == deco_id:
			return deco
	return {}


func to_dict() -> Dictionary:
	var placed := {}
	for zone_id in _placed_decorations:
		var arr := []
		for entry in _placed_decorations[zone_id]:
			arr.append({
				"id": entry["id"],
				"position": [entry["position"].x, entry["position"].y],
			})
		placed[zone_id] = arr
	return {
		"unlocked_zones": _unlocked_zones,
		"placed_decorations": placed,
	}


func load_from_dict(dict: Dictionary) -> void:
	_unlocked_zones = Array(dict.get("unlocked_zones", ["meadow"]), TYPE_STRING, "", null)
	_placed_decorations = {}
	var placed: Dictionary = dict.get("placed_decorations", {})
	for zone_id in placed:
		_placed_decorations[zone_id] = []
		for entry in placed[zone_id]:
			var pos_arr: Array = entry["position"]
			_placed_decorations[zone_id].append({
				"id": entry["id"],
				"position": Vector2(pos_arr[0], pos_arr[1]),
			})
```

- [ ] **Step 5: Run tests to verify they pass**

Run: GUT → Run `test_zone_manager.gd`
Expected: All 12 tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/managers/zone_manager.gd data/zones.json data/decorations.json tests/test_zone_manager.gd
git commit -m "feat: ZoneManager — zone unlocks, decoration placement, expedition slots"
```

---

## Task 8: Progression Manager

**Files:**
- Create: `scripts/managers/progression_manager.gd`
- Create: `tests/test_progression_manager.gd`

Tracks stardust currency and milestone progress.

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_progression_manager.gd
extends GutTest

var pm: ProgressionManager

func before_each() -> void:
	pm = ProgressionManager.new()

func test_starts_with_zero_stardust() -> void:
	assert_eq(pm.stardust, 0)

func test_earn_stardust() -> void:
	pm.earn_stardust(100)
	assert_eq(pm.stardust, 100)

func test_spend_stardust() -> void:
	pm.earn_stardust(100)
	var success := pm.spend_stardust(60)
	assert_true(success)
	assert_eq(pm.stardust, 40)

func test_cannot_overspend() -> void:
	pm.earn_stardust(50)
	var success := pm.spend_stardust(100)
	assert_false(success)
	assert_eq(pm.stardust, 50, "Stardust should be unchanged after failed spend")

func test_passive_stardust_trickle() -> void:
	# 1 stardust per buddy per minute
	var earned := pm.calculate_passive_stardust(5, 120.0)  # 5 buddies, 2 minutes
	assert_eq(earned, 10)

func test_total_buddies_tracking() -> void:
	pm.record_buddy_found()
	pm.record_buddy_found()
	assert_eq(pm.total_buddies_found, 2)

func test_to_dict_and_from_dict() -> void:
	pm.earn_stardust(500)
	pm.record_buddy_found()
	pm.record_buddy_found()
	pm.record_buddy_found()

	var dict := pm.to_dict()
	var restored := ProgressionManager.new()
	restored.load_from_dict(dict)

	assert_eq(restored.stardust, 500)
	assert_eq(restored.total_buddies_found, 3)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_progression_manager.gd`
Expected: All tests FAIL

- [ ] **Step 3: Implement ProgressionManager**

```gdscript
# scripts/managers/progression_manager.gd
class_name ProgressionManager
extends RefCounted

signal stardust_changed(new_amount: int)

const STARDUST_PER_BUDDY_PER_MINUTE := 1

var stardust: int = 0
var total_buddies_found: int = 0


func earn_stardust(amount: int) -> void:
	stardust += amount
	stardust_changed.emit(stardust)


func spend_stardust(amount: int) -> bool:
	if stardust < amount:
		return false
	stardust -= amount
	stardust_changed.emit(stardust)
	return true


func calculate_passive_stardust(buddy_count: int, elapsed_seconds: float) -> int:
	var minutes := elapsed_seconds / 60.0
	return int(buddy_count * minutes * STARDUST_PER_BUDDY_PER_MINUTE)


func record_buddy_found() -> void:
	total_buddies_found += 1


func to_dict() -> Dictionary:
	return {
		"stardust": stardust,
		"total_buddies_found": total_buddies_found,
	}


func load_from_dict(dict: Dictionary) -> void:
	stardust = dict.get("stardust", 0)
	total_buddies_found = dict.get("total_buddies_found", 0)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_progression_manager.gd`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/managers/progression_manager.gd tests/test_progression_manager.gd
git commit -m "feat: ProgressionManager — stardust economy, passive trickle, milestone tracking"
```

---

## Task 9: Expedition Manager

**Files:**
- Create: `scripts/managers/expedition_manager.gd`
- Create: `tests/test_expedition_manager.gd`

Handles sending buddies on vacations, timers, result rolling, and returning with finds.

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_expedition_manager.gd
extends GutTest

var em: ExpeditionManager

func before_each() -> void:
	em = ExpeditionManager.new()
	em.max_slots = 2

func test_send_buddy_on_expedition() -> void:
	var buddy := BuddyData.new()
	buddy.id = "b1"
	buddy.state = BuddyData.State.IDLE
	buddy.personality.energy = 0.5
	var success := em.send_on_expedition(buddy)
	assert_true(success)
	assert_eq(buddy.state, BuddyData.State.EXPEDITION)
	assert_eq(em.active_count(), 1)

func test_cannot_exceed_max_slots() -> void:
	var b1 := BuddyData.new()
	b1.id = "b1"
	b1.personality.energy = 0.5
	var b2 := BuddyData.new()
	b2.id = "b2"
	b2.personality.energy = 0.5
	var b3 := BuddyData.new()
	b3.id = "b3"
	b3.personality.energy = 0.5
	em.send_on_expedition(b1)
	em.send_on_expedition(b2)
	var success := em.send_on_expedition(b3)
	assert_false(success, "Should not exceed max slots")

func test_high_energy_returns_faster() -> void:
	var slow := BuddyData.new()
	slow.id = "slow"
	slow.personality.energy = 0.1
	var fast := BuddyData.new()
	fast.id = "fast"
	fast.personality.energy = 0.9

	var slow_dur := em.calculate_duration(slow)
	var fast_dur := em.calculate_duration(fast)
	assert_lt(fast_dur, slow_dur, "High energy should return faster")

func test_roll_expedition_result() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := BuddyData.new()
	buddy.personality.curiosity = 0.5

	# Roll many results, verify distribution is reasonable
	var results := {"blob": 0, "claude_buddy": 0, "decoration": 0, "nice_walk": 0}
	for i in range(1000):
		rng.seed = i
		var result := em.roll_result(buddy, rng)
		results[result.type] += 1

	# ~45% blob, ~5% claude, ~10% decoration, ~40% nice_walk
	assert_gt(results["blob"], 300, "Should find blobs ~45%% of the time")
	assert_gt(results["nice_walk"], 250, "Should have nice walks ~40%% of the time")
	assert_gt(results["claude_buddy"], 10, "Should find claude buddies ~5%% of the time")
	assert_lt(results["claude_buddy"], 100, "Claude buddies should be rare")
	assert_gt(results["decoration"], 50, "Should find decorations ~10%% of the time")

func test_check_returns_completed_expeditions() -> void:
	var buddy := BuddyData.new()
	buddy.id = "b1"
	buddy.personality.energy = 0.5
	em.send_on_expedition(buddy)

	# Manually set departure time to the past
	em._active_expeditions[0].departure_time = Time.get_unix_time_from_system() - 9999.0

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var completed := em.check_completed(rng)
	assert_eq(completed.size(), 1)
	assert_eq(completed[0].buddy_id, "b1")
	assert_eq(buddy.state, BuddyData.State.IDLE, "Buddy should return to idle")

func test_stardust_always_earned() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var buddy := BuddyData.new()
	buddy.personality.curiosity = 0.5
	var result := em.roll_result(buddy, rng)
	assert_gt(result.stardust, 0, "Should always earn some stardust")

func test_to_array_and_from_array() -> void:
	var buddy := BuddyData.new()
	buddy.id = "b1"
	buddy.personality.energy = 0.5
	em.send_on_expedition(buddy)
	var arr := em.to_array()
	assert_eq(arr.size(), 1)
	assert_eq(arr[0]["buddy_id"], "b1")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_expedition_manager.gd`
Expected: All tests FAIL

- [ ] **Step 3: Implement ExpeditionManager**

```gdscript
# scripts/managers/expedition_manager.gd
class_name ExpeditionManager
extends RefCounted

signal expedition_completed(result: Dictionary)

# Duration range in seconds (5-15 minutes)
const BASE_DURATION_MIN := 300.0
const BASE_DURATION_MAX := 900.0
const ENERGY_SPEED_FACTOR := 0.5  # High energy reduces duration by up to 50%

# Result probabilities
const PROB_BLOB := 0.45
const PROB_CLAUDE := 0.05
const PROB_DECORATION := 0.10
# nice_walk = 1.0 - above = 0.40

# Curiosity bonus to discovery
const CURIOSITY_BONUS := 0.05  # Adds up to 5% to blob/claude chance

# Stardust range per expedition
const STARDUST_MIN := 10
const STARDUST_MAX := 30
const STARDUST_NICE_WALK_BONUS := 20

var max_slots: int = 1
var _active_expeditions: Array = []  # Array of ExpeditionEntry


class ExpeditionEntry:
	var buddy_id: String
	var buddy_ref: BuddyData  # Live reference, null after restore from save
	var departure_time: float
	var duration: float


func send_on_expedition(buddy: BuddyData) -> bool:
	if _active_expeditions.size() >= max_slots:
		return false
	if buddy.state == BuddyData.State.EXPEDITION:
		return false

	var entry := ExpeditionEntry.new()
	entry.buddy_id = buddy.id
	entry.buddy_ref = buddy
	entry.departure_time = Time.get_unix_time_from_system()
	entry.duration = calculate_duration(buddy)

	buddy.state = BuddyData.State.EXPEDITION
	_active_expeditions.append(entry)
	return true


func calculate_duration(buddy: BuddyData) -> float:
	var base := (BASE_DURATION_MIN + BASE_DURATION_MAX) / 2.0
	var reduction := buddy.personality.energy * ENERGY_SPEED_FACTOR
	return base * (1.0 - reduction)


func active_count() -> int:
	return _active_expeditions.size()


func check_completed(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var now := Time.get_unix_time_from_system()
	var completed: Array[Dictionary] = []
	var still_active: Array = []

	for entry in _active_expeditions:
		if now >= entry.departure_time + entry.duration:
			var buddy := entry.buddy_ref
			if buddy:
				buddy.state = BuddyData.State.IDLE
			var result := roll_result(buddy, rng) if buddy else roll_result_no_buddy(rng)
			result["buddy_id"] = entry.buddy_id
			completed.append(result)
			expedition_completed.emit(result)
		else:
			still_active.append(entry)

	_active_expeditions = still_active
	return completed


func roll_result(buddy: BuddyData, rng: RandomNumberGenerator) -> Dictionary:
	var curiosity_bonus := buddy.personality.curiosity * CURIOSITY_BONUS if buddy else 0.0
	var roll := rng.randf()

	var blob_threshold := PROB_BLOB + curiosity_bonus
	var claude_threshold := blob_threshold + PROB_CLAUDE + curiosity_bonus * 0.5
	var deco_threshold := claude_threshold + PROB_DECORATION

	var stardust := rng.randi_range(STARDUST_MIN, STARDUST_MAX)
	var result: Dictionary

	if roll < blob_threshold:
		result = {"type": "blob", "stardust": stardust}
	elif roll < claude_threshold:
		result = {"type": "claude_buddy", "stardust": stardust}
	elif roll < deco_threshold:
		result = {"type": "decoration", "stardust": stardust}
	else:
		result = {"type": "nice_walk", "stardust": stardust + STARDUST_NICE_WALK_BONUS}

	return result


func roll_result_no_buddy(rng: RandomNumberGenerator) -> Dictionary:
	# Fallback for offline resolution where buddy ref is lost
	var stub := BuddyData.new()
	stub.personality.curiosity = 0.5
	return roll_result(stub, rng)


func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _active_expeditions:
		result.append({
			"buddy_id": entry.buddy_id,
			"departure_time": entry.departure_time,
			"duration": entry.duration,
		})
	return result


func load_from_array(arr: Array, roster: BuddyRoster) -> void:
	_active_expeditions = []
	for dict in arr:
		var entry := ExpeditionEntry.new()
		entry.buddy_id = dict["buddy_id"]
		entry.departure_time = dict["departure_time"]
		entry.duration = dict["duration"]
		entry.buddy_ref = roster.get_buddy(entry.buddy_id)
		if entry.buddy_ref:
			entry.buddy_ref.state = BuddyData.State.EXPEDITION
		_active_expeditions.append(entry)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_expedition_manager.gd`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/managers/expedition_manager.gd tests/test_expedition_manager.gd
git commit -m "feat: ExpeditionManager — vacation timers, result rolling, slot management"
```

---

## Task 10: Save Manager + Offline Catch-Up

**Files:**
- Create: `scripts/managers/save_manager.gd`
- Create: `tests/test_save_manager.gd`

Handles JSON save/load and the offline catch-up calculation (stardust trickle, expedition resolution, buddy zone shuffling).

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_save_manager.gd
extends GutTest

var sm: SaveManager

func before_each() -> void:
	sm = SaveManager.new()
	# Use a test save path to avoid polluting real saves
	sm.save_path = "user://test_save.json"

func after_each() -> void:
	# Clean up test save file
	if FileAccess.file_exists("user://test_save.json"):
		DirAccess.remove_absolute("user://test_save.json")

func test_save_and_load_round_trip() -> void:
	var roster := BuddyRoster.new()
	var buddy := BuddyData.new()
	buddy.id = "test_1"
	buddy.buddy_name = "Roundtrip Blob"
	roster.add_buddy(buddy)

	var zone_mgr := ZoneManager.new()
	zone_mgr.load_data("res://data/zones.json", "res://data/decorations.json")

	var prog := ProgressionManager.new()
	prog.earn_stardust(250)

	var exp_mgr := ExpeditionManager.new()

	sm.save_game(roster, zone_mgr, prog, exp_mgr)
	assert_true(FileAccess.file_exists("user://test_save.json"))

	# Load into fresh managers
	var r2 := BuddyRoster.new()
	var z2 := ZoneManager.new()
	z2.load_data("res://data/zones.json", "res://data/decorations.json")
	var p2 := ProgressionManager.new()
	var e2 := ExpeditionManager.new()

	var success := sm.load_game(r2, z2, p2, e2)
	assert_true(success)
	assert_eq(r2.count(), 1)
	assert_eq(r2.get_buddy("test_1").buddy_name, "Roundtrip Blob")
	assert_eq(p2.stardust, 250)

func test_offline_catchup_stardust() -> void:
	var elapsed := 3600.0  # 1 hour
	var buddy_count := 5
	var catchup := sm.calculate_offline_catchup(elapsed, buddy_count)
	# 5 buddies * 60 minutes * 1 stardust/buddy/min = 300
	assert_eq(catchup.stardust_earned, 300)

func test_offline_catchup_expeditions() -> void:
	# Set up an expedition that departed 1 hour ago with 10 minute duration
	var exp_mgr := ExpeditionManager.new()
	var buddy := BuddyData.new()
	buddy.id = "b1"
	buddy.personality.energy = 0.5
	exp_mgr.send_on_expedition(buddy)
	exp_mgr._active_expeditions[0].departure_time = Time.get_unix_time_from_system() - 3600.0

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var completed := exp_mgr.check_completed(rng)
	assert_eq(completed.size(), 1, "Expedition should have completed during offline time")

func test_no_save_file_returns_false() -> void:
	var r := BuddyRoster.new()
	var z := ZoneManager.new()
	z.load_data("res://data/zones.json", "res://data/decorations.json")
	var p := ProgressionManager.new()
	var e := ExpeditionManager.new()
	var success := sm.load_game(r, z, p, e)
	assert_false(success, "Should return false when no save file exists")

func test_last_played_timestamp_saved() -> void:
	var roster := BuddyRoster.new()
	var zone_mgr := ZoneManager.new()
	zone_mgr.load_data("res://data/zones.json", "res://data/decorations.json")
	var prog := ProgressionManager.new()
	var exp_mgr := ExpeditionManager.new()

	sm.save_game(roster, zone_mgr, prog, exp_mgr)

	var file := FileAccess.open("user://test_save.json", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	assert_has(data, "last_played")
	assert_gt(data["last_played"], 0.0)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_save_manager.gd`
Expected: All tests FAIL

- [ ] **Step 3: Implement SaveManager**

```gdscript
# scripts/managers/save_manager.gd
class_name SaveManager
extends RefCounted

var save_path: String = "user://buddy_sanctuary_save.json"


func save_game(
	roster: BuddyRoster,
	zone_mgr: ZoneManager,
	progression: ProgressionManager,
	expeditions: ExpeditionManager,
) -> void:
	var data := {
		"last_played": Time.get_unix_time_from_system(),
		"buddy_roster": roster.to_array(),
		"zones": zone_mgr.to_dict(),
		"progression": progression.to_dict(),
		"expeditions": expeditions.to_array(),
	}
	var json_string := JSON.stringify(data, "  ")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


func load_game(
	roster: BuddyRoster,
	zone_mgr: ZoneManager,
	progression: ProgressionManager,
	expeditions: ExpeditionManager,
) -> bool:
	if not FileAccess.file_exists(save_path):
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SaveManager: failed to parse save file")
		return false

	var data: Dictionary = json.data

	roster.load_from_array(data.get("buddy_roster", []))
	zone_mgr.load_from_dict(data.get("zones", {}))
	progression.load_from_dict(data.get("progression", {}))
	expeditions.load_from_array(data.get("expeditions", []), roster)

	return true


func get_last_played() -> float:
	if not FileAccess.file_exists(save_path):
		return 0.0

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return 0.0

	var json := JSON.new()
	json.parse(file.get_as_text())
	var data: Dictionary = json.data
	return data.get("last_played", 0.0)


func calculate_offline_catchup(elapsed_seconds: float, buddy_count: int) -> Dictionary:
	var pm := ProgressionManager.new()
	var stardust := pm.calculate_passive_stardust(buddy_count, elapsed_seconds)
	return {
		"stardust_earned": stardust,
		"elapsed_seconds": elapsed_seconds,
	}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_save_manager.gd`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/managers/save_manager.gd tests/test_save_manager.gd
git commit -m "feat: SaveManager — JSON save/load, offline catch-up calculation"
```

---

## Task 11: Sanctuary Autoload

**Files:**
- Modify: `scripts/autoload/sanctuary.gd`

Wires all managers together. Central access point for the entire game state.

- [ ] **Step 1: Implement Sanctuary autoload**

```gdscript
# scripts/autoload/sanctuary.gd
extends Node

var buddy_roster := BuddyRoster.new()
var zone_manager := ZoneManager.new()
var progression := ProgressionManager.new()
var expedition_manager := ExpeditionManager.new()
var save_manager := SaveManager.new()
var buddy_creator := BuddyCreator.new()
var rng := RandomNumberGenerator.new()

const AUTOSAVE_INTERVAL := 180.0  # 3 minutes
var _autosave_timer := 0.0
var _passive_stardust_timer := 0.0
const PASSIVE_STARDUST_INTERVAL := 60.0  # Earn every minute


func _ready() -> void:
	rng.randomize()
	zone_manager.load_data("res://data/zones.json", "res://data/decorations.json")
	buddy_creator.load_data("res://data/parts", "res://data/names", "res://data/claude_species.json")

	# Try loading save
	var had_save := save_manager.load_game(
		buddy_roster, zone_manager, progression, expedition_manager
	)

	if had_save:
		_handle_offline_catchup()
	else:
		_start_new_game()

	# Connect signals
	buddy_roster.buddy_added.connect(_on_buddy_added)
	zone_manager.zone_unlocked.connect(_on_zone_unlocked)


func _process(delta: float) -> void:
	# Autosave
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

	# Passive stardust
	_passive_stardust_timer += delta
	if _passive_stardust_timer >= PASSIVE_STARDUST_INTERVAL:
		_passive_stardust_timer = 0.0
		var earned := progression.calculate_passive_stardust(buddy_roster.count(), PASSIVE_STARDUST_INTERVAL)
		if earned > 0:
			progression.earn_stardust(earned)

	# Check expedition returns
	var completed := expedition_manager.check_completed(rng)
	for result in completed:
		_handle_expedition_result(result)


func save_game() -> void:
	save_manager.save_game(buddy_roster, zone_manager, progression, expedition_manager)


func send_on_expedition(buddy: BuddyData) -> bool:
	expedition_manager.max_slots = zone_manager.get_expedition_slots()
	return expedition_manager.send_on_expedition(buddy)


func buy_decoration(deco_id: String, zone_id: String, position: Vector2) -> bool:
	var deco_def := zone_manager.get_decoration_def(deco_id)
	if deco_def.is_empty():
		return false
	var cost: int = deco_def.get("cost", 0)
	if not progression.spend_stardust(cost):
		return false
	zone_manager.place_decoration(zone_id, deco_id, position)
	return true


func _start_new_game() -> void:
	# Give the player their first buddy
	var starter := buddy_creator.create_blob(rng)
	buddy_roster.add_buddy(starter)
	progression.record_buddy_found()


func _handle_offline_catchup() -> void:
	var last_played := save_manager.get_last_played()
	if last_played <= 0.0:
		return
	var elapsed := Time.get_unix_time_from_system() - last_played
	if elapsed <= 0.0:
		return

	var catchup := save_manager.calculate_offline_catchup(elapsed, buddy_roster.count())
	progression.earn_stardust(catchup.stardust_earned)

	# TODO: Present welcome back screen with catchup details
	# For now, just apply the results silently


func _handle_expedition_result(result: Dictionary) -> void:
	var stardust: int = result.get("stardust", 0)
	progression.earn_stardust(stardust)

	match result["type"]:
		"blob":
			var new_buddy := buddy_creator.create_blob(rng)
			buddy_roster.add_buddy(new_buddy)
			progression.record_buddy_found()
		"claude_buddy":
			var rarity_roll := _roll_claude_rarity()
			var new_buddy := buddy_creator.create_claude_buddy(rng, rarity_roll)
			new_buddy.shiny = rng.randf() < 0.01
			buddy_roster.add_buddy(new_buddy)
			progression.record_buddy_found()
		"decoration":
			# TODO: Pick a random decoration and give it for free
			pass
		"nice_walk":
			# Buddy had a good time — happiness boost handled elsewhere
			pass


func _roll_claude_rarity() -> BuddyData.Rarity:
	var roll := rng.randf()
	if roll < 0.60:
		return BuddyData.Rarity.COMMON
	elif roll < 0.85:
		return BuddyData.Rarity.UNCOMMON
	elif roll < 0.95:
		return BuddyData.Rarity.RARE
	elif roll < 0.99:
		return BuddyData.Rarity.EPIC
	else:
		return BuddyData.Rarity.LEGENDARY


func _on_buddy_added(_buddy: BuddyData) -> void:
	zone_manager.check_unlocks(buddy_roster.count())


func _on_zone_unlocked(zone_id: String) -> void:
	expedition_manager.max_slots = zone_manager.get_expedition_slots()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
```

- [ ] **Step 2: Verify project loads without errors**

Run: Open Godot → Run project (F5)
Expected: Window opens, "Sanctuary autoload initialized" in console (or similar), no errors

- [ ] **Step 3: Commit**

```bash
git add scripts/autoload/sanctuary.gd
git commit -m "feat: Sanctuary autoload — wires all managers, autosave, passive stardust, expedition results"
```

---

## Task 12: Buddy Sprite Scene (Paper Doll Visual Assembly)

**Files:**
- Create: `scripts/zones/buddy_sprite.gd`
- Create: `scenes/buddy/buddy.tscn`

The visual representation of a buddy — assembles Sprite2D children at anchor points, applies colors, handles click interaction and basic animations.

- [ ] **Step 1: Create placeholder sprite assets**

Create simple colored rectangles as placeholder PNGs (1x1 white pixel is fine — modulate does the rest). These will be replaced with Krita art later.

```bash
# Create 1x1 white placeholder PNG for each slot
# (In practice, create these in Krita or use a script)
# For now, use Godot's built-in PlaceholderTexture2D in the scene
```

- [ ] **Step 2: Create buddy scene template**

```ini
# scenes/buddy/buddy.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/zones/buddy_sprite.gd" id="1"]

[node name="Buddy" type="Node2D"]
script = ExtResource("1")

[node name="Body" type="Sprite2D" parent="."]
[node name="BodyAccent" type="Sprite2D" parent="."]
[node name="Eyes" type="Sprite2D" parent="."]
[node name="Mouth" type="Sprite2D" parent="."]
[node name="AccHead" type="Sprite2D" parent="."]
[node name="AccNeck" type="Sprite2D" parent="."]
[node name="AccHeld" type="Sprite2D" parent="."]
[node name="AccBack" type="Sprite2D" parent="."]
[node name="AccFeet" type="Sprite2D" parent="."]
[node name="ClickArea" type="Area2D" parent="."]
[node name="ClickShape" type="CollisionShape2D" parent="ClickArea"]
[node name="HeartParticles" type="GPUParticles2D" parent="."]
[node name="ShinyShimmer" type="GPUParticles2D" parent="."]
```

- [ ] **Step 3: Implement buddy_sprite.gd**

```gdscript
# scripts/zones/buddy_sprite.gd
class_name BuddySprite
extends Node2D

signal clicked(buddy_data: BuddyData)

@onready var body_sprite: Sprite2D = $Body
@onready var body_accent: Sprite2D = $BodyAccent
@onready var eyes_sprite: Sprite2D = $Eyes
@onready var mouth_sprite: Sprite2D = $Mouth
@onready var acc_head: Sprite2D = $AccHead
@onready var acc_neck: Sprite2D = $AccNeck
@onready var acc_held: Sprite2D = $AccHeld
@onready var acc_back: Sprite2D = $AccBack
@onready var acc_feet: Sprite2D = $AccFeet
@onready var click_area: Area2D = $ClickArea
@onready var heart_particles: GPUParticles2D = $HeartParticles
@onready var shiny_shimmer: GPUParticles2D = $ShinyShimmer

var buddy_data: BuddyData
var _part_pool: PartPool

const DEPTH_SCALE_MIN := 0.7
const DEPTH_SCALE_MAX := 1.0
const DEPTH_Y_MIN := 300.0   # "back" of the depth band
const DEPTH_Y_MAX := 600.0   # "front" of the depth band


func setup(data: BuddyData, part_pool: PartPool) -> void:
	buddy_data = data
	_part_pool = part_pool
	_assemble_appearance()
	_update_depth_sort()
	shiny_shimmer.emitting = data.shiny
	heart_particles.emitting = false


func _assemble_appearance() -> void:
	if buddy_data.species != "blob":
		_assemble_claude_species()
		return

	# Blob — paper doll assembly
	var body_def := _part_pool.get_body(buddy_data.appearance.body_index)
	var body_tex := _load_texture(body_def.get("texture", ""))
	if body_tex:
		body_sprite.texture = body_tex
		body_sprite.modulate = buddy_data.appearance.color_primary
		body_accent.texture = body_tex
		body_accent.modulate = buddy_data.appearance.color_secondary
		body_accent.modulate.a = 0.3  # Subtle accent overlay

	# Position parts at anchor points
	var anchors: Dictionary = body_def.get("anchors", {})
	_set_part(eyes_sprite, "eyes", buddy_data.appearance.eyes_index, anchors.get("eyes", [32, 18]))
	_set_part(mouth_sprite, "mouth", buddy_data.appearance.mouth_index, anchors.get("mouth", [32, 28]))

	# Accessories
	var acc_sprites := [acc_head, acc_neck, acc_held, acc_back, acc_feet]
	var acc_anchor_keys := ["acc_head", "acc_neck", "acc_held", "acc_back", "acc_feet"]
	var acc_slot_names := ["head", "neck", "held", "back", "feet"]
	for i in range(5):
		if buddy_data.appearance.accessory_indices[i] >= 0:
			_set_accessory(
				acc_sprites[i],
				acc_slot_names[i],
				buddy_data.appearance.accessory_indices[i],
				anchors.get(acc_anchor_keys[i], [32, 32])
			)
		else:
			acc_sprites[i].visible = false

	# Set up click collision shape based on body size
	_setup_click_area()


func _assemble_claude_species() -> void:
	# Claude buddies use a single pre-drawn sprite
	var tex := _load_texture(
		"res://assets/sprites/claude_species/%s.png" % buddy_data.species
	)
	if tex:
		body_sprite.texture = tex
		body_sprite.modulate = Color.WHITE  # No color tinting
	body_accent.visible = false
	eyes_sprite.visible = false
	mouth_sprite.visible = false
	acc_head.visible = false
	acc_neck.visible = false
	acc_held.visible = false
	acc_back.visible = false
	acc_feet.visible = false
	_setup_click_area()


func _set_part(sprite: Sprite2D, _pool_name: String, _index: int, anchor: Array) -> void:
	# TODO: Load actual texture from part pool by index
	# For now, use placeholder
	sprite.position = Vector2(anchor[0], anchor[1])
	sprite.modulate = Color.WHITE  # Parts keep their drawn colors


func _set_accessory(sprite: Sprite2D, _slot_name: String, _index: int, anchor: Array) -> void:
	sprite.position = Vector2(anchor[0], anchor[1])
	sprite.visible = true


func _setup_click_area() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 64)  # Default click area; adjust per body later
	$ClickArea/ClickShape.shape = shape


func _update_depth_sort() -> void:
	# Belt-scroll depth: higher Y = closer to camera = larger + rendered on top
	var t := clampf(
		(position.y - DEPTH_Y_MIN) / (DEPTH_Y_MAX - DEPTH_Y_MIN), 0.0, 1.0
	)
	var s := lerpf(DEPTH_SCALE_MIN, DEPTH_SCALE_MAX, t)
	scale = Vector2(s, s)
	z_index = int(position.y)


func _ready() -> void:
	click_area.input_event.connect(_on_click)


func _on_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_pet_reaction()
		clicked.emit(buddy_data)


func _show_pet_reaction() -> void:
	heart_particles.emitting = true
	# Quick happy wiggle
	var tween := create_tween()
	tween.tween_property(self, "rotation", deg_to_rad(5), 0.05)
	tween.tween_property(self, "rotation", deg_to_rad(-5), 0.1)
	tween.tween_property(self, "rotation", 0.0, 0.05)
	# Boost happiness
	if buddy_data:
		buddy_data.happiness = minf(buddy_data.happiness + 0.05, 1.0)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null
```

- [ ] **Step 4: Verify buddy scene loads in editor**

Open `scenes/buddy/buddy.tscn` in Godot editor — should show the node hierarchy without errors.

- [ ] **Step 5: Commit**

```bash
git add scripts/zones/buddy_sprite.gd scenes/buddy/buddy.tscn
git commit -m "feat: BuddySprite — paper doll visual assembly with anchor points, depth sorting, click reaction"
```

---

## Task 13: Zone Base Scene

**Files:**
- Create: `scripts/zones/zone_base.gd`
- Create: `scenes/zones/zone_base.tscn`
- Create: `scenes/zones/meadow.tscn`

The template for all zone scenes — parallax background, depth band, buddy spawning, decoration rendering.

- [ ] **Step 1: Create zone_base.gd**

```gdscript
# scripts/zones/zone_base.gd
class_name ZoneBase
extends Node2D

@export var zone_id: String = "meadow"

@onready var background: ParallaxBackground = $ParallaxBackground
@onready var buddy_container: Node2D = $BuddyContainer
@onready var decoration_container: Node2D = $DecorationContainer

const BUDDY_SCENE := preload("res://scenes/buddy/buddy.tscn")

# Depth band limits (Y range where buddies can walk)
const DEPTH_BAND_TOP := 300.0
const DEPTH_BAND_BOTTOM := 600.0
const ZONE_WIDTH := 1920.0  # Wider than screen for scrolling

var _buddy_sprites: Dictionary = {}  # buddy_id -> BuddySprite


func _ready() -> void:
	_populate_buddies()
	_populate_decorations()


func _populate_buddies() -> void:
	for child in buddy_container.get_children():
		child.queue_free()
	_buddy_sprites.clear()

	var buddies := Sanctuary.buddy_roster.get_buddies_in_zone(zone_id)
	for buddy_data in buddies:
		_spawn_buddy(buddy_data)


func _spawn_buddy(buddy_data: BuddyData) -> void:
	var buddy_node: BuddySprite = BUDDY_SCENE.instantiate()
	buddy_container.add_child(buddy_node)

	# Random starting position within the depth band
	var rng := Sanctuary.rng
	buddy_node.position = Vector2(
		rng.randf_range(64.0, ZONE_WIDTH - 64.0),
		rng.randf_range(DEPTH_BAND_TOP, DEPTH_BAND_BOTTOM)
	)

	buddy_node.setup(buddy_data, Sanctuary.buddy_creator._part_pool)
	buddy_node.clicked.connect(_on_buddy_clicked)
	_buddy_sprites[buddy_data.id] = buddy_node


func _populate_decorations() -> void:
	for child in decoration_container.get_children():
		child.queue_free()

	var decorations := Sanctuary.zone_manager.get_decorations_in_zone(zone_id)
	for deco in decorations:
		var sprite := Sprite2D.new()
		# TODO: Load decoration texture from deco def
		sprite.position = deco["position"]
		sprite.z_index = int(deco["position"].y)
		decoration_container.add_child(sprite)


func _on_buddy_clicked(buddy_data: BuddyData) -> void:
	# Signal up to the main scene to show info card
	# For now, print
	print("Clicked: %s (%s)" % [buddy_data.buddy_name, buddy_data.species])
```

- [ ] **Step 2: Create zone_base.tscn**

```ini
# scenes/zones/zone_base.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/zones/zone_base.gd" id="1"]

[node name="ZoneBase" type="Node2D" script=ExtResource("1")]

[node name="ParallaxBackground" type="ParallaxBackground" parent="."]
[node name="Layer1" type="ParallaxLayer" parent="ParallaxBackground"]
[node name="BG" type="Sprite2D" parent="ParallaxBackground/Layer1"]

[node name="DecorationContainer" type="Node2D" parent="."]
[node name="BuddyContainer" type="Node2D" parent="."]
```

- [ ] **Step 3: Create meadow.tscn (inherits zone_base)**

```ini
# scenes/zones/meadow.tscn — inherits from zone_base
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://scenes/zones/zone_base.tscn" id="1"]

[node name="Meadow" instance=ExtResource("1")]
zone_id = "meadow"
```

- [ ] **Step 4: Update main.tscn to load meadow**

```ini
# scenes/main.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://scenes/zones/meadow.tscn" id="1"]

[node name="Main" type="Node2D"]

[node name="CurrentZone" parent="." instance=ExtResource("1")]

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(640, 360)
```

- [ ] **Step 5: Run the project**

Run: F5 in Godot
Expected: Window opens showing the meadow zone. One starter buddy should appear (from `_start_new_game`). No errors in console.

- [ ] **Step 6: Commit**

```bash
git add scripts/zones/zone_base.gd scenes/zones/ scenes/main.tscn
git commit -m "feat: ZoneBase + Meadow — side-scroll zone with buddy spawning and depth band"
```

---

## Task 14: Buddy AI Brain

**Files:**
- Create: `scripts/ai/buddy_brain.gd`
- Create: `tests/test_buddy_brain.gd`

State machine that drives buddy behavior based on personality. Handles wandering, idling, sleeping, playing, and interaction responses.

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_buddy_brain.gd
extends GutTest

func test_idle_buddy_eventually_wanders() -> void:
	var brain := BuddyBrain.new()
	var buddy := BuddyData.new()
	buddy.personality.energy = 0.8  # High energy = wanders sooner
	brain.setup(buddy)

	# Simulate ticks until state changes
	var changed := false
	for i in range(100):
		brain.tick(0.1, RandomNumberGenerator.new())
		if brain.current_action != BuddyBrain.Action.IDLE:
			changed = true
			break
	assert_true(changed, "High energy buddy should start wandering quickly")

func test_shy_buddy_avoids_crowds() -> void:
	var brain := BuddyBrain.new()
	var buddy := BuddyData.new()
	buddy.personality.shyness = 0.9
	brain.setup(buddy)

	# Simulate a crowd nearby
	var should_flee := brain.should_avoid_position(Vector2(100, 400), 5)
	assert_true(should_flee, "Very shy buddy should avoid crowded areas")

func test_social_buddy_seeks_others() -> void:
	var brain := BuddyBrain.new()
	var buddy := BuddyData.new()
	buddy.personality.social = 0.9
	brain.setup(buddy)

	var target := brain.pick_target_near_buddies(
		Vector2(100, 400),
		[Vector2(200, 400), Vector2(300, 400)]
	)
	assert_not_null(target, "Social buddy should pick a target near others")

func test_warm_buddy_seeks_decoration() -> void:
	var brain := BuddyBrain.new()
	var buddy := BuddyData.new()
	buddy.personality.warmth = 0.9
	buddy.preferred_furniture = ["lamp", "cushion"]
	brain.setup(buddy)

	var decos := [
		{"id": "lamp", "position": Vector2(300, 400)},
		{"id": "bench", "position": Vector2(500, 400)},
	]
	var target := brain.pick_liked_decoration(decos)
	assert_eq(target["id"], "lamp", "Should prefer liked furniture")

func test_movement_speed_scales_with_energy() -> void:
	var brain_slow := BuddyBrain.new()
	var slow_buddy := BuddyData.new()
	slow_buddy.personality.energy = 0.1
	brain_slow.setup(slow_buddy)

	var brain_fast := BuddyBrain.new()
	var fast_buddy := BuddyData.new()
	fast_buddy.personality.energy = 0.9
	brain_fast.setup(fast_buddy)

	assert_gt(brain_fast.move_speed, brain_slow.move_speed)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: GUT → Run `test_buddy_brain.gd`
Expected: All tests FAIL

- [ ] **Step 3: Implement BuddyBrain**

```gdscript
# scripts/ai/buddy_brain.gd
class_name BuddyBrain
extends RefCounted

enum Action { IDLE, WANDERING, SLEEPING, PLAYING, INSPECTING, CHATTING, FLEEING }

const BASE_SPEED := 30.0        # pixels/sec at energy 0.0
const SPEED_PER_ENERGY := 70.0  # additional pixels/sec at energy 1.0
const IDLE_BASE_TIME := 3.0     # seconds of idle before considering wandering
const CROWD_RADIUS := 100.0     # pixels
const CROWD_THRESHOLD := 3      # buddies within radius = "crowded"

var buddy_data: BuddyData
var current_action: Action = Action.IDLE
var move_speed: float = BASE_SPEED
var target_position: Vector2 = Vector2.ZERO

var _idle_timer: float = 0.0
var _action_timer: float = 0.0
var _idle_threshold: float = IDLE_BASE_TIME


func setup(buddy: BuddyData) -> void:
	buddy_data = buddy
	move_speed = BASE_SPEED + buddy.personality.energy * SPEED_PER_ENERGY
	# Low energy = longer idle time before wandering
	_idle_threshold = IDLE_BASE_TIME + (1.0 - buddy.personality.energy) * 5.0


func tick(delta: float, rng: RandomNumberGenerator) -> void:
	_action_timer += delta

	match current_action:
		Action.IDLE:
			_idle_timer += delta
			# Higher energy = shorter idle time
			if _idle_timer >= _idle_threshold:
				_idle_timer = 0.0
				current_action = Action.WANDERING
				_idle_threshold = IDLE_BASE_TIME + rng.randf_range(0.0, (1.0 - buddy_data.personality.energy) * 5.0)
		Action.WANDERING:
			# Wander for a bit then go idle
			if _action_timer >= rng.randf_range(2.0, 6.0):
				_action_timer = 0.0
				current_action = Action.IDLE
		Action.SLEEPING:
			if _action_timer >= rng.randf_range(5.0, 15.0):
				_action_timer = 0.0
				current_action = Action.IDLE
		_:
			if _action_timer >= 3.0:
				_action_timer = 0.0
				current_action = Action.IDLE


func should_avoid_position(pos: Vector2, nearby_count: int) -> bool:
	# Shy buddies avoid crowds
	if buddy_data.personality.shyness < 0.5:
		return false
	return nearby_count >= CROWD_THRESHOLD


func pick_target_near_buddies(
	current_pos: Vector2, buddy_positions: Array[Vector2]
) -> Variant:
	if buddy_data.personality.social < 0.5:
		return null
	if buddy_positions.is_empty():
		return null
	# Pick the closest buddy to move toward
	var closest: Vector2 = buddy_positions[0]
	var closest_dist := current_pos.distance_to(closest)
	for pos in buddy_positions:
		var dist := current_pos.distance_to(pos)
		if dist < closest_dist:
			closest_dist = dist
			closest = pos
	# Offset slightly so we don't stack on top
	return closest + Vector2(20, 0)


func pick_liked_decoration(decorations: Array) -> Variant:
	for deco in decorations:
		if deco["id"] in buddy_data.preferred_furniture:
			return deco
	return null
```

- [ ] **Step 4: Run tests to verify they pass**

Run: GUT → Run `test_buddy_brain.gd`
Expected: All 5 tests PASS

- [ ] **Step 5: Wire BuddyBrain into BuddySprite**

Update `scripts/zones/buddy_sprite.gd` — add brain and movement:

```gdscript
# Add to buddy_sprite.gd class variables:
var brain := BuddyBrain.new()

# Add to setup():
func setup(data: BuddyData, part_pool: PartPool) -> void:
	buddy_data = data
	_part_pool = part_pool
	_assemble_appearance()
	_update_depth_sort()
	shiny_shimmer.emitting = data.shiny
	heart_particles.emitting = false
	brain.setup(data)

# Add _process:
func _process(delta: float) -> void:
	brain.tick(delta, Sanctuary.rng)

	if brain.current_action == BuddyBrain.Action.WANDERING:
		# Pick a random direction if we don't have a target
		if brain.target_position == Vector2.ZERO or position.distance_to(brain.target_position) < 5.0:
			brain.target_position = Vector2(
				Sanctuary.rng.randf_range(64.0, ZoneBase.ZONE_WIDTH - 64.0),
				Sanctuary.rng.randf_range(ZoneBase.DEPTH_BAND_TOP, ZoneBase.DEPTH_BAND_BOTTOM)
			)

		# Move toward target
		var dir := (brain.target_position - position).normalized()
		position += dir * brain.move_speed * delta

		# Flip sprite based on movement direction
		body_sprite.flip_h = dir.x < 0

		# Clamp to depth band
		position.y = clampf(position.y, ZoneBase.DEPTH_BAND_TOP, ZoneBase.DEPTH_BAND_BOTTOM)
		position.x = clampf(position.x, 64.0, ZoneBase.ZONE_WIDTH - 64.0)

	_update_depth_sort()
```

- [ ] **Step 6: Run the project and verify buddies wander**

Run: F5 in Godot
Expected: Starter buddy wanders around the meadow zone, pauses, wanders again. Clicking shows heart particles and prints name to console.

- [ ] **Step 7: Commit**

```bash
git add scripts/ai/buddy_brain.gd scripts/zones/buddy_sprite.gd tests/test_buddy_brain.gd
git commit -m "feat: BuddyBrain — personality-driven AI state machine with wandering, crowd avoidance, social seeking"
```

---

## Task 15: HUD + Buddy Info Card + Expedition Panel

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scenes/ui/hud.tscn`
- Create: `scripts/ui/buddy_info_card.gd`
- Create: `scenes/ui/buddy_info_card.tscn`
- Create: `scripts/ui/expedition_panel.gd`
- Create: `scenes/ui/expedition_panel.tscn`

The player-facing UI — stardust counter, buddy count, info card on click, and expedition send/track panel.

- [ ] **Step 1: Implement HUD**

```gdscript
# scripts/ui/hud.gd
extends CanvasLayer

@onready var stardust_label: Label = $TopBar/StardustLabel
@onready var buddy_count_label: Label = $TopBar/BuddyCountLabel
@onready var zone_label: Label = $TopBar/ZoneLabel

func _ready() -> void:
	Sanctuary.progression.stardust_changed.connect(_on_stardust_changed)
	Sanctuary.buddy_roster.buddy_added.connect(_on_buddy_added)
	_update_display()

func _update_display() -> void:
	stardust_label.text = "Stardust: %d" % Sanctuary.progression.stardust
	buddy_count_label.text = "Buddies: %d" % Sanctuary.buddy_roster.count()

func set_zone_name(zone_name: String) -> void:
	zone_label.text = zone_name

func _on_stardust_changed(_amount: int) -> void:
	_update_display()

func _on_buddy_added(_buddy: BuddyData) -> void:
	_update_display()
```

- [ ] **Step 2: Create hud.tscn**

```ini
# scenes/ui/hud.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="HUD" type="CanvasLayer" script=ExtResource("1")]

[node name="TopBar" type="HBoxContainer" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 400.0
offset_bottom = 40.0

[node name="StardustLabel" type="Label" parent="TopBar"]
text = "Stardust: 0"

[node name="Spacer" type="Control" parent="TopBar"]
custom_minimum_size = Vector2(20, 0)

[node name="BuddyCountLabel" type="Label" parent="TopBar"]
text = "Buddies: 0"

[node name="Spacer2" type="Control" parent="TopBar"]
custom_minimum_size = Vector2(20, 0)

[node name="ZoneLabel" type="Label" parent="TopBar"]
text = "The Meadow"
```

- [ ] **Step 3: Implement BuddyInfoCard**

```gdscript
# scripts/ui/buddy_info_card.gd
extends PanelContainer

signal expedition_requested(buddy: BuddyData)
signal rename_requested(buddy: BuddyData)

@onready var name_label: Label = $VBox/NameLabel
@onready var species_label: Label = $VBox/SpeciesLabel
@onready var rarity_label: Label = $VBox/RarityLabel
@onready var personality_label: Label = $VBox/PersonalityLabel
@onready var happiness_bar: ProgressBar = $VBox/HappinessBar
@onready var expedition_btn: Button = $VBox/Buttons/ExpeditionBtn
@onready var rename_btn: Button = $VBox/Buttons/RenameBtn
@onready var close_btn: Button = $VBox/Buttons/CloseBtn

var _buddy: BuddyData

func _ready() -> void:
	expedition_btn.pressed.connect(func(): expedition_requested.emit(_buddy))
	rename_btn.pressed.connect(func(): rename_requested.emit(_buddy))
	close_btn.pressed.connect(func(): visible = false)
	visible = false

func show_buddy(buddy: BuddyData) -> void:
	_buddy = buddy
	name_label.text = buddy.buddy_name
	species_label.text = "Species: %s" % buddy.species.capitalize()
	rarity_label.text = "Rarity: %s%s" % [
		BuddyData.Rarity.keys()[buddy.rarity],
		" (SHINY)" if buddy.shiny else ""
	]

	var p := buddy.personality
	personality_label.text = (
		"Curiosity: %.0f%%  Shyness: %.0f%%\n"
		+ "Energy: %.0f%%  Warmth: %.0f%%  Social: %.0f%%"
	) % [p.curiosity * 100, p.shyness * 100, p.energy * 100, p.warmth * 100, p.social * 100]

	happiness_bar.value = buddy.happiness
	expedition_btn.disabled = buddy.state == BuddyData.State.EXPEDITION
	visible = true
```

- [ ] **Step 4: Create buddy_info_card.tscn**

```ini
# scenes/ui/buddy_info_card.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/buddy_info_card.gd" id="1"]

[node name="BuddyInfoCard" type="PanelContainer" script=ExtResource("1")]
anchors_preset = 3
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -280.0
offset_top = -350.0
offset_right = -10.0
offset_bottom = -10.0

[node name="VBox" type="VBoxContainer" parent="."]

[node name="NameLabel" type="Label" parent="VBox"]
text = "Buddy Name"
horizontal_alignment = 1

[node name="SpeciesLabel" type="Label" parent="VBox"]
text = "Species: Blob"

[node name="RarityLabel" type="Label" parent="VBox"]
text = "Rarity: Common"

[node name="PersonalityLabel" type="Label" parent="VBox"]
text = "Curiosity: 50%"

[node name="HappinessBar" type="ProgressBar" parent="VBox"]
max_value = 1.0
value = 0.5

[node name="Buttons" type="HBoxContainer" parent="VBox"]

[node name="ExpeditionBtn" type="Button" parent="VBox/Buttons"]
text = "Send on Vacation"

[node name="RenameBtn" type="Button" parent="VBox/Buttons"]
text = "Rename"

[node name="CloseBtn" type="Button" parent="VBox/Buttons"]
text = "Close"
```

- [ ] **Step 5: Implement ExpeditionPanel**

```gdscript
# scripts/ui/expedition_panel.gd
extends PanelContainer

@onready var slot_container: VBoxContainer = $VBox/SlotContainer
@onready var available_label: Label = $VBox/AvailableLabel

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible:
		_refresh()

func toggle() -> void:
	visible = !visible
	if visible:
		_refresh()

func _refresh() -> void:
	var max_slots := Sanctuary.zone_manager.get_expedition_slots()
	var active := Sanctuary.expedition_manager.active_count()
	available_label.text = "Expedition Slots: %d / %d" % [active, max_slots]

	# Clear and rebuild slot display
	for child in slot_container.get_children():
		child.queue_free()

	for exp_data in Sanctuary.expedition_manager.to_array():
		var label := Label.new()
		var elapsed := Time.get_unix_time_from_system() - exp_data["departure_time"]
		var remaining := max(0.0, exp_data["duration"] - elapsed)
		label.text = "%s — %.0fs remaining" % [exp_data["buddy_id"], remaining]
		slot_container.add_child(label)
```

- [ ] **Step 6: Create expedition_panel.tscn**

```ini
# scenes/ui/expedition_panel.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/expedition_panel.gd" id="1"]

[node name="ExpeditionPanel" type="PanelContainer" script=ExtResource("1")]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -300.0
offset_top = 50.0
offset_right = -10.0
offset_bottom = 300.0

[node name="VBox" type="VBoxContainer" parent="."]

[node name="Title" type="Label" parent="VBox"]
text = "Expeditions"
horizontal_alignment = 1

[node name="AvailableLabel" type="Label" parent="VBox"]
text = "Slots: 0 / 1"

[node name="SlotContainer" type="VBoxContainer" parent="VBox"]
```

- [ ] **Step 7: Wire UI into main.tscn**

Update `scenes/main.tscn` to include HUD, InfoCard, and ExpeditionPanel as children. Update the main scene script to wire buddy clicks to the info card.

- [ ] **Step 8: Run project and verify UI**

Run: F5
Expected: HUD shows stardust and buddy count at top. Clicking a buddy shows info card. Expedition panel accessible.

- [ ] **Step 9: Commit**

```bash
git add scripts/ui/ scenes/ui/ scenes/main.tscn
git commit -m "feat: HUD + BuddyInfoCard + ExpeditionPanel — core game UI"
```

---

## Task 16: Zone Navigation

**Files:**
- Create: `scripts/ui/zone_nav.gd`
- Create: `scenes/ui/zone_nav.tscn`

Arrow buttons and zone map widget for switching between zones.

- [ ] **Step 1: Implement zone_nav.gd**

```gdscript
# scripts/ui/zone_nav.gd
extends CanvasLayer

signal zone_changed(zone_id: String)

@onready var left_arrow: Button = $LeftArrow
@onready var right_arrow: Button = $RightArrow
@onready var zone_name: Label = $ZoneName

var _zone_ids: Array[String] = []
var _current_index: int = 0

func _ready() -> void:
	left_arrow.pressed.connect(_go_left)
	right_arrow.pressed.connect(_go_right)
	Sanctuary.zone_manager.zone_unlocked.connect(_on_zone_unlocked)
	_refresh_zones()

func _refresh_zones() -> void:
	_zone_ids = Sanctuary.zone_manager.get_unlocked_zone_ids()
	_update_display()

func _update_display() -> void:
	if _zone_ids.is_empty():
		return
	var zone_data := Sanctuary.zone_manager.get_zone_data(_zone_ids[_current_index])
	zone_name.text = zone_data.get("name", _zone_ids[_current_index])
	left_arrow.visible = _current_index > 0
	right_arrow.visible = _current_index < _zone_ids.size() - 1

func _go_left() -> void:
	if _current_index > 0:
		_current_index -= 1
		_update_display()
		zone_changed.emit(_zone_ids[_current_index])

func _go_right() -> void:
	if _current_index < _zone_ids.size() - 1:
		_current_index += 1
		_update_display()
		zone_changed.emit(_zone_ids[_current_index])

func _on_zone_unlocked(_zone_id: String) -> void:
	_refresh_zones()
```

- [ ] **Step 2: Create zone_nav.tscn**

```ini
# scenes/ui/zone_nav.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/zone_nav.gd" id="1"]

[node name="ZoneNav" type="CanvasLayer" script=ExtResource("1")]

[node name="LeftArrow" type="Button" parent="."]
offset_top = 320.0
offset_right = 40.0
offset_bottom = 400.0
text = "<"

[node name="RightArrow" type="Button" parent="."]
offset_left = 1240.0
offset_top = 320.0
offset_right = 1280.0
offset_bottom = 400.0
text = ">"

[node name="ZoneName" type="Label" parent="."]
offset_left = 540.0
offset_top = 680.0
offset_right = 740.0
offset_bottom = 710.0
horizontal_alignment = 1
text = "The Meadow"
```

- [ ] **Step 3: Wire zone navigation into main scene**

The main scene needs to swap the active zone scene when the player navigates. Add zone loading logic to the main script.

```gdscript
# Add a main scene script that handles zone switching
# scenes/main.gd (attached to Main node)
extends Node2D

const ZONE_SCENES := {
	"meadow": preload("res://scenes/zones/meadow.tscn"),
	# Add more zones as they're created
}

@onready var zone_nav = $ZoneNav
@onready var current_zone: ZoneBase = $CurrentZone

func _ready() -> void:
	zone_nav.zone_changed.connect(_on_zone_changed)

func _on_zone_changed(zone_id: String) -> void:
	if ZONE_SCENES.has(zone_id):
		current_zone.queue_free()
		current_zone = ZONE_SCENES[zone_id].instantiate()
		add_child(current_zone)
```

- [ ] **Step 4: Run project and test navigation arrows**

Run: F5
Expected: Left/right arrows visible at screen edges. Only one zone unlocked initially so right arrow hidden. Zone name label shows "The Meadow" at bottom.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/zone_nav.gd scenes/ui/zone_nav.tscn scenes/main.tscn
git commit -m "feat: ZoneNav — arrow navigation between unlocked zones"
```

---

## Task 17: Decoration Shop

**Files:**
- Create: `scripts/ui/decoration_shop.gd`
- Create: `scenes/ui/decoration_shop.tscn`

Buy decorations with stardust and place them in zones via drag-and-drop.

- [ ] **Step 1: Implement decoration_shop.gd**

```gdscript
# scripts/ui/decoration_shop.gd
extends PanelContainer

signal decoration_placed(deco_id: String, zone_id: String, position: Vector2)

@onready var item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var stardust_label: Label = $VBox/StardustLabel

var _placing_deco_id: String = ""

func _ready() -> void:
	visible = false
	Sanctuary.progression.stardust_changed.connect(_on_stardust_changed)

func toggle() -> void:
	visible = !visible
	if visible:
		_refresh()

func _refresh() -> void:
	stardust_label.text = "Stardust: %d" % Sanctuary.progression.stardust
	for child in item_list.get_children():
		child.queue_free()

	var available := Sanctuary.zone_manager.get_available_decorations()
	for deco in available:
		var btn := Button.new()
		btn.text = "%s — %d stardust" % [deco["name"], deco["cost"]]
		btn.disabled = Sanctuary.progression.stardust < deco["cost"]
		btn.pressed.connect(_on_buy.bind(deco["id"]))
		item_list.add_child(btn)

func _on_buy(deco_id: String) -> void:
	_placing_deco_id = deco_id
	visible = false
	# Enter placement mode — next click in the zone places the decoration
	Input.set_custom_mouse_cursor(null)  # TODO: placement cursor

func _input(event: InputEvent) -> void:
	if _placing_deco_id == "" or not event is InputEventMouseButton:
		return
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		# Get the current zone from the main scene
		var zone_id := "meadow"  # TODO: Get from current zone
		if Sanctuary.buy_decoration(_placing_deco_id, zone_id, pos):
			decoration_placed.emit(_placing_deco_id, zone_id, pos)
		_placing_deco_id = ""

func _on_stardust_changed(_amount: int) -> void:
	if visible:
		_refresh()
```

- [ ] **Step 2: Create decoration_shop.tscn**

```ini
# scenes/ui/decoration_shop.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/decoration_shop.gd" id="1"]

[node name="DecorationShop" type="PanelContainer" script=ExtResource("1")]
anchors_preset = 8
anchor_left = 0.5
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -200.0
offset_top = -400.0
offset_right = 200.0
offset_bottom = -50.0

[node name="VBox" type="VBoxContainer" parent="."]

[node name="Title" type="Label" parent="VBox"]
text = "Decoration Shop"
horizontal_alignment = 1

[node name="StardustLabel" type="Label" parent="VBox"]
text = "Stardust: 0"

[node name="ScrollContainer" type="ScrollContainer" parent="VBox"]
custom_minimum_size = Vector2(0, 250)

[node name="ItemList" type="VBoxContainer" parent="VBox/ScrollContainer"]
```

- [ ] **Step 3: Add shop toggle button to HUD**

Add a "Shop" button to the HUD that toggles the decoration shop.

- [ ] **Step 4: Run project and verify shop**

Run: F5
Expected: Shop button in HUD opens decoration list. Items grayed out if insufficient stardust. Buying places a decoration in the zone.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/decoration_shop.gd scenes/ui/decoration_shop.tscn scripts/ui/hud.gd scenes/ui/hud.tscn
git commit -m "feat: DecorationShop — buy and place decorations with stardust"
```

---

## Task 18: Welcome Back Screen

**Files:**
- Create: `scripts/ui/welcome_back.gd`
- Create: `scenes/ui/welcome_back.tscn`

Shows the offline catch-up recap when the player returns after being away.

- [ ] **Step 1: Implement welcome_back.gd**

```gdscript
# scripts/ui/welcome_back.gd
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var message_label: RichTextLabel = $Panel/VBox/Message
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn

func _ready() -> void:
	panel.visible = false
	continue_btn.pressed.connect(func(): panel.visible = false)

func show_recap(
	elapsed_seconds: float,
	stardust_earned: int,
	new_buddies: Array[String],
	completed_expeditions: Array[Dictionary],
) -> void:
	var hours := int(elapsed_seconds / 3600.0)
	var minutes := int(fmod(elapsed_seconds, 3600.0) / 60.0)

	var text := "[center][b]Welcome back![/b][/center]\n\n"
	if hours > 0:
		text += "You were away for %dh %dm.\n\n" % [hours, minutes]
	else:
		text += "You were away for %dm.\n\n" % [minutes]

	text += "While you were gone...\n"
	text += "  +%d stardust collected\n" % stardust_earned

	for exp_result in completed_expeditions:
		var buddy_id: String = exp_result.get("buddy_id", "A buddy")
		match exp_result.get("type", "nice_walk"):
			"blob":
				text += "  %s came back from vacation with a new friend!\n" % buddy_id
			"claude_buddy":
				text += "  %s met a rare buddy on vacation!\n" % buddy_id
			"decoration":
				text += "  %s found a cute trinket!\n" % buddy_id
			"nice_walk":
				text += "  %s had a lovely time.\n" % buddy_id

	if new_buddies.size() > 0:
		text += "\n%d new buddies joined the sanctuary!\n" % new_buddies.size()

	message_label.text = text
	panel.visible = true
```

- [ ] **Step 2: Create welcome_back.tscn**

```ini
# scenes/ui/welcome_back.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/welcome_back.gd" id="1"]

[node name="WelcomeBack" type="CanvasLayer" script=ExtResource("1")]
layer = 10

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -250.0
offset_top = -200.0
offset_right = 250.0
offset_bottom = 200.0

[node name="VBox" type="VBoxContainer" parent="Panel"]

[node name="Message" type="RichTextLabel" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 300)
bbcode_enabled = true
text = "Welcome back!"

[node name="ContinueBtn" type="Button" parent="Panel/VBox"]
text = "Continue"
```

- [ ] **Step 3: Wire welcome back into Sanctuary autoload**

Update `_handle_offline_catchup()` in `sanctuary.gd` to show the welcome back screen with actual data instead of silently applying results.

- [ ] **Step 4: Test by manually changing save timestamp**

Modify the save file's `last_played` to be an hour in the past, relaunch. Verify welcome back screen appears with stardust and expedition results.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/welcome_back.gd scenes/ui/welcome_back.tscn scripts/autoload/sanctuary.gd
git commit -m "feat: WelcomeBack — offline catch-up recap screen with stardust and expedition results"
```

---

## Task 19: Integration — Full Game Loop

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/autoload/sanctuary.gd`

Wire everything together: start game, see buddy, send on expedition, earn stardust, buy decoration, unlock zones, welcome back on return. Verify the complete idle loop works end to end.

- [ ] **Step 1: Add keyboard shortcuts**

```gdscript
# Add to main scene script or sanctuary.gd:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Esc
		Sanctuary.save_game()
		get_tree().quit()
	# E key toggles expedition panel
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		$ExpeditionPanel.toggle()
	# S key toggles shop
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		$DecorationShop.toggle()
```

- [ ] **Step 2: Create integration test checklist**

Manual playtest — verify each step:

1. Launch game — meadow zone visible, one starter buddy wandering
2. Click buddy — heart particles, info card appears with name and stats
3. Click "Send on Vacation" — buddy walks offscreen, expedition timer visible
4. Wait for return — buddy walks back, stardust earned (check HUD)
5. If buddy found a friend — new buddy appears in sanctuary
6. Press S — shop opens, decorations listed with costs
7. Buy a decoration — stardust deducted, click to place in zone
8. Buddy interacts with decoration — walks toward it, sits/plays
9. Reach 10 buddies — "The Burrow" unlocks, navigate right to see it
10. Close and reopen — welcome back screen shows elapsed time and stardust
11. Save file exists at `user://buddy_sanctuary_save.json`

- [ ] **Step 3: Fix any integration issues found during playtest**

Address anything broken from the playtest checklist.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: full game loop integration — expedition, shop, zone unlock, save/load, welcome back"
```

---

## Task 20: Polish Pass — Placeholder Art + Particles

**Files:**
- Create: placeholder PNGs in `assets/`
- Modify: particle nodes in buddy scene

Create minimal but visible placeholder art so the game is visually playable. Colored rectangles for bodies, dots for eyes, simple shapes for accessories. Set up heart and shiny particles.

- [ ] **Step 1: Create colored placeholder sprites**

Using Godot's built-in drawing or simple PNGs:
- `assets/sprites/bodies/round_blobby.png` — 64x64 white circle on transparent
- `assets/sprites/bodies/tall_noodle.png` — 32x80 white oval on transparent
- `assets/sprites/eyes/dot_eyes.png` — 16x8 two black dots
- `assets/sprites/mouths/simple_smile.png` — 16x8 curved line
- Background for meadow — simple green gradient

These are purely functional placeholders. Real art comes from Krita later.

- [ ] **Step 2: Configure heart particles**

Set up `HeartParticles` on the buddy scene:
- Texture: small pink heart (8x8)
- Direction: upward
- Spread: 45 degrees
- Lifetime: 0.8s
- One-shot: true
- Amount: 5

- [ ] **Step 3: Configure shiny shimmer particles**

Set up `ShinyShimmer` on the buddy scene:
- Texture: small white sparkle (4x4)
- Direction: all around
- Spread: 360 degrees
- Lifetime: 1.5s
- One-shot: false (continuous for shiny buddies)
- Amount: 3
- Modulate with slight rainbow color cycling

- [ ] **Step 4: Run and verify visual readability**

Run: F5
Expected: Buddies are visible colored blobs with eyes and mouths. Hearts pop when clicked. Shiny buddies sparkle continuously. Meadow has a visible background.

- [ ] **Step 5: Commit**

```bash
git add assets/ scenes/buddy/buddy.tscn
git commit -m "art: placeholder sprites, heart particles, shiny shimmer — visually playable"
```

---

## Summary

**20 tasks, building bottom-up:**

| Task | What it builds |
|------|---------------|
| 1 | Project scaffold + GUT |
| 2 | BuddyData model |
| 3 | PartPool (rarity-weighted picks) |
| 4 | NameGenerator |
| 5 | BuddyCreator (paper doll assembly) |
| 6 | BuddyRoster manager |
| 7 | ZoneManager (unlocks, decorations) |
| 8 | ProgressionManager (stardust) |
| 9 | ExpeditionManager (vacations) |
| 10 | SaveManager (JSON, offline catch-up) |
| 11 | Sanctuary autoload (wires everything) |
| 12 | BuddySprite (paper doll visuals) |
| 13 | ZoneBase + Meadow scene |
| 14 | BuddyBrain AI |
| 15 | HUD + InfoCard + ExpeditionPanel |
| 16 | Zone navigation |
| 17 | Decoration shop |
| 18 | Welcome back screen |
| 19 | Full game loop integration |
| 20 | Placeholder art + particles |

**Total estimated commits: ~20.** Each task produces working, testable code.
