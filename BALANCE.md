# Vespercoil — balance tables

Living reference for numeric design. Values are read from `data/` and the scripts
that own them; edit the resource, not this file, when tuning. Supersedes
`DESIGN.md` §6 for post-expansion content.

Stat resolution: `(base + sum(flat)) * (1 + sum(percent))`. CDR clamped 0–80%,
cooldown floored at 0.06 s. Damage order: crit → attacker type mult → defender
resist (cap 0.8) → armour (floor 1.0) → shield → vulnerability → status DR
(`enemy.status.damage_reduction()`). TRUE damage skips mult/resist/armour, still
crits.

## Weapons (baseline, level 1)

| Weapon | Dmg | CD (s) | Count | Pierce | Radius | Speed | Tags | Evolution (Lv8 + Lv5 passive) |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Needle | 12 | 0.85 | 1 | 2 | 6 | 600 | physical, projectile, mobility | Might → Railstorm |
| Orbit | 8 | 0.65 | 2 | 0 | 74 | 2.4 | physical, area | Lens → Solar Crown |
| Seeker | 18 | 1.40 | 1 | 0 | 7 | 340 | projectile, mobility | Clock → Starfall |
| Flask | 7 | 2.80 | 1 | 0 | 65 | 260 | fire, area | Wisdom → Wildfire |
| Lightning | 24 | 2.00 | 3 | 0 | 170 | 0 | area, projectile | Duplicator → Tempest |
| Field | 5 | 0.80 | 1 | 0 | 90 | 0 | area | Magnet → Event Horizon |
| Sawdisc | 16 | 1.65 | 1 | 3 | 10 | 440 | physical, projectile | Duplicator → Razortide |
| Cinderfall | 40 | 3.80 | 1 | 0 | 66 | 0 | fire, area | Might → Extinction |
| Frostbell | 10 | 2.60 | 1 | 0 | 125 | 0 | ice, area | Clock → Absolute Zero |
| Dart Fan | 10 | 1.10 | 1 | 1 | 5 | 420 | projectile, mobility | Clock → Storm Swallow |
| Nova Shard | 14 | 2.00 | 1 | 0 | 7 | 380 | projectile, area | Duplicator → Corona Burst |
| Cascade | 16 | 2.40 | 1 | 0 | 6 | 500 | projectile, physical | Might → Avalanche |

Draft weights: base 1.0; heavier picks 1.1–1.3 (Sawdisc/Cinderfall/Frostbell 1.3,
Cascade/Nova 1.2, Dart Fan 1.1). Owned weapons draft at ×1.4.

## Passives (per level, 5 levels)

| Passive | Stat | Flat/lv | %/lv | Tags |
|---|---|---:|---:|---|
| Vitality | max_health | +20 | — | — |
| Boots | speed | — | +8% | mobility |
| Clock | cdr | +0.10 | — | — |
| Might | damage | — | +15% | physical |
| Lens | area | — | +12% | area |
| Duplicator | projectiles | +1 | — | projectile |
| Magnet | pickup | — | +25% | — |
| Wisdom | xp | — | +12% | — |
| Plate | armour | +1 | — | physical |

## Synergy set bonuses

Owning ≥ 2 tagged items (weapons + passives) grants one `synergy_<tag>` source.
Recomputed on every `inventory_changed`.

| Tag | Threshold | Stat | Effect |
|---|---:|---|---|
| fire | 2 | mult_fire | +20% |
| ice | 2 | mult_ice | +20% |
| physical | 2 | damage | +12% |
| mobility | 2 | speed | +10% |
| area | 2 | area | +15% |
| projectile | 2 | projectiles | +1 |

## Enemies

| Enemy | HP | Speed | Contact | R | XP | Behaviour | Notes |
|---|---:|---:|---:|---:|---:|---|---|
| Chaser | 18 | 60 | 8 | 12 | 1 | chaser | Basic pressure |
| Swarmer | 9 | 110 | 5 | 8 | 1 | swarm | Pack ≥3 → +25% speed; alone → flee |
| Bruiser | 110 | 35 | 18 | 22 | 8 | chaser | Elite farm every 120 s |
| Shooter | 32 | 45 | 7 | 13 | 3 | kiter | Prefers 280 range |
| Exploder | 24 | 72 | 10 | 14 | 3 | chaser | Death blast 64 r, 1.5× dmg |
| Splitter | 44 | 55 | 10 | 17 | 5 | chaser | Two swarmers on death |
| Shielded | 35 (+35 sh) | 52 | 12 | 16 | 5 | shielder | Shield regen 40%/s after 1.5 s; pulses allies +aegis |
| Rift Hound | 48 | 68 | 14 | 16 | 4 | charger | 0.8 s windup then charge |
| Brood Oracle | 85 | 30 | 8 | 20 | 10 | summoner | Prefers 600; +2 swarmers / 5 s |
| Prism Stalker | 38 | 42 | 16 | 14 | 6 | sniper | Prefers 500; locks lane then fires |
| Grave Maw | 42 | 55 | 15 | 15 | 7 | burrower | Burrows 2.2 s untargetable; surfaces +0.4 s windup |
| Night Stalker | 28 | 95 | 12 | 13 | 4 | stalker | 0.35 s telegraph then a short dash |
| Still Spire | 55 | 0 | 14 | 16 | 6 | kiter | Stationary lane holder |
| Pale Mender | 40 | 48 | 6 | 14 | 5 | mender | Heals allies in 160 r every 4 s; prefers 320 |
| Ruin Colossus | 320 | 28 | 28 | 32 | 18 | chaser | Slow wall of HP |
| Veil Wraith | 48 | 70 | 16 | 14 | 9 | wraith | Fades untargetable 1.4 s then closes |
| Ash Spitter | 36 | 40 | 9 | 14 | 5 | kiter | Prefers 280; burn on contact |

Scaling (new spawns): HP × (1 + min(0.04 × elapsed_min, 1.2)), damage × (1 + min(0.02 × elapsed_min, 0.5)), speed × (1 + min(0.01 × elapsed_min, 0.3)). Wave batch and cadence use an additional × (1 + min(0.015 × elapsed_min, 0.35)) pressure multiplier. Elite: ×8 HP, ×1.4 dmg, ×1.5 size. Boss health, shields and speed use the same time scales. F6 stress probe fills to 1,500 actives.

## Status effects

| ID | Duration | Tick | Stacks | Effect |
|---|---:|---:|---|---|
| burn | 3.0 s | 0.5 s | INTENSITY ×5 | 5.0 DoT |
| poison | 4.0 s | 1.0 s | REFRESH ×1 | 3.0 DoT, scales with missing HP |
| chill | 2.0 s | 0.5 s | INTENSITY ×3 | speed ×0.65; converts to freeze at 3 stacks |
| freeze | 1.5 s | 0.5 s | REFRESH ×1 | speed ×0.10, DR 0.30 |
| shock | 3.0 s | 0.5 s | REFRESH ×1 | +25% vulnerability taken |
| bleed | 4.0 s | 0.5 s | INTENSITY ×5 | 4.0 DoT, scales missing HP |
| aegis | 2.0 s | 0.5 s | REFRESH ×1 | DR 0.25 (shielder ally pulse) |

## Guardians

| Stage | Title | Kind | HP | Shield | Ability CD (normal / enraged) | Spawn |
|---:|---|---|---:|---:|---|---|
| 0 | THE GATEKEEPER | charger | 650 | 0 | 4.0 / 2.5 s | 03:00 (scout), then +600 s cycle |
| 1 | THE PRISM WARDEN | shielded | 4,500 | 180 | 4.0 / 2.5 s | next 600 s step |
| 2 | THE BROODMOTHER | summoner | 18,000 | 0 | 4.0 / 2.5 s | next 600 s step |
| 3 | THE LAST COIL | bruiser | 45,000 | 0 | 4.0 / 2.5 s | next 600 s step; ends an expedition |
| 4 | THE REAVER | breaker | 62,000 | 4,000 | 4.0 / 2.4 s | Guardian Gauntlet finale-1; ascension cycles |
| 5 | THE CHRONARCH | wraith | 80,000 | 0 | 4.5 / 2.2 s | Guardian Gauntlet finale |

Movement speed: `36 + 5×stage`. Enrage below 50% HP shortens ability CD.
Guardian defeat: chest + 35 heal; stage 3 death wins the run.

## Relics (run modifiers)

| Source | ID | Effect |
|---|---|---|
| Beacon 1 | wayfarers_lens | area +20% |
| Beacon 2 | clockwork_heart | cdr +8 pp |
| Beacon 3 | echo_chamber | projectiles +1 |
| Altar (−15 HP) | bloodglass | damage +12% |

## Regions

| Region | Bias | Incursion (every 18 s from 00:25, ≤6) |
|---|---|---|
| Asterfall Ruins | balanced | Rift Hound (charger) |
| Ember Foundry | +15% damage, −15 max HP | Prism Stalker (sniper); 5 hazard patches 4 dps fire |
| Hollow Garden | +35% pickup radius | Brood Oracle (summoner); 5 slow patches ×0.55 |

Soft terrain: 5 patches/region, non-blocking. Asterfall/Hollow slow from the
patch's zone kind ×0.55–0.85; Ember = 4 dps fire (no slow).

## Seeded sub-zones

Each run seeds `RunManager.run_seed`; `world.gd` draws six 60° wedges
(shuffled zone kinds + spin) with named labels on the floor and atlas.
Landmark angles/radii jitter ±~8–12% inside safe bands; terrain placement and
radius are seeded. Zone kinds: GLASS FLATS / ASHEN RING / MOSS BASIN /
CRYSTAL VEIN / DROWNED SPAN / BONE CIRCUIT (slow ×0.7 / 1.0 / 0.65 / 0.75 /
0.55 / 0.85).

## Waves

Eras swap the whole roster every 600 s (notice: THE HORDE EVOLVES).

| Era | Wave | Window (s) | Interval | Batch | Formation | Types (weights) |
|---:|---|---|---:|---:|---|---|
| 0 | era0 | 0–600 | 0.90 | 5 | line | chaser 6, swarmer 3, bruiser 1, shooter 1 |
| 1 | era1 | 600–1200 | 0.55 | 9 | pincer | + exploder/splitter/shielded/stalker/spire |
| 2 | era2 | 1200–1800 | 0.40 | 13 | ring | + mender/colossus/burrower |
| 3 | era3 | 1800–2400 | 0.34 | 16 | pincer | + wraith/spitter/charger/sniper |
| 4 | era4 | 2400–3000 | 0.30 | 18 | ring | full roster incl. summoner |
| 5 | era5 | 3000–3600 | 0.26 | 20 | pincer | fast specialists, thin skirmishers dropped |
| 6 | era6 | 3600+ | 0.22 | 24 | ring | all 24 vessels |

Incursion specials (separate from waves): count `min(6, 1 + elapsed/120)`,
type = charger / sniper / summoner by region.

## Contracts & economy

- Contracts: start 40 kills, +35 each, cap 400. Reward `20+5n` gold, `12+3n` XP.
- Cache: 15 gold, 12 XP, 15 heal (single-use).
- Building vault cache: 60 gold, 40 XP, 25 heal, chest (once per room). Cinder Vault elite guard on first entry.
- Hidden legacy: room buff draft + 40 gold (once per room).
- Beacon: 30 gold, 25 heal + relic (10 uncontested s inside 90 r circle).
- Incidents every 90 s from 00:45, 18 s duration: swarmers / telegraphed strikes / gold.
- Meta shop: might/vitality/boots to Lv 20, cost formula in `MetaProgression.cost`.

## Damage pipeline constants

| Constant | Value | Where |
|---|---:|---|
| Crit base mult | 2.0 (bonus = crit_damage) | damage.gd |
| Base crit chance / bonus | 5% / +50% | stats.gd |
| Resist cap | 0.8 | damage.gd |
| Minimum hit | 1.0 | damage.gd |
| Shield regen | 40% max / s after 1.5 s idle | enemy_manager.gd |
| Separation scan | serial % 3, ≤12 items, 3×3 cells | enemy_ai.gd |
| Spatial hash cell / pad | 96 / 64 | spatial_hash.gd |

## Pack III — weapons

Same resolver as the main table (`WeaponData.at_level`), all composed through
`FiringPattern` × `ProjectileBehavior`. `projectile_count` feeds the pattern as a
count bonus, so Duplicator/Artificer/Glazier widen these too.

| Weapon | Dmg | CD (s) | Pattern | Behaviour | Pierce | R | Speed | Evolution (Lv8 + Lv5 passive) |
|---|---:|---:|---|---|---:|---:|---:|---|
| Scattergun | 9 | 1.25 | spread ×6, 70° | straight | 0 | 5 | 620 | Might → Gravebreaker |
| Chain Bolt | 16 | 1.50 | single | chain 260 px | 4 | 6 | 700 | Storm Sigil → Tesla Noose |
| Crescent | 14 | 1.30 | spread ×3, 44° | boomerang 0.42 | 2 | 9 | 480 | Clock → Waning Verdict |
| Ricochet Orb | 12 | 1.40 | single | bounce ×4 | 3 | 7 | 520 | Lens → Pinball Requiem |
| Carousel | 11 | 1.00 | radial ×5 | orbit r96 v3.2 | 6 | 7 | 300 | Magnet → Grand Carousel |
| Purging Halo | 13 | 0.75 | spiral ×4, +22°/cast | straight, burn | 2 | 6 | 520 | Ember Sigil → Sainted Halo |
| Railshot | 34 | 2.50 | single | straight | 8 | 7 | 1150 | Razor → Lance Cascade |
| Shard Storm | 10 | 2.20 | burst ×4 @ 0.11 s | split on expire ×3 | 1 | 6 | 460 | Rime Sigil → Glacier Requiem |

Damage types: Chain Bolt lightning, Shard Storm ice (+chill), Purging Halo fire
(+burn), the rest physical. Level 8 before evolution is roughly ×1.6–1.9 the
level-1 damage; evolved doubles it again and adds the signature bonus (10 extra
pierce for Railshot, +3 projectiles for Carousel and Halo, +2 for Crescent and
Shard Storm, +4 chain for Chain Bolt, extra knockback and area for Scattergun,
+2 pierce and area for Ricochet).

## Pack III — passives

| Passive | Stat | Flat/lv | %/lv | Max | Weight |
|---|---|---:|---:|---:|---:|
| Dead Eye | crit_damage | +0.15 | — | 5 | 1.0 |
| Overclock | cdr | +0.06 | — | 5 | 1.0 |
| Hoarder | gold | — | +10% | 5 | 1.0 |
| Iron Will | armour | +1.5 | — | 5 | 1.0 |
| Titan | max_health | +28 | — | 5 | 0.9 |
| Spirit Ward | resist_true | +0.08 | — | 5 | 0.9 |
| Void Pact | curse | +0.25 | — | 3 | 0.8 |

Curse runs through `RunManager` multipliers: +6% XP and +8% gold per point, plus
+4% enemy HP per point from `curse` in `enemy.activate`.

## Pack III — trinkets

| Trinket | Effect | Magnitude | Internal cooldown |
|---|---|---:|---:|
| Blink Ward | iframes on being hit | 0.7 s | 6.0 s |
| Bounty Mark | gold per elite kill | 6 | — |
| Frostbite | chill within 130 px of a corpse | — | — |
| Tremor Core | area damage around the player | 42 dmg / 165 r | 3.5 s |
| Second Wind | heal while under 34% vitality | 2.5 HP/s | — |
| Greed Engine | coin recovered as XP | 0.5× | — |

## Pack III — vessels

| Vessel | HP | Speed | Contact | R | XP | Behaviour |
|---|---:|---:|---:|---:|---:|---|
| Gloomjack | 30 | 88 | 12 | 13 | 3 | leaper: 0.4 s windup, 0.30 s leap dash (heading clamped to 5.0 like a charge), 78 r landing crater (0.6× dmg), 2.6 s CD |
| Coil Sentinel | 42 | 96 | 9 | 14 | 4 | orbiter: 175 r ring, 3-shot spread at 2.0 s, 0.7× dmg per bolt |
| Ash Mortar | 55 | 52 | 18 + burn | 16 | 5 | mortar: 430 r standoff band, 88 r shell at 0.9× dmg, 4.6 s CD, 1.5 s telegraph |
| Veil Shepherd | 70 | 70 | 7 | 17 | 5 | shepherd: advances to 300 r, applies `rally` (+35% speed, 3 s) and a pull to allies within 180 r every 4.5 s |
| Bone Breaker | 150 | 46 | 22 + bleed | 22 | 8 | breaker: 20 shield, 1.0 s windup, 155 r slam at 0.8× dmg under 300 r, 4.5 s CD |

All five inherit the standard scaling (HP × elapsed, elite ×8, boss ×60) and the
standard elite affix roll.

## Pack III — relics and keepers

| Relic | Awarded | Stat |
|---|---|---:|
| Reaver Heart | stage 1 guardian felled | +0.12 cdr |
| Mirror Scale | stage 2 guardian felled | +0.08 crit chance |
| Coil Eye | stage 3 guardian felled | +0.35 crit damage |

| Keeper | Awakens from | Starting weapon | Trade-off |
|---|---|---|---|
| Ravager | Crimson Vein clear (or 1,500 kills) | Scattergun | +0.40 crit damage, +2 armour, −6% speed |
| Glazier | Glass Expanse clear (or 6 caches) | Shard Storm | +1 projectile, −15% damage, −10 HP |

## Pack III — first knobs to turn if it plays too strong

1. `projectile_count` on the composed weapons: it now widens patterns, so
   Duplicator + Glazier + a spread weapon is the biggest single multiplier in the
   game. If builds trivialise era IV, cut the level-up count entries before
   touching base damage.
2. Tremor Core (42 dmg / 3.5 s, no cost) and Second Wind (2.5 HP/s) are the
   strongest trinkets; both are pure value with no downside.
3. Ash Mortars stack: three of them mark the same arena. If forts feel unfair,
   raise their standoff band or the 1.5 s telegraph rather than cutting damage.
4. The Reaver/Chronarch health (62k/80k) is scaled for gauntlet runs that already
   carry a level-8 board. They are not part of a normal expedition ladder.

## Pack IV — keepers are earned

A fresh save wakes only Ranger. Every other keeper is awakened by clearing the
ground that names them **or** by one single-run feat, so a sealed ground can never
lock the roster. `MILESTONE_UNLOCKS` in `meta_progression.gd` owns the feats and
each region file owns its own keeper, so the two cannot drift apart.

| Keeper | Starting weapon | Trade-off | Ground clear | Alternate feat |
|---|---|---|---|---|
| Ranger | Needle | balanced | — (starter) | — |
| Artificer | Sawdisc | +1 projectile, −10 HP | Clockwork Bastion | 100 kills in one run |
| Pathfinder | Seeker | +20% speed, −15 HP | Storm Crown | 250 kills in one run |
| Cinderkeeper | Flask | +20% fire, −10 HP | Sundered Dunes | 400 kills in one run |
| Frostweaver | Frost | +20% ice, −8% speed | Drowned Coast | win on Veteran or Nightmare |
| Warden | Orbit | +40 HP, −8% speed | Ember Foundry | 500 kills in one run |
| Arcanist | Lightning | +15% damage, −20 HP | Hollow Garden | survive ten minutes |
| Salvager | Sawdisc | +30% pickup, −15 HP | Sable Abyss | open 3 caches in one run |
| Archivist | Field | +20% area, −8% speed | Gilded Spire | discover a hidden room |
| Hexblade | Cascade | +12% crit chance, −10 HP | Rime Hollow | 750 kills in one run |
| Eclipse | Nova Shard | +25% damage, −30 HP | Bone Cathedral | win on Nightmare |
| Ravager | Scattergun | +40% crit damage, +2 armour, −6% speed | Crimson Vein | 1,500 kills in one run |
| Glazier | Shard Storm | +1 projectile, −15% damage, −10 HP | Glass Expanse | open 6 caches in one run |
| Fenwalker | Dart Fan | +25% pickup, +5% cdr, −10 HP | Fallow Marsh | open 5 caches in one run |
| Starwright | Cinderfall | +20% area, +18% xp, −12 HP | Comet Fields | survive five minutes |
| Veilbinder | Crescent | +20% physical, +4% crit chance, −10 HP | Veilwood | defeat 900 enemies in one run |
| Ashcaller | Purging Halo | +20% fire, +12% gold, −5% speed | Cinder Reach | discover two hidden rooms |
| Stormwright | Chain Bolt | +25% lightning, +4% cdr, −15 HP | Storm Citadel | defeat 1,200 enemies in one run |
| Brinelord | Ricochet Orb | +10% physical and true resistance, +1 armour, −8% speed | Tidal Maw | survive fifteen minutes |
| Polaris | Railshot | +25% true damage, +10% xp, −20 HP | Black Aurora | defeat 2,000 enemies in one run |

Every ground now awakens a keeper except Asterfall Ruins, the starter's home, so
there are nineteen earnable keepers in all.

**The deep seven cover the axes the starting twelve did not.** Fenwalker and
Stormwright are the first keepers to grant `cdr` at all, Starwright and Polaris are
the first to grant `xp`, Ashcaller the first to grant `gold`, Veilbinder the first
to scale `mult_physical` and the only keeper scaling `mult_true`; Brinelord is the
first to grant `resist_true`. That matters because the Observatory's blessing
upgrades and the new greater passives both lean on those axes, so a keeper pick can
now complement a build instead of only stacking damage.

**Pacing.** Four of the new keepers sit on the shallow half of the ladder (Fallow
Marsh one clear deep, Clockwork Bastion one clear deep, Storm Crown and Sundered
Dunes one clear each) and the last three behind the deep five (Veilwood, Cinder
Reach, Storm Citadel, Tidal Maw, Black Aurora). The milestone feats are deliberately
reachable without those grounds — 5 caches, five minutes survived, 900 kills, two
hidden rooms — so a player who cannot yet clear Crimson Vein can still earn every
keeper by playing the three open grounds well.

**Roster pacing.** On a fresh save the player flies Ranger through Asterfall, Ember
and Garden, which are the three open grounds. The first clear is always a keeper:
Ember → Warden or Garden → Arcanist. Dunes and Coast (both one clear deep) hand back
Cinderkeeper and Frostweaver, so an ordinary early run rebuilds the old starting
five within three or four expeditions — the roster feels gated, not amputated.

## Pack IV — greater passives (per level, 5 levels unless noted)

Every new card carries a **second stat** (`PassiveData.stat2`) at a lower rate than
a dedicated single-stat card, so one draft pick buys breadth instead of depth. The
primaries sit deliberately below the specialists: Boots is +8% speed, Ember Sigil
+10% fire, so Emberdrift (+7% fire, +2% speed) is never a strict upgrade of either.

| Passive | Primary | Secondary | Max | Tags |
|---|---|---|---:|---|
| Whetstone | `mult_physical` +9% | `crit_chance` +1% | 5 | physical |
| Voidglass | `mult_true` +7% | `crit_damage` +5% | 5 | — |
| Emberdrift | `mult_fire` +7% | `speed` +2% | 5 | fire, mobility |
| Frostbloom | `mult_ice` +7% | `area` +4% | 5 | ice, area |
| Stormlace | `mult_lightning` +7% | `cdr` +2% | 5 | — |
| Bulwark | `max_health` +10% | `armour` +0.4 | 5 | — |
| Perimeter | `pickup` +15% | `gold` +4% | 5 | — |
| Scholar | `xp` +10% | `cdr` +2% | 5 | — |
| Duelist | `crit_chance` +3% | `crit_damage` +6% | 5 | physical |
| Steadfast | `resist_physical` +4% | `resist_true` +4% | 5 | — |
| Prismatic Ward | `resist_ice` +4% | `resist_lightning` +4% | 5 | ice |
| Gambler's Ledger | `gold` +12% | `curse` +0.34 | 3 | — |

Two of these close real holes rather than adding more of the same: `mult_physical`
and `mult_true` had no draft card at all, so elemental-agnostic physical and
true-damage boards had no in-run scaling curve. Gambler's Ledger is the first draft
pick that raises Curse **with** an upside, mirroring Void Pact's pure-bargain shape.

**Tags and synergy.** Emberdrift carries `fire`+`mobility`, Frostbloom `ice`+`area`
and Prismatic Ward `ice`, so the two-item tag bonuses in `Synergy.BONUSES` are now
reachable from passives alone — two cards can trigger a set bonus without a weapon
of that element.

## Pack IV — trinkets (3 new)

| Trinket | Effect | Magnitude |
|---|---|---|
| Cinder Burst | Each kill burns vessels within 130 px of the corpse | — |
| Shrapnel | Each kill sprays damage into the same 130 px ring | 26 damage |
| Vital Echo | Each level-up heals you | 12 HP |

Cinder Burst and Shrapnel ride the same kill hook as Frostbite, so a full
kill-payload board (those three plus Life Siphon and Gold Fang) is legal but costs
three of the trinket slots plus both of the others — a real build commitment.

## Pack IV — first knobs to turn if it plays too strong

1. The first clear is now a guaranteed keeper, which is intended. If the roster
   unlocks too fast, raise a milestone threshold rather than removing the ground
   clear: the clear is the readable route and the feat is the safety valve.
2. Gambler's Ledger: `curse` +0.34 per rank to a cap of 3 is roughly one free
   difficulty step. If Curse drafts compound badly with `void_pact`, cut the gold
   side first (12% → 8%) before touching the cap.
3. Whetstone/Voidglass are the only scaling for their damage types; if physical or
   true boards run away, cut their primaries (9%/7%) before their secondaries.
4. Polaris (+25% true) and Voidglass (+7% true/level) are the only two sources of
   true damage in the game. If resistance stops mattering, cut Polaris first: a
   passive is opt-in, a keeper choice is a whole run.
5. Brinelord stacks +10% physical resist, +10% true resist and +1 armour for a
   single −8% speed, which is the cheapest defensive package on the roster. If the
   deep grounds feel free with him, raise the speed penalty before cutting the
   resistances, so he keeps his identity as the tank.
