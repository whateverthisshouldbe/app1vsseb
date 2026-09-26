#!/usr/bin/env python3
"""Generates map/Map.model.json, the whole game world, as a Rojo model.

Run from the project root:  python3 tools/build_map.py

Layout (studs, ground surface at y=0):
  x -420..-200  Long Island: the strip mall where you start
  x -200..-110  The bridge (gate to Pen Street)
  x -110.. 205  Pen Street: the financial district
  x  210.. 375  Stratton Oakpen tower, trading floor on the ground floor
  z  150.. 330  The harbor pier and the yacht (north of the tower)
The customer areas in src/shared/Config.luau match these numbers.
"""

import json
import math
import os
import random

random.seed(1987)  # Black Monday. Deterministic output.

OUT = os.path.join(os.path.dirname(__file__), "..", "map", "Map.model.json")

# ---------------------------------------------------------------------------
# Math
# ---------------------------------------------------------------------------


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def matvec(m, v):
    return [sum(m[i][k] * v[k] for k in range(3)) for i in range(3)]


def rot(rx=0.0, ry=0.0, rz=0.0):
    """Same as CFrame.Angles(rad(rx), rad(ry), rad(rz))."""
    rx, ry, rz = math.radians(rx), math.radians(ry), math.radians(rz)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    mx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    my = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    mz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]
    return matmul(matmul(mx, my), mz)


IDENTITY = rot()

FACING = {"-z": 0, "-x": 90, "+z": 180, "+x": -90}


def look_matrix(p1, p2):
    """Rotation whose -Z axis points from p1 to p2 (like CFrame.lookAt)."""
    d = [p2[i] - p1[i] for i in range(3)]
    length = math.sqrt(sum(c * c for c in d))
    f = [c / length for c in d]
    back = [-c for c in f]
    up = [0, 1, 0]
    if abs(f[1]) > 0.99:
        up = [1, 0, 0]
    right = [up[1] * back[2] - up[2] * back[1], up[2] * back[0] - up[0] * back[2], up[0] * back[1] - up[1] * back[0]]
    rl = math.sqrt(sum(c * c for c in right))
    right = [c / rl for c in right]
    up = [back[1] * right[2] - back[2] * right[1], back[2] * right[0] - back[0] * right[2], back[0] * right[1] - back[1] * right[0]]
    return [[right[i], up[i], back[i]] for i in range(3)], length


def clean(x):
    x = round(x, 4)
    return 0.0 if x == 0 else x


# ---------------------------------------------------------------------------
# Instance helpers
# ---------------------------------------------------------------------------

PART_COUNT = 0


def rgb(r, g, b):
    return [clean(r / 255), clean(g / 255), clean(b / 255)]


def inst(class_name, name, props=None, children=None):
    node = {"name": name, "className": class_name}
    if props:
        node["properties"] = props
    if children:
        node["children"] = children
    return node


def cframe(pos, matrix=IDENTITY):
    return {"CFrame": {"position": [clean(c) for c in pos], "orientation": [[clean(c) for c in row] for row in matrix]}}


def part(name, size, pos, color, material="SmoothPlastic", matrix=IDENTITY, cls="Part", children=None, **props):
    global PART_COUNT
    PART_COUNT += 1
    p = {
        "Anchored": True,
        "Size": [clean(max(0.05, s)) for s in size],
        "CFrame": cframe(pos, matrix),
        "Color": rgb(*color),
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    p.update(props)
    return inst(cls, name, p, children)


class Group:
    """A Model (or Folder) that collects parts, with an optional local transform."""

    def __init__(self, name, origin=(0, 0, 0), yaw=0, cls="Model"):
        self.name = name
        self.cls = cls
        self.origin = origin
        self.matrix = rot(0, yaw, 0)
        self.children = []

    def to_world(self, pos):
        v = matvec(self.matrix, pos)
        return [self.origin[i] + v[i] for i in range(3)]

    def add(self, node):
        self.children.append(node)
        return node

    def box(self, name, size, pos, color, material="SmoothPlastic", r=(0, 0, 0), **props):
        return self.add(part(name, size, self.to_world(pos), color, material, matmul(self.matrix, rot(*r)), **props))

    def wedge(self, name, size, pos, color, material="SmoothPlastic", r=(0, 0, 0), **props):
        return self.add(part(name, size, self.to_world(pos), color, material, matmul(self.matrix, rot(*r)), cls="WedgePart", **props))

    def cyl(self, name, length, diameter, pos, color, material="SmoothPlastic", vertical=True, r=None, **props):
        rr = r if r is not None else ((0, 0, 90) if vertical else (0, 0, 0))
        return self.box(name, (length, diameter, diameter), pos, color, material, r=rr, Shape="Cylinder", **props)

    def ball(self, name, diameter, pos, color, material="SmoothPlastic", **props):
        return self.box(name, (diameter, diameter, diameter), pos, color, material, Shape="Ball", **props)

    def beam(self, name, p1, p2, thickness, color, material="SmoothPlastic", **props):
        w1, w2 = self.to_world(p1), self.to_world(p2)
        m, length = look_matrix(w1, w2)
        mid = [(w1[i] + w2[i]) / 2 for i in range(3)]
        return self.add(part(name, (thickness, thickness, length), mid, color, material, m, **props))

    def group(self, child):
        self.children.append(child)
        return child

    def sub(self, name, origin=(0, 0, 0), yaw=0):
        """A child group positioned relative to this one."""
        g = Group(name, self.to_world(origin), 0)
        g.matrix = matmul(self.matrix, rot(0, yaw, 0))
        self.children.append(g)
        return g

    def to_json(self):
        kids = [c.to_json() if isinstance(c, Group) else c for c in self.children]
        return inst(self.cls, self.name, None, kids)


def surface_text(text, color, font="GothamBlack", bg=None, ppu=20, face="Front", stroke=None):
    label_props = {
        "Text": text,
        "TextScaled": True,
        "Font": font,
        "TextColor3": rgb(*color),
        "BackgroundTransparency": 1 if bg is None else 0,
        "Size": {"UDim2": [[1, 0], [1, 0]]},
    }
    if bg is not None:
        label_props["BackgroundColor3"] = rgb(*bg)
    if stroke is not None:
        label_props["TextStrokeColor3"] = rgb(*stroke)
        label_props["TextStrokeTransparency"] = 0
    return inst(
        "SurfaceGui",
        "Text" + face,
        {"Face": face, "SizingMode": "PixelsPerStud", "PixelsPerStud": ppu, "LightInfluence": 0, "Brightness": 2},
        [inst("TextLabel", "Label", label_props)],
    )


def sign(g, name, text, pos, width, height, facing, color, bg=None, font="GothamBlack", thickness=0.4, part_color=(20, 20, 20), material="SmoothPlastic", ppu=20, stroke=None, transparent=False):
    """A flat sign whose text faces `facing` ('+x', '-x', '+z', '-z')."""
    return g.box(
        name,
        (width, height, thickness),
        pos,
        part_color,
        material,
        r=(0, FACING[facing], 0),
        CanCollide=not transparent,
        Transparency=1 if transparent else 0,
        CastShadow=False,
        children=[surface_text(text, color, font, bg, ppu, stroke=stroke)],
    )


def ticker(g, pos, width, height, facing):
    """A black LED strip; the client scrolls stock prices across its front."""
    return g.box("TickerBoard", (width, height, 0.4), pos, BLACK, "SmoothPlastic", r=(0, FACING[facing], 0), CastShadow=False)


def light(kind="PointLight", color=(255, 220, 170), brightness=1.5, rng=24, **props):
    p = {"Color": rgb(*color), "Brightness": brightness, "Range": rng, "Shadows": False}
    p.update(props)
    return inst(kind, kind, p)


# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------

ASPHALT = (38, 38, 42)
CONCRETE = (150, 146, 140)
SIDEWALK = (170, 166, 158)
GRASS = (70, 110, 55)
WHITE = (240, 240, 235)
BLACK = (20, 20, 22)
GOLD = (255, 196, 60)
MONEY = (90, 235, 130)
YELLOW_LINE = (240, 200, 40)
TAXI = (250, 195, 20)
BRONZE = (140, 95, 45)
GLASS_BLUE = (70, 110, 150)
WOOD = (130, 90, 55)
TEAK = (165, 115, 70)
NEON_PINK = (255, 60, 160)
NEON_BLUE = (60, 170, 255)
NEON_GREEN = (80, 255, 140)
NEON_RED = (255, 50, 50)
WARM_WINDOW = (255, 200, 120)

# ---------------------------------------------------------------------------
# Props
# ---------------------------------------------------------------------------


def lamp_post(g, x, z, y=0.5, height=14, arm_dir=1):
    lamp = g.sub("StreetLamp", (x, y, z))
    lamp.cyl("Pole", height, 0.7, (0, height / 2, 0), (30, 35, 32), "Metal")
    lamp.box("Arm", (0.5, 0.5, 3.4), (0, height - 0.3, arm_dir * 1.5), (30, 35, 32), "Metal")
    lamp.box("Bulb", (1.6, 0.6, 1.6), (0, height - 0.7, arm_dir * 3), WARM_WINDOW, "Neon", CanCollide=False,
             children=[light("PointLight", (255, 200, 140), 1.6, 26)])
    lamp.cyl("Base", 1.2, 1.4, (0, 0.6, 0), (30, 35, 32), "Metal")


def tree(g, x, z, y=0.5, scale=1.0):
    t = g.sub("Tree", (x, y, z))
    h = 7 * scale
    t.cyl("Trunk", h, 1.2 * scale, (0, h / 2, 0), (95, 65, 40), "Wood")
    for i, (dx, dy, dz, d) in enumerate([(0, h + 2.5, 0, 7), (1.8, h + 1, 1, 5), (-1.6, h + 1.5, -1.2, 5.5), (0.5, h + 4.5, -0.6, 4.5)]):
        shade = random.randint(-15, 15)
        t.ball("Leaves", d * scale, (dx * scale, dy, dz * scale), (60 + shade, 115 + shade, 50 + shade), "Grass", CanCollide=False)
    return t


def planter_tree(g, x, z, y=0.5):
    p = g.sub("Planter", (x, y, z))
    p.box("Box", (4, 1.4, 4), (0, 0.7, 0), (90, 88, 84), "Concrete")
    p.box("Soil", (3.4, 0.2, 3.4), (0, 1.45, 0), (70, 50, 35), "Ground", CanCollide=False)
    tree(p, 0, 0, 1.4, 0.8)


def car(g, x, z, yaw, color, taxi=False, y=0):
    c = g.sub("Taxi" if taxi else "Car", (x, y, z), yaw)
    c.box("Body", (13, 2.6, 6.2), (0, 2.2, 0), color, "SmoothPlastic", Reflectance=0.05)
    c.box("Cabin", (7, 2.2, 5.6), (-0.8, 4.6, 0), color)
    c.box("Windows", (7.2, 1.6, 5.7), (-0.8, 4.7, 0), (25, 35, 45), "Glass", Transparency=0.2)
    c.box("Bumper", (0.4, 0.8, 6.2), (6.6, 1.4, 0), (60, 60, 60), "Metal")
    c.box("BumperRear", (0.4, 0.8, 6.2), (-6.6, 1.4, 0), (60, 60, 60), "Metal")
    c.box("HeadlightL", (0.2, 0.6, 1.2), (6.55, 2.6, 2.2), (255, 250, 220), "Neon")
    c.box("HeadlightR", (0.2, 0.6, 1.2), (6.55, 2.6, -2.2), (255, 250, 220), "Neon")
    c.box("TailL", (0.2, 0.6, 1.2), (-6.55, 2.6, 2.2), (220, 30, 30), "Neon")
    c.box("TailR", (0.2, 0.6, 1.2), (-6.55, 2.6, -2.2), (220, 30, 30), "Neon")
    for wx in (-4, 4):
        for wz in (-3, 3):
            c.box("Wheel", (2.6, 2.6, 1), (wx, 1.3, wz), (25, 25, 25), "SmoothPlastic", Shape="Cylinder", r=(0, 90, 0))
    if taxi:
        c.box("Checker", (13.05, 0.5, 6.25), (0, 2.8, 0), BLACK)
        c.box("RoofSign", (2.4, 1, 1.2), (-0.8, 6.2, 0), (255, 245, 180), "Neon",
              children=[surface_text("TAXI", BLACK, ppu=30, face="Front"), surface_text("TAXI", BLACK, ppu=30, face="Back")])


def bench(g, x, z, yaw=0, y=0.5):
    b = g.sub("Bench", (x, y, z), yaw)
    b.box("Seat", (6, 0.4, 2), (0, 1.8, 0), WOOD, "Wood", cls="Seat")
    b.box("Back", (6, 2, 0.4), (0, 3, 0.9), WOOD, "Wood")
    for lx in (-2.6, 2.6):
        b.box("Leg", (0.4, 1.6, 2), (lx, 0.8, 0), (40, 40, 40), "Metal")


def hydrant(g, x, z, y=0.5):
    h = g.sub("Hydrant", (x, y, z))
    h.cyl("Body", 2.2, 1, (0, 1.1, 0), (200, 30, 30), "Metal")
    h.ball("Top", 1.1, (0, 2.3, 0), (200, 30, 30), "Metal")
    h.cyl("Nozzle", 1.6, 0.4, (0, 1.4, 0), (200, 30, 30), "Metal", vertical=False)


def trash_can(g, x, z, y=0.5):
    t = g.sub("TrashCan", (x, y, z))
    t.cyl("Can", 3, 1.8, (0, 1.5, 0), (40, 70, 50), "DiamondPlate")
    t.cyl("Lid", 0.3, 2, (0, 3.1, 0), (30, 55, 40), "Metal")


def hot_dog_cart(g, x, z, yaw=0, y=0.5):
    c = g.sub("HotDogCart", (x, y, z), yaw)
    c.box("Cart", (6, 3, 3), (0, 2.5, 0), (200, 200, 205), "Metal")
    c.box("Front", (6.05, 1.2, 3.05), (0, 2.2, 0), (220, 40, 40), "SmoothPlastic")
    for wx in (-2, 2):
        c.box("Wheel", (1.6, 1.6, 0.5), (wx, 0.8, 1.6), BLACK, Shape="Cylinder", r=(0, 90, 0))
    c.cyl("Pole", 6, 0.3, (0, 7, 0), (200, 200, 200), "Metal")
    c.box("Umbrella", (7, 0.4, 7), (0, 10, 0), (240, 180, 30), "Fabric")
    c.box("UmbrellaStripe", (7.05, 0.45, 2), (0, 10, 0), (220, 40, 40), "Fabric")
    sign(c, "Sign", "HOT DOGS $2", (0, 4.8, -1.6), 5, 1, "-z", WHITE, bg=(220, 40, 40), ppu=30)


def skyscraper(g, name, x0, x1, z0, z1, height, color, material="Glass", band=(200, 200, 200), band_mat="Concrete",
               street_face=None, lit=0.25, setbacks=(), crown=None, base_y=0):
    """A tower with floor bands, lit windows and optional setbacks."""
    b = g.sub(name)
    tiers = [(x0, x1, z0, z1, base_y, base_y + height)]
    # setbacks: list of (fraction_of_height, inset)
    if setbacks:
        tiers = []
        prev_y = base_y
        prev = (x0, x1, z0, z1)
        for frac, inset in list(setbacks) + [(1.0, None)]:
            top = base_y + height * frac
            tiers.append((prev[0], prev[1], prev[2], prev[3], prev_y, top))
            if inset is not None:
                prev = (x0 + inset, x1 - inset, z0 + inset, z1 - inset)
            prev_y = top
    for ti, (a0, a1, c0, c1, y0, y1) in enumerate(tiers):
        w, d, h = a1 - a0, c1 - c0, y1 - y0
        cx, cz = (a0 + a1) / 2, (c0 + c1) / 2
        b.box("Body", (w, h, d), (cx, y0 + h / 2, cz), color, material, Reflectance=0.08 if material == "Glass" else 0)
        # Floor bands.
        for fy in range(int(y0) + 12, int(y1) - 2, 12):
            b.box("Band", (w + 0.6, 1, d + 0.6), (cx, fy, cz), band, band_mat, CastShadow=False)
        b.box("Cap", (w + 1.2, 1.6, d + 1.2), (cx, y1 + 0.8, cz), band, band_mat)
        # Lit windows on each face.
        faces = [("+x", a1 + 0.2, cz, d), ("-x", a0 - 0.2, cz, d), ("+z", cx, c1 + 0.2, w), ("-z", cx, c0 - 0.2, w)]
        for facing, fx, fz, span in faces:
            for _ in range(min(36, int(span * h * lit / 180))):
                wy = random.randrange(int(y0) + 6, max(int(y0) + 7, int(y1) - 4), 12) if h > 14 else y0 + h / 2
                off = random.uniform(-span / 2 + 3, span / 2 - 3)
                ww = random.choice((4, 6, 8, 10))
                shade = random.choice((WARM_WINDOW, (255, 230, 170), (190, 220, 255)))
                if facing in ("+x", "-x"):
                    b.box("LitWindow", (0.2, 5, ww), (fx, wy, fz + off), shade, "Neon", CanCollide=False, CastShadow=False)
                else:
                    b.box("LitWindow", (ww, 5, 0.2), (fx + off, wy, fz), shade, "Neon", CanCollide=False, CastShadow=False)
    top = tiers[-1]
    tcx, tcz, ty = (top[0] + top[1]) / 2, (top[2] + top[3]) / 2, top[5]
    if crown == "spire":
        b.box("SpireBase", (8, 10, 8), (tcx, ty + 5, tcz), band, "Metal")
        b.wedge("SpireA", (8, 20, 4), (tcx, ty + 20, tcz - 2), band, "Metal", r=(0, 180, 0))
        b.wedge("SpireB", (8, 20, 4), (tcx, ty + 20, tcz + 2), band, "Metal")
        b.cyl("Antenna", 40, 0.8, (tcx, ty + 40, tcz), (180, 180, 180), "Metal")
        b.ball("Beacon", 1.6, (tcx, ty + 60.5, tcz), NEON_RED, "Neon", children=[light("PointLight", NEON_RED, 3, 30)])
    elif crown == "watertower":
        wt = b.sub("WaterTower", (tcx + 4, ty, tcz + 4))
        for lx, lz in ((-2, -2), (2, -2), (-2, 2), (2, 2)):
            wt.box("Leg", (0.5, 6, 0.5), (lx, 3, lz), (60, 45, 35), "Wood")
        wt.cyl("Tank", 7, 6.5, (0, 9.5, 0), (120, 85, 55), "WoodPlanks")
        wt.wedge("RoofA", (6.5, 2.5, 3.25), (0, 14.25, -1.625), (60, 60, 60), "Metal", r=(0, 180, 0))
        wt.wedge("RoofB", (6.5, 2.5, 3.25), (0, 14.25, 1.625), (60, 60, 60), "Metal")
    elif crown == "helipad":
        b.cyl("Helipad", 0.4, min(top[1] - top[0], top[3] - top[2]) * 0.7, (tcx, ty + 1.8, tcz), (50, 50, 55), "Concrete")
        b.box("H1", (1.2, 0.1, 8), (tcx - 2.5, ty + 2.05, tcz), WHITE, "SmoothPlastic")
        b.box("H2", (1.2, 0.1, 8), (tcx + 2.5, ty + 2.05, tcz), WHITE, "SmoothPlastic")
        b.box("H3", (4, 0.1, 1.2), (tcx, ty + 2.05, tcz), WHITE, "SmoothPlastic")
    elif crown == "flat":
        pass
    else:
        # Rooftop clutter.
        for _ in range(3):
            b.box("AC", (random.uniform(3, 6), 2.5, random.uniform(3, 6)),
                  (tcx + random.uniform(-6, 6), ty + 2.8, tcz + random.uniform(-6, 6)), (120, 120, 125), "DiamondPlate")
    return b


# ---------------------------------------------------------------------------
# World
# ---------------------------------------------------------------------------

root = Group("Map")
gates = Group("Gates", cls="Folder")

# ===========================================================================
# 1. LONG ISLAND STRIP MALL
# ===========================================================================
li = root.sub("StripMall")
li.box("Island", (240, 4, 260), (-315, -2, 0), GRASS, "Grass")
li.box("ParkingLot", (170, 0.2, 140), (-305, 0.1, 0), ASPHALT, "Asphalt")
li.box("Road", (20, 0.2, 40), (-212, 0.1, 0), ASPHALT, "Asphalt")
li.box("MallSidewalk", (180, 0.5, 8), (-315, 0.25, -74), SIDEWALK, "Concrete")

# Parking lines.
for x in range(-385, -224, 10):
    li.box("Line", (0.4, 0.05, 12), (x, 0.22, -50), WHITE, "SmoothPlastic", CanCollide=False)
    li.box("Line", (0.4, 0.05, 12), (x, 0.22, 50), WHITE, "SmoothPlastic", CanCollide=False)
li.box("Arrow", (12, 0.05, 1), (-300, 0.22, 0), WHITE, "SmoothPlastic", CanCollide=False)

# The mall itself: five units, facade facing +z (the lot).
mall = li.sub("Mall", (-315, 0, -94))
mall.box("Back", (180, 20, 2), (0, 10, -15), (185, 170, 150), "Brick")
mall.box("Roof", (182, 2, 34), (0, 21, 0), (120, 110, 100), "Concrete")
mall.box("RoofTrim", (184, 3, 2), (0, 21.5, 17), (230, 225, 210), "SmoothPlastic")
mall.box("Canopy", (182, 1, 8), (0, 13, 20), (210, 200, 185), "Concrete")
mall.box("CanopyStripe", (182.2, 0.6, 8.2), (0, 12.7, 20), (200, 40, 40), "SmoothPlastic")
mall.box("Facade", (180, 8, 1), (0, 16, 16.4), (230, 225, 210), "Concrete")
mall.box("EndWall", (1.5, 20, 34), (90, 10, 0), (185, 170, 150), "Brick")
for px in range(-88, 90, 36):
    mall.box("Pillar", (2, 13, 2), (px, 6.5, 23), (230, 225, 210), "Concrete")
units = [
    ("NAIL SALON", NEON_PINK),
    ("PIZZA", (255, 140, 40)),
    ("INVESTOR CENTER", GOLD),
    ("LAUNDROMAT", NEON_BLUE),
    ("PAWN & LOANS", NEON_GREEN),
]
for i, (label, col) in enumerate(units):
    ux = -72 + i * 36
    mall.box("Divider", (1.5, 20, 34), (ux - 18, 10, 0), (185, 170, 150), "Brick")
    sign(mall, "StoreSign", label, (ux, 16.5, 17.3), 28, 5, "+z", col, bg=BLACK, part_color=BLACK, ppu=16)
    if label == "INVESTOR CENTER":
        # Open front so you can walk in. The legendary starter office.
        office = mall.sub("InvestorCenter", (ux, 0, 0))
        office.box("Floor", (34, 0.4, 30), (0, 0.2, 0), (110, 100, 80), "Carpet")
        office.box("Whiteboard", (16, 7, 0.4), (0, 8, -13.6), WHITE, "SmoothPlastic",
                   children=[surface_text("SELL ME\nTHIS PEN", (30, 60, 200), "PermanentMarker", ppu=24)])
        sign(office, "Motto", "PICK UP THE PHONE AND START DIALING", (0, 14.5, -13.5), 30, 2, "+z", (200, 30, 30), bg=WHITE, ppu=20)
        for row, dz in enumerate((-6, 2)):
            for dx in (-10, 0, 10):
                d = office.sub("Desk", (dx, 0, dz))
                d.box("Top", (7, 0.4, 3.5), (0, 3, 0), (140, 110, 80), "Wood")
                d.box("LegL", (0.4, 3, 3.2), (-3.2, 1.5, 0), (60, 60, 60), "Metal")
                d.box("LegR", (0.4, 3, 3.2), (3.2, 1.5, 0), (60, 60, 60), "Metal")
                d.box("Computer", (2.4, 2, 2), (-1.5, 4.2, -0.4), (200, 195, 170), "SmoothPlastic")
                d.box("Screen", (1.8, 1.4, 0.1), (-1.5, 4.3, 0.62), (60, 200, 90), "Neon")
                d.box("Phone", (1.2, 0.5, 0.9), (1.8, 3.45, 0.3), BLACK, "SmoothPlastic")
                d.box("Chair", (2.4, 0.5, 2.4), (0, 1.8, 2.8), (40, 40, 45), "Fabric", cls="Seat")
        office.box("CeilingLight", (20, 0.3, 2), (0, 19.8, 0), (255, 250, 230), "Neon",
                   children=[light("PointLight", (255, 245, 220), 1.2, 30)])
        office.box("CoffeeTable", (4, 3, 2), (14, 1.5, -12), (80, 70, 60), "Wood")
        office.cyl("CoffeePot", 1.4, 1, (14, 3.7, -12), (40, 30, 25), "Glass")
    else:
        mall.box("Storefront", (32, 11, 0.4), (ux, 6.5, 16.8), (160, 190, 210), "Glass", Transparency=0.45)
        mall.box("Door", (5, 9, 0.5), (ux + 8, 4.5, 16.9), (70, 70, 70), "Metal")
        mall.box("Interior", (34, 0.4, 30), (ux, 0.2, 0), (200, 195, 190), "Marble")
        mall.box("InteriorLight", (16, 0.3, 2), (ux, 19.8, 0), col, "Neon", children=[light("PointLight", col, 1, 22)])

# Pylon sign at the lot entrance.
pylon = li.sub("PylonSign", (-228, 0, 58))
pylon.box("Post", (2, 26, 2), (0, 13, 0), (120, 120, 125), "Metal")
sign(pylon, "Top", "STRIP MALL PLAZA", (0, 27, 0), 18, 5, "-x", GOLD, bg=(120, 20, 20), part_color=(120, 20, 20), ppu=16)
sign(pylon, "TopBack", "STRIP MALL PLAZA", (0, 27, 0.5), 18, 5, "+x", GOLD, bg=(120, 20, 20), part_color=(120, 20, 20), ppu=16, thickness=0.2)
sign(pylon, "Tenant", "NOW HIRING: BROKERS", (0, 22, 0), 16, 3, "-x", BLACK, bg=WHITE, part_color=WHITE, ppu=16)

for x in range(-380, -225, 38):
    lamp_post(li, x, -64, 0.2, 14, 1)
    lamp_post(li, x + 19, 66, 0.2, 14, -1)
# Parked cars on the south edge, outside the customer area.
car_colors = [(150, 30, 30), (40, 60, 120), (200, 200, 205), (30, 30, 30), (90, 110, 70), (180, 140, 60)]
for i, x in enumerate(range(-380, -240, 20)):
    if i % 3 != 1:
        car(li, x, 63, 90, random.choice(car_colors), y=0.2)
for x, z in ((-410, -40), (-410, 30), (-400, 100), (-240, 100), (-330, 105), (-280, -118), (-360, -118), (-215, -60), (-215, 60)):
    tree(li, x, z, 0, random.uniform(0.9, 1.3))
li.box("Dumpster", (8, 4, 4), (-395, 2.2, -60), (40, 90, 50), "DiamondPlate")
li.box("DumpsterLid", (8.2, 0.4, 4.2), (-395, 4.4, -60), (30, 70, 40), "Metal")

root.add(part("Spawn", (12, 1, 12), (-315, 0.7, -64), GOLD, "Neon", rot(0, 180, 0), cls="SpawnLocation",
              Duration=0, Neutral=True, Transparency=0.6, CanCollide=True))

# ===========================================================================
# 2. THE BRIDGE
# ===========================================================================
br = root.sub("Bridge")
br.box("Deck", (94, 2, 40), (-155, -1, 0), (90, 85, 80), "Concrete")
br.box("Road", (94, 0.2, 28), (-155, 0.1, 0), ASPHALT, "Asphalt")
br.box("WalkN", (94, 0.5, 6), (-155, 0.25, 17), (140, 120, 95), "WoodPlanks")
br.box("WalkS", (94, 0.5, 6), (-155, 0.25, -17), (140, 120, 95), "WoodPlanks")
for side in (-1, 1):
    br.box("Rail", (94, 0.6, 0.6), (-155, 3.5, side * 20), (80, 60, 45), "Metal")
    for x in range(-200, -108, 4):
        br.box("Baluster", (0.4, 3.5, 0.4), (x, 1.75, side * 20), (80, 60, 45), "Metal")
# Gothic stone towers.
for tx in (-178, -132):
    for side in (-1, 1):
        br.box("Leg", (6, 64, 6), (tx, 30, side * 21), (150, 125, 100), "Brick")
    br.box("TowerTop", (8, 10, 50), (tx, 58, 0), (150, 125, 100), "Brick")
    br.box("ArchBeam", (8, 4, 36), (tx, 42, 0), (150, 125, 100), "Brick")
    br.box("Pier", (14, 30, 52), (tx, -17, 0), (120, 110, 100), "Slate")
    br.box("Flag", (0.3, 3, 5), (tx, 68, 0), (200, 40, 40), "Fabric")
    br.cyl("FlagPole", 8, 0.3, (tx, 66, 0), (200, 200, 200), "Metal")
# Sagging main cables and suspenders.
for side in (-1, 1):
    zc = side * 21
    anchors = [(-200, 2), (-178, 60), (-132, 60), (-110, 2)]
    for (xa, ya), (xb, yb) in zip(anchors, anchors[1:]):
        steps = 8
        pts = []
        for s in range(steps + 1):
            t = s / steps
            x = xa + (xb - xa) * t
            sag = 12 * math.sin(math.pi * t) if (xa, xb) == (-178, -132) else 4 * math.sin(math.pi * t)
            y = ya + (yb - ya) * t - sag
            pts.append((x, y))
        for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
            br.beam("Cable", (x1, y1, zc), (x2, y2, zc), 0.7, (120, 120, 125), "Metal")
        for (x1, y1) in pts[1:-1]:
            if y1 > 5:
                br.beam("Suspender", (x1, y1, zc), (x1, 3.8, zc), 0.25, (130, 130, 135), "Metal")
    lamp_post(br, -165, side * 18, 0.5, 12, -side)
    lamp_post(br, -145, side * 18, 0.5, 12, -side)
sign(br, "Welcome", "WELCOME TO PEN STREET", (-182.2, 36, 0), 34, 5, "-x", GOLD, bg=(10, 40, 25), part_color=(10, 40, 25), ppu=16)

gates.add(part("Gate_PenStreet", (1.5, 18, 40), (-198, 9, 0), GOLD, "ForceField", Transparency=0.25, CastShadow=False))

# ===========================================================================
# 3. PEN STREET
# ===========================================================================
ps = root.sub("PenStreet")
ps.box("Ground", (500, 4, 307), (135, -2, -1.5), (120, 118, 112), "Concrete")
ps.box("Avenue", (314, 0.2, 36), (49, 0.1, 0), ASPHALT, "Asphalt")
ps.box("SidewalkN", (314, 0.5, 14), (49, 0.25, 25), SIDEWALK, "Concrete")
ps.box("SidewalkS", (314, 0.5, 14), (49, 0.25, -25), SIDEWALK, "Concrete")
ps.box("CurbN", (314, 0.6, 0.6), (49, 0.3, 18), (200, 195, 185), "Concrete")
ps.box("CurbS", (314, 0.6, 0.6), (49, 0.3, -18), (200, 195, 185), "Concrete")
for x in range(-104, 200, 10):
    ps.box("CenterLine", (6, 0.05, 0.35), (x, 0.22, 0.4), YELLOW_LINE, "SmoothPlastic", CanCollide=False)
    ps.box("CenterLine", (6, 0.05, 0.35), (x, 0.22, -0.4), YELLOW_LINE, "SmoothPlastic", CanCollide=False)
for cx in (-40, 110):
    for z in range(-16, 17, 3):
        ps.box("Crosswalk", (8, 0.05, 1.6), (cx, 0.22, z), WHITE, "SmoothPlastic", CanCollide=False)

# The Exchange: columns, pediment, big banner.
ex = ps.sub("PenStockExchange", (35, 0, 0))
ex.box("Steps1", (110, 1, 12), (0, 0.5, 38), (220, 215, 205), "Marble")
ex.box("Steps2", (106, 1, 9), (0, 1.5, 39.5), (220, 215, 205), "Marble")
ex.box("Steps3", (102, 1, 6), (0, 2.5, 41), (220, 215, 205), "Marble")
ex.box("Portico", (100, 1, 14), (0, 3.2, 47), (230, 225, 215), "Marble")
ex.box("Body", (104, 44, 70), (0, 22, 88), (225, 220, 210), "Marble")
for i in range(6):
    cx = -40 + i * 16
    ex.cyl("Column", 30, 5, (cx, 18.7, 46), (240, 238, 230), "Marble")
    ex.box("ColumnBase", (6.5, 1.2, 6.5), (cx, 4.3, 46), (230, 225, 215), "Marble")
    ex.box("Capital", (7, 1.6, 7), (cx, 34.2, 46), (230, 225, 215), "Marble")
ex.box("Entablature", (100, 6, 16), (0, 38, 47), (230, 225, 215), "Marble")
ex.wedge("PedimentL", (16, 12, 50), (-25, 47, 47), (230, 225, 215), "Marble", r=(0, 90, 0))
ex.wedge("PedimentR", (16, 12, 50), (25, 47, 47), (230, 225, 215), "Marble", r=(0, -90, 0))
sign(ex, "Name", "PEN STOCK EXCHANGE", (0, 38, 38.9), 80, 4.5, "-z", (60, 50, 40), font="Garamond", part_color=(230, 225, 215), material="Marble", ppu=16)
ex.box("Banner", (60, 22, 0.4), (0, 22, 52.8), (20, 60, 140), "Fabric",
       children=[surface_text("PSE", WHITE, "GothamBlack", ppu=10)])
for fx in (-44, 44):
    ex.cyl("FlagPole", 16, 0.4, (fx, 52, 46), (220, 220, 220), "Metal")
    ex.box("Flag", (0.2, 5, 8), (fx, 57, 42), (30, 40, 120), "Fabric")
ticker(ex, (0, 30, 52.3), 60, 3, "-z")

# Giant golden pen monument in front of the exchange.
mon = ps.sub("PenMonument", (35, 0.5, 26))
mon.cyl("Plinth", 2, 12, (0, 1, 0), (60, 60, 65), "Granite")
mon.cyl("PenBody", 24, 2.6, (-3.7, 14, 0), GOLD, "Foil", r=(0, 0, 72))
mon.cyl("PenCap", 6, 3, (-0.35, 24.4, 0), (40, 40, 45), "Metal", r=(0, 0, 72))
mon.box("Clip", (0.4, 5, 0.6), (-0.2, 24, 1.6), (230, 230, 230), "Metal", r=(0, 0, -18))
mon.box("Nib", (1.4, 3, 1.4), (-7.6, 2.8, 0), (230, 230, 230), "Metal", r=(0, 0, -18))
sign(mon, "Plaque", "THE PEN\nit's not a pen, it's a lifestyle", (0, 1.4, -6.05), 9, 1.8, "-z", GOLD, bg=(30, 30, 30), part_color=(30, 30, 30), ppu=30)

# Charging bull on a traffic island.
bull = ps.sub("ChargingBull", (-75, 0, 0), yaw=180)
bull.box("Island", (34, 0.8, 12), (0, 0.4, 0), (110, 105, 100), "Granite")
bull.box("Pedestal", (18, 3, 7), (0, 2.3, 0), (80, 75, 72), "Granite")
bull.box("Body", (11, 5, 5), (0, 8.3, 0), BRONZE, "Metal", Reflectance=0.15)
bull.box("Chest", (4, 6, 5.4), (4.5, 8.8, 0), BRONZE, "Metal", Reflectance=0.15)
bull.box("Hump", (4, 2, 4.4), (3, 11.2, 0), BRONZE, "Metal", Reflectance=0.15)
bull.box("Head", (4, 3, 3), (7.4, 7.4, 0), BRONZE, "Metal", r=(0, 0, -30), Reflectance=0.15)
bull.box("Snout", (1.6, 1.8, 2.4), (9, 6, 0), BRONZE, "Metal", r=(0, 0, -30))
for side in (-1, 1):
    bull.box("Horn", (0.6, 0.6, 4), (7.8, 9.4, side * 2.6), (200, 170, 100), "Metal", r=(side * 30, 0, 20))
    bull.box("HornTip", (0.5, 2, 0.5), (8.4, 10.8, side * 4.2), (200, 170, 100), "Metal", r=(0, 0, 30))
    bull.box("FrontLeg", (1.2, 4.5, 1.2), (5.6, 5.3, side * 1.6), BRONZE, "Metal", r=(0, 0, 25))
    bull.box("BackLeg", (1.2, 4.5, 1.2), (-4.4, 5.3, side * 1.6), BRONZE, "Metal", r=(0, 0, -30))
bull.box("Tail", (0.5, 0.5, 5), (-6.6, 10.6, 0), BRONZE, "Metal", r=(0, 90, 50))
sign(bull, "Plaque", "CHARGING PEN BULL", (0, 2.3, 3.55), 10, 1.2, "+z", GOLD, bg=(30, 30, 30), part_color=(30, 30, 30), ppu=30)

# Leaderboard gantry over the avenue, facing arriving players.
lb = ps.sub("LeaderboardGantry", (-100, 0, 0))
for side in (-1, 1):
    lb.box("Pole", (1.6, 34, 1.6), (0, 17, side * 20), (60, 60, 65), "Metal")
lb.box("Beam", (2, 2, 42), (0, 33, 0), (60, 60, 65), "Metal")
lb.box("LeaderboardBoard", (36, 16, 1), (0, 24, 0), BLACK, "SmoothPlastic", r=(0, 90, 0))
lb.box("BoardFrame", (37, 17, 0.8), (0.6, 24, 0), GOLD, "Metal", r=(0, 90, 0))

# Buildings.
skyscraper(ps, "TowerA", -105, -55, 34, 90, 150, GLASS_BLUE, "Glass", (200, 210, 220), "Metal", crown="flat")
skyscraper(ps, "TowerB", 120, 185, 34, 110, 190, (200, 175, 135), "Limestone", (170, 145, 110), "Limestone",
           setbacks=((0.55, 6), (0.8, 14)), crown="spire")
skyscraper(ps, "BrickC", -105, -52, -95, -34, 70, (140, 70, 55), "Brick", (190, 180, 165), "Concrete", crown="watertower")
skyscraper(ps, "TowerD", -30, 100, -110, -34, 230, (35, 45, 60), "Glass", (120, 140, 160), "Metal",
           setbacks=((0.6, 10),), crown="spire", lit=0.3)
skyscraper(ps, "BankE", 120, 200, -100, -34, 100, (225, 220, 210), "Marble", (190, 170, 120), "Marble")
skyscraper(ps, "TowerF", -30, 20, 128, 150, 120, (60, 80, 70), "Glass", (180, 190, 180), "Metal")
skyscraper(ps, "TowerG", 60, 115, 130, 150, 90, (170, 150, 130), "Concrete", (120, 110, 100), "Concrete")

# Giant ad screens on Tower D facing the street.
sign(ps, "AdPen", "SELL ME\nTHIS PEN", (5, 40, -34.6), 40, 24, "+z", WHITE, bg=(200, 20, 60), part_color=BLACK, ppu=8, stroke=BLACK)
sign(ps, "AdWolf", "MONEY\nNEVER\nSLEEPS", (70, 40, -34.6), 24, 24, "+z", (255, 230, 90), bg=(20, 20, 120), part_color=BLACK, ppu=8)
ticker(ps, (35, 22, -33.6), 128, 4, "+z")
sign(ps, "BankName", "FIRST PEN-SYLVANIA BANK", (160, 30, -33.8), 70, 6, "+z", GOLD, part_color=(225, 220, 210), material="Marble", font="Garamond", ppu=14)
sign(ps, "RoofAd", "BUY PENS", (-78.5, 82, -64), 40, 12, "+z", NEON_PINK, part_color=(30, 30, 30), ppu=10, transparent=True)
ps.box("RoofAdFrame", (40, 0.6, 0.6), (-78.5, 76, -64), (60, 60, 60), "Metal")

# Street furniture.
for x in range(-95, 200, 26):
    if abs(x - 35) > 8:
        lamp_post(ps, x, 30.5, 0.5, 15, -1)
    lamp_post(ps, x + 13, -30.5, 0.5, 15, 1)
for x in (-60, 10, 80, 160):
    planter_tree(ps, x, 21.5)
    planter_tree(ps, x + 20, -21.5)
for x in (-20, 140):
    hydrant(ps, x, 19.5)
for x in (-50, 50, 150):
    trash_can(ps, x, -19.8)
bench(ps, 90, 29, 180)
bench(ps, -10, -29, 0)
hot_dog_cart(ps, 0, 27, 180)
hot_dog_cart(ps, 140, -27, 0)
# Parked taxis along the curb.
for x in (-20, 30, 95, 150, 185):
    car(ps, x, 14.5, 0, TAXI, taxi=True, y=0.2)
for x in (-60, 60, 125):
    car(ps, x, -14.5, 180, TAXI, taxi=True, y=0.2)
# Subway entrance.
sub = ps.sub("Subway", (175, 0.5, 24))
sub.box("RailL", (10, 3, 0.4), (0, 1.5, -2.2), (40, 90, 50), "Metal")
sub.box("RailR", (10, 3, 0.4), (0, 1.5, 2.2), (40, 90, 50), "Metal")
sub.box("Stairs", (10, 0.2, 4), (0, 0.05, 0), BLACK, "Slate", CanCollide=False)
for gx in (-4.8, 4.8):
    sub.cyl("GlobePost", 5, 0.4, (gx, 2.5, -2.2), (40, 90, 50), "Metal")
    sub.ball("Globe", 1.4, (gx, 5.4, -2.2), NEON_GREEN, "Neon", children=[light("PointLight", NEON_GREEN, 1, 12)])
sign(sub, "Name", "PEN ST STATION", (0, 3.8, -2.4), 8, 1.2, "-z", WHITE, bg=(40, 90, 50), part_color=(40, 90, 50), ppu=30)

# ===========================================================================
# 4. STRATTON OAKPEN TOWER + TRADING FLOOR
# ===========================================================================
so = root.sub("StrattonOakpen")
FX0, FX1, FZ0, FZ1, FH = 210, 376, -82, 82, 36
so.box("Floor", (FX1 - FX0, 0.4, FZ1 - FZ0), ((FX0 + FX1) / 2, 0.2, 0), (95, 95, 105), "Marble", Reflectance=0.12)
so.box("Carpet", (120, 0.05, 76), (282, 0.42, 0), (110, 20, 30), "Carpet", CanCollide=False)
so.box("Ceiling", (FX1 - FX0, 2, FZ1 - FZ0), ((FX0 + FX1) / 2, FH + 1, 0), (215, 212, 205), "SmoothPlastic")
# Walls: glass curtain with a doorway on the west side.
so.box("WallN", (FX1 - FX0, FH, 1), ((FX0 + FX1) / 2, FH / 2, FZ1), (120, 160, 190), "Glass", Transparency=0.55)
so.box("WallS", (FX1 - FX0, FH, 1), ((FX0 + FX1) / 2, FH / 2, FZ0), (120, 160, 190), "Glass", Transparency=0.55)
so.box("WallE", (1, FH, FZ1 - FZ0), (FX1, FH / 2, 0), (120, 110, 100), "Wood")
so.box("WallW_N", (1, FH, FZ1 - 13), (FX0, FH / 2, (FZ1 + 13) / 2), (120, 160, 190), "Glass", Transparency=0.55)
so.box("WallW_S", (1, FH, -13 - FZ0), (FX0, FH / 2, (FZ0 - 13) / 2), (120, 160, 190), "Glass", Transparency=0.55)
so.box("WallW_Top", (1, FH - 18, 26), (FX0, 18 + (FH - 18) / 2, 0), (40, 40, 45), "Concrete")
for z in range(FZ0, FZ1 + 1, 12):
    if abs(z) > 14:
        so.box("Mullion", (1.4, FH, 1.4), (FX0, FH / 2, z), (30, 30, 35), "Metal")
so.box("Canopy", (10, 1, 34), (FX0 - 5, 18.5, 0), (30, 30, 35), "Metal")
sign(so, "EntranceSign", "STRATTON OAKPEN", (FX0 - 0.8, 22.5, 0), 26, 4, "-x", GOLD, part_color=(40, 40, 45), ppu=16)
so.box("RedCarpet", (30, 0.1, 10), (FX0 - 15, 0.3, 0), (160, 20, 30), "Carpet", CanCollide=False)
for side in (-1, 1):
    so.cyl("VelvetPost", 3, 0.5, (FX0 - 26, 2, side * 6), GOLD, "Foil")
    so.cyl("VelvetPost", 3, 0.5, (FX0 - 6, 2, side * 6), GOLD, "Foil")
    so.box("VelvetRope", (20, 0.4, 0.4), (FX0 - 16, 3.1, side * 6), (160, 20, 30), "Fabric", CanCollide=False)

gates.add(part("Gate_TradingFloor", (1.5, 18, 26), (FX0 - 1.5, 9, 0), GOLD, "ForceField", Transparency=0.25, CastShadow=False))

# Tower above the trading floor.
skyscraper(so, "Tower", 214, 372, -78, 78, 290, (25, 35, 55), "Glass", (200, 170, 90), "Metal",
           setbacks=((0.45, 12), (0.75, 30)), crown="spire", lit=0.25, base_y=FH + 2)
sign(so, "TowerSign", "STRATTON OAKPEN", (213.2, 120, 0), 130, 22, "-x", GOLD, part_color=(25, 35, 55), ppu=6, transparent=True)
sign(so, "TowerSignN", "STRATTON OAKPEN", (293, 120, 78.8), 130, 22, "+z", GOLD, part_color=(25, 35, 55), ppu=6, transparent=True)

# Trading desks: three rows on each side of the central pit.
desk_colors = [(60, 200, 110), (80, 160, 255), (255, 90, 90), (255, 200, 80)]
for side in (-1, 1):
    for row_z in (46, 58, 70):
        z = side * row_z
        so.box("DeskRow", (112, 0.5, 5), (279, 3.2, z), (70, 55, 45), "Wood")
        so.box("DeskPanel", (112, 3, 0.4), (279, 1.6, z + side * 2.3), (50, 45, 40), "Wood")
        for x in range(227, 334, 8):
            so.box("Monitor", (3.2, 2.2, 0.3), (x - 1.8, 5, z + side * 1.4), BLACK, "SmoothPlastic", r=(0, 0, 0))
            so.box("Screen", (2.9, 1.9, 0.05), (x - 1.8, 5, z + side * 1.23), random.choice(desk_colors), "Neon", CanCollide=False, CastShadow=False)
            so.box("Monitor2", (3.2, 2.2, 0.3), (x + 1.8, 5, z + side * 1.4), BLACK, "SmoothPlastic")
            so.box("Screen2", (2.9, 1.9, 0.05), (x + 1.8, 5, z + side * 1.23), random.choice(desk_colors), "Neon", CanCollide=False, CastShadow=False)
            so.box("Phone", (1.2, 0.5, 0.9), (x, 3.7, z - side * 0.8), BLACK)
            so.box("Chair", (2.4, 0.5, 2.4), (x, 1.9, z - side * 3.8), (20, 20, 25), "Leather", cls="Seat")
            so.box("ChairBack", (2.4, 2.6, 0.4), (x, 3.3, z - side * 5), (20, 20, 25), "Leather")
# Tickers on both long walls.
for side in (-1, 1):
    ticker(so, (293, 28, side * (FZ1 - 1.2)), 150, 4, "+z" if side < 0 else "-z")
# Ceiling lights.
for x in range(225, 370, 24):
    for z in (-50, 0, 50):
        so.box("CeilingPanel", (14, 0.3, 3), (x, FH - 0.2, z), (255, 250, 235), "Neon", CastShadow=False,
               children=[light("PointLight", (255, 240, 215), 1.3, 40)])
# Goldfish tank by the entrance. Yes, that goldfish.
tank = so.sub("GoldfishTank", (222, 0.4, -20))
tank.box("Stand", (6, 3, 4), (0, 1.5, 0), BLACK, "Wood")
tank.box("Water", (5.6, 3.6, 3.6), (0, 4.8, 0), (80, 170, 220), "Glass", Transparency=0.5, CanCollide=False)
tank.box("Fish", (0.9, 0.6, 0.3), (0.4, 5, 0), (255, 140, 20), "Neon", CanCollide=False)
sign(tank, "Label", "DON'T EAT GARY", (0, 2.4, 2.05), 5, 0.8, "+z", GOLD, bg=BLACK, part_color=BLACK, ppu=30)

# The stage where the Wolf gives his speech.
stage = so.sub("SpeechStage", (360, 0, 0))
stage.box("Platform", (26, 3, 50), (0, 1.9, 0), (25, 25, 30), "Wood")
stage.box("Edge", (0.6, 0.4, 50), (-13, 3.3, 0), GOLD, "Neon", CastShadow=False)
for s in range(3):
    stage.box("Step", (2, 1 + s, 12), (-14 - (2 - s) * 2 + 1, (1 + s) / 2 + 0.4, 0), (35, 35, 40), "Wood")
stage.box("Podium", (3, 4.5, 4), (-6, 5.5, 0), (90, 60, 35), "Wood")
stage.box("PodiumLogo", (0.1, 2, 2.4), (-7.55, 5.8, 0), GOLD, "Neon", CanCollide=False)
stage.box("Mic", (0.2, 1.6, 0.2), (-7, 8.4, 0), (60, 60, 60), "Metal", r=(0, 0, 20))
stage.box("Screen", (1, 16, 44), (12.4, 14, 0), BLACK, "SmoothPlastic",
          children=[inst("SurfaceGui", "Screen", {"Face": "Left", "SizingMode": "PixelsPerStud", "PixelsPerStud": 12, "LightInfluence": 0, "Brightness": 2},
                         [inst("TextLabel", "Label", {"Text": "STRATTON OAKPEN\nSELL ME THIS PEN", "TextScaled": True, "Font": "GothamBlack",
                                                      "TextColor3": rgb(*GOLD), "BackgroundColor3": rgb(10, 20, 40), "Size": {"UDim2": [[1, 0], [1, 0]]}})])])
for z in range(-22, 23, 11):
    stage.box("StageLight", (1.2, 1.2, 3), (-12, 30, z), (255, 190, 60), "Neon", CastShadow=False,
              children=[light("SpotLight", (255, 220, 160), 2, 40, Angle=45, Face="Bottom")])
    stage.box("Confetti", (4, 0.2, 4), (-2, 33, z), WHITE, "SmoothPlastic", Transparency=1, CanCollide=False, CastShadow=False,
              children=[inst("ParticleEmitter", "Confetti", {
                  "Enabled": False, "Rate": 60, "Lifetime": {"NumberRange": [4, 6]}, "Speed": {"NumberRange": [2, 6]},
                  "SpreadAngle": [60, 60], "Acceleration": [0, -6, 0], "RotSpeed": {"NumberRange": [-200, 200]},
                  "Rotation": {"NumberRange": [0, 360]},
                  "Color": {"ColorSequence": {"keypoints": [{"time": 0, "color": rgb(*GOLD)}, {"time": 0.5, "color": rgb(*MONEY)}, {"time": 1, "color": rgb(*WHITE)}]}},
                  "Size": {"NumberSequence": {"keypoints": [{"time": 0, "value": 0.5, "envelope": 0.2}, {"time": 1, "value": 0.4, "envelope": 0.1}]}},
                  "LightEmission": 0.4,
              })])
# Money rain over the pit, also triggered by the speech.
for x in range(240, 340, 25):
    so.box("Confetti", (6, 0.2, 30), (x, 34.5, 0), WHITE, "SmoothPlastic", Transparency=1, CanCollide=False, CastShadow=False,
           children=[inst("ParticleEmitter", "Confetti", {
               "Enabled": False, "Rate": 25, "Lifetime": {"NumberRange": [5, 7]}, "Speed": {"NumberRange": [1, 3]},
               "SpreadAngle": [30, 30], "Acceleration": [0, -5, 0], "RotSpeed": {"NumberRange": [-120, 120]},
               "Color": {"ColorSequence": {"keypoints": [{"time": 0, "color": rgb(*MONEY)}, {"time": 1, "color": rgb(40, 160, 80)}]}},
               "Size": {"NumberSequence": {"keypoints": [{"time": 0, "value": 0.6, "envelope": 0}, {"time": 1, "value": 0.6, "envelope": 0}]}},
               "Squash": {"NumberSequence": {"keypoints": [{"time": 0, "value": -0.6, "envelope": 0}, {"time": 1, "value": -0.6, "envelope": 0}]}},
           })])

# The boss's fishbowl office in the corner.
boss = so.sub("CornerOffice", (360, 0, 62))
boss.box("GlassW", (0.5, 14, 36), (-13, 7, 0), (150, 190, 220), "Glass", Transparency=0.6)
boss.box("GlassS", (26, 14, 0.5), (0, 7, -18), (150, 190, 220), "Glass", Transparency=0.6)
boss.box("Door", (0.6, 10, 6), (-13, 5, -10), (150, 190, 220), "Glass", Transparency=0.8, CanCollide=False)
boss.box("Rug", (18, 0.1, 22), (2, 0.45, 0), (200, 170, 90), "Fabric", CanCollide=False)
boss.box("Desk", (10, 3.4, 4), (4, 1.9, 0), (60, 35, 20), "Wood")
boss.box("GoldChair", (3, 0.6, 3), (8, 2, 0), GOLD, "Foil", cls="Seat")
boss.box("ChairBack", (0.5, 5, 3), (9.8, 4.2, 0), GOLD, "Foil")
boss.box("Nameplate", (2.4, 0.6, 0.4), (4, 3.9, -1.4), GOLD, "Foil")
boss.cyl("GlobeStand", 2.4, 0.4, (-6, 1.6, 12), GOLD, "Foil")
boss.ball("Globe", 2.4, (-6, 4, 12), (60, 120, 200), "SmoothPlastic")
sign(boss, "Door Sign", "THE WOLF", (-13.4, 11, -10), 6, 1.2, "-x", GOLD, bg=BLACK, part_color=BLACK, ppu=30)

# ===========================================================================
# 5. HARBOR + YACHT
# ===========================================================================
hb = root.sub("Harbor")
hb.box("Promenade", (200, 0.3, 70), (282, 0.15, 116), (150, 110, 75), "WoodPlanks")
hb.box("Corridor", (24, 0.3, 64), (198, 0.15, 50), SIDEWALK, "Concrete")
for x in range(186, 380, 4):
    if not (274 <= x <= 306):
        hb.box("Rail", (0.4, 3.2, 0.4), (x, 1.6, 151.5), (220, 220, 220), "Metal")
hb.box("RailTopW", (88, 0.4, 0.6), (230, 3.3, 151.5), (220, 220, 220), "Metal")
hb.box("RailTopE", (72, 0.4, 0.6), (343, 3.3, 151.5), (220, 220, 220), "Metal")
for x in range(195, 375, 30):
    lamp_post(hb, x, 146, 0, 12, -1)
    tree(hb, x + 15, 86, 0, 1.1)
for x in (230, 330, 360):
    bench(hb, x, 140, 180, 0)
sign(hb, "MarinaSign", "PEN STREET MARINA", (290, 18, 150), 40, 6, "-z", WHITE, bg=(20, 60, 120), part_color=(20, 60, 120), ppu=16)
hb.box("MarinaArchL", (2, 20, 2), (269, 10, 150), WHITE, "Metal")
hb.box("MarinaArchR", (2, 20, 2), (311, 10, 150), WHITE, "Metal")

gates.add(part("Gate_Yacht", (26, 16, 1.5), (290, 8, 153), GOLD, "ForceField", Transparency=0.25, CastShadow=False))

pier = hb.sub("Pier")
pier.box("Deck", (24, 1, 180), (290, -0.5, 242), TEAK, "WoodPlanks")
for z in range(158, 332, 12):
    for x in (279, 301):
        pier.cyl("Post", 12, 1.4, (x, -5, z), (90, 65, 45), "Wood")
    pier.cyl("Bollard", 1.4, 1, (301, 0.7, z), (40, 40, 45), "Metal")
for z in range(170, 330, 40):
    lamp_post(pier, 280, z, 0, 10, 1)
# Small boats along the west side.
for i, z in enumerate((185, 235, 285)):
    boat = pier.sub("SpeedBoat", (268, -2.2, z))
    boat.box("Hull", (8, 2.5, 20), (0, 0, 0), random.choice((WHITE, (200, 40, 40), (30, 60, 120))), "SmoothPlastic")
    boat.box("Bow", (5.66, 2.5, 5.66), (0, 0, 10), WHITE, "SmoothPlastic", r=(0, 45, 0))
    boat.box("Windshield", (7, 1.6, 0.3), (0, 2, 3), (40, 60, 80), "Glass", Transparency=0.3, r=(-20, 0, 0))
    boat.box("Seat", (6, 1, 3), (0, 1.7, -3), (230, 220, 200), "Fabric", cls="Seat")

# The yacht. Hull along +z; the bow is a square rotated 45 degrees.
y = hb.sub("Yacht", (330, 0, 0))
DECK = 5.4
y.box("HullLower", (34, 8, 112), (0, -4, 250), (20, 30, 60), "SmoothPlastic")
y.box("HullUpper", (34, 5, 112), (0, 2.5, 250), WHITE, "SmoothPlastic", Reflectance=0.1)
y.box("BowLower", (24, 8, 24), (0, -4, 306), (20, 30, 60), "SmoothPlastic", r=(0, 45, 0))
y.box("BowUpper", (24, 5, 24), (0, 2.5, 306), WHITE, "SmoothPlastic", r=(0, 45, 0), Reflectance=0.1)
y.box("GoldStripe", (34.2, 0.6, 112.2), (0, 1, 250), GOLD, "Foil", CanCollide=False)
y.box("Deck", (33, 0.4, 112), (0, DECK - 0.2, 250), TEAK, "WoodPlanks")
y.box("BowDeck", (23, 0.4, 23), (0, DECK - 0.2, 306), TEAK, "WoodPlanks", r=(0, 45, 0))
for side in (-1, 1):
    sign(y, "Name", "NAOMI", (side * 17.1, 1.4, 250), 16, 3, "+x" if side > 0 else "-x", (20, 30, 60), font="Garamond", part_color=WHITE, ppu=20, transparent=True)
    # Leave a gap on the pier side where the gangway comes aboard.
    spans = [(195, 305)] if side > 0 else [(195, 208), (220, 305)]
    for z0, z1 in spans:
        y.box("Rail", (0.4, 0.4, z1 - z0), (side * 16.6, DECK + 3, (z0 + z1) / 2), (230, 230, 230), "Metal")
        for z in range(z0 + 1, z1, 6):
            y.box("Stanchion", (0.3, 3, 0.3), (side * 16.6, DECK + 1.5, z), (230, 230, 230), "Metal")
y.box("SternRail", (33, 0.4, 0.4), (0, DECK + 3, 194.3), (230, 230, 230), "Metal")
# Superstructure: three decks.
y.box("Deck2", (26, 7.6, 58), (0, DECK + 3.8, 262), WHITE, "SmoothPlastic")
y.box("Deck2Windows", (26.2, 2.4, 56), (0, DECK + 4.4, 262), (20, 30, 45), "Glass", Transparency=0.1)
y.box("Deck2Front", (18.4, 7.6, 18.4), (0, DECK + 3.8, 286), WHITE, "SmoothPlastic", r=(0, 45, 0))
y.box("Deck3", (20, 6, 40), (0, DECK + 10.6, 266), WHITE, "SmoothPlastic")
y.box("Deck3Windows", (20.2, 2, 38), (0, DECK + 11, 266), (20, 30, 45), "Glass", Transparency=0.1)
y.box("Bridge", (16, 5, 18), (0, DECK + 16, 276), WHITE, "SmoothPlastic")
y.box("BridgeWindow", (16.2, 2, 18.2), (0, DECK + 16.5, 276), (20, 30, 45), "Glass", Transparency=0.1)
y.box("RadarArch", (18, 1.2, 2), (0, DECK + 21, 270), (230, 230, 230), "Metal")
y.box("Radar", (6, 0.4, 1), (0, DECK + 22.2, 270), (40, 40, 45), "Metal")
y.cyl("Mast", 10, 0.6, (0, DECK + 26, 272), (230, 230, 230), "Metal")
y.ball("MastLight", 1, (0, DECK + 31, 272), (255, 255, 255), "Neon", children=[light("PointLight", (255, 255, 255), 2, 30)])
# Helipad with a helicopter on the top deck.
y.cyl("Helipad", 0.4, 18, (0, DECK + 13.8, 256), (50, 50, 55), "Concrete")
y.box("H1", (1, 0.1, 7), (-2.2, DECK + 14.05, 256), WHITE)
y.box("H2", (1, 0.1, 7), (2.2, DECK + 14.05, 256), WHITE)
y.box("H3", (3.4, 0.1, 1), (0, DECK + 14.05, 256), WHITE)
heli = y.sub("Helicopter", (0, DECK + 14, 256), yaw=90)
heli.box("Cabin", (8, 4.5, 5), (0, 3, 0), (20, 20, 25), "SmoothPlastic", Reflectance=0.2)
heli.box("Glass", (3, 3, 4.6), (4.2, 3.4, 0), (30, 60, 90), "Glass", Transparency=0.3)
heli.box("Tail", (10, 1.2, 1.2), (-8.5, 3.8, 0), (20, 20, 25))
heli.box("TailFin", (1.4, 3, 0.3), (-13, 5, 0), GOLD, "Foil")
heli.box("RotorA", (18, 0.2, 0.8), (0, 6.2, 0), (60, 60, 60), "Metal")
heli.box("RotorB", (0.8, 0.2, 18), (0, 6.2, 0), (60, 60, 60), "Metal")
for s in (-1, 1):
    heli.box("Skid", (9, 0.4, 0.4), (0, 0.4, s * 2.4), (60, 60, 60), "Metal")
# Aft party deck: where the customers hang out.
y.box("HotTub", (10, 1.6, 10), (0, DECK + 0.8, 308), WHITE, "SmoothPlastic", r=(0, 45, 0))
y.box("TubWater", (8.6, 0.2, 8.6), (0, DECK + 1.5, 308), (60, 220, 230), "Neon", CanCollide=False, r=(0, 45, 0))
for x in (-10, -4, 4, 10):
    y.box("Lounger", (3, 1, 6), (x, DECK + 0.9, 198.5), WHITE, "Fabric", cls="Seat")
y.box("Bar", (12, 3.6, 3), (-9, DECK + 1.8, 229), (40, 30, 25), "Wood")
y.box("BarTop", (12.4, 0.3, 3.4), (-9, DECK + 3.75, 229), GOLD, "Foil")
y.box("DJBooth", (6, 3.4, 3), (9, DECK + 1.7, 229), BLACK, "SmoothPlastic")
y.box("DJLights", (6, 0.3, 0.3), (9, DECK + 3.6, 227.6), NEON_PINK, "Neon", CanCollide=False)
for z in (200, 212, 224):
    for x in (-15, 15):
        y.ball("DeckLight", 0.8, (x, DECK + 3.5, z), WARM_WINDOW, "Neon", CanCollide=False,
               children=[light("PointLight", WARM_WINDOW, 1, 14)] if x < 0 else None)
# Gangway from the pier up to the deck.
hb.box("Gangway", (12.6, 0.5, 5), (307.5, DECK / 2 + 0.2, 214), (200, 200, 205), "DiamondPlate", r=(0, 0, 24))
hb.box("GangwayRailN", (12.6, 0.3, 0.3), (307.5, DECK / 2 + 3, 216.4), (230, 230, 230), "Metal", r=(0, 0, 24))
hb.box("GangwayRailS", (12.6, 0.3, 0.3), (307.5, DECK / 2 + 3, 211.6), (230, 230, 230), "Metal", r=(0, 0, 24))

# ===========================================================================
# 6. BACKDROP: skyline, Statue of Pen-erty
# ===========================================================================
sky = root.sub("Skyline")
def backdrop_block(x, z, w, d, h):
    color = random.choice(((40, 55, 75), (70, 75, 85), (110, 100, 90), (30, 35, 45), (150, 140, 125)))
    mat = "Glass" if color[2] > color[0] else "Concrete"
    skyscraper(sky, "Backdrop", x - w / 2, x + w / 2, z - d / 2, z + d / 2, h, color, mat,
               (150, 150, 150), "Concrete", lit=0.18, crown=random.choice((None, None, "spire", "watertower")), base_y=-4)

# Manhattan behind Pen Street (south), and across the river (east).
for i in range(14):
    backdrop_block(-80 + i * 34 + random.uniform(-6, 6), -205 + random.uniform(-10, 10), random.uniform(22, 32), random.uniform(22, 32), random.uniform(90, 260))
for i in range(9):
    backdrop_block(470 + random.uniform(-10, 10), -180 + i * 45, random.uniform(24, 34), random.uniform(24, 34), random.uniform(80, 240))
sky.box("SouthIsland", (520, 4, 90), (150, -3, -205), (90, 90, 90), "Concrete")
sky.box("EastIsland", (70, 4, 460), (470, -3, 0), (90, 90, 90), "Concrete")

# Statue of Pen-erty on its own island in the harbor.
lib = root.sub("StatueOfPenerty", (140, 0, 380))
GREEN = (95, 165, 140)
lib.box("Island", (70, 6, 70), (0, -3, 0), (110, 105, 95), "Rock")
lib.box("Fort", (46, 6, 46), (0, 3, 0), (150, 140, 120), "Brick", r=(0, 45, 0))
lib.box("Pedestal", (22, 26, 22), (0, 19, 0), (190, 180, 160), "Granite")
lib.box("PedestalTop", (18, 4, 18), (0, 34, 0), (190, 180, 160), "Granite")
lib.box("Robe", (12, 26, 10), (0, 49, 0), GREEN, "Metal")
lib.box("RobeTop", (9, 8, 8), (0, 66, 0), GREEN, "Metal")
lib.ball("Head", 7, (0, 73, 0), GREEN, "Metal")
for i in range(7):
    a = math.radians(-90 + i * 30)
    lib.box("CrownSpike", (0.8, 5, 0.8), (math.cos(a) * 3.6, 77, math.sin(a) * 3.6 - 1), GREEN, "Metal",
            r=(math.degrees(math.sin(a)) * 0.5, 0, -math.degrees(math.cos(a)) * 0.5))
lib.box("Arm", (2.6, 16, 2.6), (5.5, 77, 0), GREEN, "Metal", r=(0, 0, -12))
lib.cyl("GiantPen", 20, 2.2, (7.5, 92, 0), GOLD, "Foil", r=(0, 0, 78))
lib.box("PenTip", (1.4, 2.4, 1.4), (9.6, 102.2, 0), (240, 240, 240), "Metal", r=(0, 0, -12))
lib.ball("PenGlow", 3, (9.8, 104, 0), (255, 230, 120), "Neon", CanCollide=False, children=[light("PointLight", (255, 220, 120), 4, 40)])
lib.box("Tablet", (5, 7, 1.5), (-6, 60, -3), GREEN, "Metal", r=(0, 0, 15))
sign(lib, "Plaque", "STATUE OF PEN-ERTY", (0, 24, -11.1), 18, 3, "-z", GOLD, bg=(40, 40, 40), part_color=(40, 40, 40), ppu=20)

# ===========================================================================
# 7. THE PENTHOUSE (rebirth 8) on top of Tower A. Visitors come to the door.
# ===========================================================================
ph = root.sub("Penthouse")
PY = 152  # floor surface
CREAM = (235, 228, 214)
ph.box("Floor", (50, 0.4, 56), (-80, PY - 0.2, 62), (60, 45, 35), "WoodPlanks")
ph.box("Roof", (50, 1, 38), (-80, PY + 14.5, 55), CREAM, "SmoothPlastic")
# Elevator lobby (z 34..46) with the elevator back down.
ph.box("LobbyFloor", (22, 0.1, 10), (-80, PY + 0.05, 40), (230, 225, 215), "Marble", CanCollide=False)
ph.box("LobbyWallS", (50, 14, 1), (-80, PY + 7, 34.5), CREAM, "SmoothPlastic")
ph.box("Elevator_street", (8, 11, 0.6), (-80, PY + 5.5, 35.3), GOLD, "Foil")
sign(ph, "ElevatorSign", "ELEVATOR  ↓  PEN STREET", (-80, PY + 12, 35.1), 12, 1.6, "+z", GOLD, bg=BLACK, part_color=BLACK, ppu=24)
ph.box("LobbySideW", (1, 14, 12), (-91.5, PY + 7, 40), CREAM, "SmoothPlastic")
ph.box("LobbySideE", (1, 14, 12), (-68.5, PY + 7, 40), CREAM, "SmoothPlastic")
ph.box("DoorWallW", (7.5, 14, 1), (-87.75, PY + 7, 46), CREAM, "SmoothPlastic")
ph.box("DoorWallE", (7.5, 14, 1), (-72.25, PY + 7, 46), CREAM, "SmoothPlastic")
ph.box("DoorTop", (8, 4, 1), (-80, PY + 12, 46), CREAM, "SmoothPlastic")
ph.box("DoorFrame", (9, 0.6, 1.2), (-80, PY + 10, 46), GOLD, "Foil")
ph.box("Doorbell", (0.4, 0.6, 0.3), (-85, PY + 5, 46.6), GOLD, "Neon")
sign(ph, "DoorSign", "THE PENTHOUSE", (-80, PY + 12, 45.3), 7, 1.4, "-z", GOLD, bg=BLACK, part_color=BLACK, ppu=30)
# Glass all around the living room, with a door to the terrace.
for side in (-1, 1):
    ph.box("GlassSide", (0.6, 14, 40), (-80 + side * 24.7, PY + 7, 54), (170, 210, 230), "Glass", Transparency=0.6)
ph.box("GlassNorthW", (26, 14, 0.6), (-92, PY + 7, 74), (170, 210, 230), "Glass", Transparency=0.6)
ph.box("GlassNorthE", (14, 14, 0.6), (-62, PY + 7, 74), (170, 210, 230), "Glass", Transparency=0.6)
ph.box("GlassNorthTop", (10, 4, 0.6), (-74, PY + 12, 74), (170, 210, 230), "Glass", Transparency=0.6)
ph.box("Rug", (26, 0.1, 12), (-80, PY + 0.05, 66), (160, 30, 45), "Fabric", CanCollide=False)
ph.box("Sofa", (16, 2, 4), (-80, PY + 1, 71), (240, 240, 235), "Fabric", cls="Seat")
ph.box("SofaBack", (16, 3, 1.2), (-80, PY + 2.5, 72.8), (240, 240, 235), "Fabric")
ph.box("SofaArm", (4, 2, 10), (-90, PY + 1, 67), (240, 240, 235), "Fabric", cls="Seat")
ph.box("CoffeeTable", (7, 1.4, 3.5), (-80, PY + 0.7, 65.5), (30, 30, 30), "Glass", Reflectance=0.3)
ph.box("GoldBar", (1.4, 0.5, 0.7), (-79, PY + 1.65, 65.5), GOLD, "Foil")
ph.box("Piano", (6, 3.2, 5), (-66, PY + 1.6, 66), (15, 15, 15), "SmoothPlastic", Reflectance=0.3)
ph.box("PianoLid", (6, 0.2, 5), (-66, PY + 4.4, 67), (15, 15, 15), "SmoothPlastic", r=(-30, 0, 0))
ph.box("Bar", (3, 4, 14), (-101, PY + 2, 63), (40, 30, 25), "Wood")
ph.box("BarTop", (3.6, 0.3, 14.6), (-101, PY + 4.15, 63), GOLD, "Foil")
for z in (58, 63, 68):
    ph.cyl("BarStool", 3, 1.4, (-98, PY + 1.5, z), (200, 170, 90), "Metal")
ph.box("TV", (0.4, 7, 13), (-55.9, PY + 6, 56), BLACK, "SmoothPlastic",
       children=[inst("SurfaceGui", "Screen", {"Face": "Left", "SizingMode": "PixelsPerStud", "PixelsPerStud": 16, "LightInfluence": 0, "Brightness": 1.5},
                      [inst("TextLabel", "Label", {"Text": "PEN +420%", "TextScaled": True, "Font": "GothamBlack", "TextColor3": rgb(*MONEY), "BackgroundColor3": rgb(5, 15, 10), "Size": {"UDim2": [[1, 0], [1, 0]]}})])])
sign(ph, "WolfNeon", "SELL ME THIS PEN", (-80, PY + 11, 46.9), 14, 2.2, "+z", NEON_PINK, part_color=BLACK, ppu=20, transparent=True)
for x, z in ((-80, 60), (-80, 52)):
    ph.box("Chandelier", (6, 0.6, 6), (x, PY + 13.4, z), (255, 240, 200), "Neon", CastShadow=False,
           children=[light("PointLight", (255, 235, 200), 1.5, 34)])
# Terrace with an infinity pool.
ph.box("Terrace", (50, 0.4, 14), (-80, PY - 0.2, 81), (200, 195, 185), "Limestone")
ph.box("Pool", (20, 0.2, 8), (-90, PY + 0.05, 82), (60, 210, 230), "Neon", CanCollide=False, Transparency=0.15)
ph.box("PoolEdge", (22, 0.5, 0.6), (-90, PY + 0.25, 77.7), WHITE, "Marble")
for x in (-74, -68, -62):
    ph.box("Lounger", (3, 1, 6), (x, PY + 0.5, 82), WHITE, "Fabric", cls="Seat")
for x in range(-104, -54, 3):
    ph.box("GlassRail", (3, 3.5, 0.3), (x + 1.5, PY + 1.75, 87.8), (170, 210, 230), "Glass", Transparency=0.5)
for side in (-1, 1):
    ph.box("GlassRailSide", (0.3, 3.5, 14), (-80 + side * 24.8, PY + 1.75, 81), (170, 210, 230), "Glass", Transparency=0.5)
planter_tree(ph, -58, 85, PY)
planter_tree(ph, -102, 85, PY)
sign(ph, "RoofSign", "PENTHOUSE", (-80, PY + 19, 34.8), 30, 7, "-z", GOLD, part_color=BLACK, ppu=10, transparent=True)
ph.box("RoofSignBar", (30, 0.6, 0.6), (-80, PY + 15.4, 34.8), (60, 60, 60), "Metal")
# Street-level elevator in the Tower A lobby.
ps.box("Elevator_penthouse", (8, 11, 0.6), (-80, 6, 33.5), GOLD, "Foil")
sign(ps, "PenthouseElevatorSign", "PENTHOUSE ELEVATOR", (-80, 13.4, 33.3), 14, 2, "-z", GOLD, bg=BLACK, part_color=BLACK, ppu=24)
ps.box("ElevatorAwning", (14, 0.6, 5), (-80, 15, 31), (30, 30, 35), "Metal")

# ===========================================================================
# 8. THE SWISS VAULT (rebirth 10): a snowy island and a bank full of gold.
# ===========================================================================
sv = root.sub("SwissVault")
VX, VZ = -620, 380
SNOW = (245, 248, 252)
sv.box("Island", (190, 6, 170), (VX, -3, VZ), SNOW, "Snow")
sv.box("Rocks", (200, 4, 180), (VX, -6, VZ), (90, 90, 95), "Rock")
sv.box("Path", (14, 0.2, 40), (VX, 0.1, 320), (120, 115, 110), "Cobblestone")


def mountain(g, x, z, base, height, peak_snow=True):
    m = g.sub("Mountain", (x, 0, z))
    steps = 5
    for i in range(steps):
        w = base * (1 - i / steps)
        h = height / steps
        color = SNOW if (peak_snow and i >= steps - 2) else (110, 105, 100)
        m.box("Tier", (w, h, w), (0, h * i + h / 2, 0), color, "Snow" if color == SNOW else "Rock", r=(0, 45 * (i % 2), 0))
    m.box("Peak", (base * 0.18, height * 0.25, base * 0.18), (0, height + height * 0.1, 0), SNOW, "Snow", r=(0, 45, 0))


for x, z, b, h in ((-690, 455, 70, 70), (-630, 470, 90, 95), (-560, 455, 70, 60), (-700, 400, 40, 35), (-545, 400, 40, 30)):
    mountain(sv, x, z, b, h)
for x, z in ((-690, 330), (-670, 310), (-560, 330), (-575, 310), (-700, 360), (-548, 360)):
    t = sv.sub("Pine", (x, 0, z))
    t.cyl("Trunk", 4, 1, (0, 2, 0), (80, 55, 35), "Wood")
    for i, (w, y) in enumerate(((8, 5), (6, 8), (4, 11))):
        t.box("Needles", (w, 3.5, w), (0, y, 0), (40, 90, 60), "Grass", r=(0, 45 * i, 0))
        t.box("Snow", (w * 0.8, 0.4, w * 0.8), (0, y + 1.9, 0), SNOW, "Snow", r=(0, 45 * i, 0))
# The bank: hall interior x -655..-585, z 345..415.
BW = (225, 220, 210)
sv.box("Floor", (70, 0.4, 70), (VX, 0.2, 380), (240, 235, 225), "Marble", Reflectance=0.1)
sv.box("FloorInlay", (30, 0.05, 30), (VX, 0.43, 382), GOLD, "Foil", CanCollide=False)
sv.box("Ceiling", (74, 2, 74), (VX, 31, 380), BW, "Marble")
sv.box("WallN", (74, 30, 2), (VX, 15, 416), BW, "Marble")
sv.box("WallW", (2, 30, 74), (-656, 15, 380), BW, "Marble")
sv.box("WallE", (2, 30, 74), (-584, 15, 380), BW, "Marble")
sv.box("WallS_W", (31, 30, 2), (-641.5, 15, 344), BW, "Marble")
sv.box("WallS_E", (31, 30, 2), (-598.5, 15, 344), BW, "Marble")
sv.box("WallS_Top", (12, 14, 2), (VX, 23, 344), BW, "Marble")
for x in (-650, -640, -630, -610, -600, -590):
    sv.cyl("Column", 22, 3.5, (x, 11, 339), BW, "Marble")
sv.box("Portico", (74, 3, 12), (VX, 23.5, 339), BW, "Marble")
sign(sv, "BankName", "BANQUE DE PEN-EVE", (VX, 23.5, 332.9), 56, 3, "-z", GOLD, part_color=BW, material="Marble", font="Garamond", ppu=16)
sv.box("SwissFlag", (8, 8, 0.3), (VX, 34, 343), (220, 30, 40), "Fabric")
sv.box("CrossV", (1.6, 5, 0.35), (VX, 34, 342.9), WHITE, "Fabric")
sv.box("CrossH", (5, 1.6, 0.35), (VX, 34, 342.9), WHITE, "Fabric")
# The vault door on the north wall.
sv.cyl("VaultDoor", 2, 26, (VX, 14, 414), (150, 155, 165), "DiamondPlate", r=(0, 90, 0), Reflectance=0.2)
sv.cyl("VaultHub", 3, 6, (VX, 14, 412.5), (190, 190, 200), "Metal", r=(0, 90, 0))
for a in range(0, 180, 45):
    sv.box("Spoke", (0.8, 12, 0.8), (VX, 14, 411.8), (190, 190, 200), "Metal", r=(0, 0, a))
sign(sv, "VaultSign", "NUMBERED ACCOUNTS ONLY", (VX, 28.5, 414.9), 30, 2, "-z", GOLD, bg=BLACK, part_color=BLACK, ppu=20)
# Gold everywhere, kept to the edges so customers can walk the hall.
for x0, z0 in ((-651, 352), (-651, 368), (-651, 392), (-651, 408), (-589, 352), (-589, 368), (-589, 392), (-589, 408)):
    for layer in range(3):
        for i in range(4 - layer):
            for j in range(2):
                sv.box("GoldBar", (1.8, 0.8, 3.6), (x0 - 2.7 + i * 1.9 + layer * 0.95, 0.8 + layer * 0.8, z0 - 1.9 + j * 3.8), GOLD, "Foil")
# Safety deposit boxes on the side walls.
for side in (-1, 1):
    for y in range(4, 26, 3):
        for z in range(352, 410, 4):
            if 360 <= z <= 404:
                sv.box("DepositBox", (0.4, 2.6, 3.6), (VX + side * 34.8, y, z), (190, 170, 110), "Metal")
for x, z in ((-635, 365), (-605, 365), (-635, 395), (-605, 395)):
    sv.box("Chandelier", (5, 0.6, 5), (x, 29.4, z), (255, 240, 200), "Neon", CastShadow=False, children=[light("PointLight", (255, 235, 200), 1.6, 40)])
sv.box("TellerDesk", (24, 4, 3), (VX, 2.4, 409), (70, 45, 30), "Wood")
sv.box("TellerTop", (24.6, 0.3, 3.6), (VX, 4.55, 409), GOLD, "Foil")
sv.box("Snowfall", (190, 1, 170), (VX, 70, VZ), WHITE, "SmoothPlastic", Transparency=1, CanCollide=False, CastShadow=False,
       children=[inst("ParticleEmitter", "Snow", {
           "Rate": 120, "Lifetime": {"NumberRange": [8, 12]}, "Speed": {"NumberRange": [3, 6]},
           "SpreadAngle": [20, 20], "EmissionDirection": "Bottom", "Acceleration": [1, 0, 0],
           "Color": {"ColorSequence": {"keypoints": [{"time": 0, "color": [1, 1, 1]}, {"time": 1, "color": [1, 1, 1]}]}},
           "Size": {"NumberSequence": {"keypoints": [{"time": 0, "value": 0.35, "envelope": 0.1}, {"time": 1, "value": 0.35, "envelope": 0.1}]}},
       })])

# ===========================================================================
# 9. PRIVATE ISLAND (rebirth 14): the retirement plan.
# ===========================================================================
pi = root.sub("PrivateIsland")
IX, IZ = 560, 560
SAND = (238, 214, 160)
pi.box("Sand", (8, 200, 200), (IX, -4, IZ), SAND, "Sand", Shape="Cylinder", r=(0, 0, 90))
pi.box("Grass", (8, 120, 120), (IX, -3.7, IZ + 30), (90, 160, 70), "Grass", Shape="Cylinder", r=(0, 0, 90))


def palm(g, x, z, lean=12, yaw=0):
    p = g.sub("Palm", (x, 0, z), yaw)
    prev = (0, 0, 0)
    for i in range(6):
        nxt = (math.sin(math.radians(lean)) * (i + 1) * 3.2, (i + 1) * 3.2, 0)
        p.beam("Trunk", prev, nxt, 1.2 - i * 0.08, (120, 90, 55), "Wood")
        prev = nxt
    top = prev
    for a in range(0, 360, 60):
        tip = (top[0] + math.cos(math.radians(a)) * 8, top[1] - 2.5, math.sin(math.radians(a)) * 8)
        p.beam("Frond", top, tip, 0.5, (60, 150, 60), "Grass")
        p.box("Leaf", (7, 0.2, 2.4), ((top[0] + tip[0]) / 2, (top[1] + tip[1]) / 2 + 0.2, (top[2] + tip[2]) / 2), (70, 170, 70), "Grass", r=(0, -a, -18))
    p.ball("Coconut", 1, (top[0] + 0.6, top[1] - 0.8, 0.5), (90, 60, 30), "Wood")


for i in range(14):
    a = math.radians(i * (360 / 14) + 8)
    palm(pi, IX + math.cos(a) * 84, IZ + math.sin(a) * 84, random.uniform(8, 20), -math.degrees(a) + 180)
# Villa on the north side.
pi.box("VillaBase", (84, 1, 40), (IX, 0.5, 610), (240, 238, 232), "Concrete")
pi.box("VillaGround", (70, 12, 30), (IX, 7, 612), WHITE, "SmoothPlastic")
pi.box("VillaGlass", (60, 9, 0.4), (IX, 6, 596.8), (150, 200, 220), "Glass", Transparency=0.4)
pi.box("VillaUpper", (50, 10, 26), (IX + 8, 18, 614), WHITE, "SmoothPlastic")
pi.box("VillaUpperGlass", (44, 7, 0.4), (IX + 8, 18, 600.8), (150, 200, 220), "Glass", Transparency=0.4)
pi.box("VillaRoof", (56, 1, 32), (IX + 8, 23.5, 614), (60, 50, 45), "Wood")
pi.box("Balcony", (50, 0.6, 6), (IX + 8, 12.7, 598), (200, 190, 175), "Wood")
sign(pi, "VillaSign", "VILLA JOLFORT", (IX, 11, 596.4), 24, 2.4, "-z", GOLD, part_color=WHITE, ppu=20, transparent=True)
pi.box("Pool", (40, 0.2, 10), (IX, 0.55, 584), (50, 200, 225), "Neon", CanCollide=False, Transparency=0.15)
pi.box("PoolDeck", (46, 0.5, 14), (IX, 0.25, 584), (220, 210, 190), "Wood")
for x in range(-18, 19, 6):
    pi.box("Lounger", (3, 1, 6), (IX + x, 1, 575.5), WHITE, "Fabric", cls="Seat")
# Beach bar, umbrellas, bonfire.
pi.box("BarHut", (14, 4, 6), (IX - 32, 2, 530), (160, 120, 70), "Wood")
pi.box("BarRoof", (18, 1, 10), (IX - 32, 9, 530), (200, 170, 90), "Grass")
for dx in (-6, 6):
    pi.cyl("BarPost", 8, 0.6, (IX - 32 + dx, 4.5, 533), (120, 90, 55), "Wood")
sign(pi, "BarSign", "TIKI TICKER BAR", (IX - 32, 7, 526.8), 12, 1.6, "-z", (255, 220, 120), bg=(90, 50, 20), part_color=(90, 50, 20), ppu=24)
for x, z, c in ((IX + 20, 528, (230, 60, 60)), (IX + 35, 540, (60, 140, 230)), (IX - 10, 520, (250, 200, 40))):
    u = pi.sub("Umbrella", (x, 0, z))
    u.cyl("Pole", 8, 0.3, (0, 4, 0), WHITE, "Metal")
    u.box("Canopy", (7, 0.4, 7), (0, 8, 0), c, "Fabric", r=(0, 45, 0))
    u.box("Towel", (3, 0.1, 6), (2.5, 0.1, 0), c, "Fabric", CanCollide=False)
pi.cyl("FirePit", 1, 6, (IX + 5, 0.5, 545), (70, 70, 70), "Rock")
pi.box("Fire", (2.5, 2.5, 2.5), (IX + 5, 1.8, 545), (255, 140, 40), "Neon", CanCollide=False, r=(0, 45, 0),
       children=[light("PointLight", (255, 150, 60), 3, 24), inst("Fire", "Fire", {"Heat": 6, "Size": 5})])
# Dock with a seaplane.
pi.box("Dock", (10, 1, 50), (IX, -0.3, 450), TEAK, "WoodPlanks")
for z in range(430, 476, 10):
    for dx in (-4.5, 4.5):
        pi.cyl("DockPost", 8, 1, (IX + dx, -3, z), (90, 65, 45), "Wood")
plane = pi.sub("Seaplane", (IX + 18, -1.5, 440), yaw=90)
plane.box("Fuselage", (16, 3, 3), (0, 3, 0), WHITE, "SmoothPlastic")
plane.box("Nose", (2, 2.4, 2.4), (8.6, 3, 0), (220, 40, 40), "SmoothPlastic")
plane.box("Wing", (4, 0.4, 22), (1, 4.6, 0), WHITE, "SmoothPlastic")
plane.box("Tail", (2, 3, 0.4), (-7.5, 5, 0), (220, 40, 40), "SmoothPlastic")
plane.box("Stabilizer", (2, 0.3, 7), (-7.5, 3.5, 0), WHITE, "SmoothPlastic")
for dz in (-4, 4):
    plane.box("Float", (12, 1.2, 1.4), (1, 0, dz), (200, 200, 205), "Metal")
    plane.beam("Strut", (1, 0.6, dz), (1, 2, dz * 0.4), 0.3, (120, 120, 120), "Metal")
plane.box("Propeller", (0.2, 5, 0.5), (9.7, 3, 0), BLACK, "Metal")

# Teleport arrival markers (purely decorative rings).
for x, y, z in ((-315, 0.25, -58), (-30, 0.55, 25), (290, 0.45, 0), (560, 0.1, 502), (-620, 0.45, 352)):
    root.add(part("TeleportPad", (0.2, 7, 7), (x, y, z), NEON_BLUE, "Neon", rot(0, 0, 90), Shape="Cylinder",
                  CanCollide=False, Transparency=0.4, CastShadow=False))

# ---------------------------------------------------------------------------
# Write
# ---------------------------------------------------------------------------

root.children.append(gates)
model = root.to_json()
model.pop("name", None)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(model, f, separators=(",", ":"))
print(f"Wrote {os.path.relpath(OUT)} with {PART_COUNT} parts")
