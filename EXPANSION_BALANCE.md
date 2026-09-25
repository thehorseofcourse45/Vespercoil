# Vespercoil — expansion balance tables

Numeric baseline for the additions in `EXPANSION.md`. Read the resources and
scripts, not this file, when tuning. Extends `BALANCE.md`.

## New enemies

| Enemy | HP | Speed | Contact | R | XP | Behaviour | Notes |
|---|---:|---:|---:|---:|---:|---|---|
| Warden Herald | 70 | 55 | 11 | 16 | 8 | buffer | Prefers 220; every 3.5 s rallies allies in 180 r (+35% speed, 3 s) and heals them 6% max |
| Void Screamer | 30 | 62 | 8 | 14 | 6 | screamer | Prefers 340; 8-projectile rings every 3.4 s within 720 |

Both join era 2 (herald), era 3 (herald + screamer) and era 4 (full roster).
Sable Abyss incursions spawn Wardens.

## Status additions

| ID | Duration | Tick | Stacks | Effect |
|---|---:|---:|---|---|
| rally | 3.0 s | 0.5 s | REFRESH ×1 | speed ×1.35 (Herald ally buff) |

## Elemental reactions

| Incoming | Requires | Reaction | Consumes | Burst (flat + % max HP) | Radius |
|---|---|---|---|---|---:|
| shock | freeze | SHATTER | freeze | 14 + 9% | 120 |
| burn | chill | STEAM BURST | chill | 8 + 4% | 95 |
| chill | burn | QUENCH | — | 6 + 3% | 75 |
| poison | burn | BLIGHT | — | 10 + 5% | 85 |

Reaction damage is TRUE and the area hit deals 50% of the burst to other foes in
radius.

## Elite affixes

| Affix | Effect |
|---|---|
| splitting | Death spawns three swarmers |
| frost_aura | Applies chill to the player within 150 r each second |
| death_nova | Telegraphs a 96 r, 22 damage strike on death |
| regenerating | Heals 1.2% max HP per second |
| warded | +30% max HP as shield on spawn |

Elites (non-boss) roll one affix at spawn.

## Trinkets (three slots)

| Trinket | Effect |
|---|---|
| Life Siphon | Heal 0.4 per kill |
| Gold Fang | 6% chance of bonus gold per kill |
| Bramble Heart | On being struck, 22 TRUE damage to foes within 190 r |
| Frenzy Charm | On kill, +28% speed for 2.5 s |
| Grave Bell | On level-up, 26 TRUE damage nova within 220 r |
| Ward Pulse | Every 8 s apply aegis (25% DR, 2 s) |

## Weather fronts

| Front | Duration | Enemy speed | Spawn | Player effect |
|---|---:|---:|---:|---|
| Ash Squall | 22 s | ×1.18 | ×1.10 | −12% speed |
| Aurora Surge | 20 s | ×1.00 | ×1.35 | +50% XP |
| Blood Moon | 24 s | ×1.05 | ×1.15 | +50% gold |
| Gloom Tide | 20 s | ×1.25 | ×0.90 | — |

First front at 45–75 s, then every ≈90–130 s.

## Curse

Each curse point: +8% gold, +6% XP, +1.2 wave batch, +4% enemy HP.
Sources: the `curse` meta upgrade (max 5) and up to two draft bargains per run.

## Run-time pressure

New enemies ramp with elapsed run time: HP +4% per minute (max +120%), damage +2% per minute (max +50%), speed +1% per minute (max +30%), and ordinary wave pressure +1.5% per minute (max +35%). Boss health, shields and speed use the same time scales.

## Permanent upgrade tree

| Branch | Node | Max | Requires | Effect per level |
|---|---|---:|---|---|
| Offense | might | 20 | — | +3% damage |
| Offense | precision | 5 | Might 5 | +1.5% critical chance |
| Offense | execution | 5 | Precision 2 | +8% critical damage |
| Offense | volley | 1 | Might 10 | +1 projectile |
| Offense | area | 3 | Might 5 | +10% weapon area |
| Offense | fire | 3 | Precision 2 | +10% fire damage |
| Offense | ice | 3 | Precision 2 | +10% ice damage |
| Offense | lightning | 3 | Precision 2 | +10% lightning damage |
| Offense | knockback | 3 | Execution 2 | +15% weapon knockback |
| Survival | vitality | 20 | — | +5 max HP |
| Survival | aegis | 5 | Vitality 5 | +1 armour |
| Survival | revive | 2 | Aegis 2 | +1 revival per run (60% HP, 3 s i-frames) |
| Survival | physical_ward | 3 | Vitality 5 | +8% physical resistance |
| Survival | fire_ward | 3 | Aegis 2 | +8% fire resistance |
| Expedition | boots | 20 | — | +2% speed |
| Expedition | haste | 5 | Boots 5 | +3% cooldown recovery |
| Expedition | wisdom | 5 | Boots 2 | +8% experience |
| Expedition | reroll | 5 | Boots 1 | +1 draft reroll |
| Expedition | reserve | 5 | Boots 3 | +40 starting gold |
| Expedition | pickup | 3 | Boots 2 | +20% pickup radius |
| Expedition | gold | 3 | Wisdom 2 | +10% gold |
| Expedition | banish | 2 | Reroll 2 | +1 starting banish charge |
| Expedition | trinket_slot | 1 | Reserve 3 | +1 trinket slot |
| Risk | curse | 5 | — | +1 curse |

Cost is `50 × 1.6^level`. Purchases are profile-persistent and apply to future expeditions. Existing non-zero ranks remain usable after the tree changes.

## Guardian limit-break

Any guardian past stage 0 grants one eligible level-8 weapon hyper: +50% damage
plus a per-weapon bonus (extra projectiles, pierce, or area).

## Run modes

| Mode | Rules |
|---|---|
| Expedition | Standard 30-minute run |
| Daily Challenge | Date-derived seed, pinned loadout, Veteran difficulty, stored best score |
| Guardian Gauntlet | Four guardians back-to-back, 8 s between spawns, no waves |
| Endless Ascent | Ascension after each Last Coil; enemy HP +60% per ascension, guardian cycle re-arms |
