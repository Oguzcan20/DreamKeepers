#!/usr/bin/env python3
"""Dreamkeepers battle SFX synthesizer.

Renders short cinematic battle cues as 16-bit mono 44.1 kHz WAV files.
Replaces the jarring iOS system-sound placeholders -- the boss "encounter"
beep in particular sounded like an ambulance siren.

Cues produced:
    boss_encounter.wav  ~3.8s  dark D-minor impact + brass crescendo + riser
    boss_victory.wav    ~2.6s  triumphant D-major brass fanfare + timpani
    ultimate.wav        ~1.4s  heavy layered impact + power-down sweep
    skill.wav           ~0.4s  quick whoosh + blip (plays often -> kept subtle)

Requires numpy. Usage:
    ./synth_battle_audio.py [output_dir]
"""
import os
import sys
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(1729)


# ---------------------------------------------------------------- primitives

def zeros(dur):
    return np.zeros(int(dur * SR), dtype=np.float64)


def tvec(dur):
    return np.arange(int(dur * SR)) / SR


def add(dst, start, src, gain=1.0):
    s = int(start * SR)
    e = min(len(dst), s + len(src))
    if s < 0 or s >= len(dst) or e <= s:
        return
    dst[s:e] += src[: e - s] * gain


def _freq_curve(freq, dur, glide_to):
    t = tvec(dur)
    if glide_to is None:
        return np.full(t.shape, float(freq)), t
    return freq * (glide_to / freq) ** (t / dur), t


def sine(freq, dur, glide_to=None, vib_rate=0.0, vib_depth=0.0):
    f, t = _freq_curve(freq, dur, glide_to)
    if vib_rate:
        f = f * (1.0 + vib_depth * np.sin(2 * np.pi * vib_rate * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph)


def saw(freq, dur, glide_to=None):
    f, _ = _freq_curve(freq, dur, glide_to)
    ph = np.cumsum(f) / SR
    return 2.0 * (ph - np.floor(ph + 0.5))


def noise(dur):
    return rng.uniform(-1.0, 1.0, int(dur * SR))


def _onepole_lp(sig, a):
    # y[n] = (1-a) x[n] + a y[n-1], vectorised via cumulative recurrence.
    b = 1.0 - a
    # scipy-free IIR: iterate in chunks is still O(n); use lfilter-like loop
    out = np.empty_like(sig)
    y = 0.0
    for i in range(sig.shape[0]):
        y = b * sig[i] + a * y
        out[i] = y
    return out


def lowpass(sig, cutoff):
    a = float(np.exp(-2 * np.pi * cutoff / SR))
    return _onepole_lp(sig, a)


def highpass(sig, cutoff):
    return sig - lowpass(sig, cutoff)


def lowpass_swept(sig, c0, c1):
    n = sig.shape[0]
    cs = c0 * (c1 / c0) ** (np.arange(n) / max(1, n - 1))
    a = np.exp(-2 * np.pi * cs / SR)
    b = 1.0 - a
    out = np.empty_like(sig)
    y = 0.0
    for i in range(n):
        y = b[i] * sig[i] + a[i] * y
        out[i] = y
    return out


def expenv(sig, tau):
    return sig * np.exp(-tvec(len(sig) / SR)[: len(sig)] / tau)


def riseenv(sig, power=1.5):
    n = len(sig)
    return sig * (np.arange(n) / max(1, n - 1)) ** power


def ar(sig, a, r):
    n = len(sig)
    env = np.ones(n)
    ai = max(1, int(a * SR))
    ri = max(1, int(r * SR))
    env[:ai] = np.linspace(0.0, 1.0, ai)
    env[n - ri:] = np.linspace(1.0, 0.0, ri)
    return sig * env


# ---------------------------------------------------------------- instruments

def brass_chord(freqs, dur, detune=0.008, cutoff=2500, drive=1.9):
    """Detuned saw stack, low-passed and saturated -> a brass-ish swell."""
    n = int(dur * SR)
    out = np.zeros(n)
    for f in freqs:
        for dt in (-detune, 0.0, detune):
            out += saw(f * (1.0 + dt), dur)
    out /= len(freqs) * 3
    out = lowpass(out, cutoff)
    return np.tanh(drive * out) / np.tanh(drive)


def timpani(root, dur=0.6):
    body = expenv(sine(root, dur, glide_to=root * 0.78), dur * 0.28)
    click = highpass(noise(0.02), 900) * 0.35
    out = body.copy()
    out[: len(click)] += click
    return out


def cymbal(dur, tau, cutoff=3000):
    return expenv(highpass(noise(dur), cutoff), tau)


# ---------------------------------------------------------------- reverb

def reverb(sig, mix=0.22):
    combs = [(1116, 0.805), (1188, 0.827), (1277, 0.783), (1356, 0.764)]
    allps = [(556, 0.7), (441, 0.7)]
    wet = np.zeros_like(sig)
    for delay, fb in combs:
        y = np.zeros_like(sig)
        for i in range(sig.shape[0]):
            y[i] = sig[i] + (y[i - delay] * fb if i >= delay else 0.0)
        wet += y
    wet /= len(combs)
    for delay, g in allps:
        out = np.zeros_like(wet)
        for i in range(wet.shape[0]):
            prev = out[i - delay] if i >= delay else 0.0
            buf_in = wet[i] + prev * g
            out[i] = prev - g * buf_in
        wet = out
    return (1 - mix) * sig + mix * wet


def finalize(sig, peak=0.95, drive=1.1):
    m = max(1e-9, float(np.max(np.abs(sig))))
    g = peak / m
    return np.tanh(drive * (sig * g)) / np.tanh(drive) * 0.985


def write_wav(path, sig):
    data = np.clip(sig, -1.0, 1.0)
    pcm = (data * 32767.0).astype('<i2')
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"  {os.path.basename(path):22s} {len(sig)/SR:4.2f}s  {len(pcm)*2//1024} KB")


# ---------------------------------------------------------------- notes (Hz)

D1, A1 = 36.71, 55.00
D2, F2, A2, C3 = 73.42, 87.31, 110.00, 130.81
D3, F3, Fs3, A3 = 146.83, 174.61, 185.00, 220.00
E3, G3, Bb3 = 164.81, 196.00, 233.08
D4, Fs4, A4, D5 = 293.66, 369.99, 440.00, 587.33


# ---------------------------------------------------------------- compositions

def boss_encounter():
    d = zeros(3.8)

    # downbeat: crash + sub drop + low boom
    add(d, 0.0, cymbal(1.9, 0.9, 2600), 0.42)
    sub = expenv(sine(96.0, 1.5, glide_to=D1) + sine(D1, 1.5), 0.55)
    add(d, 0.0, sub, 0.55)
    add(d, 0.0, expenv(lowpass(noise(0.45), 150), 0.32), 0.5)

    # timpani triplet into the bar
    for t in (0.00, 0.30, 0.60):
        add(d, t, timpani(D2, 0.55), 0.5)

    # brass stab, then the long crescendo swell
    add(d, 0.0, ar(brass_chord([D2, A2, D3, F3, A3], 0.55), 0.012, 0.15), 0.5)

    swell = brass_chord([D2, A2, D3, F3, A3], 1.65, detune=0.01)
    n = len(swell)
    swell *= (np.arange(n) / n) ** 1.6
    swell *= 1.0 + 0.06 * np.sin(2 * np.pi * 5.2 * tvec(n / SR)[:n])
    add(d, 0.55, swell, 0.62)

    # riser: swept-noise + sine glissando
    add(d, 0.55, riseenv(lowpass_swept(noise(1.7), 500, 6500), 2.2), 0.3)
    add(d, 0.55, riseenv(sine(D3, 1.7, glide_to=D4 * 2), 2.5), 0.12)

    # the hit at 2.20: accent crash + low sforzando chord + big timpani
    add(d, 2.20, cymbal(1.6, 1.5, 4200), 0.4)
    add(d, 2.20, timpani(A1, 0.9), 0.8)
    low = brass_chord([A1, D2, A2, D3], 1.6, detune=0.012, cutoff=1800)
    low *= 1.0 + 0.14 * np.sin(2 * np.pi * 3.0 * tvec(len(low) / SR)[: len(low)])
    add(d, 2.20, ar(low, 0.015, 0.5), 0.5)

    # ominous tail drone
    drone = sine(D2, 1.5) + sine(A2, 1.5)
    drone *= 1.0 + 0.16 * np.sin(2 * np.pi * 3.2 * tvec(len(drone) / SR)[: len(drone)])
    add(d, 2.30, ar(drone, 0.12, 0.9), 0.26)

    return finalize(reverb(d, 0.22))


def boss_victory():
    d = zeros(2.6)

    # accelerating timpani roll into the fanfare
    t, gap = 0.0, 0.13
    for _ in range(10):
        add(d, t, timpani(D2, 0.4), 0.4)
        t += gap
        gap *= 0.8

    # dotted brass fanfare: D - D - (E) - big Dmaj
    add(d, 0.00, ar(brass_chord([D3, Fs3, A3], 0.34), 0.01, 0.08), 0.5)
    add(d, 0.28, ar(brass_chord([D3, Fs3, A3], 0.26), 0.01, 0.06), 0.48)
    add(d, 0.50, ar(brass_chord([E3, G3, Bb3], 0.20), 0.01, 0.05), 0.4)

    big = brass_chord([D3, Fs3, A3, D4], 1.7, detune=0.011)
    nb = len(big)
    big *= 1.0 + 0.05 * np.sin(2 * np.pi * 5.6 * tvec(nb / SR)[:nb])
    big *= np.minimum(1.0, 0.55 + 0.9 * (np.arange(nb) / nb) ** 0.5)
    add(d, 0.78, ar(big, 0.014, 0.55), 0.6)

    # crash + sub punch under the big chord
    add(d, 0.78, cymbal(1.5, 1.3, 2800), 0.4)
    add(d, 0.78, expenv(sine(A2, 1.6, glide_to=D2), 1.1), 0.55)

    # sparkle bell arpeggio on top
    for k, bf in enumerate((D4 * 2, Fs4 * 2, A4 * 2, D4 * 4)):
        add(d, 0.95 + 0.10 * k, expenv(sine(bf, 0.6), 0.32), 0.07)

    # sustained major tail
    tail = sine(D2, 1.3) + sine(A2, 1.3) + sine(D3, 1.3) + sine(Fs3, 1.3) + sine(A3, 1.3)
    add(d, 1.30, ar(tail, 0.1, 0.8), 0.22)

    return finalize(reverb(d, 0.25))


def ultimate():
    d = zeros(1.4)

    add(d, 0.00, riseenv(highpass(noise(0.12), 1400), 2.0), 0.24)

    add(d, 0.10, expenv(sine(120.0, 1.1, glide_to=33.0), 0.42), 0.9)
    add(d, 0.10, expenv(lowpass(noise(0.3), 170), 0.26), 0.5)

    rm = sine(1210.0, 0.3) * sine(1210.0 * 1.4703, 0.3) + 0.6 * sine(2417.0, 0.3)
    add(d, 0.10, expenv(rm, 0.2), 0.22)

    pd = saw(430.0, 0.55, glide_to=68.0) + saw(430.0 * 1.006, 0.55, glide_to=68.0)
    pd = np.tanh(1.6 * lowpass(pd, 3000))
    add(d, 0.10, expenv(pd, 0.4), 0.3)

    for sf in (1976.0, 2637.0, 3136.0):
        add(d, 0.12, expenv(sine(sf, 0.9), 0.6), 0.045)

    return finalize(reverb(d, 0.15), peak=0.92)


def skill():
    d = zeros(0.42)
    add(d, 0.0, ar(lowpass_swept(noise(0.28), 4200, 700), 0.008, 0.14), 0.28)
    add(d, 0.02, expenv(sine(523.0, 0.2, glide_to=784.0), 0.06), 0.16)
    click = highpass(noise(0.012), 2200)
    add(d, 0.0, click, 0.13)
    return finalize(d, peak=0.8, drive=1.0)


CUES = {
    "boss_encounter": boss_encounter,
    "boss_victory": boss_victory,
    "ultimate": ultimate,
    "skill": skill,
}


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    print(f"Rendering {len(CUES)} cues -> {out_dir}")
    for name, fn in CUES.items():
        write_wav(os.path.join(out_dir, f"{name}.wav"), fn())
    print("done.")


if __name__ == "__main__":
    main()
