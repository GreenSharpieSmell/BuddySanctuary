# Buddy Sanctuary — Game Design Spec

**Brangerine Studios | April 2, 2026**

---

## Overview

Buddy Sanctuary is a cozy idle collector where procedurally generated buddies wander, explore, and exist happily in a growing sanctuary. Players observe, decorate, and send buddies on relaxing vacations. There are no punishment mechanics, no negative states, and no way to fail. Buddies are always content at minimum — player interaction only makes things better, never worse.

The core fantasy: a place where every buddy is welcome, no matter what they look like or what stats they rolled.

---

## Tech Stack

| Component | Tool |
|-----------|------|
| Engine | Godot 4 (GDScript) |
| Art | Krita (smooth 2D, exported as PNG/spritesheets) |
| Placeholder art | Free itch.io asset packs for environments |
| Platform | Desktop first (Windows), mobile port later |
| Save format | JSON |
| Audio | Godot built-in (ambient + SFX) |

All dependencies must be free and open source.

---

## Design Pillars

1. **No punishment, ever.** Buddies never get sad, hungry, sick, or die. Unmet wants mean a buddy wanders looking for something to do. Meeting a want produces visible joy (hearts, sparkles). Ignoring it has zero consequences. Content (0.5 happiness) is the floor — it never drops below that.

2. **The sanctuary takes care of itself.** Walk away for a week, come back, everyone's fine. Maybe they even got up to something fun while you were gone.

3. **Every buddy is valid.** Ugly color combos, weird feature rolls, "bad" stats — every buddy deserves the sanctuary equally. No buddy is better or worse, just different.

4. **Observation over optimization.** The joy is in watching emergent behavior, not min-maxing. You don't control buddies directly. You shape the environment and watch what happens.

5. **Only ever grows.** No prestige, no rebirth, no reset mechanics. Your sanctuary gets bigger, never smaller. You never lose anything.

---

## Architecture: Data-Driven with Shared Systems

Separate the data layer (buddy definitions, sanctuary state, progression, save file) from the visual layer (zone scenes render what the data says).

**Core architecture:**

```
Sanctuary Autoload (singleton)
  - BuddyRoster: all owned buddies
  - ZoneManager: unlocked zones, decoration placements
  - ExpeditionManager: active expeditions, timers
  - ProgressionManager: milestones, stardust, unlocks
  - SaveManager: save/load, offline catch-up calculation
  - NameGenerator: random name assembly from curated lists

Zone Scenes (dumb viewers)
  - Query Sanctuary for "who's in this zone?"
  - Render buddies at their positions
  - Handle player clicks (pet buddy, inspect, place decoration)
  - No game logic — purely visual + input

BuddyCreator (standalone system)
  - Part pools, rarity rolls, anchor assembly
  - Color randomizer (full RGB, uncurated)
  - Personality generation
  - Outputs a complete BuddyResource
```

Zones are lightweight scenes. Adding a new zone = new art + a scene file, not new logic. The creator builds buddies, the sanctuary is where they live. Fully decoupled.

---

## Camera & View

**2.5D belt-scroll perspective (Streets of Rage style):**

- Side-view with limited Y-axis depth — buddies walk left/right AND slightly up/down into the scene
- Sprites stay front-facing at all times, no rotation
- Depth sorting: buddies further "back" (higher Y) render behind buddies in "front" (lower Y)
- Slight scale: buddies in the back are a bit smaller, front are a bit larger
- Decorations placed at specific depth lanes — buddies can walk in front of or behind objects
- Parallax background layers for depth illusion

**Zone navigation:**
- Click arrows on screen edges or a zone map widget to switch between zones
- Buddies simulate in all zones at all times — you're just moving the camera

---

## Buddy Data Model

Each buddy is a resource containing:

```
id:           unique identifier
species:      "blob" or one of 18 claude buddy types
rarity:       common / uncommon / rare / epic / legendary
shiny:        true/false (1% chance on any buddy)
name:         auto-generated from name lists, player-renameable
appearance:
  body:       index into body part pool + rarity
  eyes:       index into eyes part pool + rarity
  mouth:      index into mouth part pool + rarity
  acc1-acc5:  index into accessory pools + rarity (can be empty)
  color_primary:   RGB (full random, uncurated)
  color_secondary: RGB (full random, uncurated)
personality:
  curiosity:  0.0-1.0   (explores, follows others, inspects things)
  shyness:    0.0-1.0   (hides behind furniture, avoids crowds)
  energy:     0.0-1.0   (movement speed, activity frequency)
  warmth:     0.0-1.0   (seeks warm/cozy spots)
  social:     0.0-1.0   (gravitates toward other buddies)
preferences:
  liked_zone:      derived from personality
  liked_furniture: derived from personality
current_zone:  which zone they're currently in
state:         idle / wandering / sleeping / playing / expedition
happiness:     0.0-1.0 (baseline 0.5 = content, only rises, never drops)
```

**Overall buddy rarity = its rarest individual part.** A blob with all common parts except Legendary heart eyes is a Legendary buddy.

**Shiny** is a visual overlay (iridescent shimmer + sparkle particles), not a part swap. Any buddy — blob or Claude species, any rarity — can be shiny. It's purely cosmetic flair on top of whatever they already look like.

---

## Buddy Assembly — Modular Paper Doll System

**Part pools (each drawn in Krita as separate layered pieces):**

| Slot | Count | Examples |
|------|-------|---------|
| Bodies | ~20 | round, tall, blobby, spiky, flat, wiggly, noodle |
| Eyes | ~20 | dots, big sparkly, sleepy, one-eye, X eyes, heart eyes |
| Mouths | ~20 | smile, :3 cat mouth, derp, fangs, no mouth, whistle |
| Accessory 1 (head) | ~20 | hats, bows, horns, antenna, crown, flower |
| Accessory 2 (neck) | ~20 | scarves, necklaces, ties, bandana, collar |
| Accessory 3 (held) | ~20 | stick, balloon, flower, tiny flag, umbrella |
| Accessory 4 (back) | ~20 | wings, cape, backpack, shell, tail |
| Accessory 5 (feet) | ~20 | shoes, puddle, shadow trail, sparkles |

**Per-part rarity:**
```
Common:     60%
Uncommon:   25%
Rare:       10%
Epic:        4%
Legendary:   1%
```

**Accessory slots can roll "empty"** — not every buddy is loaded with stuff. The roll is: 50% chance of an accessory in each slot, then rarity roll within the pool.

**Anchor point system:**

Each body template defines attachment coordinates for every slot:
```
Body "Round Blobby":
  eye_anchor:   (32, 18)
  mouth_anchor: (32, 28)
  acc1_anchor:  (32, 8)     # top of head
  acc2_anchor:  (32, 24)    # neck area
  acc3_anchor:  (28, 32)    # hand/side
  acc4_anchor:  (32, 20)    # back center
  acc5_anchor:  (32, 44)    # feet/ground
```

**Godot assembly:**
- Body is a base `Sprite2D`
- Eyes, mouth, and accessories are child `Sprite2D` nodes positioned at the body's anchor points
- Body resource defines both the texture AND its anchor coordinates

**Color application:**
- Body sprites drawn in grayscale in Krita
- Primary color modulates the body at runtime via `Sprite2D.modulate`
- Secondary color applied to a separate accent layer (spots, belly, tips)
- Eyes, mouth, and accessories keep their original drawn colors

**Name generation:**
- Player provides curated lists of first names, middle names, last names
- Roller picks one of each on buddy creation
- Full name displayed, player can rename anytime

---

## Claude Buddy Species

The 18 species from the Claude Code companion system appear as rare discoverable catches:

| Species | Personality Archetype |
|---------|----------------------|
| Axolotl | High warmth, high social |
| Blob | Balanced, gentle |
| Cactus | Low social, high warmth |
| Capybara | Low energy, high social (zen) |
| Cat | High shyness, low social |
| Chonk | Low energy, high warmth |
| Dragon | High energy, high curiosity |
| Duck | Balanced, high social |
| Ghost | High shyness, high curiosity |
| Goose | High energy, low shyness (chaotic) |
| Mushroom | Low energy, high shyness |
| Octopus | High curiosity, high social |
| Owl | Low energy, high curiosity (wise) |
| Penguin | Balanced, high social |
| Rabbit | High energy, high curiosity |
| Robot | Low warmth, balanced |
| Snail | Low energy, low curiosity (patient) |
| Turtle | Low energy, high warmth (steady) |

Claude buddies use pre-drawn species sprites (not the paper doll system). Rarity determines accessories (hats, effects). Each has a fixed personality archetype with slight per-instance variance so two Owls aren't identical.

---

## Buddy AI & Behavior

**Movement:**
- Buddies walk left/right and slightly up/down in the depth band
- Speed and frequency driven by `energy` personality stat
- Random idle pauses with small animations (look around, stretch, yawn)

**Personality-driven behaviors:**

| Trait | High Behavior |
|-------|--------------|
| Curiosity | Wanders more, inspects decorations, follows new arrivals |
| Shyness | Stays near edges/corners, hides behind furniture, peeks out |
| Energy | Bounces, runs, jumps, rarely sits still |
| Warmth | Seeks lamps and cozy spots, basks contentedly |
| Social | Follows groups, sits next to others, rarely alone |

**Buddy-to-buddy interactions:**
- Two social buddies near each other: chat bubble animation (gibberish symbols, hearts)
- Curious buddy follows a new arrival around
- Shy buddy scoots away if too many crowd nearby
- High-energy buddy startles a sleepy one (little ! popup, both settle)

**Decoration responses:**
- Buddy near a liked decoration: heart particle, sits contentedly
- Specific items trigger animations: cushion = nap, toy = play, lamp = bask
- Multiple buddies can share a decoration (three blobs napping on one cushion)

**Zone wandering:**
- Buddies drift toward their liked zone over time (gentle bias, not instant)
- They still wander through other zones for variety
- Placing liked decorations in a zone strengthens the pull

---

## Expeditions

Expeditions are relaxing vacations, not recruit missions. You send a buddy off to have a nice time. Sometimes they happen to make a friend.

**Flow:**
1. Pick a buddy from your roster
2. They wave and walk offscreen
3. Real-time timer (5-15 minutes open, calculated if offline)
4. They walk back — maybe with a new friend trailing behind

**Results:**
```
Always:  some stardust
~45%:    found a new blob friend
~5%:     met a Claude species buddy
~10%:    found a decoration/trinket
~40%:    just had a lovely time (stardust bonus, came back happy)
```

**Personality effects on expeditions:**
- High energy: returns faster
- High curiosity: slightly better discovery rates
- But ANY buddy can go — no stat gating, no "not good enough"

**Expedition slots:**
- Start with 1 slot
- Unlock more at zone milestones
- Max ~4-5 concurrent (so the sanctuary isn't empty)

**Claude buddy discovery roll (when the 5% hits):**
```
Common:     60%
Uncommon:   25%
Rare:       10%
Epic:        4%
Legendary:   1%
Shiny:       1% on top of any rarity
```

---

## Sanctuary Zones

Six zones, unlocked by buddy count milestones. Each is a distinct side-scroll scene with its own visual identity and depth band.

| Zone | Unlock | Vibe |
|------|--------|------|
| The Meadow | Always unlocked | Warm, sunny, flowers, starter zone |
| The Burrow | 10 buddies | Cozy underground nook, warm lighting |
| The Pond | 20 buddies | Water features, lily pads, gentle rain |
| The Mushroom Grotto | 35 buddies | Bioluminescent, mysterious, glowy |
| The Canopy | 50 buddies | Treetop platforms, breezy, dappled light |
| The Crystal Cave | 75 buddies | Sparkly, prismatic, endgame zone |

Each zone:
- Has ground and platforms for buddy movement
- Has decoration slots for player-placed items
- Has ambient details (particles, gentle animation, optional weather)
- Has a visual style that naturally attracts certain personality types

Zone unlocks also grant a new expedition slot and add themed decorations to the shop.

---

## Progression & Economy

**Stardust (soft currency):**
- Earned passively (buddies existing generates a trickle)
- Earned from expeditions (especially "nice walk" results)
- Spent on decorations and furniture
- NOT spent on zone unlocks — those are buddy count milestones only

**Decoration shop:**
- Simple list of buyable items
- Grows as zones unlock (each zone adds themed items)
- Place decorations freely in any zone via drag-and-drop in the depth band

**No other currencies. No premium currency. No microtransactions.**

---

## Player Interaction

**Click buddy = pet + inspect:**
- First click: instant feel-good reaction (heart particles, happy wiggle)
- Opens info card showing: name, species/type, rarity, personality stats, liked things, current happiness
- Options from info card: rename, send on expedition

**Click decoration = move/remove:**
- Drag to reposition within the zone
- Option to sell back for partial stardust

**Click zone edges / zone map = navigate between zones**

---

## Save System

**Single auto-save file (JSON):**
```
sanctuary_state:
  unlocked_zones
  placed_decorations (per zone, with positions)
  stardust
  total_buddies_ever_found
  milestones_hit
buddy_roster:
  array of all buddy data
expeditions:
  active expeditions with departure timestamps
last_played:
  timestamp of last session
settings:
  volume, window size
```

**Auto-save:** every few minutes + on quit. One save slot.

**Offline catch-up on launch:**
1. Read `last_played` timestamp
2. Calculate elapsed real time
3. Resolve completed expeditions
4. Generate stardust trickle for elapsed time
5. Shuffle buddy zones based on preferences
6. Present "Welcome back!" recap:
   - Who came back from vacation
   - New buddies found
   - Buddies that moved zones
   - Stardust collected

---

## Phased Development

### Phase 1: Sanctuary Game (MVP)
The core Godot game — buddies, zones, expeditions, decorations, save/load, offline progress. A complete standalone idle collector.

### Phase 2: Terminal Companion
A lightweight terminal client that reads the save file (read-only) and shows buddy status updates as text notifications. Integrates with Claude Code's companion system so Cinder's speech bubble can reference actual sanctuary state.

Example: "Cinder peeks in: Blobbert is napping on the big cushion in The Burrow"

### Phase 3: Claude Embodiment
Cinder (or the user's Claude buddy) gets a body in the sanctuary. Terminal commands translate to in-game actions ("go to the pond", "sit with Blobbert", "rearrange the lamp"). Cinder wanders autonomously when not directed, has their own personality stats, and can report what they observe.

### Phase 4: Mobile Port
Godot's native mobile export. Touch-friendly UI adjustments — tap to pet, tap to inspect, drag to place decorations. Core game logic unchanged.

---

## Open Questions

| Question | Notes |
|----------|-------|
| Buddy sprite resolution | Depends on art style exploration in Krita. 64x64? 128x128? TBD after first art pass. |
| Window resolution | Needs to feel cozy but not cramped. 1280x720 default? |
| Sound design | Ambient per-zone music + buddy SFX. Scope TBD. |
| Buddy cap per zone | Performance consideration — max buddies visible at once? |
| Expedition destinations | Are they named places? Or just "buddy went on vacation"? |
| Weather system | Mentioned in preferences — is this Phase 1 or later? |
