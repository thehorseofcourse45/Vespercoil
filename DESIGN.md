# Vespercoil — Godot 4 arena survivor

## 1. Project structure

```text
Vespercoil/
  project.godot                  Engine settings, autoloads, main scene and layers.
  default_bus_layout.tres        Master, Music, SFX and UI audio buses.
  README.md                     Launch instructions, controls and verification results.
  DESIGN.md                     Ordered architecture, contracts, balance and build plan.
  scenes/
    main.tscn                   Game root with injected system dependencies.
    player.tscn                 Player assembly and camera.
    projectile.tscn             Reusable projectile assembly used by the projectile pool.
    enemies/{chaser,swarmer,bruiser,shooter,exploder,splitter,shielded,charger,summoner,sniper,burrower,stalker,spire,mender,colossus,wraith,spitter}.tscn
                                Seven shared-component assemblies with distinct data.
  data/
    weapons/{needle,orbit,seeker,flask,lightning,field}.tres
                                Six editable weapon definitions with eight levels.
    passives/{vitality,boots,clock,might,lens,duplicator,magnet,wisdom,plate}.tres
                                Nine editable, five-level passive definitions.
    enemies/{chaser,swarmer,bruiser,shooter,exploder,splitter,shielded,charger,summoner,sniper,burrower,stalker,spire,mender,colossus,wraith,spitter}.tres
                                Enemy balance and appearance.
    waves/{era0,era1,era2,era3,era4}.tres
                                Time-indexed spawn schedule entries.
  scripts/
    autoload/{game_events,run_manager,meta_progression}.gd
                                Signal contract, run accounting, versioned persistent economy.
    data/{weapon_data,passive_data,enemy_data,wave_data}.gd
                                The four exported Resource schemas.
    components/{health,hurtbox,hitbox,velocity,experience_drop,stats}.gd
                                Reusable entity components and stat resolution.
    entities/{player,enemy,projectile}.gd
                                Composition roots and pooled transient state.
    weapons/{weapon,forward_weapon,orbit_weapon,pattern_weapon}.gd
                                Shared fire-time resolution and six distinct behaviours.
    systems/{enemy_manager,projectile_manager,pickup_manager,effects,arsenal,spawn_director,audio}.gd
                                Central loops, object pools, draft inventory and scheduling.
    ui/{hud,draft}.gd            HUD, menus, meta shop and weighted upgrade draft.
    main.gd                     System assembly and arena presentation.
  tests/smoke.gd                Runnable headless integration and load checks.
  tests/capture.gd              Reproducible rendered UI captures.
  preview-{arena,draft,shop}.png Rendered screenshots of this implementation.
  VALIDATION.md                Engine version, measured checks and remaining limits.
```

## 2. Node trees

Script-created children are marked `runtime`; their ownership is explicit and references
are injected by their composition root. No unrelated system discovers another by path.

```text
Main (Node2D)
  Player (Node2D, player.tscn)
    Body (Polygon2D)
    HealthComponent (Node)
    HurtboxComponent (Node)
    VelocityComponent (Node)
    StatsComponent (Node)
    Camera2D (Camera2D)
  EnemyManager (Node2D, runtime)
    Enemy × pooled capacity (Node2D, one of seven scenes)
  ProjectileManager (Node2D, runtime)
    Projectile × pooled capacity (Node2D)
  PickupManager (Node2D, runtime; pooled record objects, one draw loop)
  Effects (Node2D, runtime; pooled records, capped draw loop)
  Arsenal (Node, runtime)
    Weapon × owned count (Node, runtime)
  SpawnDirector (Node, runtime)
  Audio (Node, runtime)
    AudioStreamPlayer × 12 (runtime, fixed voice pool)
  HUD (CanvasLayer, runtime, PROCESS_MODE_ALWAYS)
    Controls (Control)
    Draft (PanelContainer, runtime, PROCESS_MODE_ALWAYS)

Player (Node2D)
  Body (Polygon2D)
  HealthComponent (Node)
  HurtboxComponent (Node)
  VelocityComponent (Node)
  StatsComponent (Node)
  Camera2D (Camera2D)

Enemy (Node2D)
  Body (Polygon2D)
  HealthComponent (Node)
  HurtboxComponent (Node)
  HitboxComponent (Node)
  VelocityComponent (Node)
  ExperienceDropComponent (Node)

Projectile (Node2D)
  Body (Polygon2D)
  HitboxComponent (Node)
  VelocityComponent (Node)
```

## 3. Data schemas

All resources are editable in the inspector. Runtime copies avoid mutating shared assets.

| Resource | Exported fields (type) |
|---|---|
| WeaponData | id:StringName, title:String, behavior:StringName, color:Color, base_damage:float, cooldown:float, projectile_count:int, pierce:int, area_scale:float, knockback:float, duration:float, projectile_speed:float, radius:float, weight:float, level_changes:Array[Dictionary], evolution_passive:StringName, evolution_title:String |
| PassiveData | id:StringName, title:String, stat:StringName, flat_per_level:float, percent_per_level:float, max_level:int, weight:float, color:Color |
| EnemyData | id:StringName, title:String, health:float, speed:float, damage:float, radius:float, xp:int, color:Color, shot_interval:float, shield:float |
| WaveData | start_time:float, end_time:float, enemy_types:Array[StringName], weights:Array[float], spawn_interval:float, batch_size:int, formation:String (exported enum) |

`level_changes` has seven dictionaries for levels 2–8. Each dictionary adds named
numeric weapon fields to the baseline. Stats resolve `(base + sum(flat)) *
(1 + sum(percent))`; cooldown reduction is clamped to 0–80% and cooldown to at least
0.06 seconds. Armour subtracts damage with a minimum incoming hit of 1. Weapons
read stats at each discharge/persistent contact tick; existing travelling shots keep
their discharge snapshot. No passive modifier is baked into a weapon when acquired.

## 4. Signal bus contract

| Signal and arguments | Emitter | Listeners |
|---|---|---|
| run_started() | Main | RunManager |
| enemy_died(position:Vector2, xp:int, kind:StringName, elite:bool) | EnemyManager | RunManager, PickupManager, Effects |
| damage_dealt(weapon:StringName, amount:float, position:Vector2, heavy:bool) | EnemyManager | RunManager, Effects, Audio |
| player_hurt(amount:float) | Player | RunManager, Effects, Audio |
| pickup_collected(kind:StringName, value:int) | PickupManager | RunManager, Player, Arsenal, Audio |
| level_up(level:int) | RunManager | Draft |
| inventory_changed() | Arsenal | Player, HUD |
| run_ended(victory:bool) | Player / EnemyManager | RunManager, HUD |
| impact(position:Vector2, magnitude:float, color:Color) | ProjectileManager / EnemyManager | Effects |

Component-local `HealthComponent.depleted()` is emitted by health and connected by
its owning Player; enemy death is synchronously handled by EnemyManager to make
pool reuse safe. Draft talks to its injected Arsenal; weapon handlers talk to their
injected combat services. Those are related collaborators, not global path lookups.

## 5. Core scripts and performance design

Complete source is supplied in `scripts/`; all six weapons and all requested systems
are implemented. Read `weapon.gd`, then `forward_weapon.gd` and `orbit_weapon.gd`
for the base and two concrete implementations. `pattern_weapon.gd` implements
seekers, arcing flasks, chain lightning and a persistent player field.

### Collision matrix

| Category / named bit | Physics mask | Actual narrow phase |
|---|---|---|
| Player / 1 | 0 | Enemy contact circle and hostile projectile segment versus player |
| Enemy / 2 | 0 | Spatial hash candidate circles / swept projectile segment |
| Player shot / 4 | 0 | Enemy spatial hash only |
| Hostile shot / 8 | 0 | Player only |
| Pickup / 16 | 0 | Player distance only |
| World / 32 | 0 | Building shells and vault walls only; open terrain stays non-blocking |

These are logical categories also named in project settings. There are deliberately
no Area2Ds or physics bodies, so no hidden enemy/enemy or projectile/projectile
overlap pairs. Hurtbox and Hitbox are lightweight Node components. A 96-unit spatial
grid reduces local attack queries; piercing shots use swept segment tests to prevent
tunnelling. Building shells and interior vault walls resolve with circle-versus-rect
push-out in World; open terrain remains non-blocking, so direct pursuit is still
valid pathfinding across the arena.

One EnemyManager updates every active enemy; enemies have no processing callback.
Each type has its own free list, initially 224 instances (1,568 total), growing by 32.
Deaths and far-away despawns return instances. IDs change every activation so
lingering hit cooldowns cannot confuse a reused instance with its previous life.
This node approach keeps component scenes inspectable and permits shield/shooter/
splitter logic. MultiMesh would lower visual submission overhead but still needs
CPU gameplay records, custom hit feedback and index management. Profile this
implementation on target hardware before substituting MultiMesh for swarm visuals.
See [Godot's MultiMesh guidance](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html).

Projectiles preallocate 256 and grow by 64. Pickups preallocate 2,048 records and grow
by 256. Damage labels (64), particles (256), lightning traces (64), and audio voices
(12, at most 3 for one cue) have fixed caps; cosmetic exhaustion drops the effect.
Pickup records coalesce nearby equal kinds to avoid unbounded gem accumulation.
Grid candidates and pool lists are CPU work; this is a working reference, not a
claim of measured 60 FPS on all machines at 1,500 units. Debug F3 reports actual FPS,
enemy count, pool utilisation and renderer draw calls. F6 is a repeatable load probe.

### Evolution pairs

After 10:00, a chest evolves an eligible level-8 weapon with its matching level-5
passive: Needle + Might → Railstorm (double damage, wider piercing volley);
Orbit + Lens → Solar Crown (extra satellites, doubled reach);
Seeker + Clock → Starfall (faster multi-seekers);
Flask + Wisdom → Wildfire (larger, longer pools);
Lightning + Duplicator → Tempest (more hops);
Field + Magnet → Event Horizon (large field with inward knockback).
One chest grants one random eligible evolution; otherwise it grants 50 gold.

## 6. Balance table

**Post-expansion numeric baseline lives in `BALANCE.md`** (12 weapons, 17 enemies,
4 guardians, tags/synergies, relics, regions, waves). The tables below are the
original six-weapon / seven-enemy prototype snapshot and are superseded for
content counts.

Baseline fields before levels/passives; cooldown in seconds, speed in units/second.

| Weapon | Damage | CD | Count | Pierce | Area | Knockback | Duration | Speed | Radius | Intent |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Needle | 12 | 0.85 | 1 | 2 | 1 | 35 | 1.8 | 600 | 6 | Directional lane clearing; movement aims it |
| Orbit | 8 | 0.65 | 2 | 0 | 1 | 45 | 0 | 2.4 | 74 | Risky close defence; per-enemy contact cooldown |
| Seeker | 18 | 1.4 | 1 | 0 | 1 | 20 | 3 | 340 | 7 | Reliable cleanup; reacquires nearest live target |
| Flask | 7 | 2.8 | 1 | 0 | 1 | 5 | 4 | 260 | 65 | Arcing delivery, persistent area denial |
| Lightning | 24 | 2.0 | 3 | 0 | 1 | 10 | 0.15 | 0 | 170 | Distinct-target chained burst |
| Field | 5 | 0.8 | 1 | 0 | 1 | 12 | 0 | 0 | 90 | Reliable persistent close-range damage |

| Enemy | HP | Speed | Contact damage | Radius | XP | Intent |
|---|---:|---:|---:|---:|---:|---|
| Chaser | 18 | 60 | 8 | 12 | 1 | Basic readable pressure |
| Swarmer | 9 | 110 | 5 | 8 | 1 | Fragile flanking pressure |
| Bruiser | 110 | 35 | 18 | 22 | 8 | Slow durable roadblock |
| Shooter | 32 | 45 | 7 | 13 | 3 | Keeps 280-unit range; fires every 2.4 s |
| Exploder | 24 | 72 | 10 | 14 | 3 | Death blast with 64-unit radius |
| Splitter | 44 | 55 | 10 | 17 | 5 | Two swarmer children on death |
| Shielded | 35 + 35 shield | 52 | 12 | 16 | 5 | Shield regenerates after 1.5 s without damage |

Every two minutes: an elite has ×8 HP, ×1.4 damage, ×1.5 size; bosses at 10/20/30
minutes have ×60 HP, ×2 damage, ×2.3 size. Final boss death wins; death loses.
Enemy HP scales +2.5% per minute and speed up to +30%. Spawn cadence rises from
2/1.4 s to 16/0.34 s. Weapon levels add damage and selected counts/area/pierce;
five-level passives multiply this growth. A 30-minute run can continue past 30:00
until its final boss dies. Late power depends on collecting gems and coherent builds.

| Passive | Per level (5 levels) | Intent |
|---|---|---|
| Vitality | +20 flat max HP | Forgiveness |
| Boots | +8% movement speed | Spacing |
| Clock | +10 percentage points cooldown reduction | Firing density; global 80% cap |
| Might | +15% damage | Offensive scaling |
| Lens | +12% area | Coverage |
| Duplicator | +1 projectile | Strong count synergy |
| Magnet | +25% pickup radius | Collection economy |
| Wisdom | +12% XP | Early investment |
| Plate | +1 flat armour | Contact mitigation |

## 7. Independently playable build order

1. Player polygon moves, camera follows, one chaser pursues; health and restart.
2. Enemy pool, spatial hash, Needle and enemy death; FPS overlay and 1,500-unit probe.
3. Pooled gems, XP, three-card paused draft and reroll; ten-minute survival slice.
4. Six weapons, nine passives, stat resolution and inventory pips; varied builds.
5. Seven enemies, weighted wave schedule, formations, elites and three bosses;
   complete win/lose 30-minute run.
6. Gold, chests, evolutions, vacuum, healing, characters and versioned meta shop;
   complete repeatable progression loop.
7. Hit flash, capped effects/audio, hit-stop, shake, pause and run breakdown;
   presentation-complete placeholder-art build (this delivery).
8. Shippable: target-machine profiling, long-run balance/playtesting, controller UI
   navigation/accessibility review, art/audio replacement, export signing and QA.
   These release activities require measured playtests; source completeness alone
   does not establish shipping performance or balance.
