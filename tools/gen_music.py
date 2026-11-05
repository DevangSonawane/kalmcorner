#!/usr/bin/env python3
"""
Calm Corner - background music generator (one soft track for the whole app).

    python3 tools/gen_music.py            # writes assets/audio/music/calm.flac

Design goals (the earlier tracks were bright and hissy, most energy at 2-7 kHz):
  * warm and low: almost all energy below 1 kHz, nothing piercing
  * no noise beds, no fast wobble, no high bells
  * slow harmony (one chord every ~20 s), sparse soft "felt piano" notes
  * long seamless loop (~3 minutes) so it does not feel repetitive
Deterministic: the same file every run.
"""
import os, shutil, subprocess, wave
import numpy as np
from scipy import signal

SR = 22050
rng = np.random.default_rng(11)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def lp(x, fc, order=2):
    return signal.sosfilt(signal.butter(order, fc, "lowpass", fs=SR, output="sos"), x)


def hp(x, fc, order=2):
    return signal.sosfilt(signal.butter(order, fc, "highpass", fs=SR, output="sos"), x)


def add_circ(buf, seg, start):
    n = buf.shape[-1]
    start %= n
    k = min(seg.shape[-1], n - start)
    buf[..., start:start + k] += seg[..., :k]
    if k < seg.shape[-1]:
        buf[..., : seg.shape[-1] - k] += seg[..., k:]


def pan2(x, p):
    """p in 0..1, equal-power."""
    return np.stack([x * np.cos(p * np.pi / 2), x * np.sin(p * np.pi / 2)])


# Fmaj9 -> C/E add9 -> Dm9 -> Bbmaj7(#11) -> Fmaj7/A -> Gm9 -> Bbmaj9 -> Csus2
CHORDS = [
    [41, 53, 57, 60, 64, 67],
    [40, 52, 55, 60, 62, 67],
    [38, 50, 53, 57, 60, 64],
    [34, 46, 53, 57, 62, 64],
    [33, 45, 53, 57, 60, 64],
    [31, 43, 50, 53, 57, 62],
    [34, 46, 50, 57, 60, 62],
    [36, 48, 55, 60, 62, 67],
]
CHORD_LEN = 21.0
XF = 7.0
# Soft melody notes per chord (pentatonic-friendly, kept in the middle register).
MELODY = [
    [65, 67, 69, 72],
    [64, 67, 69, 72],
    [62, 65, 69, 72],
    [62, 64, 65, 69],
    [60, 64, 65, 69],
    [62, 65, 67, 70],
    [62, 65, 69, 70],
    [60, 62, 67, 69],
]


def pad_voice(freq, n, seed):
    t = np.arange(n) / SR
    r = np.random.default_rng(seed)
    out = np.zeros((2, n))
    for cents, p in ((-2.5, 0.3), (2.5, 0.7)):
        f = freq * 2 ** (cents / 1200)
        ph = r.uniform(0, 2 * np.pi)
        v = np.sin(2 * np.pi * f * t + ph) + 0.12 * np.sin(4 * np.pi * f * t + ph)
        # Very slow swell (20-40 s period), shallow.
        v *= 0.88 + 0.12 * np.sin(2 * np.pi * r.uniform(1 / 40, 1 / 20) * t + r.uniform(0, 6.28))
        out += pan2(v, p)
    return out


def felt_note(freq, dur=6.0):
    """A soft, rounded piano-like tone: gentle attack, long decay, few harmonics."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    env = (1 - np.exp(-t / 0.018)) * np.exp(-t / 1.9)
    y = (
        np.sin(2 * np.pi * freq * t)
        + 0.25 * np.sin(2 * np.pi * 2 * freq * t) * np.exp(-t / 0.8)
        + 0.06 * np.sin(2 * np.pi * 3 * freq * t) * np.exp(-t / 0.4)
    )
    return lp(y * env, 2400, 2)


def reverb(x, rt=4.0, wet=0.5, damp=3000):
    n = int(rt * SR)
    t = np.arange(n) / SR
    ir = lp(rng.standard_normal(n), damp) * np.exp(-t * 6.9 / rt)
    ir /= np.sqrt(np.sum(ir ** 2))
    tail = signal.fftconvolve(x, ir)[: len(x)]
    return x * (1 - wet) + tail * wet


def build():
    N = int(len(CHORDS) * CHORD_LEN * SR)
    buf = np.zeros((2, N))

    # Pads with long crossfades between chords.
    for ci, chord in enumerate(CHORDS):
        n = int((CHORD_LEN + 2 * XF) * SR)
        seg = np.zeros((2, n))
        for vi, m in enumerate(chord):
            gain = (0.25, 0.8, 0.8, 0.65, 0.5, 0.4)[vi]  # light bass, warm middle  # bass softer, top softer
            pitch = m if vi == 0 else m + 12  # keep the pad in the warm middle
            seg += pad_voice(mtof(pitch), n, ci * 10 + vi) * gain
        k = int(XF * SR)
        w = np.ones(n)
        w[:k] = np.sin(np.linspace(0, np.pi / 2, k)) ** 2
        w[-k:] = np.cos(np.linspace(0, np.pi / 2, k)) ** 2
        add_circ(buf, seg * w * 0.08, int((ci * CHORD_LEN - XF) * SR))

    # Sparse felt-piano phrases: 2-4 notes per chord, unhurried.
    mel = np.zeros((2, N))
    for ci, notes in enumerate(MELODY):
        t0 = ci * CHORD_LEN + rng.uniform(2.0, 4.0)
        count = int(rng.integers(2, 5))
        for k in range(count):
            m = int(rng.choice(notes))
            v = rng.uniform(0.07, 0.1)
            add_circ(mel, pan2(felt_note(mtof(m)), rng.uniform(0.35, 0.65)) * v, int(t0 * SR))
            # Occasionally a soft lower harmony note.
            if rng.random() < 0.3:
                add_circ(mel, pan2(felt_note(mtof(m - 12)), 0.5) * v * 0.5, int((t0 + 0.05) * SR))
            t0 += rng.uniform(2.6, 4.8)
    buf += mel

    # Process circularly so the loop point is seamless.
    tiled = np.concatenate([buf, buf, buf], axis=1)
    out = []
    for ch in range(2):
        y = hp(tiled[ch], 150, 4)  # phone speakers can't play deep bass anyway
        y = lp(y, 2600, 2)
        y = reverb(y)
        out.append(y[N : 2 * N])
    x = np.stack(out)
    # Quiet, consistent level: RMS -26 dBFS, peaks below -6 dBFS.
    x *= 10 ** (-26 / 20) / (np.sqrt(np.mean(x ** 2)) + 1e-9)
    peak = np.max(np.abs(x))
    if peak > 10 ** (-6 / 20):
        x *= 10 ** (-6 / 20) / peak
    return x


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "music")
    os.makedirs(out_dir, exist_ok=True)
    x = build()
    wav = os.path.join(out_dir, "calm.wav")
    pcm = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    with wave.open(wav, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    if shutil.which("ffmpeg"):
        # FLAC: lossless and gapless (MP3 adds padding that clicks at the loop).
        flac = wav[:-4] + ".flac"
        r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "flac", "-compression_level", "8", flac])
        if r.returncode == 0:
            os.remove(wav)
            print("wrote", flac, f"{x.shape[1] / SR:.0f}s")
            return
    print("wrote", wav, f"{x.shape[1] / SR:.0f}s")


if __name__ == "__main__":
    main()
