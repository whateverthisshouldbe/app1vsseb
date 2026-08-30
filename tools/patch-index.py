#!/usr/bin/env python3
"""Maakt de data-imports in index.html werkend.

De component in de bundle doet import('./schemaData.js'). De bundler draait
die code vanuit een blob:-URL, en relatieve specifiers kunnen daar niet
geresolved worden ("Failed to resolve module specifier"). Deze patch maakt
er absolute URL's van, gebaseerd op document.baseURI, zodat de modules naast
index.html gewoon gevonden worden.

Draai dit opnieuw na elke nieuwe export van de standalone HTML.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MODULES = ("schemaData.js", "winkelData.js")


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")

    template = json.loads(m.group(2))
    patched = template
    for mod in MODULES:
        oud = "import('./%s')" % mod
        nieuw = "import(new URL('%s', document.baseURI).href)" % mod
        if nieuw in patched:
            continue
        if oud not in patched:
            sys.exit("import van %s niet gevonden — is de bundle veranderd?" % mod)
        patched = patched.replace(oud, nieuw)

    if patched == template:
        print("index.html was al gepatcht")
        return

    INDEX.write_text(
        # </script> moet geescaped blijven, anders sluit de script-tag te vroeg
        html[:m.start(2)] + json.dumps(patched).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("index.html gepatcht: %s" % ", ".join(MODULES))


if __name__ == "__main__":
    main()
