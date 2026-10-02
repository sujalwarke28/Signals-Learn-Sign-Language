"""Generates assets/lottie/confetti.json -- an original Lottie confetti burst.

Each particle is a shape layer whose position keyframes sample a simple
projectile trajectory (outward velocity + gravity + drag), so the burst reads as
physical rather than as a linear fan-out. Run from the repo root:
  python3 tool/generate_lottie.py
"""
import json
import math
import os
import random

W = H = 512
FR = 60
OP = 110            # total frames
N = 46              # particles
random.seed(7)

# Muted-but-cheerful palette that reads well on both light and dark surfaces.
PALETTE = [
    (0x6C, 0x5C, 0xE7), (0x8E, 0x7C, 0xFF), (0x2E, 0xC4, 0xB6),
    (0xFF, 0xB7, 0x4D), (0xFF, 0x8A, 0x8A), (0x4D, 0xB6, 0xFF),
    (0xA0, 0xE8, 0x7A), (0xFF, 0xD1, 0x66),
]


def srgb(c):
    return [round(v / 255.0, 4) for v in c] + [1]


def trajectory(angle, speed, frames, samples=10):
    """Sampled (frame, [x, y, 0]) keyframes for one particle."""
    vx = math.cos(angle) * speed
    vy = math.sin(angle) * speed
    g = 0.42            # gravity per frame^2
    drag = 0.982
    x, y = W / 2, H / 2 + 20
    pts = [(0, [round(x, 1), round(y, 1), 0])]
    step = max(1, frames // samples)
    for f in range(1, frames + 1):
        vx *= drag
        vy = vy * drag + g
        x += vx
        y += vy
        if f % step == 0 or f == frames:
            pts.append((f, [round(x, 1), round(y, 1), 0]))
    return pts


def kf_multi(points):
    """Animated multi-dimensional property from [(frame, value), ...]."""
    out = []
    for i, (t, v) in enumerate(points):
        k = {"t": t, "s": v}
        if i < len(points) - 1:
            k["i"] = {"x": 0.4, "y": 1.0}
            k["o"] = {"x": 0.6, "y": 0.0}
        out.append(k)
    return {"a": 1, "k": out}


def kf_scalar(points):
    out = []
    for i, (t, v) in enumerate(points):
        k = {"t": t, "s": [v]}
        if i < len(points) - 1:
            k["i"] = {"x": [0.5], "y": [1.0]}
            k["o"] = {"x": [0.5], "y": [0.0]}
        out.append(k)
    return {"a": 1, "k": out}


layers = []
for i in range(N):
    # bias the burst upward and outward
    angle = random.uniform(-math.pi * 0.96, -math.pi * 0.04)
    speed = random.uniform(5.5, 13.0)
    delay = random.randint(0, 9)
    life = OP - delay
    size = random.uniform(9, 17)
    ribbon = random.random() < 0.55          # rectangles vs. round dots
    spin = random.choice([-1, 1]) * random.uniform(360, 1080)
    color = srgb(random.choice(PALETTE))

    shape = ({"ty": "rc", "d": 1, "s": {"a": 0, "k": [size, size * random.uniform(0.38, 0.6)]},
              "p": {"a": 0, "k": [0, 0]}, "r": {"a": 0, "k": 2}, "nm": "r"}
             if ribbon else
             {"ty": "el", "d": 1, "s": {"a": 0, "k": [size * 0.8, size * 0.8]},
              "p": {"a": 0, "k": [0, 0]}, "nm": "e"})

    layers.append({
        "ddd": 0, "ind": i + 1, "ty": 4, "nm": f"p{i}", "sr": 1, "ao": 0,
        "ip": delay, "op": OP, "st": delay, "bm": 0,
        "ks": {
            "o": kf_scalar([(delay, 0), (delay + 3, 100),
                            (delay + int(life * 0.66), 100), (OP, 0)]),
            "r": kf_scalar([(delay, random.uniform(0, 360)),
                            (OP, random.uniform(0, 360) + spin)]),
            "p": kf_multi([(delay + t, v) for t, v in trajectory(angle, speed, life)]),
            "a": {"a": 0, "k": [0, 0, 0]},
            "s": {"a": 1, "k": [
                {"t": delay, "s": [40, 40, 100], "i": {"x": [0.2], "y": [1]}, "o": {"x": [0.4], "y": [0]}},
                {"t": delay + 7, "s": [100, 100, 100]},
            ]},
        },
        "shapes": [{
            "ty": "gr", "nm": "g", "np": 3,
            "it": [
                shape,
                {"ty": "fl", "c": {"a": 0, "k": color}, "o": {"a": 0, "k": 100},
                 "r": 1, "bm": 0, "nm": "f"},
                {"ty": "tr", "p": {"a": 0, "k": [0, 0]}, "a": {"a": 0, "k": [0, 0]},
                 "s": {"a": 0, "k": [100, 100]}, "r": {"a": 0, "k": 0},
                 "o": {"a": 0, "k": 100}, "sk": {"a": 0, "k": 0}, "sa": {"a": 0, "k": 0}},
            ],
        }],
    })

doc = {"v": "5.7.4", "fr": FR, "ip": 0, "op": OP, "w": W, "h": H,
       "nm": "confetti", "ddd": 0, "assets": [], "layers": layers, "markers": []}

out = os.path.join(os.path.dirname(__file__), "..", "assets", "lottie", "confetti.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(doc, f, separators=(",", ":"))
print(f"wrote confetti.json  {N} particles  {os.path.getsize(out)//1024}KB")
