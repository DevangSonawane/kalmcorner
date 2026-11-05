#!/usr/bin/env python3
"""
Soft UI sounds for Calm Corner (replaces the beepy ui_tap / ui_back / toggles).

    python3 tools/gen_ui_sounds.py

Each sound is a muted wooden "tock": a low, quickly falling tone, rounded with
a low-pass filter, short and quiet. No noise bursts, nothing above ~1.5 kHz.
"""
import os, wave
import numpy as np
from scipy import signal

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")


def lp(x, fc):
    return signal.sosfilt(signal.butter(2, fc, "lowpass", fs=SR, output="sos"), x)


def tock(f0, f1, dur=0.09, tau=0.022, attack=0.003):
    t = np.arange(int(dur * SR)) / SR
    f = f0 * (f1 / f0) ** np.clip(t / 0.03, 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) + 0.18 * np.sin(2 * ph)
    env = (1 - np.exp(-t / attack)) * np.exp(-t / tau)
    y = lp(y * env, 1400)
    fade = int(0.01 * SR)
    y[-fade:] *= np.linspace(1, 0, fade)
    return y


def norm(y, peak_db):
    return y * (10 ** (peak_db / 20) / (np.max(np.abs(y)) + 1e-9))


def write(name, y):
    pcm = (np.clip(y, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", name)


def two(a, b, gap=0.06):
    y = np.zeros(int((gap + len(b) / SR) * SR) + 1)
    y[: len(a)] += a
    s = int(gap * SR)
    y[s : s + len(b)] += b
    return y


def main():
    write("ui_tap", norm(tock(340, 250), -16))
    write("ui_back", norm(tock(300, 200, dur=0.1, tau=0.026), -17))
    write("ui_toggle_on", norm(two(tock(300, 240), tock(400, 320)), -17))
    write("ui_toggle_off", norm(two(tock(400, 320), tock(300, 240)), -17))


if __name__ == "__main__":
    main()
