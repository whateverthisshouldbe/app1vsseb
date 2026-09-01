#!/usr/bin/env python3
"""Maakt van het schema een lus, en voegt de inslaanpagina toe.

  1. De app opende altijd op dag 14: dat was de previewwaarde van de
     designtool, niet iets dat meeliep met de tijd. Nu bepaalt een startdatum
     in de browser welke dag het is, en na dag 60 begint hij weer bij 1.
  2. Het boodschappenlijstje toont niet meer alle negen weken, maar deze week
     en een week vooruit.
  3. Nieuwe pagina 'Inslaan' met de lang houdbare producten, hun verpakking en
     wat ze kosten, bereikbaar via een knop rechtsboven op Boodschappen.

Draai dit na tools/ui-tweaks.py.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "<!-- ui-loop -->"

# ── 1. de dag loopt mee met de kalender ──────────────────────────────────
DAG_OUD = "    const dagNr = st.dag ?? (this.props.startDag ?? 14);"
DAG_NIEUW = "    const dagNr = st.dag ?? this.vandaagDag();"

METHODE_ANKER = "  renderVals() {"
METHODE = """  // Het schema is een lus van 60 verschillende dagen. De startdatum staat in
  // de browser, dus de app schuift elke dag een stap op en begint na dag 60
  // opnieuw bij dag 1. Zonder opslag (privevenster) valt hij terug op dag 1.
  vandaagDag() {
    const sleutel = 'voedingsschema.start';
    const nu = new Date();
    nu.setHours(0, 0, 0, 0);
    let start = null;
    try { start = localStorage.getItem(sleutel); } catch (e) { /* geen opslag */ }
    if (!start) {
      start = nu.getFullYear() + '-' + String(nu.getMonth() + 1).padStart(2, '0') +
              '-' + String(nu.getDate()).padStart(2, '0');
      try { localStorage.setItem(sleutel, start); } catch (e) { /* geen opslag */ }
    }
    const verstreken = Math.floor((nu - new Date(start + 'T00:00:00')) / 86400000);
    return ((verstreken % 60) + 60) % 60 + 1;
  }

  renderVals() {"""

# vooruit en terug lopen door de lus in plaats van tegen 1 en 60 aan te botsen
VORIGE_OUD = """      vorigeDag: () => this.setState({ dag: Math.max(1, dagNr - 1), week: null }),
      volgendeDag: () => this.setState({ dag: Math.min(60, dagNr + 1), week: null }),"""
VORIGE_NIEUW = """      vorigeDag: () => this.setState({ dag: dagNr === 1 ? 60 : dagNr - 1, week: null }),
      volgendeDag: () => this.setState({ dag: dagNr === 60 ? 1 : dagNr + 1, week: null }),"""

# ── 2. deze week en een week vooruit ─────────────────────────────────────
PILLS_OUD = """    const weekPills = d.weken.map(w => ({
      label: 'Week ' + w.week, kies: () => this.setState({ week: w.week }),
      bg: w.week === weekNr ? '#201e1d' : '#ebddc5', kleur: w.week === weekNr ? '#f5ead8' : '#474238'
    }));"""
PILLS_NIEUW = """    // Een lus heeft geen week 1 t/m 9 om uit te kiezen: je wilt deze week
    // zien, en hooguit alvast de volgende om op vooruit te kopen.
    const dezeWeek = Math.min(9, Math.ceil(dagNr / 7));
    const volgendeWeek = dezeWeek === 9 ? 1 : dezeWeek + 1;
    const weekPills = [
      { label: 'Deze week', nr: dezeWeek },
      { label: 'Volgende week', nr: volgendeWeek }
    ].map(o => ({
      label: o.label, kies: () => this.setState({ week: o.nr }),
      bg: o.nr === weekNr ? '#201e1d' : '#ebddc5', kleur: o.nr === weekNr ? '#f5ead8' : '#474238'
    }));"""

# de gekozen week mag alleen deze of de volgende zijn, ook na een dagwissel
WEEKNR_OUD = "    const weekNr = st.week ?? Math.ceil(dagNr / 7);"
WEEKNR_NIEUW = """    const nuWeek = Math.min(9, Math.ceil(dagNr / 7));
    const naWeek = nuWeek === 9 ? 1 : nuWeek + 1;
    const weekNr = (st.week === nuWeek || st.week === naWeek) ? st.week : nuWeek;"""

# ── 3. inslaanpagina ─────────────────────────────────────────────────────
KOP_OUD = """            <h2 style="font-family:Caprasimo,system-ui;font-size:28px;margin:0">Boodschappen</h2>"""
KOP_NIEUW = """            <div style="display:flex;align-items:center;gap:12px">
              <h2 style="flex:1;font-family:Caprasimo,system-ui;font-size:28px;margin:0">Boodschappen</h2>
              <button sc-camel-on-click="{{ goInslaan }}" style="flex:none;border:0;background:#ebddc5;color:#8c491a;border-radius:999px;padding:9px 14px;font-size:12px;font-weight:700;cursor:pointer">Inslaan &rsaquo;</button>
            </div>"""

SCHERM_ANKER = "        <!-- ══════ WEEKPLANNER ══════ -->"
SCHERM = """        <!-- ══════ INSLAAN ══════ -->
        <sc-if value="{{ isInslaan }}">
        <div style="padding:var(--top) 22px 20px">
          <button sc-camel-on-click="{{ goBood }}" style="border:0;background:#ebddc5;color:#474238;border-radius:999px;padding:8px 14px;font-size:12.5px;font-weight:700;cursor:pointer">&lsaquo; Boodschappen</button>
          <h2 style="font-family:Caprasimo,system-ui;font-size:28px;margin:16px 0 0">Inslaan</h2>
          <p style="font-size:13px;color:#645c50;margin:6px 0 0;line-height:1.55">Wat lang houdbaar is en dus in een keer kan. Sla je dit in, dan staat het niet meer wekelijks op je lijstje: de app rekent de voorraad af tegen wat je elke week nodig hebt.</p>
          <div style="display:flex;align-items:center;gap:14px;background:#201e1d;color:#f5ead8;border-radius:24px;padding:15px 18px;margin-top:14px">
            <div style="flex:1">
              <div style="font-size:10px;letter-spacing:.09em;text-transform:uppercase;color:#a19786">Alles in een keer · schatting</div>
              <div style="font-family:Caprasimo,system-ui;font-size:26px;margin-top:3px">{{ kastTotaal }}</div>
            </div>
            <div style="text-align:right">
              <div style="font-size:12px;color:#e1d6bf">{{ kastAantal }} producten</div>
              <div style="font-size:11.5px;color:#a19786;margin-top:2px">voor 60 dagen</div>
            </div>
          </div>
          <div style="display:flex;flex-direction:column;gap:8px;margin-top:16px">
            <sc-for list="{{ kast }}" as="k" hint-placeholder-count="8">
              <div style="background:#f9f4ed;border-radius:20px;padding:13px 15px">
                <div style="display:flex;align-items:baseline;gap:10px">
                  <span style="flex:1;font-size:13.5px;font-weight:600">{{ k.naam }}</span>
                  <span style="font-size:13.5px;font-weight:700">{{ k.totaal }}</span>
                </div>
                <div style="font-size:11.5px;color:#645c50;margin-top:3px">{{ k.regel }}</div>
                <div style="font-size:11px;color:#a19786;margin-top:2px">{{ k.winkel }} &middot; {{ k.nodig }} nodig over 60 dagen</div>
              </div>
            </sc-for>
          </div>
        </div>
        </sc-if>

        <!-- ══════ WEEKPLANNER ══════ -->"""

KAST_JS_ANKER = "    const scherm = st.screen;"
KAST_JS = """    const kast = (d.voorraadkast || []).map(r => ({
      naam: r.n, winkel: r.winkel, nodig: r.nodig,
      totaal: this.euro(r.totaal),
      regel: r.aantal + ' ' + r.eh + ' van ' + r.maat + ' · ' + this.euro(r.stuk) + ' per stuk'
    }));
    const kastTotaal = this.euro((d.voorraadkast || []).reduce((a, r) => a + r.totaal, 0));

    const scherm = st.screen;"""

UITVOER_OUD = "      weekPills, rondes, eigenItems, nieuw: st.nieuw,"
UITVOER_NIEUW = """      weekPills, rondes, eigenItems, nieuw: st.nieuw,
      kast, kastTotaal, kastAantal: kast.length,
      isInslaan: scherm === 'inslaan',
      goInslaan: () => this.setState({ screen: 'inslaan' }),"""


def vervang(t, oud, nieuw, wat):
    if oud not in t:
        sys.exit("niet gevonden: %s" % wat)
    return t.replace(oud, nieuw, 1)


def bouw(t):
    t = vervang(t, DAG_OUD, DAG_NIEUW, "dagnummer")
    t = vervang(t, METHODE_ANKER, METHODE, "plek voor vandaagDag()")
    t = vervang(t, VORIGE_OUD, VORIGE_NIEUW, "vorige/volgende dag")
    t = vervang(t, WEEKNR_OUD, WEEKNR_NIEUW, "weeknummer")
    t = vervang(t, PILLS_OUD, PILLS_NIEUW, "weekknoppen")
    t = vervang(t, KOP_OUD, KOP_NIEUW, "kop van Boodschappen")
    t = vervang(t, SCHERM_ANKER, SCHERM, "plek voor de inslaanpagina")
    t = vervang(t, KAST_JS_ANKER, KAST_JS, "plek voor de voorraadlogica")
    t = vervang(t, UITVOER_OUD, UITVOER_NIEUW, "uitvoer van het lijstje")
    return MERK + t


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")
    template = json.loads(m.group(2))
    if MERK in template:
        print("de lus en de inslaanpagina staan er al in")
        return
    INDEX.write_text(
        html[:m.start(2)] + json.dumps(bouw(template)).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("lus en inslaanpagina toegevoegd")


if __name__ == "__main__":
    main()
