# Regression suite

Headless suites for Vespercoil. Each is a standalone `SceneTree` script, run one at a time:

```bash
G=/c/Godot/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --path "C:/Godot/Vespercoil" --script tests/<name>.gd
```

A suite passes when it prints its own `... PASS` line, exits 0, and emits no `SCRIPT ERROR`.
Autoloads load the player's real save before any test body runs, so suites that measure combat
or economy must zero `bonuses` / `gold` first or they inherit a maxed Observatory.

> **Note (2026-09-24):** this file was rebuilt after an edit truncated it to 0 bytes. The
> suite list below is generated from the tests that actually exist on disk and pass today.
> The per-row "what it proves" text and the historical fix log from before that point are
> gone; re-add them as suites are touched.

## Suites

| # | Area | Test | What it proves |
|---|---|---|---|
| 1 | Boot / core loop | `smoke` | Autoloads, stats resolution, CDR clamp, pool reuse, shields, splitters, despawn |
| 2 | Content | `content` | Title-to-run flow, regional bonuses, characters, 27 weapons / 165 enemies / 25 grounds, seeded zones, era wave swaps, caches, beacons, relics, events, guardians, tag synergy, terrain, telemetry, pause and resume |
| 3 | Progression | `expansion` | 49-node permanent upgrade tree, time-based enemy pressure, active ability, trinkets, elemental reactions, elite affixes, weather, props, draft banish/lock, curse, build codes, boss rush, endless ascension, daily seed, achievements |
| 4 | Save | `wipe_save` | Title-screen Clear save arms on the first press and erases on the second; gold, bonuses, keepers, records and achievements clear in memory and on disk; settings survive; newer/unreadable saves are overwritten. Snapshots and restores the real save |
| 5 | Pickups | `pickup_cap` | `LIVE_CAP` ceiling holds, reclaim takes the farthest first, active / buckets / spatial hash stay consistent, reclaimed nodes return to the free pool |
| 6 | Spatial index | `spatial_hash` | Negative-floor indexing, insert/query, rebuild, in/out of range queries |
| 7 | Performance | `perf_grid` | Bounded grid entries and unique `nearby()` results after churn |
| 8 | Late difficulty | `late_horde` | Four time ramps reach their knee at 20m and hold their caps; 9 commons and 10 elites load, spawn plain/elite (1.5x size, 8x HP, affix rolled) and cannot appear before their 3-8m / 6-10m rolls |
| 9 | Observatory tree | `observatory` | All 7 lockstep tables agree on all 49 ids (MAX, BONUS_INFO, BRANCHES, UPGRADE_REQUIRES, bonuses initializer, POSITIONS, ICONS); icons load; no prerequisite exceeds its parent's MAX; every non-BOSSES branch keeps a root; cards fit the 904x506 viewport and never overlap a sibling; BOSSES nodes are boss-mapped with non-empty requirements; every branch renders every card |
| 10 | Observatory effects | `upgrade_effects` | Each of the 20 added nodes changes a resolved stat or reaches a live consumer; risk nodes carry +1 curse per rank; `cursed_plate` scales off permanent Curse; `ballistics` raises projectile speed but NOT orbit spin speed; `evasion` / `last_stand` are exercised against a live player |
| 11 | Vault | `vault` | 27 weapons resolve at Lv8 and land damage; 39 passives name real stats, ship an icon, are offered by a fresh draft, and every two-stat card moves both numbers; 17 trinkets have live effects and are draftable |
| 12 | Weapon feel | `cinder_jet` | Cinder Jet does chip damage and lets burn ramp: a 320 HP colossus survives 2 s burning, dies at ~3.5 s, and direct dps stays under Purging Halo's. Also proves the shrapnel kill chain terminates instead of blowing the stack |
| 13 | Admin panel | `admin_panel` | The ADMIN CONSOLE fits its own viewport on the FIRST open (not only after an action rebuilds it), the notice banner never overlays it, all 12 controls leave it the same size and actually do their work, and the console REOPENS after every close path (Return, hotkey, Escape, and over a level-up draft) -- `menu_kind` must not stay `admin` after a close |
| 14 | Damage | `damage_pipeline` | Crit chance/multiplier, true path, shield-first, resistances, vulnerability |
| 15 | Status | `status_effects` | Burn stacks/tick, chill to freeze, freeze DR, shields |
| 16 | Depth | `depth` | Nightmare scaling and gold, upgrades, room variants |
| 17 | Expanse | `expanse` | All 20 regions span 8x, seed-driven zones and difficulty |
| 18 | Regions | `regions` | Twenty-five grounds, unique looping soundtracks, gates |
| 19 | Rooms | `rooms` | Six distinct off-map interiors, wall layouts, caches |
| 20 | Map / UI | `map_upgrades_characters` | M overlay and pause return, field guide, characters |
| 21 | Keepers | `keeper_unlocks` | A fresh save wakes only Ranger; all twenty-four earnable keepers have a ground route, a portrait, and a signature stat that survives `apply()`; each ground clear awakens exactly its own keeper, a loss awakens nobody and no stat feat or difficulty win moves the roster; repeat clears are idempotent; clearing every ground completes the roster; the twelve deep keepers boot a real run and open with their own weapon and power; the Library's Keepers screen lists the roster and every sealed keeper's ground |
| 22 | World geometry | `walls_cache` | `interior_walls()` memo returns walls byte-identical to a fresh rebuild for all 6 rooms, repeated calls are stable, and switching rooms invalidates the cache |
| 23 | Collision | `projectile_stride` | A deferred collision phase still sweeps its skipped frame; the arsenal is muted and pre-fired shots drained so the frame is isolated |
| 24 | Bursts | `burst_overlap` | Overlapping bursts fire and pending burst shots stay bounded |
| 25 | Regional art | `regional_art` | 50 unique regional enemy SVG geometries, imports and scene bindings, over 14 templates |
| 26 | Contact | `enemy_contact` | Melee pursuit holds at contact; the charge window stays active |
| 27 | Regional encounters | `region_encounters` | Every ground's five-family roster (six on the deep five) and the raid that rolls from it; its own guardian opens the run and pays its weapon or relic |
| 28 | Map zones | `map_zones` | 20 regions have six distinct themed zones, colours and seeded layouts |
| 29 | Menus | `mainmenu_layout` | Title, setup and library menus build with the expected buttons and mode flow |
| 30 | Characters | `character_looks` | All 25 keepers use distinct imported sprites |
| 31 | Crowd motion | `crowd_motion` | Separation stays stable at 60 Hz |
| 32 | Bestiary | `bestiary_admin` | The three bestiary tabs list every enemy and guardian, and the admin run controls work in a live run |
| 33 | Ground activities | `ground_activities` | Relays and elite hunts activate, complete and reward |
| 34 | Resolution | `resolution_settings` | Six window sizes through 4K, selector and application |
| 35 | Performance | `late_run_perf` | Perf probe, not pass/fail: reports the late-run enemy tick cost |

> **2026-09-28:** rows 23-35 added from suites already on disk but missing from this
> list; `projectile_stride` was fixed to disable the arsenal and drain pre-fired
> projectiles before driving collisions.

> **Sandboxed suites.** `wipe_save`, `observatory_tree` and `thirtyfive_upgrades` write
> `user://vespercoil.cfg`. Each now REFUSES to start unless `APPDATA` contains
> `large-tree-test-profile`. Run them as:
> `APPDATA="$LOCALAPPDATA/large-tree-test-profile" "$G" --headless --path "C:/Godot/Vespercoil" --script tests/<name>.gd`
> Without the sandbox they exit 1 immediately rather than touching the player's save.

## Pack IV notes (2026-09-24)

- **Keepers are earned.** `FRESH_UNLOCKED` is now just `["Ranger"]`; the other
twenty-four moved into `NEW_UNLOCKS`. Awakening happens in `MetaProgression.awaken()`,
which is idempotent, and it is fed from exactly one route: the cleared ground's own
`reward_character` (region data owns the pairing). The `MILESTONE_UNLOCKS` table is
gone -- single-run feats no longer awaken anyone, so only map clears move the
roster. `NEW_UNLOCKS` became an `Array[String]`, which every existing
`for name in NEW_UNLOCKS` caller already accepted.
- **`MAP_UNLOCKS` and `LEGACY_UNLOCKS` are gone.** `MAP_UNLOCKS` duplicated what
`reward_character` already said and `LEGACY_UNLOCKS` was never read by anything.
Anything that still names them is stale.
- **`PassiveData` has a second stat.** `stat2` / `flat2_per_level` /
`percent2_per_level` are empty on the original cards, so behaviour is unchanged
for them. A two-stat card writes a second source keyed `<id>_2`; without that
separate key the second stat would overwrite the first inside
`StatsComponent.sources` and only one of the two would ever resolve.
- Suites that used to rely on the five starters being pre-unlocked call
`meta.awaken(character)` themselves now.
- **`StatsComponent.sources` is keyed by source name, so two `set_bonus` calls that
share a source silently keep only the last one.** This is not a warning or an
error: the earlier bonus simply disappears. Kit that grants more than one stat must
name a source per stat (`character`, `character_haste`, `character_scholar`, …).
The same trap applies to `PassiveData.stat2`, which is why the second stat writes a
`<id>_2` source. `keeper_unlocks` resolves every keeper against a Ranger baseline
precisely so a lost bonus fails the suite instead of shipping quietly.
- **Keepers are pinned by a test table, not by the code.** `ROSTER_STATS` in
`keeper_unlocks.gd` lists each keeper's signature stat; adding a keeper without a
row there fails `%d keepers are pinned, expected %d`.

## Known gotchas

- A `SceneTree` test cannot use the bare autoload identifiers (`MetaProgression`, `RunManager`).
  Use `root.get_node("MetaProgression")`. A static type annotation on a scene class
  (e.g. `var w: Weapon = ...`) makes GDScript compile that class at *test* compile time, when the
  autoload is not registered — that is why `upgrade_effects.gd` leaves the type off.
- Card overlap in the Observatory is checked as 142x78 rectangles, not by comparing positions.
  Two cards 20px apart are distinct Vectors but still overlap.
- `BOSS_UPGRADE_REQUIRES` is keyed by upgrade id, not region, so two rewards may share a region
  and both then display the same boss name.

## Deep five notes (2026-09-28)

- `Regions.count()` is 25: Saltbound Flats, Amberhold, The Vesperine, Lodestone
Fields and The Red Chancery (indices 20-24), each with five exclusive families
(the enemy registry is now 165 kinds), a regional guardian and a relic. Unlocks
chain from the Black Aurora / Tidal Maw / Veilwood clears, twenty-one distinct
clears and sixteen wins.
- Each new ground awakens its own keeper (Saltsworn, Amberkeeper, Bellsinger,
Lodestar, Quillkeeper -- the roster is now 25); no Observatory nodes were added.
Their guardians still record `bosses_defeated`, and their relics ride the
standard boss reward.
- `regional_art` now counts 50 unique portraits; floors for the five are new
512px atlases; soundtracks are region_20.wav through region_24.wav.
- Laser rule change: warnings and beams hesitate 0.6s (`LASER_TRACK_DELAY`) before
tracking, then sweep at 0.9 rad/s; movement timed to the hesitation can dodge,
and dashes, walls and range stay the hard counters (`LASER_CONTENT.md`).
- The deep five each field a sixth family: a Seeker (`seeker` behaviour) firing
a homing orb tuned per family via `EnemyData.seeker_turn` / `seeker_speed` /
`seeker_status`.

## Laser regression

`tests/laser_content.gd` proves the timed beam, the warning/beam hesitation windows and their delayed tracking, the source-specific shield, pool cleanup,
wall blocking, draft availability and new horde/boss entries. Run existing damage,
late-horde, content and vault checks after combat changes.

## Run pacing notes (2026-09-29)

- The level curve is exponential now: `run_manager.gd` charges
`12.0 * pow(1.16, level - 1)` XP per level instead of the old `8 + 3*level^1.35`
polynomial. Tuned against a measured 7-minute run (5.9k XP inflow): the old curve
ended at level 35 with a level every ~15s late; the new one ends at level 30 with
~1 per 45s late, and long runs meet a real wall (the two curves cross at ~level 26).
`tests/level_curve.gd` pins the growth ratio and a fixed soak value. One knob: the
1.16 growth base.

## Content expansion II (2026-09-29)

- Weapons 23 -> 27: rend (bleed arcs, evolves to Exsanguine), miasma (poison spray, Venom Bloom), voidlance (TRUE damage forward lance, Nullspike), thunderhead (chain lightning + shock, Skybreaker).
- Trinkets 15 -> 17: sanguine (kills seed bleed nearby), venom_fang (kills seed poison).
- Reactions 4 -> 6: hemorrhage (bleed onto frozen) and congeal (freeze onto bleeding). Blight (poison+burn) is now player-reachable.
- Achievements 12 -> 29; RunManager now banks best_level, elites, grounds_cleared and keepers_total each run.
- Regional guardians: five new attack patterns (spiral, carpet, shriek, hunt, pincer), assigned to ten grounds; `region_encounters` checks the full list.
- Weather 4 -> 8: meteor_shower, sandstorm, ember_rain, veil_fog; a region's favoured fronts appear ~55% of the time.
- Elite affixes 5 -> 10: leeching, thorns, frenzy, volatile, hexing. Thorns retaliation skips guardians (`boss_title` guard) and non-weapon sources - keep that guard, the region suite kills guardians with fake nukes.
- Contracts rotate: kills / caches / rooms / elites / survival (75 s unharmed), driven by CONTRACT_CYCLE.
- Enemies 153 -> 165: twelve additions filling thin roles plus a new trapper behaviour (seeds telegraphed charges). Rosters extended in nine grounds.
- Abilities 7 -> 12: venom_nova, crimson_rite, chronolock, thunder_chorus, ward_chime; Fenwalker / Hexblade / Lodestar / Bellsinger / Veilbinder reassigned.
- Modes: Weekly Mutator (ISO-week seed, two of four mutators) and a Hardcore toggle (no revivals).
- New tests: keeper_abilities, weekly_mutators.
