#!/usr/bin/env python3
"""
Calm Corner - procedural audio generator (no downloads, no licences, no attribution).

Usage:
    pip install numpy scipy
    python3 tools/gen_audio.py --out assets/audio            # writes .ogg if ffmpeg exists, else .wav
    python3 tools/gen_audio.py --out assets/audio --wav      # force .wav
    python3 tools/gen_audio.py --out assets/audio --only pop # build only ids containing "pop"

Writes:  <out>/sfx/*.ogg   <out>/music/*.ogg   <out>/manifest.json
Everything is deterministic (fixed seed), so re-running gives identical files.
"""
import argparse, json, os, shutil, subprocess, wave
import numpy as np
from scipy import signal

SR = 22050
rng = np.random.default_rng(7)


# ----------------------------------------------------------------- helpers --
def tt(dur):
    return np.arange(int(dur * SR)) / SR


def expdecay(t, tau, attack=0.004):
    return (1 - np.exp(-t / attack)) * np.exp(-t / tau)


def sos_filter(x, kind, fc, order=2):
    sos = signal.butter(order, fc, btype=kind, fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, fc, order=2): return sos_filter(x, "lowpass", fc, order)
def hp(x, fc, order=2): return sos_filter(x, "highpass", fc, order)
def bp(x, lo, hi, order=2): return sos_filter(x, "bandpass", [lo, hi], order)


def white(n): return rng.standard_normal(n)


def pink(n):
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n)
    f[0] = f[1]
    x = np.fft.irfft(spec / np.sqrt(f), n)
    return x / np.max(np.abs(x))


def mtof(m): return 440.0 * 2 ** ((m - 69) / 12.0)


def normalize(x, peak_db=-3.0):
    p = np.max(np.abs(x)) + 1e-9
    return x * (10 ** (peak_db / 20) / p)


def normalize_rms(x, rms_db=-22.0, peak_cap_db=-3.0):
    """Level-match by loudness (RMS), then cap the peak so loud transients never clip."""
    r = np.sqrt(np.mean(x ** 2)) + 1e-9
    y = x * (10 ** (rms_db / 20) / r)
    cap = 10 ** (peak_cap_db / 20)
    p = np.max(np.abs(y))
    return y * (cap / p) if p > cap else y


def edge_fade(x, fin=0.002, fout=0.01):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a: x[:a] *= np.linspace(0, 1, a)
    if b: x[-b:] *= np.linspace(1, 0, b)
    return x


def reverb(x, rt=1.6, wet=0.25, damp=5000):
    n = int(rt * SR)
    t = np.arange(n) / SR
    ir = lp(white(n), damp) * np.exp(-t * 6.9 / rt)
    ir /= np.sqrt(np.sum(ir ** 2))
    tail = signal.fftconvolve(x, ir)
    y = np.zeros(len(tail))
    y[:len(x)] += x * (1 - wet)
    y += tail * wet
    return y


def loopify(x, xf=0.3):
    """Make x loop seamlessly: fade the last xf seconds into the first xf seconds."""
    n = int(xf * SR)
    y = x[:-n].copy()
    fin = np.sin(np.linspace(0, np.pi / 2, n))
    y[:n] = y[:n] * fin + x[-n:] * np.cos(np.linspace(0, np.pi / 2, n))
    return y


def mix_at(buf, seg, start):
    end = min(len(buf), start + len(seg))
    if start < len(buf) and end > start:
        buf[start:end] += seg[:end - start]


def tone(f, dur, tau, attack=0.004, partials=((1, 1.0),)):
    t = tt(dur)
    y = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in partials)
    return y * expdecay(t, tau, attack)


def bell(f, dur=1.8, tau=0.9):
    t = tt(dur)
    y = np.zeros_like(t)
    for i, (k, a) in enumerate(((1.0, 1.0), (2.0, 0.35), (2.76, 0.22), (5.4, 0.10))):
        y += a * np.sin(2 * np.pi * f * k * t) * np.exp(-t / (tau / (1 + 0.9 * i)))
    return y * (1 - np.exp(-t / 0.003))


def glide(f0, f1, dur, tau, attack=0.003):
    t = tt(dur)
    f = f0 * (f1 / f0) ** np.clip(t / dur, 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * expdecay(t, tau, attack)


# ------------------------------------------------------------------- SFX ----
# UI sounds are soft wooden "tocks"; see tools/gen_ui_sounds.py (same design).
import importlib.util as _ilu
_spec = _ilu.spec_from_file_location("gen_ui_sounds", os.path.join(os.path.dirname(__file__), "gen_ui_sounds.py"))
_ui = _ilu.module_from_spec(_spec); _spec.loader.exec_module(_ui)


def sfx_ui_tap():
    return _ui.tock(340, 250)


def sfx_ui_back():
    return _ui.tock(300, 200, dur=0.1, tau=0.026)


def sfx_ui_on():
    return _ui.two(_ui.tock(300, 240), _ui.tock(400, 320))


def sfx_ui_off():
    return _ui.two(_ui.tock(400, 320), _ui.tock(300, 240))


def _pop(f0, f1, dur=0.22):
    n = int(dur * SR)
    click = bp(white(n), 1500, 6500) * expdecay(tt(dur), 0.006, 0.0005)
    return glide(f1, f0, dur, 0.035) + 0.5 * click


def sfx_pop_small(): return _pop(520, 1100)
def sfx_pop_medium(): return _pop(360, 800, 0.26)
def sfx_pop_large(): return _pop(230, 520, 0.32)


def sfx_wipe_loop():
    n = int(3.6 * SR); t = np.arange(n) / SR
    y = bp(pink(n), 900, 4200) * (1 + 0.15 * np.sin(2 * np.pi * 2.3 * t))
    return loopify(y, 0.4)


def _squeak(f0, f1):
    dur = 0.14; t = tt(dur)
    f = np.linspace(f0, f1, len(t)) * (1 + 0.012 * np.sin(2 * np.pi * 38 * t))
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    return y * np.sin(np.pi * t / dur) ** 2 * 0.6


def sfx_wipe_squeak_1(): return _squeak(2100, 2650)
def sfx_wipe_squeak_2(): return _squeak(2500, 2250)
def sfx_wipe_squeak_3(): return _squeak(1900, 2400)


def sfx_sand_loop():
    n = int(3.6 * SR); t = np.arange(n) / SR
    y = lp(hp(white(n), 1800), 8000) * (1 + 0.25 * np.sin(2 * np.pi * 1.1 * t))
    return loopify(y, 0.4)


def sfx_stone_place():
    t = tt(0.5)
    body = glide(150, 62, 0.5, 0.12)
    thud = lp(white(len(t)), 600) * expdecay(t, 0.04, 0.001)
    return body + 0.5 * thud


def sfx_pour_loop():
    dur = 2.6; n = int(dur * SR)
    y = bp(pink(n), 400, 1800) * 0.35
    for _ in range(int(dur * 28)):
        f = rng.uniform(350, 1100)
        mix_at(y, glide(f, f * 1.25, 0.09, 0.025) * rng.uniform(0.15, 0.4), rng.integers(0, n - int(0.1 * SR)))
    return loopify(y, 0.3)


def sfx_select_tube(): return tone(740, 0.25, 0.05, partials=((1, 1), (2, 0.3)))


_PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]


def _bell_note(i): return reverb(bell(_PENTA[i], 2.0, 0.9), 1.2, 0.2)


def sfx_tube_complete_0(): return _bell_note(0)
def sfx_tube_complete_1(): return _bell_note(1)
def sfx_tube_complete_2(): return _bell_note(2)
def sfx_tube_complete_3(): return _bell_note(3)
def sfx_tube_complete_4(): return _bell_note(4)
def sfx_tube_complete_5(): return _bell_note(5)


def sfx_level_complete():
    y = np.zeros(int(4 * SR))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5, 1318.5]):
        mix_at(y, bell(f, 2.2, 1.0) * 0.8, int(i * 0.16 * SR))
    return reverb(y, 2.2, 0.35)


def sfx_complete_soft():
    dur = 3.0; t = tt(dur)
    y = np.zeros_like(t)
    for f in (261.63, 329.63, 392.0, 493.88, 659.25):
        for det in (-0.003, 0.0, 0.003):
            y += np.sin(2 * np.pi * f * (1 + det) * t)
    env = (1 - np.exp(-t / 0.6)) * np.exp(-np.maximum(t - 0.8, 0) / 1.1)
    return reverb(y * env, 2.0, 0.35)


def sfx_bloom():
    y = np.zeros(int(3 * SR))
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        mix_at(y, bell(f, 2.4, 1.1) * 0.7, int(i * 0.09 * SR))
    t = tt(1.4)
    y[:len(t)] += 0.05 * np.sin(2 * np.pi * np.cumsum(np.linspace(1500, 4200, len(t))) / SR) * np.sin(np.pi * t / 1.4)
    return reverb(y, 2.0, 0.3)


def sfx_water_drop(): return glide(600, 1300, 0.2, 0.03)


def sfx_sprinkle_loop():
    n = int(2.4 * SR)
    patter = np.abs(lp(white(n), 18, 1)); patter /= patter.max()
    y = lp(hp(white(n), 3500), 9000) * (0.35 + 0.65 * patter)
    return loopify(y, 0.3)


def sfx_rain_loop():
    dur = 24; n = int(dur * SR)
    y = hp(lp(pink(n), 5000), 400) * 0.6
    for _ in range(int(dur * 40)):
        burst = bp(white(int(0.004 * SR)), 2000, 6500) * rng.uniform(0.1, 0.5)
        mix_at(y, burst, rng.integers(0, n - 300))
    return loopify(y, 2.0)


def _chime(i):
    f = [783.99, 880.0, 987.77, 1174.66][i]
    return reverb(bell(f, 3.5, 2.2) * 0.6, 2.0, 0.35)


def sfx_wind_chime_0(): return _chime(0)
def sfx_wind_chime_1(): return _chime(1)
def sfx_wind_chime_2(): return _chime(2)
def sfx_wind_chime_3(): return _chime(3)


SFX = {  # id: (function, loop?, peak dBFS)
    "ui_tap": (sfx_ui_tap, False, -16), "ui_back": (sfx_ui_back, False, -17),
    "ui_toggle_on": (sfx_ui_on, False, -17), "ui_toggle_off": (sfx_ui_off, False, -17),
    "pop_small": (sfx_pop_small, False, -4), "pop_medium": (sfx_pop_medium, False, -4),
    "pop_large": (sfx_pop_large, False, -4),
    "wipe_loop": (sfx_wipe_loop, True, -8), "wipe_squeak_1": (sfx_wipe_squeak_1, False, -10),
    "wipe_squeak_2": (sfx_wipe_squeak_2, False, -10), "wipe_squeak_3": (sfx_wipe_squeak_3, False, -10),
    "sand_loop": (sfx_sand_loop, True, -9), "stone_place": (sfx_stone_place, False, -4),
    "pour_loop": (sfx_pour_loop, True, -8), "select_tube": (sfx_select_tube, False, -7),
    "tube_complete_0": (sfx_tube_complete_0, False, -6), "tube_complete_1": (sfx_tube_complete_1, False, -6),
    "tube_complete_2": (sfx_tube_complete_2, False, -6), "tube_complete_3": (sfx_tube_complete_3, False, -6),
    "tube_complete_4": (sfx_tube_complete_4, False, -6), "tube_complete_5": (sfx_tube_complete_5, False, -6),
    "level_complete": (sfx_level_complete, False, -4), "complete_soft": (sfx_complete_soft, False, -5),
    "bloom": (sfx_bloom, False, -5), "water_drop": (sfx_water_drop, False, -8),
    "sprinkle_loop": (sfx_sprinkle_loop, True, -10), "rain_loop": (sfx_rain_loop, True, -12),
    "wind_chime_0": (sfx_wind_chime_0, False, -14), "wind_chime_1": (sfx_wind_chime_1, False, -14),
    "wind_chime_2": (sfx_wind_chime_2, False, -14), "wind_chime_3": (sfx_wind_chime_3, False, -14),
}


# ----------------------------------------------------------------- music ----
def _pad_voice(freq, n, pan_seed, nharm=3):
    t = np.arange(n) / SR
    L = np.zeros(n); R = np.zeros(n)
    for det_c in (-5, 0, 5):                       # detune in cents, spread over the stereo field
        f = freq * 2 ** (det_c / 1200)
        ph = rng.uniform(0, 2 * np.pi)
        v = np.sin(2 * np.pi * f * t + ph) + 0.28 * np.sin(4 * np.pi * f * t + ph) + 0.08 * np.sin(6 * np.pi * f * t)
        v *= 0.8 + 0.2 * np.sin(2 * np.pi * rng.uniform(0.05, 0.12) * t + rng.uniform(0, 6.28))   # slow breathing
        pan = np.clip(0.5 + det_c / 12 + 0.15 * np.sin(pan_seed), 0, 1)
        L += v * np.cos(pan * np.pi / 2); R += v * np.sin(pan * np.pi / 2)
    return L, R


def _add_circular(buf, seg, start):
    n = buf.shape[-1]; start %= n; k = min(len(seg), n - start)
    buf[..., start:start + k] += seg[..., :k]
    if k < len(seg): buf[..., :len(seg) - k] += seg[..., k:]


def make_pad_track(chords, bright, chime_every, sparkle_notes, chord_len=16.0, xf=5.0, sub=False):
    N = int(len(chords) * chord_len * SR)
    buf = np.zeros((2, N))
    for ci, chord in enumerate(chords):
        n = int((chord_len + 2 * xf) * SR)
        seg = np.zeros((2, n))
        for vi, m in enumerate(chord):
            L, R = _pad_voice(mtof(m), n, vi + ci)
            seg[0] += L; seg[1] += R
        w = np.ones(n); k = int(xf * SR)
        w[:k] = np.sin(np.linspace(0, np.pi / 2, k)) ** 2
        w[-k:] = np.cos(np.linspace(0, np.pi / 2, k)) ** 2
        _add_circular(buf, seg * w * 0.12, int((ci * chord_len - xf) * SR))
    if sub:
        t = np.arange(N) / SR
        drone = np.sin(2 * np.pi * mtof(chords[0][0] - 12) * t) * (0.6 + 0.4 * np.sin(2 * np.pi * (1 / (len(chords) * chord_len)) * t))
        buf += 0.008 * drone
    air = bp(white(N), 2500, 6500) * 0.012 * (0.5 + 0.5 * np.sin(2 * np.pi * np.arange(N) / SR / 23.0))
    buf[0] += air; buf[1] += np.roll(air, 4000)
    for _ in range(int(N / SR / chime_every)):                         # sparse, soft pentatonic sparkles
        f = mtof(rng.choice(sparkle_notes))
        s = bell(f, 4.0, 1.6) * rng.uniform(0.03, 0.07)
        pan = rng.uniform(0.2, 0.8)
        seg = np.stack([s * np.cos(pan * np.pi / 2), s * np.sin(pan * np.pi / 2)])
        _add_circular(buf, seg, int(rng.integers(0, N)))
    tiled = np.concatenate([buf, buf, buf], axis=1)                    # circular filtering + reverb
    out = []
    for ch in range(2):
        y = lp(tiled[ch], bright, 2)
        y = reverb(y, 2.6, 0.45, 4500)[:len(tiled[ch])]
        out.append(y[N:2 * N])
    return normalize_rms(np.stack(out), -22.0, -3.0)


MUSIC = {
    "dawn":    dict(chords=[[48, 52, 55, 59, 62], [45, 52, 55, 59, 60], [41, 48, 52, 55, 57], [43, 50, 52, 57, 59]],
                    bright=2400, chime_every=9, sparkle_notes=[72, 74, 76, 79, 81, 84]),
    "dusk":    dict(chords=[[50, 53, 57, 60, 64], [46, 53, 57, 62, 64], [41, 48, 52, 57, 60], [48, 55, 57, 62]],
                    bright=1500, chime_every=14, sparkle_notes=[69, 72, 74, 77, 79]),
    "moonlit": dict(chords=[[45, 52, 59, 62], [41, 48, 55, 60], [48, 55, 59, 64], [40, 47, 55, 59]],
                    bright=900, chime_every=30, sparkle_notes=[69, 72, 76], sub=True),
    "garden":  dict(chords=[[50, 54, 57, 61, 64], [47, 54, 57, 62, 66], [43, 50, 54, 59, 62], [45, 52, 55, 57, 62]],
                    bright=2800, chime_every=6, sparkle_notes=[74, 76, 78, 81, 83, 86]),
}


# ----------------------------------------------------------------- output ---
def write_wav(path, x):
    x = np.atleast_2d(x)
    pcm = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(x.shape[0]); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())


def emit(x, base, force_wav, quality):
    wav = base + ".wav"
    write_wav(wav, x)
    if not force_wav and shutil.which("ffmpeg"):
        r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", str(quality), base + ".ogg"])
        if r.returncode == 0:
            os.remove(wav); return base + ".ogg"
    return wav


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/audio")
    ap.add_argument("--wav", action="store_true")
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "sfx"), exist_ok=True)
    os.makedirs(os.path.join(a.out, "music"), exist_ok=True)
    manifest = []
    for sid, (fn, loop, peak) in SFX.items():
        if a.only and a.only not in sid: continue
        x = normalize(fn(), peak)
        x = x if loop else edge_fade(x)
        p = emit(x, os.path.join(a.out, "sfx", sid), a.wav, 4)
        manifest.append(dict(id=sid, kind="sfx", file=os.path.relpath(p, a.out), loop=loop, seconds=round(len(x) / SR, 2)))
        print("sfx  ", sid)
    # Music now comes from tools/gen_music.py (one soft track). The old bright
    # MUSIC tracks are no longer generated; keep the manifest entry for calm.
    manifest.append(dict(id="calm", kind="music", file="music/calm.flac", loop=True, seconds=168.0))
    mpath = os.path.join(a.out, "manifest.json")
    if os.path.exists(mpath):                      # --only runs merge into the existing manifest
        old = {e["id"]: e for e in json.load(open(mpath))}
        old.update({e["id"]: e for e in manifest})
        manifest = list(old.values())
    with open(mpath, "w") as f:
        json.dump(manifest, f, indent=2)
    print("done:", len(manifest), "files")


if __name__ == "__main__":
    main()