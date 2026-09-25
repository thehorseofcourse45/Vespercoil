# Vespercoil — expansion: abilities, depths and legacies

Twenty additions layered on the existing pooled, component-based architecture.
No Area2Ds, no new runtime dependencies, and the save format stays
backward-compatible (version 1 → 2 migration). Numeric tables live in
`BALANCE.md`; regression rows in `REGRESSION.md`.

## Controls (rebindable)

| Input | Action |
|---|---|
| WASD / arrows / left stick | Move |
| Space / gamepad B | Active ability (`dash` action) |
| E / gamepad A | Interact |
| R / gamepad Y | Reroll the draft |
| M | Arena map |
| Escape / gamepad Start | Pause |
| F3 / F6 | Debug counters / 1,500-unit stress probe |

Bindings are registered at runtime by the `Controls` autoload
(`scripts/autoload/controls.gd`) and persisted to
`user://vespercoil_controls.cfg`. Rebind from Settings → press a key or button.

## Combat and build

1. **Active ability slot** (`scripts/systems/abilities.gd`). One power per run
   with a cooldown that benefits from half the cdr stat. Five powers: Phase Dash,
   Void Blink, Seismic Pulse, Ward Burst, Overcharge. Characters grant a
   signature active; the HUD shows title, readiness and the bound key.
2. **Draft banish and lock** (`scripts/ui/draft.gd`). Three banish charges
   remove a weapon or passive from the whole run's pool; one card can be locked
   across rerolls. Rerolls start at 3 + the `reroll` meta upgrade.
3. **Curse / risk bargains**. A `curse` stat raises gold (+8%/point), XP
   (+6%/point), wave batch size (+1.2/point) and enemy HP (+4%/point). Sources:
   the `curse` meta upgrade and an in-run draft bargain (two per run).
4. **Elemental reactions** (`scripts/status/reactions.gd`), fired when a status
   lands on a target already carrying a reactant. The enemy manager supplies the
   area portion via `reaction_triggered`.

   | Incoming | Requires | Reaction | Consumes | Burst |
   |---|---|---|---|---|
   | shock | freeze | SHATTER | freeze | 14 + 9% max HP, 120 radius |
   | burn | chill | STEAM BURST | chill | 8 + 4% max HP, 95 radius |
   | chill | burn | QUENCH | — | 6 + 3% max HP, 75 radius |
   | poison | burn | BLIGHT | — | 10 + 5% max HP, 85 radius |

   Reactions deal TRUE damage and count toward the Reactionary legacy.
5. **Weapon limit-break** (`scripts/weapons/weapon.gd`). Defeating any guardian
   past the Gatekeeper pushes one eligible level-8 weapon into hyper: +50%
   damage plus a per-weapon bonus. The HUD and end screen mark HYPER.
6. **Trinket slots** (`scripts/systems/trinkets.gd`, `scripts/data/trinket_data.gd`).
   Three exotic, run-scoped effects outside the flat/percent stat model: Life
   Siphon, Gold Fang, Bramble Heart, Frenzy Charm, Grave Bell, Ward Pulse.

## World and enemies

7. **Fourth region — SABLE ABYSS** (`world.gd`). A lightless trench with a
   darkness veil (drawn as fading bands beyond a short radius), +10% critical
   chance, its own floor art, and Warden Herald incursions. Regions became data
    resources and the roster grew to twenty grounds with an unlock ladder, a map
   select screen and map-awakened characters — see `REGIONS.md`.
8. **Dynamic weather** (`scripts/systems/weather.gd`). Every ~90–140 s a front
   lasts ~20 s: Ash Squall (foes quicken, you slow), Aurora Surge (+50% XP,
   +35% spawns), Blood Moon (+50% gold), Gloom Tide (foes quicken, dim light).
   Fronts apply a stats source, a spawn multiplier, and a screen tint.
9. **Elite affixes** (`enemy_manager.gd`). Elites roll one of splitting,
   frost aura, death nova, regenerating, or warded, drawn as a coloured ring.
10. **Destructible props** (`scripts/systems/props.gd`). 46 seeded crystals,
    urns and bones break under player fire or the horde, dropping XP, gold or
    healing and bursting nearby foes. A local grid bounds the per-shot query.
11. **New enemy families.** Warden Herald (buffer: rallies and heals nearby
    allies with the `rally` status) and Void Screamer (bullet-hell: fires
    8-projectile rings). Both join eras 2–4 and the abyssal incursion.

## Meta, modes and records

12. **Permanent Observatory tree.** Twenty-nine nodes across Offense, Survival, Expedition,
     Risk and the boss-gated BOSSES branch. Existing ranks remain valid; new paths add projectiles, area, elemental damage,
    resistances, knockback, pickup, gold, banishes, and an extra trinket slot. Purchases are
    profile-persistent and apply to future expeditions.
13. **Achievements and bestiary** (`scripts/autoload/achievements.gd`).
    Twelve legacies from persistent progress, each paying gold once, plus a
    per-kind kill tally shown in the Hall of Legacies.
14. **Daily seeded challenge.** A date-derived seed, pinned loadout, Veteran
    difficulty, and a locally stored best score and ascension.
15. **Guardian Gauntlet** (boss rush). All four guardians back-to-back on a
    compressed timer, no waves or incursions.
16. **Endless Ascent.** Defeating the Last Coil raises ascension instead of
    ending the run; enemy HP scales +60% per ascension and the guardian cycle
    re-arms.

## UX, accessibility and platform

17. **Build codes and richer summary.** `RunCode` encodes seed, character,
    region, weapons (level/evolved/hyper), passives and trinkets into a base64
    string; the end screen offers copy, and the title screen decodes or replays
    an imported code. The summary adds per-weapon damage bars, score, ascension
    and guardians.
18. **Accessibility / QoL** (`MetaProgression.settings`). Screen shake, damage
    numbers, auto-aim facing, pause-on-level-up, and a four-mode colourblind
    palette (`scripts/ui/palette.gd`).
19. **Rebindable controls and gamepad glyphs.** Action-based input replaces raw
    key polling; menus show the bound key.
20. **Steam bridge** (`scripts/systems/steam.gd`). A guarded wrapper that
    forwards achievement unlocks and stats to the Steam singleton when present
    and no-ops to local records otherwise. No SDK is bundled.

## Persistence

`MetaProgression` version 2 adds `settings`, `modes`, `progress` and
`achievements` sections. Version 1 (or 0) saves load with defaults for the new
keys; newer-than-known versions still disable saving to preserve the file.
Controller-only menu navigation remains unreviewed release work.
