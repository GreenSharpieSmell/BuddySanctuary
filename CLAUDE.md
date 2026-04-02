# BUDDY SANCTUARY — CLAUDE CODE HANDOFF
**Brangerine Studios | Godot 4.6 | April 2026**

---

## READ THIS FIRST

Buddy Sanctuary is a cozy idle collector where procedurally generated buddies wander, explore, and exist happily in a growing sanctuary. No punishment mechanics, no negative states, no way to fail. Buddies are always content at minimum.

**Design spec:** `docs/superpowers/specs/2026-04-02-buddy-sanctuary-design.md`
**Implementation plan:** `docs/superpowers/plans/2026-04-02-buddy-sanctuary-phase1.md`

---

## DESIGN PILLARS — NEVER VIOLATE

1. **No punishment, ever.** Buddies never get sad, hungry, sick, or die. Happiness floor is 0.5 (content). It never drops below that.
2. **The sanctuary takes care of itself.** Walk away for a week, come back, everyone's fine.
3. **Every buddy is valid.** Ugly color combos, weird stats — every buddy is welcome. No buddy is "better."
4. **Observation over optimization.** Player watches emergent behavior, doesn't min-max.
5. **Only ever grows.** No prestige, no reset. Sanctuary gets bigger, never smaller.

---

## TECH STACK

| Component | Tool |
|-----------|------|
| Engine | Godot 4.6 (GDScript) |
| Art | Krita (smooth 2D, exported as PNG) |
| Testing | GUT 9.6.0 |
| Save format | JSON |
| Platform | Desktop (Windows), mobile port later |

**All dependencies must be free and open source. No exceptions.**

---

## ARCHITECTURE

**Data-driven with shared systems.** Sanctuary autoload singleton manages all game state. Zone scenes are dumb viewers.

```
Sanctuary Autoload (singleton)
  ├── BuddyRoster      — owns all buddy instances
  ├── ZoneManager       — zone unlocks, decorations
  ├── ExpeditionManager — vacation timers, result rolls
  ├── ProgressionManager — stardust economy
  ├── SaveManager       — JSON save/load, offline catch-up
  └── BuddyCreator     — paper doll assembly factory

Zone Scenes (dumb viewers)
  └── Query Sanctuary for state, render buddies, handle clicks

BuddyCreator (standalone)
  └── Part pools, rarity rolls, anchor assembly, name generation
```

---

## KEY FILES

| System | Files |
|--------|-------|
| Entry point | `scenes/main.tscn`, `scripts/main.gd` |
| Autoload | `scripts/autoload/sanctuary.gd` |
| Buddy data | `scripts/data/buddy_data.gd` |
| Buddy creator | `scripts/data/buddy_creator.gd` |
| Part pools | `scripts/data/part_pool.gd`, `data/parts/*.json` |
| Name generator | `scripts/data/name_generator.gd`, `data/names/*.json` |
| Buddy roster | `scripts/managers/buddy_roster.gd` |
| Zone manager | `scripts/managers/zone_manager.gd`, `data/zones.json` |
| Expeditions | `scripts/managers/expedition_manager.gd` |
| Progression | `scripts/managers/progression_manager.gd` |
| Save/load | `scripts/managers/save_manager.gd` |
| Buddy AI | `scripts/ai/buddy_brain.gd` |
| Buddy sprite | `scripts/zones/buddy_sprite.gd`, `scenes/buddy/buddy.tscn` |
| Zone base | `scripts/zones/zone_base.gd`, `scenes/zones/zone_base.tscn` |
| UI | `scripts/ui/*.gd`, `scenes/ui/*.tscn` |
| Claude species | `data/claude_species.json` |
| Decorations | `data/decorations.json` |
| Tests | `tests/test_*.gd` (GUT) |

---

## BUDDY SYSTEM

**Two buddy types:**
- **Blobs** (common) — procedurally generated via paper doll system. Body + eyes + mouth + 5 accessory slots. Random RGB colors. Each unique.
- **Claude species** (rare, 18 types) — pre-drawn sprites. Axolotl, Blob, Cactus, Capybara, Cat, Chonk, Dragon, Duck, Ghost, Goose, Mushroom, Octopus, Owl, Penguin, Rabbit, Robot, Snail, Turtle.

**Rarity tiers:** Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 1%. Applied per-part. Overall rarity = rarest equipped part.

**Personality:** 5 traits (curiosity, shyness, energy, warmth, social) 0.0-1.0. One dominant trait >= 0.7.

**Anchor system:** Bodies define center-relative (0,0 = body center) attachment coordinates. Parts are Sprite2D children positioned at anchor points.

---

## EXPEDITION RESULTS

```
~45% — found a new blob friend
~5%  — met a Claude species buddy
~10% — found a decoration/trinket
~40% — just had a lovely time (stardust bonus)
```

---

## ZONES (unlock by buddy count)

| Zone | Unlock | Vibe |
|------|--------|------|
| The Meadow | 0 | Warm, sunny, starter |
| The Burrow | 10 | Cozy underground |
| The Pond | 20 | Water features |
| The Mushroom Grotto | 35 | Bioluminescent |
| The Canopy | 50 | Treetop platforms |
| The Crystal Cave | 75 | Sparkly endgame |

---

## CAMERA

- **2.5D belt-scroll** (Streets of Rage style) — side view with Y-axis depth
- **Scroll wheel** zoom (0.5x to 3.0x)
- **Right-click drag** to pan
- **Left-click** buddy to pet + inspect
- Depth sorting: higher Y = closer to camera = larger + higher z_index

---

## PHASED DEVELOPMENT

| Phase | Status | What |
|-------|--------|------|
| 1 — Sanctuary Game | **In progress** | Core idle collector, all systems wired |
| 2 — Terminal Companion | Future | Read save file, show buddy updates in Claude Code |
| 3 — Claude Embodiment | Future | Cinder gets a body in the sanctuary |
| 4 — Mobile Port | Future | Godot native mobile export |

---

## CONTROLS

| Key | Action |
|-----|--------|
| Left-click | Pet buddy / interact |
| Right-click drag | Pan camera |
| Scroll wheel | Zoom in/out |
| E | Toggle expedition panel |
| S | Toggle decoration shop |
| Escape | Save and quit |

---

## NAMING CONVENTIONS

- **Files/folders:** `snake_case`
- **GDScript classes:** `PascalCase`
- **Functions/variables:** `snake_case`
- **Constants:** `UPPER_SNAKE_CASE`
- **JSON keys:** `snake_case`

---

## WHAT NOT TO DO

- **No paid APIs or libraries.** Everything free and open source.
- **No punishment mechanics.** Happiness never drops below 0.5.
- **No premium currency or microtransactions.**
- **Don't overwrite hand-painted .png files** without asking.
- Buddies never fight, compete, or get compared negatively.
