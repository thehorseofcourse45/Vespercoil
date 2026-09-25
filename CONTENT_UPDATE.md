# The Shattered Expeditions — content update

This update adds exploration goals and distinct combat threats while retaining
shared components, pools, the spatial grid, signal bus, save format and six slots.

## Regions

| Region | Run bias | Special incursion |
|---|---|---|
| Asterfall Ruins | Balanced | Rift Hound |
| Ember Foundry | +15% damage, -15 max HP | Prism Stalker |
| Hollow Garden | +35% pickup radius | Brood Oracle |

Each has its own procedural floor and ambient loop. Incursions begin at 00:25,
then every 18 seconds, scaling to six units. Original time-indexed waves continue.
Points of interest are finite objectives around the starting area; contracts and
incidents continue throughout the run.

## New arsenal

| Weapon | Base | Behaviour | Evolution |
|---|---|---|---|
| Sawdisc | 16 damage, 1.65s, 3 ricochets | Redirects toward fresh targets on contact | Duplicator → Razortide: +8 ricochets, +2 discs, double damage |
| Cinderfall | 40 damage, 3.8s, radius 66 | Marks for 0.85s, then explodes | Might → Extinction: +3 meteors, 1.5× radius, double damage |
| Frostbell | 10 damage, 2.6s, radius 125 | Reduces movement to 35% for 2s | Clock → Absolute Zero: 4s slow, 1.8× radius, double damage |

All have seven resource-defined upgrades. Frostbell count bonuses increase pulse
damage. Discharges resolve current stats; travelling attacks retain that snapshot.

## Encounters and exploration

Hounds lock a direction for 0.8s, then charge. Stalkers hold a 1.1s targeting line,
then fire a fast shot. Oracles summon two swarmers every five seconds; reproduction
is suppressed above 1,800 active units.

Gatekeeper and Prism Warden fire radial patterns. Broodmother marks ground strikes
and summons chargers. Last Coil combines rotating bullet rings, a large targeted
blast and enraged summoner reinforcements. Attack intervals shorten from 4s to
2.5s below half health.

Caches drop 15 gold, 12 XP and 15 healing. Each beacon needs ten uncontested seconds,
then awards a different relic, 30 gold and 25 healing. Relics grant +20% area, +8
percentage points cooldown reduction and +1 projectile, in capture order. Bloodglass
trades 15 HP for +12% damage, refuses lethal payments and cannot be reused.

Contracts start at 40 kills, increasing by 35 to a 400-kill cap, with increasing
gold/XP rewards. Eighteen-second incidents start at 00:45, then every 90s: extra
swarmers, telegraphed ground strikes, gold drops.

## Implementation and verification

- `world.gd`: regions, sites, relics, contracts and a fixed 48-record hazard pool.
- Existing managers handle new enemies/projectiles. No per-enemy processing or
  Area2D overlap system was added.
- Eleven original SVG sprites; three locally synthesized music loops. No new
  plugins or dependencies. Existing Godot AI add-on and project settings preserved.
- New signal: `notice(title: String, detail: String, color: Color)`, emitted by
  world/director/arsenal and consumed by HUD's bounded notice queue.

Verified using installed Godot 4.7.2 on Windows:

1. Engine import and compilation.
2. Original regression suite, including 1,500-unit combat and final victory.
3. New suite: title-to-run reload, region stats, Artificer, catalog counts,
   input-driven single-use cache collection, contested beacons, all four relics,
   safe altar payments, enemy abilities and pool resets, new weapon/evolution
   behaviours, all incidents and guardian phases, enrage, menu flow and live combat.
4. OpenGL render inspection of title, combat, draft and shop.

Tests isolate data and suppress saves. Audio teardown waits for the audio thread.
The runtime reports a host certificate-store warning at startup; gameplay is offline.
No GDScript/runtime errors remain in validated tests. Sustained 60 FPS and the full
30-minute balance curve have not been certified.
