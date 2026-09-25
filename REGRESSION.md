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
| 2 | Content | `content` | Title-to-run flow, regional bonuses, characters, 20 weapons / 75 enemies / 20 grounds, seeded zones, era wave swaps, caches, beacons, relics, events, guardians, tag synergy, terrain, telemetry, pause and resume |
| 3 | Progression | `expansion` | 49-node permanent upgrade tree, time-based enemy pressure, active ability, trinkets, elemental reactions, elite affixes, weather, props, draft banish/lock, curse, build codes, boss rush, endless ascension, daily seed, achievements |
| 4 | Save | `wipe_save` | Title-screen Clear save arms on the first press and erases on the second; gold, bonuses, keepers, records and achievements clear in memory and on disk; settings survive; newer/unreadable saves are overwritten. Snapshots and restores the real save |
| 5 | Pickups | `pickup_cap` | `LIVE_CAP` ceiling holds, reclaim takes the farthest first, active / buckets / spatial hash stay consistent, reclaimed nodes return to the free pool |
| 6 | Spatial index | `spatial_hash` | Negative-floor indexing, insert/query, rebuild, in/out of range queries |
| 7 | Performance | `perf_grid` | Bounded grid entries and unique `nearby()` results after churn |
| 8 | Late difficulty | `late_horde` | Four time ramps reach their knee at 20m and hold their caps; 5 commons and 6 elites load, spawn plain/elite (1.5x size, 8x HP, affix rolled) and cannot appear before their 5-15m / 10-15m rolls |
| 9 | Observatory tree | `observatory` | All 7 lockstep tables agree on all 49 ids (MAX, BONUS_INFO, BRANCHES, UPGRADE_REQUIRES, bonuses initializer, POSITIONS, ICONS); icons load; no prerequisite exceeds its parent's MAX; every non-BOSSES branch keeps a root; cards fit the 904x506 viewport and never overlap a sibling; BOSSES nodes are boss-mapped with non-empty requirements; every branch renders every card |
| 10 | Observatory effects | `upgrade_effects` | Each of the 20 added nodes changes a resolved stat or reaches a live consumer; risk nodes carry +1 curse per rank; `cursed_plate` scales off permanent Curse; `ballistics` raises projectile speed but NOT orbit spin speed; `evasion` / `last_stand` are exercised against a live player |
| 11 | Vault | `vault` | 20 weapons resolve at Lv8 and land damage; 38 passives name real stats, ship an icon, are offered by a fresh draft, and every two-stat card moves both numbers; 15 trinkets have live effects and are draftable |
| 12 | Damage | `damage_pipeline` | Crit chance/multiplier, true path, shield-first, resistances, vulnerability |
| 13 | Status | `status_effects` | Burn stacks/tick, chill to freeze, freeze DR, shields |
| 14 | Depth | `depth` | Nightmare scaling and gold, upgrades, room variants |
| 15 | Expanse | `expanse` | All 20 regions span 8x, seed-driven zones and difficulty |
| 16 | Regions | `regions` | Twenty grounds, unique looping soundtracks, gates |
| 17 | Rooms | `rooms` | Six distinct off-map interiors, wall layouts, caches |
| 18 | Map / UI | `map_upgrades_characters` | M overlay and pause return, field guide, characters |
| 19 | Keepers | `keeper_unlocks` | A fresh save wakes only Ranger; all nineteen earnable keepers have both a ground and a milestone, a portrait, and a signature stat that survives `apply()`; each ground clear awakens exactly its own keeper and a loss awakens nobody; every threshold is one short of firing next to its own value; repeat clears are idempotent; clearing every ground completes the roster; the seven deep keepers boot a real run and open with their own weapon and power; the Library's Keepers screen lists the roster and every sealed keeper's route |

## Pack IV notes (2026-09-24)

- **Keepers are earned.** `FRESH_UNLOCKED` is now just `["Ranger"]`; the other
twelve moved into `NEW_UNLOCKS`. Awakening happens in `MetaProgression.awaken()`,
which is idempotent, and it is fed from two routes: the cleared ground's own
`reward_character` (region data owns the pairing) and the `MILESTONE_UNLOCKS`
table (the single-run feats). `NEW_UNLOCKS` became an `Array[String]`, which every
existing `for name in NEW_UNLOCKS` caller already accepted.
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
