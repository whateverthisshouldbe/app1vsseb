#!/usr/bin/env python3
"""Plakt de losse modules tot twee bestanden die je zo in Studio kunt plakken.

    python3 tools/bundle.py

Schrijft:
  dist/ServerBundle.server.lua  -> Script in ServerScriptService
  dist/ClientBundle.client.lua  -> LocalScript in StarterPlayer > StarterPlayerScripts
"""
import re
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"

# module-naam -> bestand
MODULES = {
    "Config": SRC / "shared" / "Config.luau",
    "Net": SRC / "shared" / "Net.luau",
    "Data": SRC / "server" / "Data.luau",
    "World": SRC / "server" / "World.luau",
    "Customers": SRC / "server" / "Customers.luau",
    "Passes": SRC / "server" / "Passes.luau",
    "Pets": SRC / "server" / "Pets.luau",
    "Leaderboards": SRC / "server" / "Leaderboards.luau",
    "Game": SRC / "server" / "Game.luau",
}

SERVER_ORDER = ["Config", "Net", "Data", "World", "Customers", "Passes", "Pets", "Leaderboards", "Game"]
CLIENT_ORDER = ["Config", "Net"]

# regels die alleen bestaan om de PenShared-map te vinden: die map is er niet in een bundel
DROP_LINE = re.compile(
    r'^\s*local\s+\w+\s*=\s*game:GetService\("ReplicatedStorage"\):WaitForChild\("PenShared"\)\s*$'
)

REQUIRE_PATTERNS = [
    # require(game:GetService("ReplicatedStorage"):WaitForChild("PenShared"):WaitForChild("X"))
    re.compile(r'require\(\s*game:GetService\("ReplicatedStorage"\):WaitForChild\("PenShared"\):WaitForChild\("(\w+)"\)\s*\)'),
    # require(Shared:WaitForChild("X"))
    re.compile(r'require\(\s*\w+:WaitForChild\("(\w+)"\)\s*\)'),
    # require(script.Parent.X) / require(script.X)
    re.compile(r'require\(\s*script(?:\.Parent)?\.(\w+)\s*\)'),
]


def transform(source: str) -> str:
    lines = [ln for ln in source.splitlines() if not DROP_LINE.match(ln)]
    body = "\n".join(lines)
    for pattern in REQUIRE_PATTERNS:
        body = pattern.sub(lambda m: f"PEN.{m.group(1)}", body)
    leftover = re.search(r"require\(", body)
    if leftover:
        raise SystemExit(f"Onbekende require gevonden, bundel klopt niet:\n  {body[leftover.start():leftover.start()+90]}")
    return body


def wrap(name: str) -> str:
    body = transform(MODULES[name].read_text(encoding="utf-8"))
    indented = "\n".join(("\t" + ln) if ln.strip() else ln for ln in body.splitlines())
    return f"PEN.{name} = (function()\n{indented}\nend)()\n"


def build(order, entry_path: pathlib.Path, header: str) -> str:
    parts = [
        f"-- {header}\n",
        "-- AUTOMATISCH GEGENEREERD door tools/bundle.py - niet met de hand aanpassen.\n",
        "-- Pas de bestanden in src/ aan en draai het script opnieuw.\n\n",
        "local PEN = {}\n\n",
    ]
    for name in order:
        parts.append(wrap(name))
        parts.append("\n")
    parts.append("-- ---- startpunt ----\n")
    parts.append(transform(entry_path.read_text(encoding="utf-8")))
    parts.append("\n")
    return "".join(parts)


def main() -> None:
    DIST.mkdir(exist_ok=True)

    server = build(
        SERVER_ORDER,
        SRC / "server" / "init.server.luau",
        "Sell Me This Pen - SERVER. Plak dit in een Script in ServerScriptService.",
    )
    (DIST / "ServerBundle.server.lua").write_text(server, encoding="utf-8")

    client = build(
        CLIENT_ORDER,
        SRC / "client" / "init.client.luau",
        "Sell Me This Pen - CLIENT. Plak dit in een LocalScript in StarterPlayer > StarterPlayerScripts.",
    )
    (DIST / "ClientBundle.client.lua").write_text(client, encoding="utf-8")

    print(f"geschreven: {DIST / 'ServerBundle.server.lua'}")
    print(f"geschreven: {DIST / 'ClientBundle.client.lua'}")


if __name__ == "__main__":
    main()
