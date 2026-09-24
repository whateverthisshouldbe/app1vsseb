#!/usr/bin/env python3
"""Rendert de map als isometrische plaatjes: python3 tools/preview.py

Draait de wereldcode met de nagemaakte Roblox-API, leest alle onderdelen uit en
tekent ze. Bedoeld om de vormgeving te kunnen beoordelen zonder Roblox Studio.
"""
import json
import math
import pathlib
import subprocess
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
LUAU = "/tmp/luaubin/luau"
OUT = ROOT / "preview"

COS30, SIN30 = math.cos(math.radians(30)), math.sin(math.radians(30))
VIEW = (1 / math.sqrt(3),) * 3
LIGHT = (0.38, 0.88, 0.28)
SKY_TOP = (150, 186, 222)
SKY_BOTTOM = (226, 214, 196)


def collect_parts():
    parts_src = [
        (ROOT / "test" / "stub.luau").read_text(),
        (ROOT / "dist" / "ServerBundle.server.lua").read_text(),
        (ROOT / "test" / "dump.luau").read_text(),
    ]
    combined = ROOT / "test" / ".dump.luau"
    combined.write_text("\n\n".join(parts_src))
    result = subprocess.run([LUAU, str(combined)], capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit("wereld bouwen mislukt")
    rows = []
    for line in result.stdout.splitlines():
        if line.startswith("#PART#"):
            rows.append(json.loads(line[6:]))
    return rows


def rot_matrix(pitch, yaw, roll):
    cx, sx = math.cos(pitch), math.sin(pitch)
    cy, sy = math.cos(yaw), math.sin(yaw)
    cz, sz = math.cos(roll), math.sin(roll)
    rx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
    ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
    rz = ((cz, -sz, 0), (sz, cz, 0), (0, 0, 1))

    def mul(a, b):
        return tuple(
            tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3))
            for i in range(3)
        )

    return mul(mul(ry, rx), rz)


def apply(m, v):
    return tuple(sum(m[i][j] * v[j] for j in range(3)) for i in range(3))


FACES = [
    ((0, 1, 0), (0, 1, 3, 2)),   # boven
    ((0, -1, 0), (4, 6, 7, 5)),  # onder
    ((1, 0, 0), (2, 3, 7, 6)),   # +x
    ((-1, 0, 0), (0, 4, 5, 1)),  # -x
    ((0, 0, 1), (1, 5, 7, 3)),   # +z
    ((0, 0, -1), (0, 2, 6, 4)),  # -z
]

CORNERS = [
    (-1, 1, -1), (-1, 1, 1), (1, 1, -1), (1, 1, 1),
    (-1, -1, -1), (-1, -1, 1), (1, -1, -1), (1, -1, 1),
]


def build_faces(parts, bounds, max_height=None):
    """Alles wat het venster raakt wordt getekend; `core` is wat het kader bepaalt."""
    (x0, x1), (z0, z1) = bounds
    faces = []
    for p in parts:
        px, py, pz = p["pos"]
        reach = max(p["size"]) / 2
        if px + reach < x0 or px - reach > x1 or pz + reach < z0 or pz - reach > z1:
            continue
        if p["transparency"] >= 0.95:
            continue
        size = list(p["size"])
        if max_height is not None:
            bottom = py - size[1] / 2
            top = py + size[1] / 2
            if bottom > max_height:
                continue  # helemaal boven de snijlijn
            if top > max_height and abs(p["rot"][0]) < 0.01 and abs(p["rot"][2]) < 0.01:
                # doorsnede: het deel boven de snijlijn weghalen
                size[1] = max_height - bottom
                py = bottom + size[1] / 2
        sx, sy, sz = (v / 2 for v in size)
        m = rot_matrix(*p["rot"])
        pts = []
        for cx, cy, cz in CORNERS:
            local = (cx * sx, cy * sy, cz * sz)
            wx, wy, wz = apply(m, local)
            pts.append((px + wx, py + wy, pz + wz))
        core = x0 <= px <= x1 and z0 <= pz <= z1
        base = tuple(int(c * 255) for c in p["color"])
        alpha = 1 - p["transparency"]
        neon = p["material"] == "Neon"
        for normal, idx in FACES:
            n = apply(m, normal)
            if sum(n[i] * VIEW[i] for i in range(3)) <= 0.02:
                continue
            quad = [pts[i] for i in idx]
            depth = sum(sum(q[i] for q in quad) / 4 * VIEW[i] for i in range(3))
            shade = 0.52 + 0.48 * max(0.0, sum(n[i] * LIGHT[i] for i in range(3)))
            if neon:
                shade = max(shade, 1.05)
            faces.append((depth, quad, base, shade, alpha, core))
    faces.sort(key=lambda f: f[0])
    return faces


def sky_background(img, size):
    w, h = size
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        draw.line(
            [(0, y), (w, y)],
            fill=tuple(int(SKY_TOP[i] + (SKY_BOTTOM[i] - SKY_TOP[i]) * t) for i in range(3)),
        )


def render(parts, bounds, path, size=(1800, 1050), pad=60, max_height=None):
    faces = build_faces(parts, bounds, max_height)
    if not faces:
        raise SystemExit("niets te tekenen in dit gebied")

    def project(p):
        x, y, z = p
        return ((x - z) * COS30, (x + z) * SIN30 - y)

    projected = [[project(q) for q in quad] for _, quad, _, _, _, _ in faces]
    core_pts = [p for quad, face in zip(projected, faces) if face[5] for p in quad]
    if not core_pts:
        core_pts = [p for quad in projected for p in quad]
    xs = [p[0] for p in core_pts]
    ys = [p[1] for p in core_pts]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    scale = min((size[0] - pad * 2) / max(1e-6, maxx - minx),
                (size[1] - pad * 2) / max(1e-6, maxy - miny))
    offx = pad - minx * scale + (size[0] - pad * 2 - (maxx - minx) * scale) / 2
    offy = pad - miny * scale + (size[1] - pad * 2 - (maxy - miny) * scale) / 2

    img = Image.new("RGB", size)
    sky_background(img, size)
    draw = ImageDraw.Draw(img, "RGBA")

    for (_, _, base, shade, alpha, _), quad in zip(faces, projected):
        poly = [(p[0] * scale + offx, p[1] * scale + offy) for p in quad]
        color = tuple(min(255, int(c * shade)) for c in base) + (int(alpha * 255),)
        draw.polygon(poly, fill=color)

    OUT.mkdir(exist_ok=True)
    img.save(path)
    print(f"{path.name}: {len(faces)} vlakken")


def plan(parts, bounds, path, size=(1500, 1500), labels=()):
    """Plattegrond van bovenaf: handig om de indeling te controleren."""
    (x0, x1), (z0, z1) = bounds
    img = Image.new("RGB", size, (245, 243, 238))
    draw = ImageDraw.Draw(img, "RGBA")
    scale = min(size[0] / (x1 - x0), size[1] / (z1 - z0))

    def to_px(x, z):
        return ((x - x0) * scale, (z1 - z) * scale)

    def touches(p):
        reach = max(p["size"]) / 2
        return not (p["pos"][0] + reach < x0 or p["pos"][0] - reach > x1
                    or p["pos"][2] + reach < z0 or p["pos"][2] - reach > z1)

    visible = [p for p in parts if touches(p) and p["transparency"] < 0.95]
    visible.sort(key=lambda p: p["pos"][1])
    for p in visible:
        px, py, pz = p["pos"]
        sx, _, sz = (v / 2 for v in p["size"])
        yaw = p["rot"][1]
        c, s2 = math.cos(yaw), math.sin(yaw)
        corners = []
        for dx, dz in ((-sx, -sz), (sx, -sz), (sx, sz), (-sx, sz)):
            corners.append(to_px(px + dx * c + dz * s2, pz - dx * s2 + dz * c))
        shade = 0.55 + 0.45 * min(1.0, py / 40)
        draw.polygon(corners, fill=tuple(min(255, int(ch * 255 * shade)) for ch in p["color"]) + (235,))

    for name, x, z, text in labels:
        px, pz = to_px(x, z)
        draw.ellipse([px - 5, pz - 5, px + 5, pz + 5], fill=(255, 0, 0))
        draw.text((px + 8, pz - 6), text, fill=(0, 0, 0))

    img.save(path)
    print(f"{path.name}: plattegrond met {len(visible)} onderdelen")


def find(parts, name):
    for p in parts:
        if p["name"] == name:
            return p
    return None


def main():
    subprocess.run([sys.executable, str(ROOT / "tools" / "bundle.py")], check=True, capture_output=True)
    parts = collect_parts()
    print(f"{len(parts)} onderdelen in de map")
    OUT.mkdir(exist_ok=True)
    render(parts, ((-86, 86), (2, 148)), OUT / "1-plein.png", max_height=30)
    render(parts, ((-70, 140), (-150, -10)), OUT / "2-eerste-zaak.png", max_height=40)
    render(parts, ((-70, 150), (-420, -170)), OUT / "3-fabriek-en-toren.png")
    render(parts, ((-260, 300), (-1300, 200)), OUT / "4-hele-straat.png", size=(2000, 1200))

    marks = []
    for name in ("PenSpawn", "RebirthPad", "PetPad", "Press_kraam", "Sell_kraam", "Spot_kraam",
                 "UpgradePad_capacity", "Board_cash"):
        p = find(parts, name)
        if p:
            marks.append((name, p["pos"][0], p["pos"][2], name))
    plan(parts, ((-160, 180), (-200, 170)), OUT / "5-plattegrond.png", labels=marks)
    plaza_marks = [m for m in marks if -10 < m[2] < 160] + [
        (u, p["pos"][0], p["pos"][2], u.replace("UpgradePad_", ""))
        for u in ("UpgradePad_speed", "UpgradePad_charm", "UpgradePad_auto", "UpgradePad_legs")
        if (p := find(parts, u))
    ]
    plan(parts, ((-120, 120), (0, 160)), OUT / "6-plein-plattegrond.png", size=(1200, 800), labels=plaza_marks)


if __name__ == "__main__":
    main()
