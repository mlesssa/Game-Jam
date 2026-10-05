"""Generates every sound effect and the music loop for Bleed (pure numpy synthesis, no samples)."""
import numpy as np, wave, os
SR = 22050
rng = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")
os.makedirs(OUT + "/sfx", exist_ok=True)
os.makedirs(OUT + "/music", exist_ok=True)

def write(path, x):
    x = x / max(1e-6, np.abs(x).max()) * 0.8
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())

def pluck(f, dur, decay=0.996):
    n = max(2, int(SR / f)); buf = rng.uniform(-1, 1, n); out = np.zeros(int(SR * dur))
    for i in range(len(out)):
        out[i] = buf[i % n]
        buf[i % n] = decay * 0.5 * (buf[i % n] + buf[(i + 1) % n])
    return out

def sweep(f0, f1, dur, vib=0.0):
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    f = f0 + (f1 - f0) * t / dur + vib * np.sin(2 * np.pi * 14 * t) * 20
    ph = 2 * np.pi * np.cumsum(f) / SR
    return (np.sin(ph) + 0.3 * np.sin(2 * ph)) * np.exp(-3.2 * t / dur)

def mix(parts, total):
    out = np.zeros(int(SR * total))
    for start, p in parts:
        s = int(start * SR); e = min(len(out), s + len(p)); out[s:e] += p[:e - s]
    return out

N = {"A2": 110, "A3": 220, "C4": 261.63, "E4": 329.63, "A4": 440, "C5": 523.25, "E5": 659.25, "A5": 880,
     "F3": 174.61, "G3": 196, "B3": 246.94, "D4": 293.66, "G4": 392, "F4": 349.23, "C3": 130.81, "G2": 98, "F2": 87.31}
S = lambda n: f"{OUT}/sfx/{n}.wav"
write(S("jump"), sweep(320, 600, 0.14))
write(S("bounce"), sweep(220, 900, 0.22, vib=1))
write(S("plate"), mix([(0, pluck(440, .3, .99)), (.07, pluck(660, .3, .99))], .4))
write(S("gate"), mix([(0, pluck(165, .6, .995)), (0, 0.4 * sweep(120, 70, .5))], .6))
t = np.linspace(0, .55, int(SR * .55))
write(S("death"), (sweep(420, 70, .55) + 0.25 * rng.uniform(-1, 1, len(t)) * np.exp(-6 * t)))
write(S("checkpoint"), mix([(i * .09, pluck(f, .7, .993)) for i, f in enumerate([440, 523.25, 659.25, 880])], 1.1))
write(S("goal"), mix([(i * .11, pluck(f, 1.0, .995)) for i, f in enumerate([261.63, 329.63, 392, 523.25, 659.25, 783.99])], 1.9))
write(S("ui_move"), pluck(660, .15, .98))
write(S("ui_select"), mix([(0, pluck(880, .3, .99)), (.05, pluck(1320, .3, .99))], .4))
b = np.concatenate([sweep(880, 880, .08), np.zeros(int(SR * .05)), sweep(880, 880, .08)])
write(S("warn"), b)
write(S("swap"), mix([(0, sweep(500, 800, .08)), (.07, sweep(800, 500, .08))], .2))

# music: 4 bars of 4/4 at 60 bpm, Am | F | C | G, arpeggiated lyre + soft pad
bars = [("A2", ["A3", "C4", "E4", "A4", "E4", "C4", "E4", "C4"], ["A3", "C4", "E4"]),
        ("F2", ["F3", "A3", "C4", "F4", "C4", "A3", "C4", "A3"], ["F3", "A3", "C4"]),
        ("C3", ["C4", "E4", "G4", "C5", "G4", "E4", "G4", "E4"], ["C4", "E4", "G4"]),
        ("G2", ["G3", "B3", "D4", "G4", "D4", "B3", "D4", "B3"], ["G3", "B3", "D4"])]
extra = {"F2": 87.31, "F3": 174.61, "F4": 349.23, "C3": 130.81, "G2": 98, "G3": 196, "B3": 246.94, "D4": 293.66, "G4": 392}
N.update(extra)
parts = []
for bi, (bass, arp, pad) in enumerate(bars):
    t0 = bi * 4.0
    parts.append((t0, 0.9 * pluck(N[bass], 4.0, .9985)))
    for i, n in enumerate(arp):
        parts.append((t0 + i * .5, 0.55 * pluck(N[n], 2.0, .997)))
    tt = np.linspace(0, 4.0, int(SR * 4.0))
    env = np.sin(np.pi * tt / 4.0) ** 2
    parts.append((t0, 0.12 * env * sum(np.sin(2 * np.pi * N[n] * tt) for n in pad)))
m = mix(parts, 16.0)
# fold the tail back to the start so the loop is seamless
tail = m[int(SR * 16):] if len(m) > SR * 16 else np.zeros(0)
write(OUT + "/music/theme.wav", m)
print("audio done")
