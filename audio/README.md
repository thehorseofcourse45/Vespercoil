# Audio origin

The ten arena background tracks are `region_0.ogg` through `region_9.ogg`.
Each source page is marked CC0 1.0/public domain by OpenGameArt:

- `region_0.ogg` — [Journey to Eternity](https://opengameart.org/content/journey-to-eternity) — outer123
- `region_1.ogg` — [Devoted Guard](https://opengameart.org/content/devoted-guard) — vitalezzz
- `region_2.ogg` — [Plains of Luminescence](https://opengameart.org/content/plains-of-luminescence) — vitalezzz
- `region_3.ogg` — [Awestruck](https://opengameart.org/content/awestruck) — isaiah658
- `region_4.ogg` — [Eternal Light](https://opengameart.org/content/eternal-light) — vitalezzz
- `region_5.ogg` — [12 Music Loops](https://opengameart.org/content/12-music-loops), `316 [Chiptune Heroes] bgm_dangerous_encounter_A (faster).ogg` — SubspaceAudio
- `region_6.ogg` — [Trance Boss Battle](https://opengameart.org/content/trance-boss-battle) — MintoDog
- `region_7.ogg` — [Omega Droid](https://opengameart.org/content/omega-droid-stereo-mixstereo-mix-edit) — Umplix
- `region_8.ogg` — [12 Music Loops](https://opengameart.org/content/12-music-loops), `218 [Super Action Chiptunes] bgm_stage_9.ogg` — SubspaceAudio
- `region_9.ogg` — [Specular City](https://opengameart.org/content/specular-city) — vitalezzz

The files were transcoded to OGG for Godot without adding musical content.
CC0 does not require attribution; this provenance list is retained for the
project. The older procedural generator is no longer used by the game.

## New original music

`region_10.ogg` through `region_24.ogg` were composed and generated for this game by
`tools/generate_music.py` (numpy synthesis; no third-party samples, recordings or
melodies) and contain no third-party content.

Each track is a multi-section loop -- intro, A, B and outro -- of roughly 76 seconds.
The generator renders the wrap length past the end of the piece and crossfades it back
over the opening, so the seam is continuous when Godot repeats the track rather than the
track fading out and back in. Output is OGG Vorbis: Godot streams Vorbis from disk, while
a WAV music track is loaded into RAM in full. The tool therefore keeps no WAV source in
the repository -- re-running it regenerates the OGG files in place.

Composition is deterministic (fixed per-region seeds), but each Vorbis stream carries a
random Ogg serial number, so re-running the tool rewrites every file byte-wise even when
the audio is unchanged. Compare decoded PCM, not file hashes, before concluding that a
regeneration altered the music.

One track per ground, in atlas order:

| File | Ground | Tempo |
|---|---|---:|
| `region_10.ogg` | Fallow Marsh | 84 BPM |
| `region_11.ogg` | Sundered Dunes | 92 BPM |
| `region_12.ogg` | Clockwork Bastion | 128 BPM |
| `region_13.ogg` | Drowned Coast | 72 BPM |
| `region_14.ogg` | Comet Fields | 108 BPM |
| `region_15.ogg` | Veilwood | 96 BPM |
| `region_16.ogg` | Cinder Reach | 140 BPM |
| `region_17.ogg` | Storm Citadel | 124 BPM |
| `region_18.ogg` | Tidal Maw | 68 BPM |
| `region_19.ogg` | Black Aurora | 80 BPM |
| `region_20.ogg` | Saltbound Flats | 100 BPM |
| `region_21.ogg` | Amberhold | 112 BPM |
| `region_22.ogg` | The Vesperine | 76 BPM |
| `region_23.ogg` | Lodestone Fields | 132 BPM |
| `region_24.ogg` | The Red Chancery | 88 BPM |

All twenty-five tracks ship as OGG Vorbis; `scripts/systems/audio.gd` resolves
`region_<music>.ogg` for every ground. `tools/generate_music.py` composes only the fifteen
original grounds (10-24) -- `region_0` through `region_9` are the CC0 recordings and are
never regenerated.
