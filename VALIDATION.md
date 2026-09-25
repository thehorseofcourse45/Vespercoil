# Validation

For the current **Shattered Expeditions** update, see `CONTENT_UPDATE.md`.
Numeric tables: `BALANCE.md`. Regression rows: `REGRESSION.md`.
The results below describe the original prototype before the content expansion.

Tested using the official Godot **4.4.1 stable**, Windows x64, Compatibility renderer.

- Editor import and script compilation completed with no GDScript errors.
- Headless integration test passed stat stacking, the cooldown cap, enemy recycling
  with new activation IDs, shield absorption, splitter children, distant despawning,
  offscreen formations, health pickup collection, exhausted drafts, queued level-ups,
  chest evolution, six simultaneous weapon behaviours, 1,500-enemy combat, boss
  thresholds at 10/20/30 minutes and final-boss victory.
- The dense, fully upgraded combat test ran 180 physics ticks plus boss checks in
  **6.58 seconds wall time** after amortizing homing target searches to every 150 ms.
  This test includes effects and enemy deaths. It is **not a 60 FPS certification**;
  it shows a real CPU budget limit under a deliberately dense endgame workload.
- Arena, draft and meta-shop screenshots were rendered using OpenGL on a Radeon
  RX 6700 XT and visually inspected. The draft positioning issue found during
  inspection was corrected.
- Test saves and editor files were redirected to scratch storage, leaving the user's
  normal Godot save directory untouched. Tests suppress progression writes.

The isolated runtime reports `Failed to read the root certificate store`; this is
an environment warning from Godot's startup, unrelated to the offline game. There
are no networking features or runtime downloads.

Remaining release work: sustained visible-window profiling on target hardware,
30-minute balance playtests, controller-only menu navigation review, final art/audio
and platform exports. The node-based swarm preserves editable component scenes;
MultiMesh swarm visuals are the documented next option if rendering becomes the
bottleneck. The included F3 counters and F6 stress probe make that decision measurable.
