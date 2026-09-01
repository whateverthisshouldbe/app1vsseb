#!/usr/bin/env python3
"""Micronutrienten met echte gehaltes in plaats van tien vaste percentages.

De designtool had tien percentages hardgecodeerd in de component. Het
Excel-bestand heeft er negentien, per dag, als verhouding tot de
referentie-inname. Vermenigvuldigd met die referentie geeft dat het gehalte
zelf, en dat is wat hier getoond wordt: het gehalte, het percentage, en
waar de referentie ligt.

Gemiddeld over dezelfde zeven dagen als de macro's erboven.

Draai dit na tools/ui-rondes.py.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "<!-- ui-micros -->"

LOGICA_OUD = """const micros = [
      ['Vitamine D', 34], ['Vitamine A', 280], ['Vitamine C', 690], ['Vitamine B12', 400],
      ['Calcium', 210], ['IJzer', 290], ['Magnesium', 280], ['Zink', 285], ['Kalium', 195], ['Vezel', 118]
    ].map(([naam, p]) => ({ naam, label: p + '%', pct: Math.min(100, p / 2), kleur: p < 100 ? rood : sage }));"""

LOGICA_NIEUW = """// De tab Micronutrienten geeft per dag de verhouding tot de
    // referentie-inname; maal de referentie is dat het gehalte zelf.
    const mi = d.micros || { namen: [], ref: [], perDag: {} };
    const microRijen = laatste.map(x => mi.perDag[x.d]).filter(Boolean);
    const micros = mi.namen.map((kop, i) => {
      const deel = microRijen.length
        ? microRijen.reduce((a, r) => a + (r[i] || 0), 0) / microRijen.length
        : 0;
      const ref = mi.ref[i] || 0;
      const eenheid = (kop.match(/\\(([^)]+)\\)/) || ['', ''])[1];
      const pct = Math.round(deel * 100);
      return {
        naam: kop.replace(/\\s*\\([^)]*\\)/, ''),
        waarde: this.hoeveel(deel * ref) + (eenheid ? ' ' + eenheid : ''),
        doel: 'referentie ' + this.hoeveel(ref) + (eenheid ? ' ' + eenheid : ''),
        label: pct + '%',
        // 300% vult de balk; daarboven zegt het getal het wel
        pct: Math.min(100, pct / 3),
        kleur: pct < 100 ? rood : sage
      };
    });"""

# een getal dat prettig leest: duizendtallen met een punt, komma als decimaal
HELPER_ANKER = "  euro(n) { return '€ ' + n.toFixed(2).replace('.', ','); }"
HELPER = """  euro(n) { return '€ ' + n.toFixed(2).replace('.', ','); }

  hoeveel(n) {
    if (n >= 100) return Math.round(n).toLocaleString('nl-NL');
    const tekst = n >= 10 ? n.toFixed(1) : n.toFixed(2);
    // 80,0 leest slechter dan 80
    return tekst.replace(/\.?0+$/, '').replace('.', ',');
  }"""

# Zonder lus pakte 'de laatste 7 dagen' op dag 1 maar een dag; nu lopen ze
# door dag 1 heen terug de vorige cyclus in.
LAATSTE_OUD = """    const laatste = d.dagen.slice(Math.max(0, dagNr - 7), dagNr);"""
LAATSTE_NIEUW = """    const laatste = Array.from({ length: 7 }, (_, i) =>
      d.dagen[(((dagNr - 7 + i) % 60) + 60) % 60]).filter(Boolean);"""

MARKUP_OUD = """<p style="font-size:12px;color:#82796a;margin:0 0 12px">% van de referentie-inname, gemiddeld over 60 dagen</p>
          <div style="display:flex;flex-direction:column;gap:9px">
            <sc-for list="{{ micros }}" as="m" hint-placeholder-count="6">
              <div style="display:flex;align-items:center;gap:12px">
                <span style="width:82px;flex:none;font-size:12.5px;color:#474238">{{ m.naam }}</span>
                <div style="flex:1;height:9px;border-radius:999px;background:#e1d6bf;overflow:hidden">
                  <div style="height:100%;border-radius:999px;background:{{ m.kleur }};width:{{ m.pct }}%"></div>
                </div>
                <span style="width:46px;text-align:right;font-size:12px;font-weight:700;color:{{ m.kleur }}">{{ m.label }}</span>
              </div>
            </sc-for>
          </div>"""

MARKUP_NIEUW = """<p style="font-size:12px;color:#82796a;margin:0 0 12px">Gemiddeld over de laatste 7 dagen van je schema, met de referentie-inname erbij.</p>
          <div style="display:flex;flex-direction:column;gap:13px">
            <sc-for list="{{ micros }}" as="m" hint-placeholder-count="6">
              <div>
                <div style="display:flex;align-items:baseline;gap:8px;margin-bottom:4px">
                  <span style="flex:1;font-size:12.5px;color:#474238">{{ m.naam }}</span>
                  <span style="font-size:13px;font-weight:700;color:#201e1d">{{ m.waarde }}</span>
                  <span style="width:44px;text-align:right;font-size:12px;font-weight:700;color:{{ m.kleur }}">{{ m.label }}</span>
                </div>
                <div style="height:9px;border-radius:999px;background:#e1d6bf;overflow:hidden">
                  <div style="height:100%;border-radius:999px;background:{{ m.kleur }};width:{{ m.pct }}%"></div>
                </div>
                <div style="font-size:11px;color:#a19786;margin-top:3px">{{ m.doel }}</div>
              </div>
            </sc-for>
          </div>"""


def vervang(t, oud, nieuw, wat):
    if oud not in t:
        sys.exit("niet gevonden: %s" % wat)
    return t.replace(oud, nieuw, 1)


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")
    t = json.loads(m.group(2))
    if MERK in t:
        print("de micronutrienten staan er al in")
        return
    t = vervang(t, HELPER_ANKER, HELPER, "plek voor hoeveel()")
    t = vervang(t, LAATSTE_OUD, LAATSTE_NIEUW, "de laatste zeven dagen")
    t = vervang(t, LOGICA_OUD, LOGICA_NIEUW, "micronutrientenlogica")
    t = vervang(t, MARKUP_OUD, MARKUP_NIEUW, "micronutrientenmarkup")
    INDEX.write_text(
        html[:m.start(2)] + json.dumps(MERK + t).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("micronutrienten tonen nu de gehaltes")


if __name__ == "__main__":
    main()
