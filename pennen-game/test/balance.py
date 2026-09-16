#!/usr/bin/env python3
"""Draait de balanssimulatie: python3 test/balance.py"""
import pathlib, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parent.parent
subprocess.run([sys.executable, str(ROOT/'tools/bundle.py')], check=True, capture_output=True)
parts = [(ROOT/'test/stub.luau').read_text(), (ROOT/'dist/ServerBundle.server.lua').read_text(), (ROOT/'test/balance.luau').read_text()]
out = ROOT/'test/.balance.luau'
out.write_text("\n\n".join(parts))
r = subprocess.run(['/tmp/luaubin/luau', str(out)], capture_output=True, text=True)
sys.stdout.write(r.stdout); sys.stderr.write(r.stderr[:2000])
