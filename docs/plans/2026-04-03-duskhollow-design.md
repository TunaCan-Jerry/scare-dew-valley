# Scaredew Valley — Game Design Document

## Elevator Pitch

Stardew Valley meets tower defense in a supernatural apocalypse. Farm by day, defend by night, build a community of survivors, and push back the darkness — all the way to Cthulhu. Roguelike structure with Isaac-style progressive unlock pools.

## Core Pillars

1. **Farm & Craft** — full farming sim with crops, animals, cooking, potion-brewing, spell research
2. **Defend & Survive** — wall-and-gate tower defense each night with escalating supernatural threats. Player character is a mobile support caster.
3. **Community & Relationships** — recruit from a pool of 30-50 fully designed characters. Stardew-depth friendships/romances that unlock gameplay abilities.
4. **Explore & Discover** — excursions outside the farm for scavenging, meeting other communes, finding rare tech/items
5. **Roguelike Progression** — Isaac-style unlock pools. Small starting pool expands as you achieve milestones. Each run has different characters, items, tech, and events.

## Tech & Perspective

- Godot 4.x, GDScript
- Top-down 2D, tile-based
- Modern gothic horror setting

---

## Core Loop

### State Machine

```
MainMenu -> Run
  Run: DayPhase <-> DuskTransition <-> NightPhase <-> DawnReport -> (loop)
  DayPhase: FarmView | ExcursionView | DialogueView
```

### Day Phase

- Camera: free-scrolling top-down view of the farm and surrounding area
- Time: day clock ticks (Stardew-style). Activities take time. Player chooses how to spend the day.
- Activities: farm, craft, build/repair defenses, socialize with NPCs, go on excursions
- Can end day early to prep for night

### Dusk Transition

- Warning bell. Workers return to shelters/posts. Brief window for last-second placements.
- Lighting shifts to dark with torch/floodlight pools.

### Night Phase

- Enemies spawn from map edges in announced waves with brief pauses between
- Turrets auto-fire, walls take damage, workers fight at assigned posts
- Player character moves on the field casting support abilities (buffs, damage, crowd control)
- Non-corporeal enemies affect morale/effectiveness rather than dealing physical damage
- Wave composition is story-driven + influenced by roguelike modifiers

### Dawn Report

- Damage summary. Dead characters listed (permanent). Resources from salvage.
- Status effects discovered (bitten workers, haunted buildings).
- New day begins.

---

## Day Phase: Farming

### Farming (Stardew-style)

- Tile-based farm grid. Till, plant, water, harvest.
- **Crop categories:**
  - Food crops (wheat, potatoes, carrots) — feed community, trade
  - Medicinal herbs — potions, status effect cures
  - Arcane plants — spell components. Some only grow in cursed soil near perimeter.
- **Animals:** Chickens, goats, guard dog (helps at night). Need shelters and feed.
- **Seasons/weather:** Affects crop growth. Rain auto-waters. Storms damage fences. Fog nights = reduced visibility.

### Crafting & Research

| Station | Function |
|---------|----------|
| **Kitchen** | Cook meals from crops. Better meals = higher morale + night buffs. |
| **Alchemy Lab** | Brew potions from medicinal herbs. Cure status effects. Craft throwables (holy water bombs, acid flasks). |
| **Arcane Study** | Research spells from grimoires + arcane plants. Unlocks new player abilities for night. |
| **Armory** | Upgrade turrets, craft ammo types (silver bullets, incendiary rounds, UV shells). Tech tree branches. |

### Base Building

- Place walls, gates, turrets, floodlights on the farm perimeter
- Interior buildings: shelters, crafting stations, storage barns
- Upgrade paths per building (wood fence -> chain fence -> concrete barrier -> reinforced barrier)

### Time Management

- Day clock (like Stardew). Activities cost time. Can't do everything.
- Community members assigned to tasks work autonomously (slower than player doing it).
- Choosing between farming, crafting, building, socializing, or excursions is the core day tension.

---

## Night Phase: Tower Defense

### Defenses

| Turret | Resource | Behavior |
|--------|----------|----------|
| **Machine Gun Turret** | Bullets (auto) | Fast fire, low damage. Good vs hordes. |
| **Floodlight** | Power (auto) | Reveals enemies, slows undead. No damage. |
| **Flamethrower** | Fuel (consumable) | AoE cone. Devastating vs groups. Burns out. |
| **UV Spotlight** | Power + Blessed Silver | High damage vs vampires/werewolves. Useless vs undead. |
| **Holy Ward** | Holy Water (consumable) | AoE zone, damages and repels unholy creatures. |
| **Sniper Nest** | Silver Bullets (consumable) | Long range, high single-target. Needs worker to operate. |
| **Mine Field** | Crafted mines | One-time use. Placed during day, triggers at night. |
| **Razor Wire** | Scrap metal | Slows + damages over time. Degrades. |

### Player Commander Abilities

- Player character moves freely on field, casts support abilities
- Abilities unlock via Arcane Study research + relationship bonuses
- **Starting:** Consecrate Ground (AoE slow), Rally (stop worker panic)
- **Unlockable:** Holy Nova, Silver Storm, Binding Circle, Banish, etc.
- **Relationship-unlocked:** Each maxed NPC grants a unique ability

### Enemy Types

**Corporeal (physical threats):**

| Enemy | Behavior | Weakness |
|-------|----------|----------|
| **Zombies** | Slow swarm, melee, break walls | Fire, headshots |
| **Ghouls** | Fast, flanking, climb walls | UV light, silver |
| **Vampires** | Strong, abilities (charm workers, mist form) | UV, holy water, stakes |
| **Werewolves** | Tanky, fast, AoE. Full moon nights. | Silver bullets |
| **Shoggoths** | Massive, absorb damage, split into blobs | Fire + acid combo |
| **Eldritch Horrors** | Boss-tier, unique mechanics each | Research-specific |
| **Cthulhu** | Multi-phase final boss | Everything you've learned |

**Non-corporeal (psychological threats — affect morale, not HP):**

| Enemy | Behavior | Effect | Counter |
|-------|----------|--------|---------|
| **Wraiths** | Phase through walls, hover near workers | Lower morale, trigger panic/flee | Holy wards, high morale |
| **Banshees** | Fly over defenses, scream | AoE morale debuff, reduced accuracy | Church bell, Rally ability |
| **Phantasms** | Invisible, haunt buildings | Buildings stop functioning, Eldritch Whispers on workers | Arcane cleansing, holy water |

### Status Effects

| Effect | Source | Consequence | Cure |
|--------|--------|-------------|------|
| **Ghoul Plague** | Ghoul bite | Worker slowly turns. Lose them if uncured. | Alchemy Lab potion |
| **Lycanthropy** | Werewolf bite | Worker transforms on full moons. (Risk/reward: keep as powerful but dangerous defender?) | Alchemy Lab potion |
| **Eldritch Whispers** | Phantasm haunting | Worker goes mad, unreliable | Arcane Study research |
| **Vampiric Charm** | Vampire ability | Worker switches sides until charming vampire killed | Kill the vampire |

---

## Community & Relationships

### Character Pool

- **30-50 fully designed characters** — name, portrait, backstory, personality, trait, preferred gifts, heart events, personal quest, max-bond ability
- **Per run:** 12-18 characters appear, drawn from the unlocked pool
- **No generic NPCs.** Every person is named and designed.
- **Arrival conditions vary:** random, building-gated, excursion-found, commune-sent, post-boss
- **Character synergies:** Certain pairs have bonus dialogue or combined abilities
- **Same character, different roles:** A character who's recruitable in one run might be a commune leader in another

### Relationships (Stardew-depth + gameplay integration)

- Heart levels 0-10
- Increase via: gifts, dialogue choices, working alongside them, protecting them at night, personal quests
- Heart events at milestones (2, 4, 6, 8, 10) with story scenes and choices
- Romance available at heart 8+ for select characters
- **Max-bond ability:** Each character unlocks a unique gameplay ability at max friendship/romance
- **Permadeath:** Characters can die at night. Losing a befriended/romanced character = emotional loss + permanent ability loss

### Example Characters

| NPC | Background | Trait | Max-Bond Ability |
|-----|-----------|-------|-----------------|
| Maria | Former nurse | Healer — treats status effects faster | Field Medic — auto-cure one worker per night |
| Rev. Josiah | Small-town preacher | Faithful — huge morale aura | Divine Shield — temp invulnerability on one wall section |
| Duke | Ex-military mechanic | Tinkerer — turret repair/upgrade bonus | Overclock — one turret fires 3x speed for a wave |
| Sylvie | Occult bookshop owner | Arcane — research speed bonus | Eldritch Sight — reveal all enemies + weaknesses for a night |
| Marcus | High school teacher | Leader — worker efficiency aura | Coordinated Defense — all workers +50% accuracy for a wave |
| Jin | Survivalist/prepper | Scavenger — better excursion loot | Supply Drop — free resources at dawn |

---

## Excursions & The Outside World

### Excursions

- Leave the farm during day to explore surrounding region
- Costs daylight hours (away from farm activities)
- Procedurally arranged points of interest per run: stores, military outposts, hospitals, occult shops, churches, communes
- Risk/reward: farther = better loot + more time spent + possible daytime encounters
- Find: scrap/materials, rare items (grimoires, blueprints), seeds/reagents, survivors, lore

### Other Communes

- 3-5 survivor settlements per run, discovered through excursions
- Each has a leader (drawn from character pool), a specialty (military, religious, scientific, etc.)
- **Trade:** Surplus crops/materials for things you can't produce
- **Alliances:** Build reputation. Allied communes send fighters on tough nights, share research, warn about threats
- **Roguelike:** Which communes exist and who leads them varies per run

---

## Roguelike Structure

### A Single Run

- Start: arrive at abandoned farm with basic tools and seeds
- ~30-40 in-game days to reach the finale
- Escalation: Zombies -> Ghouls -> Vampires -> Werewolves -> Shoggoths -> Eldritch Horrors -> Cthulhu
- Run ends: Town destroyed (loss), Cthulhu defeated (victory), or evacuate (partial victory)

### What Varies Per Run

- Which 12-18 characters appear (from unlocked pool)
- Which communes exist and who leads them
- Excursion point-of-interest layout
- Item drops from night waves
- Which tech tree branches are available (blueprint-gated)
- Random events: blood moon, wandering merchant, refugee crisis, traitor

### Isaac-Style Unlock System

**Starting pool (Run 1):**
- ~8 characters
- Basic crops (wheat, potatoes, carrots)
- Basic buildings (wood fence, gun turret, floodlight, shelter, kitchen)
- Basic enemies (zombies, ghouls)
- No special ammo, no arcane research, no potions

**Unlocks expand the pool permanently:**

| Achievement | Unlocks |
|-------------|---------|
| Survive Night 5 | Vampires in enemy pool + Silver Bullets blueprint |
| Recruit 3 characters | 4 new characters in pool |
| Build Alchemy Lab | Medicinal herb seeds + potion recipes |
| Defeat a Vampire Lord | UV Cannon blueprint + 2 freed characters |
| Discover first commune | Trade system + commune leaders in character pool |
| Research first spell | Arcane plant seeds + grimoires in excursion loot |
| Reach Night 20 | Shoggoths in enemy pool + heavy blueprints |
| Complete a character's full heart arc | That character starts with bonus trust in future runs |
| Beat Cthulhu | New Game+ modifiers, hardmode enemies, ultimate character unlocks |

### Meta-Progression (persists across runs)

- **Lore journal** — story fragments uncovered. Permanent.
- **Character codex** — entries for every character met. Tracks stories across runs.
- **Starter unlocks** — milestone rewards: better starting gear/seeds for future runs
- **Pool expansion** — new characters, items, buildings, enemies, crops added to the pool

---

## Resources

| Resource | Source | Primary Use |
|----------|--------|-------------|
| **Gold** | Trade, salvage, quests | Universal currency. Hire, buy, build. |
| **Holy Water** | Chapel production | Anti-undead abilities, blessing towers, consecrating ground |
| **Blessed Silver** | Merchant, ruins | Powerful upgrades, anti-vampire weapons |
| **Fuel** | Scavenged | Flamethrower turrets, generators |
| **Scrap Metal** | Salvage, excursions | Building materials, razor wire, repairs |
| **Food** | Farming | Feed community (required daily), trade, morale |
| **Ammo** | Armory crafting | Turret operation (some turrets consume ammo) |

---

## Architecture (Godot)

### Core Systems

| System | Description |
|--------|-------------|
| DayNightCycle | State machine: phase transitions, clock, lighting |
| FarmGrid | TileMap farm. Soil states, crop growth, building placement |
| BuildingSystem | Place/upgrade/repair structures. Resource costs. Unlock-gated. |
| CropSystem | Planting, watering, growth, harvest. Season/weather. |
| DefenseSystem | Turret targeting, wall HP, damage resolution |
| EnemyWaveManager | Wave composition (story + roguelike). Spawn, pathfind, attack. |
| PlayerCommander | Player character movement + ability casting at night |
| CharacterManager | 30-50 character defs. Pool/unlock system. Arrival logic. |
| RelationshipSystem | Heart levels, gifts, events, ability unlocks |
| ResourceManager | All resource types, production, consumption |
| ExcursionSystem | Map gen, POI placement, loot tables |
| CommuneSystem | Other settlements, reputation, trade, alliances |
| UnlockManager | Achievement tracking, pool expansion. Persists to disk. |
| StatusEffectSystem | Curses, plagues, cures |
| ResearchSystem | Tech tree + arcane study. Blueprint/grimoire unlocks. |
| MoraleSystem | Per-character + global morale. Spectral enemies, deaths, food. |

### Data-Driven

All content defined as Godot Resources (.tres): characters, crops, buildings, enemies, items, recipes, tech tree nodes, wave compositions, unlock conditions. Adding content = creating resource files, not code.
