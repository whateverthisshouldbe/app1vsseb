#!/usr/bin/env python3
"""Zondagronde en woensdagronde in plaats van houdbaar tegenover vers.

De oude indeling splitste op productsoort: alles houdbaar in de grote inkoop,
alle groente, zuivel en vis in de verse ronde. Daar kun je niet mee koken —
maandag stond je dan zonder groente.

De nieuwe indeling volgt wanneer je iets nodig hebt. Die verdeling zit al in
de data (build-data.py zet per regel een 'ronde'); dit script laat de app
erop groeperen in plaats van op categorie.

Draai dit na tools/ui-loop.py.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "<!-- ui-rondes -->"

RONDES_OUD = """const houdbaar = wk.items.filter(i => !versCats.has(i.cat));
    const vers = wk.items.filter(i => versCats.has(i.cat));
    const telOp = items => items.filter(i => st.bood[bkey(i)]).length + '/' + items.length;
    const rondes = tweeRondes ? [
      { nr: '1', titel: 'Grote inkoop', sub: this.wdVol(dagVan.wd) + ' · dag ' + van + ' · houdbaar + vlees invriezen', teller: telOp(houdbaar), groepen: groepeer(houdbaar), kopBg: '#ebddc5', puntBg: '#82796a', kopKleur: '#201e1d', subKleur: '#645c50' },
      { nr: '2', titel: 'Verse ronde', sub: this.wdVol(dagVers.wd) + ' · dag ' + (van + 3) + ' · groente, fruit, zuivel, vis', teller: telOp(vers), groepen: groepeer(vers), kopBg: '#e1eecc', puntBg: '#728157', kopKleur: '#272e1b', subKleur: '#56633f' }
    ] : [
      { nr: '1', titel: 'Hele week in één keer', sub: this.wdVol(dagVan.wd) + ' · dag ' + van + ' t/m ' + wk.dagen.split('-')[1], teller: telOp(wk.items), groepen: groepeer(wk.items), kopBg: '#ebddc5', puntBg: '#82796a', kopKleur: '#201e1d', subKleur: '#645c50' }
    ];"""

RONDES_NIEUW = """// Alles gaat op zondag mee. Afgevinkte regels tellen niet meer mee in wat
    // er nog te halen is, zodat het bedrag meeloopt terwijl je door de winkel
    // loopt; de teller laat zien hoe ver je bent.
    const nogOpen = items => items.filter(i => !st.bood[bkey(i)]);
    const telOp = items => items.filter(i => st.bood[bkey(i)]).length + '/' + items.length;
    const bedrag = items => this.euro(nogOpen(items).reduce((a, i) => a + this.kosten(i), 0));
    const vlees = wk.items.some(i => /vriezer/.test(i.opm || ''));
    const rondes = [{
      nr: '1', titel: 'Zondag',
      sub: 'de hele week' + (vlees ? ', plus het vlees voor de vriezer' : ''),
      teller: telOp(wk.items), bedrag: bedrag(wk.items), groepen: groepeer(wk.items),
      kopBg: '#ebddc5', puntBg: '#82796a', kopKleur: '#201e1d', subKleur: '#645c50'
    }].filter(r => r.groepen.length);"""

# de opmerking bij een regel komt nu ook uit de regel zelf ('voor 2 weken')
OPM_OUD = """      opm: (pr[i.n] && pr[i.n][3]) ? ' · ' + pr[i.n][3] : '',"""
OPM_NIEUW = """      opm: [(pr[i.n] || [])[3], i.opm].filter(Boolean).map(x => ' · ' + x).join(''),"""

# teksten die nog over de oude indeling gingen
ADVIES_OUD = """      versAdvies: tweeRondes
        ? 'Twee rondes per week houdt alles vers: ' + this.wdVol(dagVan.wd) + ' de grote inkoop, ' + this.wdVol(dagVers.wd) + ' een korte verse ronde voor groente, fruit, zuivel en vis.'
        : 'Alles in één ronde op ' + this.wdVol(dagVan.wd) + '. Vries vlees en vis dezelfde dag in.',
      versKop: tweeRondes ? 'Verse ronde ' + this.wdVol(dagVers.wd) : 'Weeklijst week ' + weekNr,
      versSub: vers.length + ' verse producten · ' + houdbaar.length + ' houdbaar · ' + this.euro(totaal),"""
ADVIES_NIEUW = """      versAdvies: 'Alles in een ronde op zondag: de hele week aan boodschappen, de verse groente op de markt in Zeist, en het vlees van de boer de vriezer in.',
      versKop: 'Boodschappen zondag',
      versSub: nogOpen(wk.items).length + ' van de ' + wk.items.length + ' nog te halen · ' + this.euro(nogTeHalen),"""

# Het weektotaal delen door 7 gaf een misleidend dagbedrag: in de week dat
# je de voorraadkast vult en twee weken vlees haalt, schiet dat omhoog. Het
# gemiddelde over alle 60 dagen zegt wel iets.
PERDAG_OUD = """      perDag: this.euro(totaal / 7),"""
PERDAG_NIEUW = """      perDag: this.euro(d.weken.reduce((a, w2) => a + w2.items.reduce((b, i) => b + this.kosten(i), 0), 0) / 60),"""
PERDAG_LABEL_OUD = """<div style="font-size:11.5px;color:#a19786;margin-top:2px">{{ perDag }} per dag</div>"""
PERDAG_LABEL_NIEUW = """<div style="font-size:11.5px;color:#a19786;margin-top:2px">{{ perDag }} p/d over 60 dagen</div>"""

# het bedrag per ronde in de kop tonen
KOP_OUD = """                  <div style="font-size:12px;font-weight:700;color:{{ r.subKleur }}">{{ r.teller }}</div>"""
KOP_NIEUW = """                  <div style="text-align:right">
                    <div style="font-size:12px;font-weight:700;color:{{ r.kopKleur }}">{{ r.bedrag }}</div>
                    <div style="font-size:11px;color:{{ r.subKleur }};margin-top:1px">{{ r.teller }}</div>
                  </div>"""


# Het subtotaal per winkel telt ook alleen nog wat je nog moet halen.
SUBTOTAAL_OUD = """        subtotaal: this.euro(g[c].reduce((a, i) => a + this.kosten(i), 0)),"""
SUBTOTAAL_NIEUW = """        subtotaal: this.euro(g[c].filter(i => !st.bood[bkey(i)]).reduce((a, i) => a + this.kosten(i), 0)),"""

TOTAAL_OUD = """    const totaal = wk.items.reduce((a, i) => a + this.kosten(i), 0);"""
TOTAAL_NIEUW = """    const totaal = wk.items.reduce((a, i) => a + this.kosten(i), 0);
    const nogTeHalen = wk.items.filter(i => !st.bood[bkey(i)])
      .reduce((a, i) => a + this.kosten(i), 0);"""

WEEKTOTAAL_OUD = """      weekTotaal: this.euro(totaal),"""
WEEKTOTAAL_NIEUW = """      weekTotaal: this.euro(nogTeHalen), weekVolledig: this.euro(totaal),"""

LABEL_OUD = """<div style="font-size:10px;letter-spacing:.09em;text-transform:uppercase;color:#a19786">Wat deze week kost · schatting</div>"""
LABEL_NIEUW = """<div style="font-size:10px;letter-spacing:.09em;text-transform:uppercase;color:#a19786">Nog te halen · schatting</div>"""

BIO_OUD = """<div style="font-size:12px;color:#e1d6bf">{{ bioAandeel }} biologisch</div>"""
BIO_NIEUW = """<div style="font-size:12px;color:#e1d6bf">van {{ weekVolledig }}</div>"""


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
        print("de rondes staan er al in")
        return
    t = vervang(t, RONDES_OUD, RONDES_NIEUW, "rondes")
    t = vervang(t, OPM_OUD, OPM_NIEUW, "opmerking per regel")
    t = vervang(t, ADVIES_OUD, ADVIES_NIEUW, "uitlegteksten")
    t = vervang(t, KOP_OUD, KOP_NIEUW, "kop van een ronde")
    t = vervang(t, PERDAG_OUD, PERDAG_NIEUW, "dagbedrag")
    t = vervang(t, PERDAG_LABEL_OUD, PERDAG_LABEL_NIEUW, "label bij het dagbedrag")
    t = vervang(t, SUBTOTAAL_OUD, SUBTOTAAL_NIEUW, "subtotaal per winkel")
    t = vervang(t, TOTAAL_OUD, TOTAAL_NIEUW, "weektotaal")
    t = vervang(t, WEEKTOTAAL_OUD, WEEKTOTAAL_NIEUW, "uitvoer van het weektotaal")
    t = vervang(t, LABEL_OUD, LABEL_NIEUW, "label boven het bedrag")
    t = vervang(t, BIO_OUD, BIO_NIEUW, "bio-aandeel")
    INDEX.write_text(
        html[:m.start(2)] + json.dumps(MERK + t).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("rondes omgezet naar zondag en woensdag")


if __name__ == "__main__":
    main()
