# Content Expansion Brief

The prompt below is the standing brief for expanding Vespercoil's content. It is
written to be reusable: hand it to an agent (or to your future self) whenever the
game needs another content pack.

---

## The Prompt

> Expand the content of Vespercoil, the Vampire Survivors-style roguelite in this
> repository, without changing the game's architecture. Work autonomously: pick
> sensible numbers, verify them, and report what you shipped.
>
> Add, at minimum:
>
> 1. **Eight new weapons**, each using a distinct existing firing pattern or
>    projectile behaviour so no two feel alike, each with its own icon, weight,
>    level-up curve, evolution passive and evolution title.
> 2. **Seven new passive upgrades** that plug into stats the game already
>    supports, honouring the existing flat/percent convention and level caps.
> 3. **Six new trinkets** with reactive or periodic effects (not passive stat
>    sticks), each implemented in the trinket system and offered through the
>    existing draft.
> 4. **Five new enemies**, each with original vector art, balanced stats, and a
>    genuinely new AI behaviour rather than a stat clone of an existing vessel.
>    Add their behaviours to the AI, register their types, and put them into the
>    wave roster.
> 5. **Two new guardians** that cap the guardian ladder, reachable through the
>    Guardian Gauntlet and Endless Ascension, with their own health, shields,
>    stages and difficulty curve.
> 6. **Two new wave eras** extending the schedule past the current finale, so
>    long and endless runs keep escalating.
> 7. **Three new relics** awarded for felling the first three guardians.
> 8. **Two new keepers** (playable characters) unlocked by clearing the two
>    deepest grounds, each with a distinct starting weapon and stat trade-off.
>
> Constraints:
>
> - Data-driven first: new content should live in `.tres` resources plus a line
>   in a catalogue, not in hardcoded special cases.
> - Keep every existing test green. Update pinned counts deliberately and add a
>   regression suite that covers the new content so future packs cannot silently
>   break it.
> - Every new weapon must survive `at_level(8)`: a level-up entry that names a
>   key the resolver does not carry is a latent crash, so the suite must exercise
>   every weapon's full level curve.
> - Balance against what exists: new options should be competitive with the
>   current roster, not strictly better.
> - Update documentation (`README.md`, `REGRESSION.md`, plus a content reference
>   file) and record the balance assumptions in `BALANCE.md`.
> - Report honestly, including any content the player cannot practically reach
>   in a normal run.

---

## What this pass delivered

| Category | Added |
| --- | --- |
| Weapons | Scattergun, Chain Bolt, Crescent, Ricochet Orb, Carousel, Purging Halo, Railshot, Shard Storm |
| Passives | Dead Eye, Overclock, Hoarder, Iron Will, Titan, Spirit Ward, Void Pact |
| Trinkets | Blink Ward, Bounty Mark, Frostbite, Tremor Core, Second Wind, Greed Engine |
| Enemies | Gloomjack, Coil Sentinel, Ash Mortar, Veil Shepherd, Bone Breaker |
| Guardians | The Reaver, The Chronarch |
| Waves | Era V and Era VI |
| Relics | Reaver Heart, Mirror Scale, Coil Eye |
| Keepers | Ravager (Crimson Vein), Glazier (Glass Expanse) |

See `CONTENT.md` for the full reference and `BALANCE.md` for the numbers.
