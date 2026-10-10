# Laser vessels and Refractor Shield

Four new common enemy families join the existing shared late-horde roll at 3..8
minutes and recur every 60 seconds on every ground. Laser Bastion, Coil Overseer,
Bastion Juggernaut and Rift Matriarch join the elite pool at 6..10 minutes, one
random elite every 90 seconds. Regional rosters stay intact.

| Vessel | Role | Base HP | Base shield | Contact / beam hit | Speed |
| --- | --- | ---: | ---: | ---: | ---: |
| Laser Sniper | Warns, then tracks the player with a beam | 64 | 0 | 12 | 42 |
| Coil Sentry | Circles and fires a three-shot spread | 78 | 8 | 16 | 62 |
| Bastion Ram | Slow shielded tank with a warned ground slam | 160 | 32 | 24 | 34 |
| Rift Broodcaller | Keeps distance and summons two swarmers | 96 | 0 | 12 | 36 |
| Laser Bastion (elite variant) | Armored beam caster | 180 | 35 | 15 | 26 |
| Coil Overseer (elite variant) | Armored orbiting spread caster | 100 | 12 | 16 | 62 |
| Bastion Juggernaut (elite variant) | Heavy shielded ground-slam tank | 220 | 48 | 24 | 34 |
| Rift Matriarch (elite variant) | Shielded swarmer summoner | 128 | 16 | 12 | 36 |

Laser Sniper holds its beam for **3s** normally and **5s** if spawned as an elite.
Laser Bastion's natural elite spawn has 8x its base HP (1440) and shield (280),
1.4x damage and 1.5x radius before existing difficulty/time scaling.
The other elite variants use the same rank multipliers and random affixes:
Coil Overseer has 800 HP / 96 shield, Bastion Juggernaut 1760 HP / 384 shield,
and Rift Matriarch 1024 HP / 128 shield. Warded affixes can raise shields further.
Their common counterparts remain available in the Common Horde Bestiary tab;
the four elite variants have their own Elite Horde entries and crowned portraits.
**The Laser Regent** is the stage-6 Guardian Gauntlet / Endless boss: 90,000 HP,
5,000 shield, and a **10s** beam, after the Chronarch. Ordinary expeditions still
finish at the Last Coil; the new boss requires Gauntlet or Endless Ascension.

## Laser rules

- 1.2s warning; the warning line and the firing beam hesitate (`LASER_TRACK_DELAY`,
  0.6s) before tracking the player, then sweep at 0.9 radians/second -- read the
  hesitation, step out, and movement can beat the beam. Dashes, walls and the
  1000-unit range stay the hard counters.
- 1000-unit range; caster holds position during warning and firing, though incoming
  knockback can displace it. Solid building shells and interior walls stop the beam.
- Continuous luminous line, not a projectile; collision samples every 0.25s.
  Normal player hit protection, dash invulnerability, armor, lightning resistance,
  difficulty and status mitigation still apply. Beam half-widths: 5 / 7 / 10.
- Recovery is 4s after firing ends; the boss recovers in 2.5s below half health.
  The beam stops on death, recycling and room exit. Pausing freezes all beam timers.
- Refractor Shield is an ordinary draft passive: 12% laser-only damage reduction per
  level, max 5 (60%). Its reduction multiplies after ordinary resistance and armor.
  It does not shield contact hits or ordinary lightning projectiles. No new save format.

## Balance assumptions

The hesitation is the dodge window: a sidestep or blink timed to the delay leaves
the lane, and the slower sweep lets close-range footwork stay ahead at common
range. Blinking through, breaking line of sight and outranging the beam remain the
hard counters, and the 10s boss beam still forces a commitment. At zero armor/resistance, sustained common exposure permits roughly four hits
over 3s with the existing 0.55s hit protection; the 0.25s samples allow about 16
damage/second rather than 48. The elite is deliberately slower and durable; laser
damage follows the existing 1.4x/2x rank and time/difficulty scales. Refractor Shield
trades a passive pick for specialized defense and is not strictly better than the
broad Spark Ward. These are initial tuning values, not playtest win-rate claims.

## Validation

Run `tests/laser_content.gd` for beam durations, sustained hits, the warning and
beam hesitation windows and their delayed tracking,
wall clipping, dodge/dash protection, shield ranks/source isolation, pooled reuse,
off-screen rendering and horde-stagger timing, draft wiring, spawns and boss ladder.
Existing damage, late-horde, content and vault checks remain relevant.
