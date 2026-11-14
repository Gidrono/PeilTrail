"""Writes the driver step files for the GitHub use-case GIFs.

Positions are measured on 1024x512 stills of the 960x480-point recording area,
whose top-left corner sits at screen point (210, 192); see record.sh.
"""

import json
import math
from pathlib import Path

ORIGIN = (210, 192)
SCALE = 960 / 1024


def screen(point):
    x, y = point
    return [round(ORIGIN[0] + x * SCALE, 1), round(ORIGIN[1] + y * SCALE, 1)]


def ellipse(cx, cy, rx, ry, start=200, turns=1.1, points=10):
    return [(cx + rx * math.cos(math.radians(start + 360 * turns * i / points)),
             cy + ry * math.sin(math.radians(start + 360 * turns * i / points)))
            for i in range(points + 1)]


def heart(cx, cy, size):
    shape = [(0, 1), (-0.55, 0.45), (-0.72, -0.05), (-0.48, -0.4), (-0.16, -0.38), (0, -0.1),
             (0.16, -0.38), (0.48, -0.4), (0.72, -0.05), (0.55, 0.45), (0, 1)]
    return [(cx + x * size, cy + y * size) for x, y in shape]


def star(cx, cy, r):
    return [(cx + r * math.cos(math.radians(-90 + 144 * i)),
             cy + r * math.sin(math.radians(-90 + 144 * i))) for i in range(6)]


class Clip:
    def __init__(self, start):
        self.steps = [{"move": screen(start)}, {"wait": 700}]

    def _travel(self, point, ms):
        self.steps += [{"glide": [screen(point)], "ms": ms}, {"wait": 150}]

    # Strokes run at constant speed and finish within PeilTrail's 0.6 s fade,
    # so the whole shape is on screen at the moment it's completed.
    def stroke(self, path, ms, travel_ms=700, pause=900):
        self._travel(path[0], travel_ms)
        self.steps += [{"cmd": True}, {"wait": 60}]
        self.steps += [{"glide": [screen(p) for p in path[1:]], "ms": ms, "ease": False}]
        self.steps += [{"cmd": False}, {"wait": pause}]

    def lines(self, path, ms_per_segment, travel_ms=700, pause=900):
        """Straight segments with sharp corners, drawn while ⌘ stays down."""
        self._travel(path[0], travel_ms)
        self.steps += [{"cmd": True}, {"wait": 60}]
        for point in path[1:]:
            self.steps += [{"glide": [screen(point)], "ms": ms_per_segment, "ease": False}]
        self.steps += [{"cmd": False}, {"wait": pause}]

    def save(self, name):
        Path(__file__).with_name(name).write_text(json.dumps(self.steps, indent=1) + "\n")
        total = sum(s.get("ms", 0) + s.get("wait", 0) for s in self.steps) / 1000
        print(f"{name}: {total:.1f} s")


# 01: repo page. Circle the name, the Star button, the commit count and the description.
c = Clip(start=(300, 420))
c.stroke(ellipse(100, 151, 82, 34), 500)
c.stroke(ellipse(962, 150, 56, 32), 420, travel_ms=1000)
c.stroke(ellipse(698, 257, 58, 28), 420, travel_ms=800)
c.stroke(ellipse(888, 255, 126, 46), 550, travel_ms=700, pause=1300)
c.save("01-screen-share.json")

# 02: code page. Bracket the constants, circle a value, underline a line.
c = Clip(start=(560, 200))
c.lines([(356, 244), (336, 244), (336, 343), (356, 343)], 140, travel_ms=700)
c.stroke(ellipse(591, 285, 40, 24), 400, travel_ms=800)
c.stroke([(352, 378), (500, 379), (656, 377)], 420, travel_ms=800)
c.stroke(ellipse(637, 366, 32, 22), 400, travel_ms=700, pause=1300)
c.save("02-code-review.json")

# 04: README install section. Circle the brew command, then draw a heart and a star.
c = Clip(start=(500, 300))
c.stroke(ellipse(198, 139, 168, 34), 520, travel_ms=700)
c.stroke(heart(885, 190, 120), 480, travel_ms=1000)
c.lines(star(885, 405, 82), 95, travel_ms=800, pause=1300)
c.save("04-flair.json")
