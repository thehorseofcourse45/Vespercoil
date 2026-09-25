# Vespercoil — content reference (Pack III)

Everything below ships as data plus one catalogue line. No new systems were
introduced: the pack spends the extension points that already existed (weapon
composition, passives, trinket hooks, enemy AI behaviours, wave eras, guardian
ladder, relics, keepers).

Totals today: **20 weapons · 38 passives · 15 trinkets · 75 vessels · 6 guardians ·
7 wave eras · 20 keepers · 20 grounds.** (The pack below shipped the lower
counts; the catalogue has grown since, and section 7 lists what Pack IV added.)

---

## 1. Weapons (8 new)

Each is a `WeaponData` in `data/weapons/` with a `FiringPattern` ×
`ProjectileBehavior` pair, so it is composed rather than scripted. Icons live in
`art/icons/`.

| Weapon | Damage | Cooldown | Pattern | Behaviour | Evolution (Lv8 + Lv5 passive) |
|---|---:|---:|---|---|---|
| Scattergun | 9.0 | 1.25 s | spread ×6, 70° | straight | Might → **Gravebreaker** |
| Chain Bolt | 16.0 | 1.5 s | single | chain 260 px | Storm Sigil → **Tesla Noose** |
| Crescent | 14.0 | 1.3 s | spread ×3, 44° | boomerang 0.42 | Clock → **Waning Verdict** |
| Ricochet Orb | 12.0 | 1.4 s | single | bounce ×4 | Lens → **Pinball Requiem** |
| Carousel | 11.0 | 1.0 s | radial ×5 | orbit r96, v3.2 | Magnet → **Grand Carousel** |
| Purging Halo | 13.0 | 0.75 s | spiral ×4 (+22°/cast) | straight, burn | Ember Sigil → **Sainted Halo** |
| Railshot | 34.0 | 2.5 s | single | straight, pierce 8 | Razor → **Lance Cascade** |
| Shard Storm | 10.0 | 2.2 s | burst ×4 @ 0.11 s | split on expire ×3 | Rime Sigil → **Glacier Requiem** |

Level-ups add damage every level plus one of: extra fan projectiles (spread
patterns), extra radial/spiral projectiles, extra burst shots, extra pierce,
larger area, shorter cooldown or more knockback. Evolutions double damage and add
a signature bonus (pierce, projectile count, duration, area or knockback);
limit-break hypers add a smaller second bonus.

**Composed weapons now scale with the projectile stat.** `FiringPattern.directions`
and `burst_delays` take an optional count bonus, and `composed_weapon` feeds them
`projectile_count - 1`. Duplicator, the Artificer and the Glazier keeper therefore
widen *every* patterned weapon, which is what "projectile" has always meant for
the scripted weapons.

## 2. Passives (7 new)

All plug into stats the resolver already carries (`StatsComponent.base`); the
content suite asserts that mapping, so a typo cannot ship silently.

| Passive | Stat | Per level | Max |
|---|---|---:|---:|
| Dead Eye | `crit_damage` | +0.15 flat | 5 |
| Overclock | `cdr` | +0.06 flat | 5 |
| Hoarder | `gold` | +10% | 5 |
| Iron Will | `armour` | +1.5 flat | 5 |
| Titan | `max_health` | +28 flat | 5 |
| Spirit Ward | `resist_true` | +0.08 flat | 5 |
| Void Pact | `curse` | +0.25 flat | 3 |

Void Pact is the odd one out on purpose: it takes the curse bargain as a draft
pick, trading a thicker horde for richer rewards, and caps at 3 so it cannot
replace the meta upgrade.

## 3. Trinkets (6 new)

Reactive effects live in `scripts/systems/trinkets.gd`, which exposes
`EFFECTS` — the coverage list the suite checks, so no catalogue entry can be a
dead stat stick.

| Trinket | Effect | Magnitude |
|---|---|---|
| Blink Ward | Taking a hit phases you out (6 s internal cooldown) | 0.7 s iframes |
| Bounty Mark | Every elite felled pays gold | 6 gold |
| Frostbite | Each kill chills vessels within 130 px of the corpse | — |
| Tremor Core | Ground shatters for area damage every 3.5 s | 42 damage, 165 px |
| Second Wind | Below 34% vitality you knit back together | 2.5 HP/s |
| Greed Engine | Recovered coin is read as experience | 0.5× as XP |

## 4. Vessels (5 new)

Original vector art in `art/`, data in `data/enemies/`, scenes in
`scenes/enemies/`, behaviours in `scripts/systems/enemy_ai.gd`.

| Vessel | HP | Speed | Damage | XP | Behaviour |
|---|---:|---:|---:|---:|---|
| Gloomjack | 30 | 88 | 12 | 3 | **leaper** — winds up, sails in, cracks the ground on landing |
| Coil Sentinel | 42 | 96 | 9 | 4 | **orbiter** — holds a 175 px ring and answers with a 3-shot spread |
| Ash Mortar | 55 | 52 | 18 + burn | 5 | **mortar** — keeps ~430 px and marks the player's ground with a 88 px shell |
| Veil Shepherd | 70 | 70 | 7 | 5 | **shepherd** — advances and rallies the flock with `rally` plus a pull |
| Bone Breaker | 150 | 46 | 22 + bleed | 8 | **breaker** — armoured, 1.0 s windup, 155 px ground slam |

Wave roster: Gloomjack and Coil Sentinel from era I, Ash Mortar from era II,
Veil Shepherd and Bone Breaker from era III. All five appear in era IV and VI,
and in the era V specialist wave.

## 5. Guardians (2 new)

| Guardian | Kind | Health | Shield | Stage | Attack cycle |
|---|---|---:|---:|---:|---|
| The Reaver | breaker | 62,000 | 4,000 | 4 | shock ring + two slams, spawns a Bone Breaker when enraged |
| The Chronarch | wraith | 80,000 | 0 | 5 | 14–22 bolt spiral, four-to-six marked frost rings, chills the player, summons wraiths |

The expedition ladder still ends with the Last Coil (stage 3): `spawn_guardian`
takes an explicit `final` flag and the schedule passes it only for stage 3, so
**nothing changes about how a normal run ends**. The two new guardians close the
Guardian Gauntlet (now six fights, Chronarch last) and appear in Endless Ascent
cycles, where a full ladder clear triggers the next ascension.

## 6. Wave eras (2 new)

| Era | Window | Character |
|---|---|---|
| V | 3000–3600 s | pincer formations of fast specialists, thin skirmishers dropped |
| VI | 3600 s + | 24-vessel roster, 0.22 s interval, 24 per batch, ring formations |

Era VI is deliberately open-ended: it exists so endless ascensions keep
escalating instead of plateauing at era IV.

## 7. Relics (3 new)

Felling a guardian now hands over its own relic in ladder order — stage 1 Reaver
Heart (`+0.12 cdr`), stage 2 Mirror Scale (`+0.08 crit chance`), stage 3 Coil Eye
(`+0.35 crit damage`). Beacon relics are untouched, so the three-beacon, one-altar
economy is unchanged.

## 8. Keepers (2 new)

Both are gated behind the deepest grounds and both keep the legacy skill route.

| Keeper | Awakens from | Loadout | Trade-off |
|---|---|---|---|
| Ravager | Clear Crimson Vein (or 1,500 kills in one run) | Scattergun | +40% crit damage, +2 armour, −6% speed |
| Glazier | Clear Glass Expanse (or 6 caches in one run) | Shard Storm | +1 projectile, −15% damage, −10 HP |

Unlock routing now reads the region file itself: a won run hands the cleared
ground's `reward_character` to `MetaProgression.awaken()`, which is why clearing
any mode counts immediately. Only Ranger starts awake. The twelve map-gated
keepers and their alternate milestones are tabulated in `REGIONS.md`; the code
owns the milestone table and the region files own the pairing, so there is no
second copy to drift.

---

## Where to add the twenty-first weapon

1. Drop `data/weapons/<id>.tres` (copy a sibling) and `art/icons/<id>.svg`.
2. Append `<id>` to the weapon list in `scripts/systems/arsenal.gd`.
3. Give it an evolution passive that already exists at Lv5, or add a passive.
4. Run `tests/vault.gd`: it resolves every catalogue weapon at Lv8, proves it
   lands damage in a live arena and checks the icon exists.

Enemies additionally need `data/enemies/<id>.tres`, a scene in
`scenes/enemies/`, a line in `EnemyManager.TYPES`, a behaviour branch in
`EnemyAI.step` and an appearance in at least one wave file.

## Verification

`tests/vault.gd` is the gate for this pack: 20 weapons resolve at Lv8 and each
new one lands damage; 38 passives map to real stats (every two-stat card is
proved to move both of them); 15 trinkets have live effects; 5 behaviours reach
their own state machines (impacts, marked ground and rally are asserted, not
assumed); the era V/VI schedule covers all 24 vessels; six guardians each produce
an attack; three guardian relics land on the right stats; and both keepers
unlock, build and keep their loadouts.

All headless suites pass. One latent bug was found and fixed on the way:
`StatusEffectComponent.tick` wrote back to a stale index when a damage tick or an
elemental reaction killed the carrier mid-loop (which recycled it and cleared the
pool), producing an invalid-index error. The loop now re-checks bounds and only
writes back the instance it is still holding.

## 7. Pack IV — keeper gating and a deeper draft

### Keepers are earned now

A fresh save holds exactly one keeper, **Ranger**. The other nineteen are awakened
by clearing the ground that names them (each region file's `reward_character`) or
by one single-run feat. `MILESTONE_UNLOCKS` in `meta_progression.gd` owns the feat
table and `bank_run` evaluates it, so the unlock routes are one list instead of an
if-chain. The Library gained a **Keepers** screen that lists the awakened roster
and prints the route for every sealed keeper.

Routes and the full table: `REGIONS.md`. Balance and the trade-offs: `BALANCE.md`.

### Seven more keepers, one per deep ground

Every ground awakens a keeper except Asterfall Ruins, the starter's home. The
seven added here are tied to the grounds that previously gave nothing: Fallow
Marsh, Comet Fields, Veilwood, Cinder Reach, Storm Citadel, Tidal Maw and Black
Aurora. Each ships a portrait in `art/characters/`, a starting weapon from the pool
the starting twelve did not use, and a stat identity that covers an axis the
starting twelve left empty.

| Keeper | Ground | Weapon | Signature | Power |
|---|---|---|---|---|
| Fenwalker | Fallow Marsh | Dart Fan | +25% pickup, +5% cdr | Ward Burst |
| Starwright | Comet Fields | Cinderfall | +20% area, +18% xp | Starfall |
| Veilbinder | Veilwood | Crescent | +20% physical, +4% crit | Seismic Pulse |
| Ashcaller | Cinder Reach | Purging Halo | +20% fire, +12% gold | Overcharge |
| Stormwright | Storm Citadel | Chain Bolt | +25% lightning, +4% cdr | Phase Dash |
| Brinelord | Tidal Maw | Ricochet Orb | +10% physical+true resist, +1 armour | Tidepull |
| Polaris | Black Aurora | Railshot | +25% true damage, +10% xp | Void Blink |

Two of the six powers are new (`Starfall`, `Tidepull`); the rest reuse an existing
signature, which is already how the starting twelve are built (Artificer and
Hexblade share Seismic Pulse).

**Adding a keeper** needs five things: a row in `NEW_UNLOCKS`, a row in
`MILESTONE_UNLOCKS` so the alternate route exists, a `reward_character` on its
ground, an entry in `main.gd`'s `STARTING_WEAPONS` and `abilities.gd`'s
`CHARACTER_ABILITIES`, a line in `hud.gd`'s `character_description`, a branch in
`MetaProgression.apply()` and a portrait. `keeper_unlocks.gd` fails if any of those
is missing, and its `ROSTER_STATS` table must gain the keeper's signature stat.

> **Watch the source key.** `StatsComponent` stores one entry per *source name*,
so a keeper granting two stats must use two source names. Reusing `character`
for both keeps only the last one and drops the first silently — no error, no
warning. This bit the first draft of all seven keepers above.

### Twelve greater passives (`PassiveData.stat2`)

The draft's passives were all single-stat, so every pick was depth in one number.
`PassiveData` gained an optional second stat (`stat2`, `flat2_per_level`,
`percent2_per_level`) and `Arsenal.acquire_passive` writes it through a second
stat source. A plain card leaves `stat2` empty and behaves exactly as before.

The twelve new cards are deliberately **below** the specialist rates on their
primary stat, so they cannot simply replace Boots, Ember Sigil or Vigilance:

| Passive | Primary | Secondary | Max |
|---|---|---|---:|
| Whetstone | `mult_physical` +9% | `crit_chance` +1% | 5 |
| Voidglass | `mult_true` +7% | `crit_damage` +5% | 5 |
| Emberdrift | `mult_fire` +7% | `speed` +2% | 5 |
| Frostbloom | `mult_ice` +7% | `area` +4% | 5 |
| Stormlace | `mult_lightning` +7% | `cdr` +2% | 5 |
| Bulwark | `max_health` +10% | `armour` +0.4 | 5 |
| Perimeter | `pickup` +15% | `gold` +4% | 5 |
| Scholar | `xp` +10% | `cdr` +2% | 5 |
| Duelist | `crit_chance` +3% | `crit_damage` +6% | 5 |
| Steadfast | `resist_physical` +4% | `resist_true` +4% | 5 |
| Prismatic Ward | `resist_ice` +4% | `resist_lightning` +4% | 5 |
| Gambler's Ledger | `gold` +12% | `curse` +0.34 | 3 |

Whetstone and Voidglass are the only draft cards that scale `mult_physical` and
`mult_true` at all, so physical-agnostic and true-damage builds finally have an
in-run growth curve. Icons live in `art/icons/` like every other passive.

### Three reactive trinkets

| Trinket | Effect | Magnitude |
|---|---|---|
| Cinder Burst | Each kill burns vessels within 130 px of the corpse | — |
| Shrapnel | Each kill sprays damage into the same 130 px ring | 26 damage |
| Vital Echo | Each level-up heals you | 12 HP |

All three hook the signals the trinket system already listens to and are listed in
`Trinkets.EFFECTS`, which the suite checks so no catalogue entry can be a dead
stat stick.

### Where to add the thirty-ninth passive or sixteenth trinket

1. Drop `data/passives/<id>.tres` (copy a sibling) and `art/icons/<id>.svg`.
2. Append `<id>` to the passive list in `scripts/systems/arsenal.gd`.
3. Use stat names `StatsComponent.base` already carries. If the card wants two
   stats, set `stat2` and its per-level fields; leave it empty for a plain card.
4. Run `tests/vault.gd`: it asserts every passive names real stats, ships an
   icon, is offered by a fresh draft, and that a two-stat card moves both numbers.

A trinket needs `data/trinkets/<id>.tres`, a real implementation plus a line in
`scripts/systems/trinkets.gd`'s `EFFECTS`, and a line in the arsenal catalogue.

## Honest gaps

- The two new guardians are **not** part of a normal expedition's ladder; they
  live in the gauntlet and in ascension cycles. That is deliberate (an expedition
  still ends with the Last Coil) but it does mean a plain run never meets them.
- Eras V and VI are only reachable in Endless Ascent, since an expedition ends
  around 30–35 minutes.
- Enemy and weapon numbers are structurally verified but not playtested for feel;
  `BALANCE.md` holds the numbers to tune first.
- No new audio assets: the new content reuses the shipped tracks and effects.
