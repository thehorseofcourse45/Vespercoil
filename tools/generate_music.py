"""Compose Vespercoil's original region loops from synthesized notes; no samples.

Regions 0-9 ship third-party CC0 music and are not built here -- see
`audio/README.md` for that provenance. This tool composes the fifteen tracks the
project owns: regions 10-24, one per ground from Fallow Marsh to The Red Chancery.

Each track is a multi-section loop (intro / A / B / outro) of roughly 76 seconds
rather than a two-to-fifteen second phrase, and the very end is folded back over
the start so the loop point is sample-continuous instead of fading out and in.

Output is OGG Vorbis: Godot streams Vorbis from disk, while a WAV music track is
loaded into RAM in full. Intermediate WAVs are written to a temporary directory
and deleted, so nothing large is left in the repository.

Run from the project root, with ffmpeg (libvorbis) on PATH:

    python tools/generate_music.py
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio"
RATE = 44100
TARGET_SECONDS = 76.0
SEED = 71521
WRAP_SECONDS = 0.7
# Vorbis scales its bitrate for mono, so q6 lands near 100 kbps here: music-quality
# for pads and soft percussion without the megabytes of an uncompressed WAV.
VORBIS_QUALITY = "6"

# Per-ground musical identity. `roots` are MIDI notes cycled one per bar by the
# intro/A/outro; the B section rotates the same progression so the second half
# moves without leaving the key. `third` is the chord third (3 minor, 4 major).
REGIONS: dict[int, dict] = {
    10: dict(title="Fallow Marsh", bpm=84, roots=[38, 41, 36, 43], third=3,
             degrees=[0, 3, 5, 7, 10, 7, 5, 3], alt=[0, 5, 7, 10, 12, 10, 7, 5],
             color="overgrown"),
    11: dict(title="Sundered Dunes", bpm=92, roots=[40, 43, 41, 45], third=4,
             degrees=[0, 2, 3, 7, 10, 8, 7, 3], alt=[0, 3, 7, 8, 10, 8, 7, 3],
             color="dusty"),
    12: dict(title="Clockwork Bastion", bpm=128, roots=[36, 36, 41, 38], third=3,
             degrees=[0, 3, 7, 10, 12, 10, 7, 3], alt=[0, 7, 10, 12, 15, 12, 10, 7],
             color="mechanical"),
    13: dict(title="Drowned Coast", bpm=72, roots=[33, 36, 31, 38], third=3,
             degrees=[0, 3, 7, 10, 7, 3, 5, 7], alt=[0, 5, 3, 10, 12, 10, 7, 5],
             color="deepwater"),
    14: dict(title="Comet Fields", bpm=108, roots=[45, 48, 50, 43], third=4,
             degrees=[0, 4, 7, 11, 9, 7, 4, 2], alt=[0, 7, 11, 14, 12, 11, 9, 7],
             color="airy"),
    15: dict(title="Veilwood", bpm=96, roots=[40, 47, 43, 38], third=3,
             degrees=[0, 7, 5, 3, 10, 8, 7, 5], alt=[0, 3, 5, 7, 10, 12, 7, 5],
             color="overgrown"),
    16: dict(title="Cinder Reach", bpm=140, roots=[41, 43, 36, 38], third=3,
             degrees=[0, 3, 5, 7, 10, 12, 7, 5], alt=[0, 7, 10, 12, 15, 12, 10, 7],
             color="blazing"),
    17: dict(title="Storm Citadel", bpm=124, roots=[45, 43, 41, 40], third=4,
             degrees=[0, 3, 6, 7, 5, 3, 2, 0], alt=[0, 3, 7, 12, 10, 8, 7, 3],
             color="stormy"),
    18: dict(title="Tidal Maw", bpm=68, roots=[31, 34, 29, 36], third=3,
             degrees=[0, 3, 7, 10, 7, 3, 5, 7], alt=[0, 5, 7, 10, 7, 5, 3, 0],
             color="abyssal"),
    19: dict(title="Black Aurora", bpm=80, roots=[36, 39, 41, 43], third=4,
             degrees=[0, 1, 7, 5, 1, 8, 7, 5], alt=[0, 7, 8, 12, 10, 8, 7, 3],
             color="auroral"),
    20: dict(title="Saltbound Flats", bpm=100, roots=[43, 45, 41, 38], third=3,
             degrees=[0, 3, 7, 10, 7, 3, 5, 7], alt=[0, 7, 5, 3, 8, 7, 5, 3],
             color="salt"),
    21: dict(title="Amberhold", bpm=112, roots=[40, 45, 43, 41], third=4,
             degrees=[0, 4, 7, 9, 7, 4, 2, 0], alt=[0, 7, 9, 12, 11, 9, 7, 4],
             color="amber"),
    22: dict(title="The Vesperine", bpm=76, roots=[38, 39, 34, 36], third=3,
             degrees=[0, 1, 5, 7, 6, 5, 3, 1], alt=[0, 6, 7, 11, 10, 7, 6, 3],
             color="eerie"),
    23: dict(title="Lodestone Fields", bpm=132, roots=[37, 44, 40, 39], third=4,
             degrees=[0, 1, 3, 7, 8, 7, 5, 3], alt=[0, 7, 10, 12, 10, 8, 7, 3],
             color="magnetic"),
    24: dict(title="The Red Chancery", bpm=88, roots=[38, 41, 43, 36], third=3,
             degrees=[0, 2, 3, 7, 10, 8, 7, 3], alt=[0, 3, 7, 10, 12, 10, 7, 5],
             color="formal"),
}

# Additive harmonic stacks, a percussion density and a detune amount per colour.
# The detune widens pads by beating; non-integer harmonics (2.02) add unease.
TIMBRES: dict[str, dict] = {
    "overgrown": dict(pad=[(1, 1), (2, .22), (3, .10)], lead=[(1, 1), (2, .40), (3, .12)],
                      bass=[(1, 1), (2, .28)], perc=1, detune=.004, lead_gain=.055),
    "dusty": dict(pad=[(1, 1), (2, .16), (4, .06)], lead=[(1, 1), (2, .28), (3, .18)],
                  bass=[(1, 1), (2, .24)], perc=2, detune=.008, lead_gain=.052),
    "mechanical": dict(pad=[(1, 1), (3, .30), (5, .14)], lead=[(1, 1), (2, .10), (3, .35), (5, .20)],
                       bass=[(1, 1), (3, .20)], perc=2, detune=0.0, lead_gain=.046),
    "deepwater": dict(pad=[(1, 1), (2, .30), (3, .14)], lead=[(1, 1), (3, .20)],
                      bass=[(1, 1), (2, .34)], perc=0, detune=.003, lead_gain=.050),
    "airy": dict(pad=[(1, 1), (2, .20), (3, .12), (4, .05)], lead=[(1, 1), (2, .50), (4, .20)],
                 bass=[(1, 1), (2, .20)], perc=1, detune=.006, lead_gain=.053),
    "blazing": dict(pad=[(1, 1), (2, .35), (3, .20)], lead=[(1, 1), (2, .55), (3, .30)],
                    bass=[(1, 1), (2, .40)], perc=2, detune=.010, lead_gain=.050),
    "stormy": dict(pad=[(1, 1), (3, .25), (5, .12)], lead=[(1, 1), (2, .40), (4, .25)],
                   bass=[(1, 1), (3, .18)], perc=2, detune=.012, lead_gain=.048),
    "abyssal": dict(pad=[(1, 1), (2, .40), (3, .20)], lead=[(1, 1), (2, .15)],
                    bass=[(1, 1), (2, .45)], perc=0, detune=.005, lead_gain=.054),
    "auroral": dict(pad=[(1, 1), (2, .24), (3, .16), (6, .06)], lead=[(1, 1), (2, .45), (5, .15)],
                    bass=[(1, 1), (2, .22)], perc=1, detune=.007, lead_gain=.051),
    "salt": dict(pad=[(1, 1), (2, .14), (3, .08)], lead=[(1, 1), (2, .30), (3, .20)],
                 bass=[(1, 1), (2, .18)], perc=1, detune=.005, lead_gain=.055),
    "amber": dict(pad=[(1, 1), (2, .26), (4, .10)], lead=[(1, 1), (3, .30), (5, .15)],
                  bass=[(1, 1), (2, .26)], perc=1, detune=.006, lead_gain=.052),
    "eerie": dict(pad=[(1, 1), (2, .18), (2.02, .16), (3, .22)], lead=[(1, 1), (3, .35), (5, .20)],
                  bass=[(1, 1), (2, .20)], perc=0, detune=.009, lead_gain=.050),
    "magnetic": dict(pad=[(1, 1), (3, .35), (5, .20), (7, .10)], lead=[(1, 1), (2, .20), (3, .40)],
                     bass=[(1, 1), (3, .24)], perc=2, detune=.008, lead_gain=.046),
    "formal": dict(pad=[(1, 1), (2, .20), (3, .12)], lead=[(1, 1), (2, .35), (3, .15)],
                   bass=[(1, 1), (2, .30)], perc=1, detune=.004, lead_gain=.052),
}


def hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


def stack(t: np.ndarray, freq: float, harmonics: list[tuple[float, float]]) -> np.ndarray:
    """Sum a list of (harmonic multiple, gain) sine partials into one waveform."""
    out = np.zeros_like(t)
    for multiple, gain in harmonics:
        out += gain * np.sin(2 * np.pi * freq * multiple * t)
    return out


def note(out, start, length, midi, gain, harmonics, kind="pluck", detune=0.0) -> None:
    a = int(start * RATE)
    n = min(int(length * RATE), len(out) - a)
    if n <= 0 or a < 0:
        return
    t = np.arange(n, dtype=np.float32) / RATE
    freq = hz(midi)
    shape = stack(t, freq, harmonics)
    if detune:
        # A second voice slightly sharp of the first; the difference beats.
        shape = shape * .62 + stack(t, freq * (1.0 + detune), harmonics) * .62
    if kind == "pad":
        attack = np.minimum(1.0, t / .25)
        release = np.minimum(1.0, np.maximum(0.0, (length - t) / .45))
        env = attack * release
    elif kind == "bass":
        env = np.exp(-2.0 * t / max(length, .1))
    else:
        env = np.exp(-6.5 * t / max(length, .1))
    out[a:a + n] += gain * shape * env


def kick(out, start, gain=0.085) -> None:
    a = int(start * RATE)
    n = min(int(.14 * RATE), len(out) - a)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / RATE
    out[a:a + n] += gain * np.sin(2 * np.pi * (70 - 38 * t) * t) * np.exp(-25 * t)


def hat(out, start, rng, gain=0.022) -> None:
    a = int(start * RATE)
    n = min(int(.05 * RATE), len(out) - a)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / RATE
    out[a:a + n] += gain * rng.standard_normal(n) * np.exp(-90 * t)


def write_bar(out, start, bar_len, beat, kind, index, count, spec, timbre, rng) -> None:
    """Lay one bar of one section. Sparse sections return before the percussion."""
    roots = spec["roots_b"] if kind == "b" else spec["roots"]
    root = roots[index % len(roots)]
    degrees = spec["alt"] if kind == "b" else spec["degrees"]
    detune = timbre["detune"]

    pad_gain = .050 if kind in ("a", "b") else .042
    for interval in (0, spec["third"], 7):
        note(out, start, bar_len, root + interval + 12, pad_gain, timbre["pad"], "pad", detune)

    for step in range(4):
        pitch = root - 12 + (7 if step == 2 else 0)
        note(out, start + step * beat, beat * .8, pitch, .12, timbre["bass"], "bass")

    if kind == "intro":
        # One pickup note in the last intro bar so the melody has somewhere to come from.
        if index == count - 1:
            note(out, start + 2 * beat, beat, root + 24 + degrees[0], .05, timbre["lead"], "pluck", detune)
        return
    if kind == "outro":
        if index == 0:
            note(out, start, bar_len * .5, root + 24 + degrees[0], .05, timbre["lead"], "pluck", detune)
        return

    octave = 12 if (kind == "b" and index >= count - 2) else 0
    for step in range(8):
        pitch = root + 24 + degrees[(index * 3 + step) % len(degrees)] + octave
        gain = timbre["lead_gain"] if step % 2 == 0 else timbre["lead_gain"] * .62
        note(out, start + step * beat / 2, beat * .44, pitch, gain, timbre["lead"], "pluck", detune)

    if kind == "b" and index == count - 1:
        # A bell closing the B section, an octave above the melody.
        note(out, start + 3 * beat, beat * 1.5, root + 36 + degrees[0], .035, timbre["lead"], "pluck")

    if timbre["perc"] >= 1:
        kick(out, start, .085)
        kick(out, start + 2 * beat, .072)
    if timbre["perc"] >= 2:
        for step in (1, 3):
            hat(out, start + (step + .5) * beat, rng)


def compose(region: int, spec: dict) -> np.ndarray:
    beat = 60.0 / spec["bpm"]
    bar = 4 * beat
    total_bars = max(16, int(round(TARGET_SECONDS / bar)))
    intro = max(3, total_bars // 7)
    outro = intro
    body = total_bars - intro - outro
    a_len = body // 2
    sections = [("intro", intro), ("a", a_len), ("b", body - a_len), ("outro", outro)]

    spec = dict(spec)
    spec["roots_b"] = spec["roots"][1:] + spec["roots"][:1]

    # Render the wrap length past the end; it is folded back over the head below.
    out = np.zeros(int((total_bars * bar + WRAP_SECONDS) * RATE) + 2, dtype=np.float32)
    rng = np.random.default_rng(SEED + region)
    timbre = TIMBRES[spec["color"]]
    bar_index = 0
    for kind, count in sections:
        for index in range(count):
            write_bar(out, bar_index * bar, bar, beat, kind, index, count, spec, timbre, rng)
            bar_index += 1

    loop = out[:int(total_bars * bar * RATE)].copy()
    wrap_len = int(WRAP_SECONDS * RATE)
    wrap = out[len(loop):len(loop) + wrap_len]
    if len(wrap) != wrap_len:
        raise RuntimeError("wrap buffer is short: %d of %d samples" % (len(wrap), wrap_len))
    # Crossfade the audio that follows the loop point over the opening, so the seam is
    # continuous and the track can repeat without fading out and back in.
    ramp = np.linspace(0.0, 1.0, wrap_len, dtype=np.float32)
    loop[:wrap_len] = loop[:wrap_len] * (1.0 - ramp) + wrap * ramp

    echo = int(.19 * RATE)
    loop[echo:] += loop[:-echo] * .11
    loop = np.tanh(loop * 1.35)
    peak = float(np.max(np.abs(loop)))
    if peak > 0.0:
        loop *= 0.9 / peak
    return np.int16(np.clip(loop, -1.0, 1.0) * 32767)


def encode(wav_path: Path, ogg_path: Path) -> None:
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(wav_path),
         "-ac", "1", "-ar", str(RATE), "-c:a", "libvorbis", "-q:a", VORBIS_QUALITY, str(ogg_path)],
        check=True,
    )


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    print(f"composing {len(REGIONS)} original region loops at {RATE} Hz mono -> OGG q{VORBIS_QUALITY}")
    with tempfile.TemporaryDirectory() as scratch:
        for region in sorted(REGIONS):
            spec = REGIONS[region]
            samples = compose(region, spec)
            raw = Path(scratch) / f"region_{region}.wav"
            with wave.open(str(raw), "wb") as stream:
                stream.setnchannels(1)
                stream.setsampwidth(2)
                stream.setframerate(RATE)
                stream.writeframes(samples.tobytes())
            target = OUT / f"region_{region}.ogg"
            encode(raw, target)
            print("  region_%d.ogg  %-18s %5.1fs  %4d BPM  %5.1f MB"
                  % (region, spec["title"], len(samples) / RATE, spec["bpm"],
                     target.stat().st_size / 1048576))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except FileNotFoundError:
        print("ffmpeg (with libvorbis) is required on PATH to encode the loops.", file=sys.stderr)
        sys.exit(1)
