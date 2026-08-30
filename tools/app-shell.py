#!/usr/bin/env python3
"""Maakt van de prototype-pagina een echte telefoon-app.

De export van de designtool zet de app in een presentatiepagina: een kop met
uitleg, een iPhone-mockup met nep-statusbalk, en een voettekst. Voor gebruik
op de telefoon moet daar niets van overblijven — alleen het scherm zelf,
schermvullend, met de echte safe-area van het toestel.

Deze patch:
  - haalt de kop, de mockup en de voettekst weg
  - laat de app 100dvh vullen (max 560px breed op een groot scherm)
  - vervangt de vaste 62px bovenmarge (die de nep-statusbalk vrijhield)
    door env(safe-area-inset-top), idem voor de tabbalk onderaan
  - zet de PWA-meta's zodat 'Zet op beginscherm' een echte app geeft

Draai dit na tools/patch-index.py, en opnieuw na elke nieuwe export.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "/* app-shell */"

HEAD = """<link rel="manifest" href="manifest.webmanifest">
<meta name="theme-color" content="#f5ead8" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#2e2b25" media="(prefers-color-scheme: dark)">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="Voedingsschema">
<link rel="apple-touch-icon" href="icon-180.png">
<link rel="icon" href="icon-512.png">
<script>
  // offline beschikbaar maken; faalt stil als de browser geen sw ondersteunt
  if ('serviceWorker' in navigator) {
    addEventListener('load', function () {
      navigator.serviceWorker.register(new URL('sw.js', document.baseURI).href).catch(function () {});
    });
  }
</script>
"""

CSS = """<style>%s
:root {
  /* ruimte voor de echte statusbalk en de home-indicator van het toestel */
  --top: calc(env(safe-area-inset-top, 0px) + 22px);
  --top-knop: calc(env(safe-area-inset-top, 0px) + 18px);
  --bodem: calc(env(safe-area-inset-bottom, 0px) + 12px);
}
html, body { height: 100%%; overscroll-behavior: none; }
body { margin: 0; background: #f5ead8; }
/* geen tekstselectie of dubbeltik-zoom bij het tikken door de app */
body { -webkit-user-select: none; user-select: none; -webkit-tap-highlight-color: transparent; }
#app-shell {
  height: 100dvh; width: 100%%; max-width: 560px; margin: 0 auto;
  background: #f5ead8; overflow: hidden;
  font-family: Figtree, system-ui, sans-serif; color: #201e1d;
}
</style>
"""

# De vaste marges in de export hielden de nep-statusbalk en home-indicator vrij.
MARGES = [
    ('<div style="padding:62px 0 20px">',
     '<div style="padding:var(--top) 0 20px">'),
    ('<div style="padding:62px 22px 20px">',
     '<div style="padding:var(--top) 22px 20px">'),
    ('style="position:absolute;top:58px;left:18px;',
     'style="position:absolute;top:var(--top-knop);left:18px;'),
    ('border-top:1px solid #e1d6bf;padding:10px 18px 30px;',
     'border-top:1px solid #e1d6bf;padding:10px 18px var(--bodem);'),
]


def knip(t, start, eind, wat):
    i = t.find(start)
    if i < 0:
        sys.exit("%s niet gevonden — is de bundle veranderd?" % wat)
    j = t.find(eind, i)
    if j < 0:
        sys.exit("einde van %s niet gevonden" % wat)
    return t[:i] + t[j + len(eind):]


def bouw(t):
    # 1. presentatie-chrome eruit
    t = knip(t, "  <header style=", "</header>", "header")
    t = knip(t, '<p style="max-width:640px;', "</p>", "voettekst")

    # 2. de gecentreerde presentatiepagina wordt de app-shell
    oud = re.search(r'<div style="min-height:100vh;[^"]*">', t)
    if not oud:
        sys.exit("paginawrapper niet gevonden")
    t = t[:oud.start()] + '<div id="app-shell">' + t[oud.end():]

    # 3. de iPhone-mockup eromheen weg, de inhoud blijft
    oud = re.search(r'<x-import component-from-global-scope="IOSDevice"[^>]*>', t)
    if not oud:
        sys.exit("IOSDevice-mockup niet gevonden")
    t = t[:oud.start()] + '<div style="height:100%">' + t[oud.end():]
    t = t.replace("</x-import>", "</div>", 1)

    # 4. echte safe-area in plaats van de vaste mockup-marges
    for oud_s, nieuw_s in MARGES:
        if oud_s not in t and nieuw_s not in t:
            sys.exit("marge niet gevonden: %s" % oud_s[:48])
        t = t.replace(oud_s, nieuw_s)

    # 5. PWA-meta's en app-CSS
    t = t.replace('<meta name="viewport" content="width=device-width, initial-scale=1">',
                  '<meta name="viewport" content="width=device-width, initial-scale=1, '
                  'viewport-fit=cover, maximum-scale=1, user-scalable=no">\n' + HEAD, 1)
    t = t.replace("<body>", "<body>\n" + (CSS % MERK), 1)
    return t


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")

    template = json.loads(m.group(2))
    if MERK in template:
        print("index.html draait al in app-modus")
        return

    INDEX.write_text(
        html[:m.start(2)] + json.dumps(bouw(template)).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("index.html omgezet naar app-modus")


if __name__ == "__main__":
    main()
