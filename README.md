# Vespercoil — The Shattered Expeditions

Open `project.godot` in Godot 4.7.2 and press F5. Choose a ground, character and
difficulty, then **Begin Expedition**. Everything needed to play is included locally.
Settings offers six window sizes from 1280×720 to 3840×2160; unavailable sizes are disabled for the current display.

- Twenty expedition grounds, each defined by one data file: its own floor motif,
  hazard or darkness veil, enemy incursion, stat bias, soundtrack pitch and
  threat rating. Asterfall Ruins, Ember Foundry and Hollow Garden are open from
  the start; the other seventeen open by clearing grounds or accumulating wins.
- The Celestial Atlas, a full-screen map select: ten cards per page with procedural
  previews, live bias readouts, padlocked routes for sealed grounds and the
  keeper each one awakens.
- Twenty weapons, six slots per run, all with eight levels and evolutions. The
  newest eight are composed rather than scripted: Scattergun, Chain Bolt,
  Crescent, Ricochet Orb, Carousel, Purging Halo, Railshot and Shard Storm.
  Extra projectiles from gear now widen every patterned weapon.
- Sixty-four enemy types, including charging Rift Hounds, summoning Brood
  Oracles, aimed-shot Prism Stalkers, rallying Warden Heralds and Void Screamers,
  plus Gloomjacks that leap and crack the ground, Coil Sentinels that circle and
  volley, Ash Mortars that shell your position, Veil Shepherds that drive the
  flock and armoured Bone Breakers that slam. Original vector creature artwork
  replaces plain shapes.
- Twenty character loadouts, each with its own in-game sprite, setup portrait and
  signature power. Only Ranger starts awake, and every other keeper is awakened by
  clearing the ground that remembers them: Fenwalker (Fallow Marsh), Artificer
  (Clockwork Bastion), Pathfinder (Storm Crown), Cinderkeeper (Sundered Dunes),
  Frostweaver (Drowned Coast), Warden (Ember Foundry), Arcanist (Hollow Garden),
  Salvager (Sable Abyss), Archivist (Gilded Spire), Hexblade (Rime Hollow), Eclipse
  (Bone Cathedral), Ravager (Crimson Vein), Glazier (Glass Expanse), Starwright
  (Comet Fields), Veilbinder (Veilwood), Ashcaller (Cinder Reach), Stormwright
  (Storm Citadel), Brinelord (Tidal Maw) and Polaris (Black Aurora). Each one also
  keeps a single-run feat as an alternate route (100–2,000 kills, five or fifteen
  minutes survived, three to six caches, one or two hidden rooms, a Veteran or
  Nightmare win), so no sealed ground can lock you out of the roster. The Library's
  Keepers screen lists the roster and the route for every sealed keeper.
- Thirty-eight level-up passives. Beside the single-stat cards sit the greater
  two-stat passives — Whetstone, Voidglass, Emberdrift, Frostbloom, Stormlace,
  Bulwark, Perimeter, Scholar, Duelist, Steadfast, Prismatic Ward and Gambler's
  Ledger — which spend one draft pick on two stats at a lower rate, so they widen
  a build without replacing the specialist cards. Physical and elemental wards,
  Prospector for gold, Dead Eye, Overclock, Hoarder, Iron Will, Titan, Spirit Ward
  and Void Pact, which takes the curse bargain as a draft pick, all remain.
- Wayfarer, Veteran and Nightmare difficulties scale enemy health, incoming
  damage and wave pace, with higher gold rewards on harder runs.
- Six supply caches, three capturable beacons, a Bloodglass altar, two relay defenses and two elite hunts per run.
  Landmarks, terrain and six named sub-zones are seeded per run across an arena
  eight times wider than the original layout; use M to plan longer routes.
- Seven wave eras swap the roster every 10 minutes (THE HORDE EVOLVES); eras V
  and VI carry long and endless runs.
- Escalating kill contracts and three timed incidents: Rift Breach, Cinder Rain,
  Golden Convergence.
- Six guardians: Gatekeeper at 03:00, Prism Warden at 10:00, Broodmother at 20:00,
  Last Coil at 30:00, then The Reaver and The Chronarch in the Guardian Gauntlet
  and in Endless Ascent cycles. Each has attacks and enrages below half health.
  Defeat the Last Coil to win an expedition; felling the first three guardians
  leaves their own relics (Reaver Heart, Mirror Scale, Coil Eye).
- Field guide with evolution recipes, improved drafts, boss health bars, objective
  tracking, notices and volume sliders.
- Pauseable arena map showing player position, caches, beacons, altar and terrain.
- Six hidden buildings per arena with separate off-map interiors: an archive of
  book stacks, a guarded foundry vault, an overgrown root cellar, a chapel
  with pews, a tidal observatory and a clockmaker's study. Exploring near one reveals it on the map; walk through its marked
  doorway to enter, and through the interior exit to return. Each has a
  different cache reward, a free upgrade and its own temporary buff; the
  Cinder Vault guards its cache with an elite.
- Temporary Fury, Haste, Ward and Magnetism pickups drop in combat and caches.
- Five new original synthesized region tracks, the earlier CC0 music and procedural sound effects;
  `audio/README.md` records their origin.
- Active ability slot with five powers, assigned per character and shown on the
  HUD; four meta-shop nodes join reroll, reserve gold, wisdom, revives and curse.
- Three trinket slots with twelve exotic effects, from Blink Ward's phasing and
  Tremor Core's quakes to Bounty Mark, Frostbite, Second Wind and Greed Engine.
  Draft banish/lock charges and two curse bargains per run enrich rewards while
  thickening the horde.
- Elemental reactions (shatter, steam, quench, blight), elite affixes, and two
  new enemy families: the rallying Warden Herald and the Void Screamer.
- A fourth region, Sable Abyss, with a darkness veil; dynamic weather fronts.
- Five endgame grounds beyond the original fifteen: Veilwood, Cinder Reach, Storm
  Citadel, Tidal Maw and Black Aurora, each with three exclusive enemies, a
  regional guardian, a boss relic and a permanent boss-gated Observatory upgrade.
- Destructible arena props, three run modes (Daily Challenge, Guardian Gauntlet,
  Endless Ascent), twelve achievements with a bestiary, and copyable build codes.
- Rebindable controls, accessibility toggles, a colourblind palette, and a
  guarded Steam bridge for achievements and stats.
- `EXPANSION.md` documents all of the above, its balance and its integration.

## Controls

| Input | Action |
|---|---|
| WASD / left stick | Move; weapons fire automatically |
| Space / controller B | Active ability (rebindable; shown on the HUD) |
| R / controller Y | Reroll the level-up draft |
| E / controller A | Open caches, use the altar and claim room rewards |
| Walk through a doorway | Enter a hidden building or return to the arena |
| Stand inside beacon | Capture for 10 seconds while its inner circle is enemy-free |
| Escape / controller Start | Pause; volume controls and field guide |
| Main or pause menu: Bestiary | Browse every common and regional enemy and all guardians |
| M | Open or close the arena map (also available from the pause menu) |
| Ctrl+Shift+A | Open or close the admin console from the menu or during play |
| Mouse / UI navigation | Menus and upgrade cards |
| F3 | Performance counters |
| F6 during play | Developer stress probe: fill to 1,500 enemies |

The admin console can unlock all local characters, grounds, legacies and positive
shop upgrades. During a run it can toggle god mode, heal, give run gold, clear
enemies, summon the current ground's guardian, or claim its boss reward.

Chests evolve a level-8 weapon with its matching level-5 passive after 10:00;
otherwise they grant 50 gold. Check the Field Guide for evolution recipes.
Existing saves at `user://vespercoil.cfg` remain compatible (format 1–2 migrate to
3). Difficulty, character, cleared grounds and the unlock ladder persist; ground
selection and volume adjustments last for the current application session.

## Validation

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/content.gd
godot --headless --path . --script tests/expansion.gd
godot --headless --path . --script tests/vault.gd
```

Full suite and row-by-row guards: `REGRESSION.md`.
Numeric design (weapons, enemies, bosses, synergies, waves): `BALANCE.md`.
Content pack III (20 weapons, 26 passives, 12 trinkets, 24 vessels, 6 guardians,
7 eras, keepers and how to add the next one): `CONTENT.md`. Its standing brief is
`CONTENT_PROMPT.md`.
`tests/content_capture.gd` renders screenshots with a graphics backend.
`CONTENT_UPDATE.md` describes verification and balance. The original `DESIGN.md`
remains the initial architecture reference; this update supersedes its original
content counts and placeholder-art descriptions.

Tests suppress save writes. Full 30-minute balance playtesting and target-hardware
FPS certification remain release work.

The twenty grounds, their unlock ladder and the keepers they awaken:
`REGIONS.md`. `tests/ground_capture.gd` renders the atlas and the new grounds
to PNG (graphics backend required).
