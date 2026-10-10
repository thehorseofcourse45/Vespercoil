# Vespercoil — the twenty-five expedition grounds

Every ground is data. A map is one `RegionData` resource in `data/regions/`, listed
in catalogue order by `scripts/data/regions.gd`; that order is the atlas order and
the integer stored as `MetaProgression.region` and inside build codes. Ground definitions and their unlock paths live in `.tres` files; catalogue order is stable for save compatibility.

The world, the HUD, the spawn director and the soundtrack all read the selected
ground through the catalogue, so a ground is one definition of:

| Field | Meaning |
|---|---|
| `name`, `subtitle`, `perk` | Atlas card and title-screen copy |
| `color`, `floor` | Accent and base tile colour; the floor palette is derived from them |
| `motif` | Floor pattern stamped per 128 px tile (`observatory`, `foundry`, `garden`, `abyss`, `spire`, `rime`, `storm`, `ossuary`, `vein`, `mirror`, `mire`, `dunes`, `bastion`, `coast`, `comet`, `veilwood`, `cinder_reach`, `storm_citadel`, `tidal_maw`, `black_aurora`) |
| `hazard` | `""`, `burn`, `frost` or `storm` — the terrain patches' slow and damage |
| `veil` | Darkness-veil strength (0 open ground, 1 fully dark) |
| `incursion` | Enemy family that leads the periodic incursion raid |
| `bonus` | Stat bias applied on load, e.g. `{stat: damage, percent: 0.15}` |
| `unlock` | How the ground is opened (see below) |
| `unlock_hint` | Player-facing route shown on sealed atlas cards |
| `reward_character` / `reward_note` | Keeper awakened by clearing the ground |
| `music` / `pitch` | Which shipped track plays and its pitch scale |
| `danger` | Threat pips, 1–5 |

## The grounds

| # | Ground | Bias | Hazard | Veil | Incursion | Opened by |
|---:|---|---|---|---|---|---|
| 0 | Asterfall Ruins | none | — | — | Rift Hound (charger) | Default |
| 1 | Ember Foundry | +15% damage, −15 max HP | burning | — | Prism Stalker (sniper) | Default |
| 2 | Hollow Garden | +35% pickup radius | — | — | Brood Oracle (summoner) | Default |
| 3 | Sable Abyss | +10% critical chance | — | full | Veil Wraith (wraith) | Win any ground |
| 4 | Gilded Spire | +25% gold | — | — | Coil Sentinel (sentinel) | Clear Ember Foundry |
| 5 | Rime Hollow | +20% ice damage, −5% speed | freezing | — | Night Stalker (stalker) | Clear Hollow Garden |
| 6 | Storm Crown | +10% cooldown recovery | charged | — | Warden Herald (herald) | Clear Sable Abyss |
| 7 | Bone Cathedral | +30% experience | — | low (0.45) | Grave Maw (burrower) | Clear the Gilded Spire |
| 8 | Crimson Vein | +25% damage, −25 max HP | burning | — | Exploder | Clear five different grounds |
| 9 | Glass Expanse | +25% area of effect | — | — | Splitter (splitter) | Win six expeditions |
| 10 | Fallow Marsh | +20% pickup radius | slow | low | Mire Spore | Clear Hollow Garden |
| 11 | Sundered Dunes | +15% speed | burning | — | Dune Raider | Clear Ember Foundry |
| 12 | Clockwork Bastion | +12% cooldown recovery | charged | — | Gearling | Clear Gilded Spire |
| 13 | Drowned Coast | +25% gold | slow | medium | Brine Wraith | Clear Sable Abyss |
| 14 | Comet Fields | +10% critical chance | charged | low | Ash Meteor | Clear Glass Expanse |
| 15 | Veilwood | +8% experience | — | low | Briar Sentinel | Clear Comet Fields |
| 16 | Cinder Reach | +12% fire damage | burning | — | Flare Charger | Win eight expeditions |
| 17 | Storm Citadel | +10% cooldown recovery | charged | low | Storm Caller | Clear Cinder Reach |
| 18 | Tidal Maw | +20% pickup radius | — | medium | Tide Sniper | Clear Storm Citadel |
| 19 | Black Aurora | +10% critical chance | freezing | high | Eclipse Mender | Win twelve expeditions |
| 20 | Saltbound Flats | +12% pickup radius | — | low | Halite Ram | Clear the Black Aurora |
| 21 | Amberhold | +10% experience | burning | low | Resin Warden | Clear the Tidal Maw |
| 22 | The Vesperine | +8% cooldown recovery | — | medium | Chime Wraith | Clear the Veilwood |
| 23 | Lodestone Fields | +15% lightning damage | charged | low | Magnet Core | Clear twenty-one different grounds |
| 24 | The Red Chancery | +12% area of effect | — | high | Quill Lash | Win sixteen expeditions |

The first three grounds are open on a fresh save. Everything beyond them is
gated by chained clears or aggregate goals. The final five form a second endgame
chain: Comet Fields → Veilwood, eight wins → Cinder Reach, then Storm Citadel →
Tidal Maw, with twelve wins opening Black Aurora. The deep five beyond even that
(Saltbound Flats, Amberhold, The Vesperine, Lodestone Fields, The Red Chancery)
open from three endgame clears, twenty-one distinct clears and sixteen wins.
Unlock state is derived, never
persisted as a flag: `MetaProgression.region_unlocked()` evaluates the rule
against recorded progress, so clears recorded by any route — expedition, daily,
gauntlet or endless — count immediately.

## Keepers

Only **Ranger** is awake on a fresh save. Clearing any other ground on a **won**
run awakens the keeper that ground remembers and records the clear under
`progress.regions_cleared`. A loss records nothing. Each region file owns the
pairing in its own `reward_character`, so the atlas card, the clear screen and
`bank_run` cannot drift apart about which ground wakes whom.

| Ground | Awakens |
|---|---|
| Fallow Marsh | Fenwalker |
| Clockwork Bastion | Artificer |
| Storm Crown | Pathfinder |
| Sundered Dunes | Cinderkeeper |
| Drowned Coast | Frostweaver |
| Ember Foundry | Warden |
| Hollow Garden | Arcanist |
| Sable Abyss | Salvager |
| Gilded Spire | Archivist |
| Rime Hollow | Hexblade |
| Bone Cathedral | Eclipse |
| Crimson Vein | Ravager |
| Glass Expanse | Glazier |
| Comet Fields | Starwright |
| Veilwood | Veilbinder |
| Cinder Reach | Ashcaller |
| Storm Citadel | Stormwright |
| Tidal Maw | Brinelord |
| Black Aurora | Polaris |
| Saltbound Flats | Saltsworn |
| Amberhold | Amberkeeper |
| The Vesperine | Bellsinger |
| Lodestone Fields | Lodestar |
| The Red Chancery | Quillkeeper |

Every ground awakens a keeper except Asterfall Ruins, which is the starter's home:
Ranger is the one keeper nobody has to earn. The five deep grounds (Veilwood,
Cinder Reach, Storm Citadel, Tidal Maw, Black Aurora) sit at the top of the atlas
ladder, so the last keepers arrive alongside the hardest content. The five
grounds beyond them (Saltbound Flats, Amberhold, The Vesperine, Lodestone Fields
and The Red Chancery) complete the roster: each awakens its own keeper --
Saltsworn, Amberkeeper, Bellsinger, Lodestar and Quillkeeper.

Clearing the ground is the only route: a keeper wakes exactly when its atlas card
is cleared, and no stat feat or difficulty win moves the roster. There is no
second unlock table; `keeper_unlock_hint()` in `meta_progression.gd` renders each
sealed keeper's ground for the **Keepers** screen in the Library.

## The Celestial Atlas

`scripts/ui/region_select.gd` is the map-selection screen, opened from the title
screen's **GROUND** button. It draws ten cards at a time in a 5×2 grid, with page controls for the remaining ten:

- a procedural preview built from the ground's own palette, motif, hazard and veil;
- the ground bias, threat pips and clear count, or a padlock with its unlock
  route and the keeper it awakens when sealed;
- a detail bar for the highlighted ground — threat, hazard kind, subtitle, perk,
  bias and status.

Mouse click or `←` `→` `↑` `↓` / `WASD` to move, `Enter` / `Space` to begin,
`Esc` to return. Sealed cards refuse selection and flash red; the ground is never
launched from a locked card.

## Save format

`MetaProgression.VERSION` is 3. It stays backward-compatible: version 0 (legacy
`coins`), 1 and 2 saves load and migrate losslessly. Cleared grounds persist in
the existing `progress` section under `regions_cleared`, so no new section is
needed. Region selection itself still lasts for the application session; the
unlock ladder is what persists.

## Capture

`tests/ground_capture.gd` renders the atlas (ten cards on the first page, then the
remaining ten) plus the new grounds to `preview-atlas*.png` /
`preview-ground-*.png`. It needs a graphics backend, not `--headless`.
# Regional encounters and guardian drops

Every ground has five exclusive enemy families that arrive in its periodic incursion raids, alongside the shared chaser, swarmer, bruiser, and shooter that run the ordinary waves. The deep five go one step further: each ends its roster with a sixth family, a Seeker whose orb hunts the player. The first guardian at three minutes is specific to the selected ground and uses one of five attack patterns. Its gold diamond drop pulls toward the player and grants a boss-only reward; regular level-up drafts cannot offer these before the guardian is defeated. The first three grounds yield Star Lance, Cinder Forge, or Thorn Bloom if a weapon slot is open; otherwise they yield their unique relic. The other seventeen grounds each yield a unique relic. The atlas shows each ground's enemies, guardian, and boss drop. The five new guardians also unlock permanent BOSSES-branch Observatory upgrades when defeated.
