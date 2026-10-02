"""Generates the app's short UI sound cues as 16-bit 44.1kHz mono WAV files.

These are synthesised from scratch (soft bell/marimba-like additive sines with
exponential decay), so they are original and royalty-free. Run from the repo
root:  python3 tool/generate_sounds.py
Output: assets/sounds/*.wav
"""
import math
import os
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")

# Equal-temperament helper: note name -> frequency.
_NOTES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
          "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(note: str) -> float:
    name, octave = note[:-1], int(note[-1])
    semis = _NOTES[name] + (octave - 4) * 12 - 9  # relative to A4
    return 440.0 * (2 ** (semis / 12.0))


def bell(freq, dur, amp=0.5, decay=9.0, partials=(1.0, 2.0, 3.0), mix=(1.0, 0.28, 0.1)):
    """One soft struck-bell voice."""
    n = int(SR * dur)
    out = [0.0] * n
    norm = sum(mix)
    for p, m in zip(partials, mix):
        w = 2 * math.pi * freq * p
        for i in range(n):
            t = i / SR
            out[i] += m / norm * math.sin(w * t) * math.exp(-decay * t)
    # short fade-in kills the click at the attack
    fade = int(0.004 * SR)
    for i in range(min(fade, n)):
        out[i] *= i / fade
    return [v * amp for v in out]


def layer(tracks, total):
    """Mix (offset_seconds, samples) tracks into one buffer of `total` seconds."""
    n = int(SR * total)
    buf = [0.0] * n
    for offset, samples in tracks:
        start = int(offset * SR)
        for i, v in enumerate(samples):
            j = start + i
            if j < n:
                buf[j] += v
    return buf


def save(name, buf, headroom=0.82):
    peak = max((abs(v) for v in buf), default=1.0) or 1.0
    scale = headroom / peak
    # gentle tail fade so nothing ends abruptly
    n = len(buf)
    fade = min(int(0.02 * SR), n)
    frames = bytearray()
    for i, v in enumerate(buf):
        s = v * scale
        if i >= n - fade:
            s *= (n - i) / fade
        frames += struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print(f"wrote {name}  {len(buf)/SR:.2f}s  {os.path.getsize(path)//1024}KB")


def arpeggio(notes, step, dur, amp=0.5, decay=8.0):
    tracks = [(i * step, bell(hz(nt), dur, amp, decay)) for i, nt in enumerate(notes)]
    return layer(tracks, (len(notes) - 1) * step + dur)


os.makedirs(OUT, exist_ok=True)

# tap: barely-there wooden blip for buttons and card taps
save("tap.wav", bell(hz("A5"), 0.09, amp=0.34, decay=38.0, mix=(1.0, 0.15, 0.0)))

# correct: bright rising third+fifth, warm not shrill
save("correct.wav", arpeggio(["E5", "G#5", "B5"], 0.062, 0.34, amp=0.46, decay=10.0))

# incorrect: soft, low, falling — a nudge, never a buzzer
save("incorrect.wav", layer([
    (0.0, bell(hz("F#4"), 0.26, amp=0.4, decay=14.0, mix=(1.0, 0.2, 0.0))),
    (0.075, bell(hz("D4"), 0.3, amp=0.36, decay=12.0, mix=(1.0, 0.2, 0.0))),
], 0.42))

# lesson complete: four-note major climb
save("complete.wav", arpeggio(["C5", "E5", "G5", "C6"], 0.085, 0.5, amp=0.44, decay=7.0))

# forum post sent: quick two-note lift
save("post.wav", arpeggio(["D5", "A5"], 0.055, 0.24, amp=0.4, decay=16.0))

# quiz passed: longer sparkle over a held major chord
chord = [(0.0, bell(hz(n), 1.5, amp=0.3, decay=2.6)) for n in ("C4", "G4", "C5", "E5")]
sparkle = [(0.18 + i * 0.075, bell(hz(n), 0.6, amp=0.3, decay=9.0))
           for i, n in enumerate(("G5", "C6", "E6", "G6", "C7", "E6", "G6"))]
save("celebrate.wav", layer(chord + sparkle, 1.7))
