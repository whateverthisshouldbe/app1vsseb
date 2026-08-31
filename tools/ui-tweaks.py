#!/usr/bin/env python3
"""Aanpassingen aan de schermen die de designtool niet kent.

  1. 'Dag 14 van 60' wordt 'Dag 14' — het schema is een lus van 60
     verschillende dagen, geen aftelling naar een eind. De voortgangsbalk en
     'nog N dagen' vertellen datzelfde verhaal en gaan mee weg.
  2. Onder 'Vandaag eten' staan de maaltijden onder elkaar in plaats van in
     een horizontale carrousel; de dagknoppen worden een rij die past.
  3. De supplementen staan bij de dag zelf in plaats van op Voortgang.
  4. Op Voortgang vervallen het vitamine-D-blok en de supplementenlijst.
  5. Het boodschappenlijstje toont wat de week kost in plaats van een budget.

Draai dit na tools/app-shell.py.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "<!-- ui-tweaks -->"

# ── 1. kop zonder aftelling ──────────────────────────────────────────────
KOP_OUD = """<h2 style="font-family:Caprasimo,system-ui;font-size:30px;line-height:1.06;margin:4px 0 0;text-transform:uppercase;letter-spacing:-.01em">Dag {{ dagNr }}<br>van 60</h2>"""
KOP_NIEUW = """<h2 style="font-family:Caprasimo,system-ui;font-size:30px;line-height:1.06;margin:4px 0 0;text-transform:uppercase;letter-spacing:-.01em">Dag {{ dagNr }}</h2>"""

BALK_OUD = """<div style="display:flex;flex-direction:column;gap:7px">
              <div style="height:9px;border-radius:999px;background:#e1d6bf;overflow:hidden">
                <div style="height:100%;border-radius:999px;background:#c67139;width:{{ pct }}%"></div>
              </div>
              <div style="display:flex;justify-content:space-between;font-size:12px;color:#82796a">
                <span>{{ weekLabel }} · {{ dagLabel }}</span>
                <span>nog {{ resterend }} dagen</span>
              </div>
            </div>"""
BALK_NIEUW = """<div style="font-size:12px;color:#82796a">{{ weekLabel }} · {{ dagLabel }} · {{ trainingLabel }}</div>"""

# ── 2. dagen als passende rij, maaltijden onder elkaar ───────────────────
LIJST_NIEUW = """<div style="display:flex;gap:5px;padding:0 22px 14px">
            <sc-for list="{{ rail }}" as="r" hint-placeholder-count="7">
              <button sc-camel-on-click="{{ r.kies }}" style="flex:1;border:0;background:{{ r.bg }};color:{{ r.kleur }};font-size:11px;font-weight:700;height:38px;border-radius:14px;cursor:pointer;padding:0">{{ r.wd }}</button>
            </sc-for>
          </div>

          <div style="display:flex;flex-direction:column;gap:12px;padding:0 22px">
            <sc-for list="{{ kaarten }}" as="m" hint-placeholder-count="6">
              <button sc-camel-on-click="{{ m.open }}" style="width:100%;height:158px;border-radius:26px;border:0;padding:0;position:relative;overflow:hidden;cursor:pointer;background:#dcd3c4;display:block">
                <div style="position:absolute;inset:0 0 74px 0">
                  <image-slot id="{{ m.slot }}" shape="rect" placeholder="{{ m.foto }}"></image-slot>
                </div>
                <div style="position:absolute;left:0;right:0;bottom:0;height:74px;background:#2e2b25"></div>
                <div style="position:absolute;left:0;right:0;top:0;bottom:74px;background:linear-gradient(180deg,rgba(32,30,29,.18) 0%,rgba(32,30,29,0) 45%,rgba(46,43,37,.85) 100%);pointer-events:none"></div>
                <div style="position:absolute;top:12px;left:12px;display:flex;gap:6px;pointer-events:none">
                  <span style="font-size:10px;font-weight:700;padding:5px 9px;border-radius:999px;background:rgba(245,234,216,.92);color:#201e1d">{{ m.tag }}</span>
                </div>
                <div style="position:absolute;left:14px;right:14px;bottom:13px;pointer-events:none;text-align:left">
                  <div style="font-family:Caprasimo,system-ui;font-size:15px;line-height:1.15;color:#f9f4ed">{{ m.titel }}</div>
                  <div style="font-size:11px;color:rgba(249,244,237,.78);margin-top:4px">{{ m.meta }}</div>
                </div>
              </button>
            </sc-for>
          </div>"""

# ── 3/4. supplementen van Voortgang naar de dag ──────────────────────────
SUPP_KOP = """<h3 style="font-family:Caprasimo,system-ui;font-size:19px;margin:26px 0 12px">Supplementen vandaag</h3>"""
SUPP_BLOK = """<div style="display:flex;flex-direction:column;gap:8px">
            <sc-for list="{{ supps }}" as="s" hint-placeholder-count="5">
              <button sc-camel-on-click="{{ s.vink }}" style="display:flex;align-items:center;gap:12px;background:#f9f4ed;border:0;border-radius:20px;padding:13px 15px;cursor:pointer;text-align:left;width:100%">
                <span style="width:26px;height:26px;border-radius:999px;border:2px solid {{ s.rand }};background:{{ s.vulling }};flex:none;display:flex;align-items:center;justify-content:center;color:#f9f4ed;font-size:13px">{{ s.merk }}</span>
                <span style="flex:1">
                  <span style="display:block;font-size:13.5px;font-weight:600">{{ s.naam }}</span>
                  <span style="display:block;font-size:11.5px;color:#82796a;margin-top:1px">{{ s.dosis }} · {{ s.wanneer }}</span>
                </span>
              </button>
            </sc-for>
          </div>"""

VITD_BLOK = """<div style="background:#ffe1d0;border-radius:20px;padding:14px 16px;margin-top:14px">
            <div style="font-size:13px;font-weight:700;color:#643312">Vitamine D blijft achter</div>
            <div style="font-size:12.5px;color:#8c491a;line-height:1.5;margin-top:3px">53 van de 60 dagen kom je onder de referentie-inname. Neem D3 bij het ontbijt, met pindakaas of amandelen erbij.</div>
          </div>"""

# op de dag krijgt elk supplement zijn moment als onderregel
SUPP_OP_DAG = """
          <h3 style="font-family:Caprasimo,system-ui;font-size:19px;margin:26px 22px 12px">Supplementen vandaag</h3>
          <div style="display:flex;flex-direction:column;gap:8px;padding:0 22px">
            <sc-for list="{{ supps }}" as="s" hint-placeholder-count="5">
              <button sc-camel-on-click="{{ s.vink }}" style="display:flex;align-items:center;gap:12px;background:#f9f4ed;border:0;border-radius:20px;padding:13px 15px;cursor:pointer;text-align:left;width:100%">
                <span style="width:26px;height:26px;border-radius:999px;border:2px solid {{ s.rand }};background:{{ s.vulling }};flex:none;display:flex;align-items:center;justify-content:center;color:#f9f4ed;font-size:13px">{{ s.merk }}</span>
                <span style="flex:1">
                  <span style="display:block;font-size:13.5px;font-weight:600">{{ s.naam }}</span>
                  <span style="display:block;font-size:11.5px;color:#82796a;margin-top:1px">{{ s.dosis }}</span>
                </span>
                <span style="font-size:11px;font-weight:700;color:#8c491a;background:#ebddc5;border-radius:999px;padding:5px 10px;flex:none">{{ s.moment }}</span>
              </button>
            </sc-for>
          </div>
"""

BUDGET_OUD = """<div style="font-size:10px;letter-spacing:.09em;text-transform:uppercase;color:#a19786">Weekbudget · richtprijs</div>"""
BUDGET_NIEUW = """<div style="font-size:10px;letter-spacing:.09em;text-transform:uppercase;color:#a19786">Wat deze week kost · schatting</div>"""

# ── logica ───────────────────────────────────────────────────────────────
# De koppen in het lijstje zijn nu Upfront / Vlees / Groentes / Overig.
VOLGORDE_OUD = """const volgorde = ['Hanos', 'Ekoplaza', 'Slager', 'Markt', 'Bakker', 'Bakkerij', 'Supermarkt', 'Online'];"""
VOLGORDE_NIEUW = """const volgorde = ['Upfront', 'Vlees', 'Groentes', 'Overig'];"""

# Alleen wat elke dag moet: D-Bloat is 'niet dagelijks' en heeft geen moment.
SUPPS_OUD = """const supps = d.supplementen.slice(0, 6).map((s, ix) => ({
      naam: s.naam, dosis: s.dosis, wanneer: s.wanneer,"""
SUPPS_NIEUW = """const supps = d.supplementen.map((s, ix) => ({ ...s, ix })).filter(s => s.moment).map((s) => ({
      naam: s.naam, dosis: s.dosis, wanneer: s.wanneer, moment: s.moment, ix: s.ix,"""
SUPPS_VINK_OUD = """      merk: st.supp[ix] ? '✓' : '', rand: st.supp[ix] ? sage : '#dcd3c4', vulling: st.supp[ix] ? sage : 'transparent',
      vink: () => this.setState({ supp: { ...st.supp, [ix]: !st.supp[ix] } })
    }));"""
SUPPS_VINK_NIEUW = """      merk: st.supp[s.ix] ? '\u2713' : '', rand: st.supp[s.ix] ? sage : '#dcd3c4', vulling: st.supp[s.ix] ? sage : 'transparent',
      vink: () => this.setState({ supp: { ...st.supp, [s.ix]: !st.supp[s.ix] } })
    }));"""


# ── bereiding en foto's in het maaltijdscherm ────────────────────────────
KNOP_ANKER = """
          <div style="position:sticky;bottom:0;padding:14px 22px 34px;"""

BEREIDING = """
            <div style="display:flex;align-items:baseline;justify-content:space-between;margin:26px 0 12px">
              <h3 style="font-family:Caprasimo,system-ui;font-size:18px;margin:0;color:#f9f4ed">Bereiding</h3>
              <span style="font-size:12px;color:#a19786">{{ stapTeller }}</span>
            </div>
            <div style="display:flex;flex-direction:column;gap:9px">
              <sc-for list="{{ mealStappen }}" as="s" hint-placeholder-count="5">
                <div style="display:flex;gap:12px;background:#3d3830;border-radius:20px;padding:13px 15px">
                  <span style="width:24px;height:24px;border-radius:999px;background:#c67139;color:#f9f4ed;font-size:12px;font-weight:700;flex:none;display:flex;align-items:center;justify-content:center">{{ s.nr }}</span>
                  <span style="flex:1;font-size:13.5px;line-height:1.5;color:#e1d6bf">{{ s.tekst }}</span>
                </div>
              </sc-for>
            </div>
          </div>
"""

# image-slot toont src als er een foto klaarstaat, anders de placeholder
FOTO_MEAL_OUD = """<image-slot id="{{ mealSlot }}" shape="rect" placeholder="Foto van dit gerecht"></image-slot>"""
FOTO_MEAL_NIEUW = """<image-slot id="{{ mealSlot }}" shape="rect" src="{{ mealFoto }}" placeholder="Foto van dit gerecht"></image-slot>"""
FOTO_KAART_OUD = """<image-slot id="{{ m.slot }}" shape="rect" placeholder="{{ m.foto }}"></image-slot>"""
FOTO_KAART_NIEUW = """<image-slot id="{{ m.slot }}" shape="rect" src="{{ m.fotoSrc }}" placeholder="{{ m.foto }}"></image-slot>"""

KAART_JS_OUD = """      slot: 'ml-' + this.slug(b.wat), foto: 'Foto ' + b.blok.toLowerCase(),"""
KAART_JS_NIEUW = """      slot: 'ml-' + this.slug(b.wat), foto: 'Foto ' + b.blok.toLowerCase(),
      fotoSrc: (rid(b) && d.recept[rid(b)].foto) || '',"""

STAPPEN_JS_OUD = """    const mealAangevinkt = meal ? !!st.vink[dagNr + meal.blok] : false;"""
STAPPEN_JS_NIEUW = """    const mealStappen = (rec && rec.stappen ? rec.stappen : []).map((tekst, i) => ({ nr: i + 1, tekst }));
    const mealAangevinkt = meal ? !!st.vink[dagNr + meal.blok] : false;"""

UITVOER_OUD = """      mealIng, ingTeller: mealIng.filter(i => i.merk).length + ' / ' + mealIng.length,"""
UITVOER_NIEUW = """      mealIng, ingTeller: mealIng.filter(i => i.merk).length + ' / ' + mealIng.length,
      mealStappen, stapTeller: mealStappen.length + ' stappen',
      mealFoto: (rec && rec.foto) || '',"""


def vervang(t, oud, nieuw, wat):
    if oud not in t:
        sys.exit("niet gevonden: %s" % wat)
    return t.replace(oud, nieuw, 1)


def bouw(t):
    t = vervang(t, KOP_OUD, KOP_NIEUW, "dagkop")
    t = vervang(t, BALK_OUD, BALK_NIEUW, "voortgangsbalk")
    t = vervang(t, BUDGET_OUD, BUDGET_NIEUW, "budgetlabel")
    t = vervang(t, VOLGORDE_OUD, VOLGORDE_NIEUW, "winkelvolgorde")
    t = vervang(t, SUPPS_OUD, SUPPS_NIEUW, "supplementenlijst in de logica")
    t = vervang(t, SUPPS_VINK_OUD, SUPPS_VINK_NIEUW, "supplement-vinkjes")

    # maaltijdenlijst: van de rail tot en met het einde van de kaarten
    start = t.find('<div style="display:flex;gap:12px;padding:0 22px 4px;overflow-x:auto;align-items:stretch">')
    if start < 0:
        sys.exit("maaltijdcarrousel niet gevonden")
    eind = t.find("</sc-for>\n          </div>", start)
    if eind < 0:
        sys.exit("einde van de carrousel niet gevonden")
    eind += len("</sc-for>\n          </div>")
    t = t[:start] + LIJST_NIEUW + t[eind:]

    # supplementen en het vitamine-D-blok van Voortgang af
    t = vervang(t, VITD_BLOK, "", "vitamine-D-blok")
    t = vervang(t, SUPP_KOP, "", "supplementenkop")
    t = vervang(t, SUPP_BLOK, "", "supplementenlijst")

    # en op de dag erbij, direct na de maaltijden
    t = t.replace(LIJST_NIEUW, LIJST_NIEUW + "\n" + SUPP_OP_DAG, 1)

    # bereiding onder de ingredienten, boven de afvinkknop
    if KNOP_ANKER not in t:
        sys.exit("afvinkknop niet gevonden")
    t = t.replace("          </div>\n" + KNOP_ANKER, BEREIDING + KNOP_ANKER, 1)

    t = vervang(t, FOTO_MEAL_OUD, FOTO_MEAL_NIEUW, "foto in het maaltijdscherm")
    t = vervang(t, FOTO_KAART_OUD, FOTO_KAART_NIEUW, "foto op de kaart")
    t = vervang(t, KAART_JS_OUD, KAART_JS_NIEUW, "kaartlogica")
    t = vervang(t, STAPPEN_JS_OUD, STAPPEN_JS_NIEUW, "stappenlogica")
    t = vervang(t, UITVOER_OUD, UITVOER_NIEUW, "uitvoer van het maaltijdscherm")
    return MERK + t


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")

    template = json.loads(m.group(2))
    if MERK in template:
        print("de aanpassingen staan er al in")
        return

    INDEX.write_text(
        html[:m.start(2)] + json.dumps(bouw(template)).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("schermen aangepast")


if __name__ == "__main__":
    main()
