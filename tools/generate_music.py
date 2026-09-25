"""Compose original region loops from synthesized notes and noise; no samples."""
from pathlib import Path
import math
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'audio'
RATE = 22050
SEED = 71521

def hz(midi: int) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)

def note(out: np.ndarray, start: float, length: float, midi: int, gain: float, kind: str = 'pluck') -> None:
    a = int(start * RATE)
    n = min(int(length * RATE), len(out) - a)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / RATE
    f = hz(midi)
    if kind == 'pad':
        attack = np.minimum(1.0, t / 0.22)
        release = np.minimum(1.0, (length - t) / 0.4)
        shape = np.sin(2 * np.pi * f * t) + .25 * np.sin(2 * np.pi * f * 2 * t) + .12 * np.sin(2 * np.pi * f * 3 * t)
        out[a:a+n] += gain * shape * np.maximum(0, attack * release)
    elif kind == 'bass':
        env = np.exp(-2.2 * t / max(length, .1))
        shape = np.sin(2 * np.pi * f * t) + .28 * np.sin(2 * np.pi * f * 2 * t)
        out[a:a+n] += gain * shape * env
    else:
        env = np.exp(-7.0 * t / max(length, .1))
        shape = np.sin(2 * np.pi * f * t) + .4 * np.sin(2 * np.pi * f * 2.01 * t)
        out[a:a+n] += gain * shape * env

def compose(region: int) -> tuple[np.ndarray, int]:
    rng = np.random.default_rng(SEED + region)
    bpm = [96, 116, 88, 72, 104, 80, 132, 64, 124, 108][region]
    beat = 60.0 / bpm
    bars = 12
    duration = bars * 4 * beat
    out = np.zeros(int(duration * RATE), dtype=np.float32)
    roots = [
        [50, 53, 55, 48],
        [42, 43, 47, 45],
        [45, 48, 43, 50],
        [38, 41, 36, 43],
        [47, 52, 48, 43],
        [40, 47, 43, 38],
        [45, 43, 41, 40],
        [36, 39, 41, 43],
        [37, 40, 44, 39],
        [48, 52, 55, 50],
    ][region]
    degrees = [
        [0, 3, 7, 10, 7, 3, 5, 7],
        [0, 1, 7, 5, 1, 8, 7, 5],
        [0, 7, 3, 5, 10, 7, 5, 3],
        [0, 2, 3, 7, 10, 8, 7, 3],
        [0, 4, 7, 11, 9, 7, 4, 2],
        [0, 7, 5, 3, 10, 8, 7, 5],
        [0, 3, 5, 7, 10, 12, 7, 5],
        [0, 3, 6, 7, 5, 3, 2, 0],
        [0, 1, 3, 7, 8, 7, 5, 3],
        [0, 7, 4, 11, 9, 7, 4, 2],
    ][region]
    third = [3, 1, 3, 2, 4, 3, 3, 2, 4, 4][region]
    for bar in range(bars):
        start = bar * 4 * beat
        root = roots[bar % len(roots)]
        for interval in [0, third, 7]:
            note(out, start, 4 * beat, root + interval + 12, .048, 'pad')
        for step in range(4):
            note(out, start + step * beat, beat * .8, root - 12 + (7 if step == 2 else 0), .12, 'bass')
        for step in range(8):
            pitch = root + 24 + degrees[(bar * 3 + step) % len(degrees)]
            if region == 1 and step % 4 == 3:
                pitch += 1
            note(out, start + step * beat / 2, beat * .44, pitch, .057 if step % 2 == 0 else .035)
        for step in range(4):
            a = int((start + step * beat) * RATE)
            n = min(int(.12 * RATE), len(out) - a)
            t = np.arange(n, dtype=np.float32) / RATE
            out[a:a+n] += .08 * np.sin(2 * np.pi * (72 - 40 * t) * t) * np.exp(-27 * t)
            if step % 2 == 1:
                tick_a = a + int(beat * RATE * .5)
                tick_n = min(int(.05 * RATE), len(out) - tick_a)
                tick_t = np.arange(tick_n, dtype=np.float32) / RATE
                out[tick_a:tick_a+tick_n] += .025 * rng.standard_normal(tick_n) * np.exp(-80 * tick_t)
    echo = int(.19 * RATE)
    out[echo:] += out[:-echo] * .11
    fade = int(.08 * RATE)
    out[:fade] *= np.linspace(0, 1, fade)
    out[-fade:] *= np.linspace(1, 0, fade)
    out = np.tanh(out * 1.4) * .72
    return np.int16(np.clip(out, -1, 1) * 32767), bpm

for region in range(10):
    samples, bpm = compose(region)
    with wave.open(str(ROOT / f'region_{region}.wav'), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(samples.tobytes())
    print(f'region_{region}.wav: original {len(samples)/RATE:.1f}s loop at {bpm} BPM')
