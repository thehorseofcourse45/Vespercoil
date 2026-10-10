# Vespercoil SVG template library

These are editable source assets, not runtime enemy definitions. Start by copying
one SVG into `art/<new_id>.svg`; never mutate a template to create a live enemy.
The game uses the same enemy SVG in gameplay and the 32px Bestiary portrait.

## Style contract for AI authors

- Canvas: `width="64" height="64" viewBox="0 0 128 128"`, transparent background.
- Keep all visible ink inside coordinates 6..122; center the visual mass near 64,64.
- Silhouette: one bold readable contour, dark ink `#080d16` outer stroke 8 units,
  then regional metal fill and a pale 3-unit rim. Round joins and caps.
- Metal: local `metal0` diagonal gradient, pale at 0%, regional accent at 38%,
  dark at 100%. Preserve the region/enemy palette; ivory `#fff3bc` is the focal light.
- Interior: a few broad facets and 2-unit seams. Eyes, nozzles and gems have dark
  recesses; avoid text, thin engraving and tiny details that disappear at 32px.
- Change the OUTER CONTOUR and focal motif for every enemy. Palette swaps alone
  do not make a new design. Hounds retain split muzzle and two eyes; wisps retain
  a floating core but should not all become lightning inside a circle.
- Use only inline paths, circles, groups and local linear gradients. No fonts,
  scripts, external links, embedded rasters, filters, CSS, or unresolved tokens.
- New designs must remain readable at 32px (Bestiary) and approximately 26..36px
  (ordinary gameplay). Large viewing alone is insufficient.

## Choose a starting template

| File | Use / alteration |
| --- | --- |
| `enemy_hound.svg` | charge / pursuit; replace ear and jaw contour |
| `enemy_orbiter.svg` | orbiting crystal; change core and satellite shapes |
| `enemy_spitter.svg` | ranged mouth / cannon; preserve a readable nozzle |
| `enemy_archer.svg` | ranged humanoid; keep bow separate from body |
| `enemy_lancer.svg` | armored melee vessel; shield plus tall weapon |
| `enemy_tendril.svg` | plant / serpent; curved attack limb and rooted core |
| `enemy_sprite.svg` | winged / petal creature; four wings and central seed |
| `enemy_automaton.svg` | mechanical vessel; gear shell and inset dial |
| `object_cache.svg` | supply container; broad lid and central latch |
| `object_beacon.svg` | navigation beacon; elevated light and stable foot |
| `object_altar.svg` | ritual altar; floating offering over low plinth |
| `object_crystal.svg` | resource shard; faceted asymmetric variants |
| `object_pod.svg` | egg / seed / nest; curved segmented shell |
| `object_portal.svg` | gate / interactable ring; open center and cardinal marks |

## Workflow

1. Read the intended region's `data/regions/<id>.tres`, existing neighboring SVGs,
   and the desired `data/enemies/<id>.tres` behavior before drawing.
2. Choose the nearest template. Copy it, set a descriptive `<title>`, replace the
   three gradient colors, and alter silhouette plus two or three large features.
3. Render on the game's ink background and inspect at 32px and 64px. Check that
   outlines are not clipped and the visual center aligns with the hitbox.
4. For existing enemies replace only `art/<id>.svg`; paths, canvas size and scene
   binding remain compatible. Do not change stats or roster to update artwork.
5. A new enemy additionally needs its data resource, scene and registry/roster
   wiring. Templates provide ART ONLY; consult existing peers for gameplay wiring.
   Object SVGs likewise require a consumer; this library does not spawn objects.
6. Import in Godot, run `tests/regional_art.gd` for the regional enemy art, and
   inspect the actual Bestiary. Add new enemy/object references to appropriate
   existing tests when integrating new gameplay content.

## Example AI request

"Use `art/templates/enemy_hound.svg` to draw a new reef charger. Match Vespercoil's
SVG style contract. Give it a unique fin silhouette and salt gills, retain its
region's colors, and deliver a self-contained 64px SVG. Preview at 32px. Do not
change game balance or introduce a runtime art generator."

## Current regional designs

| Region | Enemy | Motif |
| --- | --- | --- |
| asterfall | `aurora_hound.svg` | aurora fins |
| asterfall | `prism_wisp.svg` | faceted prism with orbiting shards |
| ember | `forge_hound.svg` | riveted furnace jaw |
| ember | `slag_spitter.svg` | furnace vessel with molten nozzle |
| garden | `vine_whip.svg` | coiled thorn lash and rooted face |
| garden | `bloom_sprite.svg` | four petal wings and seed core |
| spire | `spire_lancer.svg` | tower helm, shield and upright lance |
| spire | `gilt_archer.svg` | crowned bow automaton |
| rime | `frost_hound.svg` | icicle cheek blades |
| rime | `glacier_wisp.svg` | radial glacier crystal |
| storm | `storm_hound.svg` | lightning cheek forks |
| storm | `tempest_wisp.svg` | two interlocking storm curls |
| ossuary | `grave_hound.svg` | bone sockets and exposed fangs |
| ossuary | `bone_archer.svg` | skeletal bow vessel |
| vein | `vein_hound.svg` | veined carapace and blood fangs |
| vein | `blood_wisp.svg` | beating sanguine droplet |
| mirror | `mirror_hound.svg` | cut-glass planes |
| mirror | `glass_wisp.svg` | fractured mirror kite |
| comet | `comet_hound.svg` | meteor crest and trailing shards |
| comet | `star_wisp.svg` | asymmetric fallen star |
| mire | `mire_hound.svg` | moss antlers and drooping cheeks |
| mire | `bog_wisp.svg` | lantern spirit with ragged roots |
| dunes | `dune_hound.svg` | sandstone brow and banded cheeks |
| dunes | `sand_wisp.svg` | suspended hourglass vortex |
| bastion | `gear_hound.svg` | toothed brass chassis |
| bastion | `clock_wisp.svg` | clockwork spirit with toothed dial |
| coast | `brine_hound.svg` | reef fins and salt gills |
| coast | `tide_wisp.svg` | breaking wave spiral |
| abyss | `void_hound.svg` | split void horns |
| abyss | `abyss_spitter.svg` | abyssal maw with recessed siphon |
| cinder_reach | `cinder_hound.svg` | flame crown and cracked muzzle |
| cinder_reach | `ash_wisp.svg` | curling ash flame |
| veilwood | `thorn_hound.svg` | branching thorn antlers |
| veilwood | `leaf_wisp.svg` | veined leaf spirit |
| storm_citadel | `arc_hound.svg` | capacitor ears and plated jaws |
| storm_citadel | `static_wisp.svg` | discharged capacitor halo |
| tidal_maw | `deep_hound.svg` | abyssal gills and lure |
| tidal_maw | `brine_wisp.svg` | deepwater droplet in a tidal cage |
| black_aurora | `shadow_hound.svg` | eclipse crescent ears |
| black_aurora | `eclipse_wisp.svg` | hollow eclipse crescent |
