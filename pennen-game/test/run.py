#!/usr/bin/env python3
"""Draait de game met een nagemaakte Roblox-API: python3 test/run.py"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LUAU = "/tmp/luaubin/luau"

subprocess.run([sys.executable, str(ROOT / "tools" / "bundle.py")], check=True, capture_output=True)

parts = [
    (ROOT / "test" / "stub.luau").read_text(),
    (ROOT / "dist" / "ServerBundle.server.lua").read_text(),
    (ROOT / "test" / "driver.luau").read_text(),
]
combined = "\n\n".join(parts)
out = ROOT / "test" / ".combined.luau"
out.write_text(combined)

result = subprocess.run([LUAU, str(out)], capture_output=True, text=True)
sys.stdout.write(result.stdout)
sys.stderr.write(result.stderr)
sys.exit(result.returncode)
