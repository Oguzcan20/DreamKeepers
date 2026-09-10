#!/usr/bin/env python3
"""Dreamkeepers battle SFX synthesizer.

Renders short cinematic battle cues as 16-bit mono 44.1 kHz WAV files.
Replaces the jarring iOS system-sound placeholders -- the boss "encounter"
beep in particular sounded like an ambulance siren.

Design intent (per user): the epic cues must be SHORT stings, not
cinematic build-ups -- a quick hit of drama, then out of the way. Basic
attacks and skills fire constantly, so their cues are tiny and quiet.

Cues produced:
    boss_encounter.wav  ~1.5s  dark D-minor stab: crash + sub drop + brass
    boss_victory.wav    ~1.6s  D-major fanfare chord + timpani pickup + sparkle
    ultimate.wav        ~1.0s  heavy layered impact + power-down sweep
    skill.wav           ~0.33s quick whoosh + blip (fires often -> subtle)
    attack.wav          ~0.12s dry percussive thwack (every basic hit -> quiet)
    summon.wav          ~0.9s  rising magical shimmer + bell arpeggio
    level_up.wav        ~1.0s  bright ascending major triad + brass pad
    reward.wav          ~0.5s  warm confirming major chord + sparkle
    button_tap.wav      ~0.04s soft muted UI click (nearly every tap -> tiny)

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
C4, E4, G4, B4, C5 = 261.63, 329.63, 392.00, 493.88, 523.25


# ---------------------------------------------------------------- compositions

def boss_encounter():
    """Short dark sting: one big D-minor hit, a quick drone, done (~1.5s)."""
    d = zeros(1.5)

    # downbeat: crash + sub drop + boom, all fast-decaying
    add(d, 0.0, cymbal(1.2, 0.45, 2600), 0.4)
    add(d, 0.0, expenv(sine(96.0, 1.1, glide_to=D1) + sine(D1, 1.1), 0.38), 0.6)
    add(d, 0.0, expenv(lowpass(noise(0.4), 150), 0.26), 0.5)

    # brass stab (D minor) + accent timpani -- the drama, kept to one hit
    add(d, 0.0, ar(brass_chord([D2, A2, D3, F3, A3], 0.75), 0.006, 0.35), 0.55)
    add(d, 0.0, timpani(A1, 0.7), 0.7)
    add(d, 0.15, timpani(D2, 0.45), 0.38)

    # brief ominous tail drone, then silence
    drone = sine(D2, 0.95) + sine(A2, 0.95)
    drone *= 1.0 + 0.16 * np.sin(2 * np.pi * 3.2 * tvec(len(drone) / SR)[: len(drone)])
    add(d, 0.4, ar(drone, 0.04, 0.6), 0.24)

    return finalize(reverb(d, 0.18))


def boss_victory():
    """Short triumphant sting: fanfare chord up front, quick sparkle (~1.6s)."""
    d = zeros(1.6)

    # tight timpani pickup (5 hits, accelerating) under the downbeat
    t, gap = 0.0, 0.10
    for _ in range(5):
        add(d, t, timpani(D2, 0.32), 0.4)
        t += gap
        gap *= 0.82

    # D-major fanfare chord immediately -- no dotted lead-in
    big = brass_chord([D3, Fs3, A3, D4], 1.2, detune=0.011)
    nb = len(big)
    big *= 1.0 + 0.05 * np.sin(2 * np.pi * 5.6 * tvec(nb / SR)[:nb])
    add(d, 0.0, ar(big, 0.01, 0.5), 0.6)

    # crash + sub punch under the chord
    add(d, 0.0, cymbal(1.2, 0.85, 2800), 0.4)
    add(d, 0.0, expenv(sine(A2, 1.2, glide_to=D2), 0.75), 0.5)

    # sparkle bell arpeggio on top
    for k, bf in enumerate((D4 * 2, Fs4 * 2, A4 * 2, D5 * 2)):
        add(d, 0.10 + 0.08 * k, expenv(sine(bf, 0.45), 0.26), 0.07)

    # short sustained major tail
    tail = sine(D2, 0.85) + sine(A2, 0.85) + sine(Fs3, 0.85) + sine(A3, 0.85)
    add(d, 0.7, ar(tail, 0.05, 0.55), 0.2)

    return finalize(reverb(d, 0.2))


def ultimate():
    d = zeros(1.0)

    add(d, 0.00, riseenv(highpass(noise(0.10), 1400), 2.0), 0.22)

    add(d, 0.08, expenv(sine(120.0, 0.8, glide_to=33.0), 0.32), 0.9)
    add(d, 0.08, expenv(lowpass(noise(0.24), 170), 0.2), 0.5)

    rm = sine(1210.0, 0.25) * sine(1210.0 * 1.4703, 0.25) + 0.6 * sine(2417.0, 0.25)
    add(d, 0.08, expenv(rm, 0.16), 0.2)

    pd = saw(430.0, 0.42, glide_to=68.0) + saw(430.0 * 1.006, 0.42, glide_to=68.0)
    pd = np.tanh(1.6 * lowpass(pd, 3000))
    add(d, 0.08, expenv(pd, 0.3), 0.28)

    for sf in (1976.0, 2637.0, 3136.0):
        add(d, 0.10, expenv(sine(sf, 0.7), 0.45), 0.04)

    return finalize(reverb(d, 0.12), peak=0.92)


def skill():
    d = zeros(0.34)
    add(d, 0.0, ar(lowpass_swept(noise(0.24), 4200, 700), 0.006, 0.11), 0.26)
    add(d, 0.02, expenv(sine(523.0, 0.18, glide_to=784.0), 0.05), 0.15)
    click = highpass(noise(0.010), 2200)
    add(d, 0.0, click, 0.12)
    return finalize(d, peak=0.72, drive=1.0)


def attack():
    """Dry percussive thwack for every basic hit -- tiny and quiet so a
    fast auto-battle doesn't turn into a machine gun."""
    d = zeros(0.12)
    # low thump body
    add(d, 0.0, expenv(sine(180.0, 0.10, glide_to=90.0), 0.028), 0.6)
    # midrange smack
    add(d, 0.0, expenv(lowpass(noise(0.08), 2600), 0.016), 0.5)
    # tiny transient click
    add(d, 0.0, highpass(noise(0.004), 3500), 0.22)
    return finalize(d, peak=0.55, drive=1.0)


def summon():
    """Rising magical shimmer -- anticipation before a gacha reveal (~0.9s)."""
    d = zeros(0.9)
    add(d, 0.0, riseenv(lowpass_swept(noise(0.7), 600, 5000), 1.8), 0.15)
    for k, bf in enumerate((D4, Fs4, A4, D5, Fs4 * 2)):
        add(d, 0.04 + 0.09 * k, expenv(sine(bf, 0.5), 0.3), 0.14)
    for k, bf in enumerate((D5 * 2, A4 * 2, Fs4 * 3)):
        add(d, 0.45 + 0.07 * k, expenv(sine(bf, 0.4), 0.18), 0.05)
    return finalize(reverb(d, 0.2), peak=0.8)


def level_up():
    """Bright ascending major triad run + soft brass pad (~1.0s)."""
    d = zeros(1.0)
    for k, nf in enumerate((D4, Fs4, A4, D5)):
        add(d, 0.08 * k, expenv(sine(nf, 0.6) + 0.4 * sine(nf * 2, 0.6), 0.28), 0.16)
    add(d, 0.0, ar(brass_chord([D3, Fs3, A3, D4], 0.7, detune=0.01), 0.02, 0.3), 0.2)
    for k, bf in enumerate((D5 * 2, Fs4 * 4, A4 * 4)):
        add(d, 0.30 + 0.06 * k, expenv(sine(bf, 0.4), 0.2), 0.05)
    add(d, 0.0, cymbal(0.5, 0.22, 5000), 0.09)
    return finalize(reverb(d, 0.18), peak=0.85)


def reward():
    """Warm confirming major chord pluck + gentle sparkle (~0.5s)."""
    d = zeros(0.5)
    chord = sine(D3, 0.45) + sine(Fs3, 0.45) + sine(A3, 0.45) + sine(D4, 0.45)
    add(d, 0.0, expenv(chord, 0.16), 0.2)
    add(d, 0.0, ar(brass_chord([D3, Fs3, A3], 0.3, detune=0.008), 0.01, 0.12), 0.15)
    for k, bf in enumerate((A4, D5, Fs4 * 2)):
        add(d, 0.06 + 0.05 * k, expenv(sine(bf, 0.3), 0.14), 0.06)
    return finalize(reverb(d, 0.15), peak=0.72)


def button_tap():
    """Soft muted UI click -- fires on nearly every tap, so tiny (~0.04s)."""
    d = zeros(0.05)
    add(d, 0.0, expenv(lowpass(noise(0.03), 1800), 0.006), 0.3)
    add(d, 0.0, expenv(sine(660.0, 0.03), 0.008), 0.12)
    return finalize(d, peak=0.4, drive=1.0)


CUES = {
    "boss_encounter": boss_encounter,
    "boss_victory": boss_victory,
    "ultimate": ultimate,
    "skill": skill,
    "attack": attack,
    "summon": summon,
    "level_up": level_up,
    "reward": reward,
    "button_tap": button_tap,
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
