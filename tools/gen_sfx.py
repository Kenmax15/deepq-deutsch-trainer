"""Synthesise the pilot's sound effects and ambiences.

Every sound is generated from scratch with numpy (no samples), so the
project owns all rights to them. Run from the repository root:

    python tools/gen_sfx.py

Output: build/sfx_wav/*.wav (44.1 kHz, 16-bit, mono). The app uses ui_click, hint,
success and wrong, converted to MP3 in web/audio/sfx/ (ffmpeg -i X.wav -ac 1 -b:a 96k X.mp3).
"""
from pathlib import Path
import wave

import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parents[1] / "build" / "sfx_wav"
rng = np.random.default_rng(7)


def write(name, x, peak=0.9):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = (x / m * peak * 32767).astype(np.int16)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x.tobytes())
    if name.endswith("_loop"):
        add_loop_chunk(path, len(x))
    print(f"{name}.wav  {len(x) / SR:5.2f} s")


def add_loop_chunk(path, frames):
    """Append a RIFF 'smpl' chunk marking the whole file as a forward loop.
    Godot's WAV importer ("Loop Mode: Detect From WAV") picks it up."""
    import struct
    data = bytearray(path.read_bytes())
    smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
    smpl += struct.pack("<6I", 0, 0, 0, frames - 1, 0, 0)
    chunk = b"smpl" + struct.pack("<I", len(smpl)) + smpl
    data += chunk
    struct.pack_into("<I", data, 4, len(data) - 8)
    path.write_bytes(bytes(data))


def t(sec):
    return np.arange(int(sec * SR)) / SR


def lowpass(x, cutoff):
    """One-pole low-pass filter."""
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def bandpass(x, lo, hi):
    return lowpass(x, hi) - lowpass(x, lo)


def pink(n):
    """Approximate pink noise (Voss-McCartney with 8 rows)."""
    rows = rng.standard_normal((8, n))
    out = np.zeros(n)
    for k in range(8):
        step = 2 ** k
        held = np.repeat(rows[k, ::step], step)[:n]
        out += held
    return out / 8


def loopable(x, fade=0.5):
    """Cross-fade the end into the start so the file loops without a click."""
    f = int(fade * SR)
    head, body, tail = x[:f], x[f:-f], x[-f:]
    ramp = np.linspace(0, 1, f)
    return np.concatenate([body, tail * (1 - ramp) + head * ramp])


def env(n, attack=0.005, release=0.1):
    e = np.ones(n)
    a, r = int(attack * SR), int(release * SR)
    if a:
        e[:a] = np.linspace(0, 1, a)
    if r:
        e[-r:] = np.linspace(1, 0, r)
    return e


# ---------------------------------------------------------------- engine loop
def engine_loop():
    dur = 3.0
    tt = t(dur)
    f0 = 38 + 2.5 * np.sin(2 * np.pi * 0.5 * tt)   # slight RPM wobble
    ph = 2 * np.pi * np.cumsum(f0) / SR
    x = sum(np.sin(k * ph) / k ** 1.2 for k in range(1, 9))
    x += 0.6 * lowpass(rng.standard_normal(len(tt)), 400)
    x *= 1 + 0.15 * np.sin(4 * ph)                 # firing pulses
    return loopable(lowpass(x, 900), 0.4)


# ----------------------------------------------------------------------- horn
def horn():
    tt = t(0.55)
    x = 0
    for f in (392, 494):                            # two-tone car horn
        x = x + np.sign(np.sin(2 * np.pi * f * tt)) * 0.5 + np.sin(2 * np.pi * 2 * f * tt) * 0.2
    return lowpass(x, 2500) * env(len(tt), 0.01, 0.08)


# ------------------------------------------------------------- city ambience
def city_ambience():
    dur = 16.0
    n = int(dur * SR)
    tt = t(dur)
    rumble = lowpass(pink(n), 250) * 2.5            # distant traffic bed
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * tt / 8.0) ** 2
    hiss = bandpass(rng.standard_normal(n), 800, 3000) * 0.15
    x = rumble * swell + hiss
    # a few distant birds (short chirps)
    for start in (2.1, 2.4, 7.3, 11.8, 12.05, 14.6):
        s = int(start * SR)
        ct = t(0.09)
        chirp = np.sin(2 * np.pi * (3200 + 2500 * ct / 0.09) * ct) * np.hanning(len(ct)) * 0.25
        x[s:s + len(ct)] += chirp
    return loopable(x, 1.0)


# --------------------------------------------------------------- crowd murmur
def crowd_murmur():
    """Unintelligible background voices: band-limited noise shaped by
    syllable-rate envelopes from several 'speakers' at different pitches."""
    dur = 12.0
    n = int(dur * SR)
    tt = t(dur)
    x = np.zeros(n)
    for spk in range(7):
        rate = rng.uniform(3.0, 5.5)                # syllables per second
        syl = np.clip(np.sin(2 * np.pi * rate * tt + rng.uniform(0, 6)), 0, None) ** 2
        phrase = (np.sin(2 * np.pi * rng.uniform(0.15, 0.35) * tt + rng.uniform(0, 6)) > -0.2).astype(float)
        phrase = lowpass(phrase, 8)
        f0 = rng.uniform(110, 230)
        voice = sum(np.sin(2 * np.pi * f0 * k * tt + rng.uniform(0, 6)) / k for k in range(1, 6))
        formant = bandpass(voice + 0.3 * rng.standard_normal(n), 300, 2400)
        x += formant * syl * phrase * rng.uniform(0.5, 1.0)
    return loopable(lowpass(x, 1800), 1.0)


# ------------------------------------------------------------- shop door bell
def door_bell():
    tt = t(1.6)
    x = np.zeros(len(tt))
    for hit in (0.0, 0.18):                         # bell rings twice as the door swings
        s = int(hit * SR)
        tl = tt[: len(tt) - s]
        b = sum(a * np.sin(2 * np.pi * f * tl) * np.exp(-tl * d)
                for f, a, d in ((1870, 1.0, 3.2), (2950, 0.55, 4.5), (4210, 0.35, 6.0), (5600, 0.2, 8.0)))
        x[s:] += b * (1.0 if hit == 0 else 0.7)
    return x


# -------------------------------------------------------------- cash register
def cash_register():
    clicks = np.zeros(int(0.25 * SR))
    for k in range(3):
        s = int((0.03 + 0.05 * k) * SR)
        c = rng.standard_normal(400) * np.exp(-np.arange(400) / 60)
        clicks[s:s + 400] += c * 0.6
    tt = t(1.1)
    ding = sum(a * np.sin(2 * np.pi * f * tt) * np.exp(-tt * 3.5)
               for f, a in ((2093, 1.0), (4186, 0.35), (2637, 0.5)))
    drawer = lowpass(rng.standard_normal(int(0.3 * SR)), 600) * np.linspace(1, 0, int(0.3 * SR)) * 0.8
    out = np.zeros(int(1.6 * SR))
    out[: len(clicks)] += clicks
    s = int(0.22 * SR)
    out[s:s + len(ding)] += ding * 0.8
    s = int(0.25 * SR)
    out[s:s + len(drawer)] += drawer
    return out


# ------------------------------------------------------------- coffee machine
def coffee_machine():
    dur = 6.0
    n = int(dur * SR)
    tt = t(dur)
    pump = np.sin(2 * np.pi * 50 * tt) * 0.3 + np.sin(2 * np.pi * 100 * tt) * 0.15
    hiss = bandpass(rng.standard_normal(n), 2000, 9000) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.2 * tt) ** 2)
    gurgle = lowpass(rng.standard_normal(n), 300) * (np.sin(2 * np.pi * 7 * tt) > 0.6) * 1.5
    return loopable(pump + hiss * 0.6 + gurgle, 0.5)


# -------------------------------------------------------------------- footstep
def footstep():
    n = int(0.12 * SR)
    x = lowpass(rng.standard_normal(n), 900) * np.exp(-np.arange(n) / (0.02 * SR))
    return x


# ------------------------------------------------------------------------- UI
def chime(freqs, step=0.11, decay=5.0, length=1.2):
    tt = t(length)
    x = np.zeros(len(tt))
    for i, f in enumerate(freqs):
        s = int(i * step * SR)
        tl = tt[: len(tt) - s]
        x[s:] += (np.sin(2 * np.pi * f * tl) + 0.3 * np.sin(2 * np.pi * 2 * f * tl)) * np.exp(-tl * decay)
    return x


def ui_click():
    tt = t(0.06)
    return np.sin(2 * np.pi * 1400 * tt) * np.exp(-tt * 80)


# -------------------------------------------------------------------- music
def cafe_music():
    """A calm 16-bar loop (I-vi-IV-V in C) with soft electric-piano tones."""
    bpm = 84
    beat = 60 / bpm
    bars = [(60, 64, 67), (57, 60, 64), (53, 57, 60), (55, 59, 62)] * 2
    dur = len(bars) * 4 * beat
    n = int(dur * SR)
    x = np.zeros(n)
    midi = lambda m: 440 * 2 ** ((m - 69) / 12)
    melody = [72, 74, 76, 79, 76, 74, 72, 69, 72, 71, 69, 67, 65, 67, 69, 71,
              72, 76, 79, 81, 79, 76, 74, 72, 69, 72, 74, 72, 71, 67, 71, 74]
    for b, chord in enumerate(bars):
        for k in range(2):                          # two chord hits per bar
            s = int((b * 4 + k * 2) * beat * SR)
            tl = t(2 * beat)
            e = np.exp(-tl * 1.6)
            for m in chord:
                f = midi(m - 12)
                x[s:s + len(tl)] += (np.sin(2 * np.pi * f * tl) + 0.2 * np.sin(2 * np.pi * 2 * f * tl)) * e * 0.25
        for k in range(4):
            note = melody[(b * 4 + k) % len(melody)]
            if (b + k) % 3 == 2:
                continue                            # leave some space
            s = int((b * 4 + k) * beat * SR)
            tl = t(beat)
            f = midi(note)
            x[s:s + len(tl)] += (np.sin(2 * np.pi * f * tl) + 0.15 * np.sin(2 * np.pi * 3 * f * tl)) * np.exp(-tl * 3) * 0.35
    return loopable(lowpass(x, 3000), 0.3)


if __name__ == "__main__":
    write("engine_loop", engine_loop(), 0.8)
    write("horn", horn())
    write("city_ambience_loop", city_ambience(), 0.7)
    write("crowd_murmur_loop", crowd_murmur(), 0.7)
    write("door_bell", door_bell())
    write("cash_register", cash_register())
    write("coffee_machine_loop", coffee_machine(), 0.6)
    write("footstep", footstep(), 0.6)
    write("success", chime([523, 659, 784, 1047]))
    write("hint", chime([880, 1175], step=0.08, decay=8, length=0.6), 0.6)
    write("wrong", chime([330, 262], step=0.12, decay=7, length=0.6), 0.6)
    write("ui_click", ui_click(), 0.5)
    write("cafe_music_loop", cafe_music(), 0.7)
