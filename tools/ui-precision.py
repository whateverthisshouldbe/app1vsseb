#!/usr/bin/env python3
"""Dagelijks bijhouden: afvinken, wegen, en het Precision-scherm.

Wat dit toevoegt:
  1. Opslag in localStorage, zodat afvinken, gewogen grammen en je
     gewichtshistorie een herstart overleven.
  2. De dagrail rolt mee: hij begint bij de eerste dag die nog niet helemaal
     afgevinkt is, en schuift door zodra een dag af is.
  3. Macro's en micronutrienten gaan per dag en tellen op wat je hebt
     afgevinkt, met de gewichten die je zelf invult.
  4. De tabs Week en Lijstje wisselen van plek; Week heet nu Precision en
     staat in het midden.
  5. Precision: per gerecht de grammen invullen, met een ringdiagram van hoe
     ver je die dag bent.
  6. Profiel: lengte en gewicht invullen, een grafiek van je gewicht en de
     BMI eronder.

Draai dit na tools/ui-micros.py.
"""
import json
import re
import sys
from pathlib import Path

INDEX = Path(__file__).resolve().parent.parent / "index.html"
MERK = "<!-- ui-precision -->"

# ── 1. opslag en dagsleutels ─────────────────────────────────────────────
VANDAAG_OUD = """  vandaagDag() {
    const sleutel = 'voedingsschema.start';"""
VANDAAG_NIEUW = """  vandaag() {
    const sleutel = 'voedingsschema.start';"""

CYCLUS_OUD = """    const verstreken = Math.floor((nu - new Date(start + 'T00:00:00')) / 86400000);
    return ((verstreken % 60) + 60) % 60 + 1;
  }"""
CYCLUS_NIEUW = r"""    const verstreken = Math.floor((nu - new Date(start + 'T00:00:00')) / 86400000);
    return { dag: ((verstreken % 60) + 60) % 60 + 1, cyclus: Math.floor(verstreken / 60) };
  }

  vandaagDag() { return this.vandaag().dag; }

  // ── opslag ────────────────────────────────────────────────────────────
  // Afvinken, wegen en de gewichtshistorie moeten een herstart overleven,
  // dus die gaan naar localStorage in plaats van alleen naar het geheugen.
  lees(sleutel, terugval) {
    try {
      const t = localStorage.getItem('voedingsschema.' + sleutel);
      return t ? JSON.parse(t) : terugval;
    } catch (e) { return terugval; }
  }

  bewaar(sleutel, waarde) {
    try {
      localStorage.setItem('voedingsschema.' + sleutel, JSON.stringify(waarde));
    } catch (e) { /* geen opslag beschikbaar */ }
    this.setState({ [sleutel]: waarde });
  }

  // Sleutel per dag in de lus. Het cyclusnummer hoort erbij: na 60 dagen
  // begint een nieuwe ronde met een schone lei.
  vk(dagNr, blok) { return this.vandaag().cyclus + '-' + dagNr + '|' + blok; }

  blokkenVan(dag) {
    return (dag.blokken || []).filter(
      b => b.blok !== 'Aanvulblok' && b.wat && b.wat !== '-');
  }

  dagKlaar(dagNr) {
    const d = this.state.d;
    if (!d) return false;
    const dag = d.dagen[(((dagNr - 1) % 60) + 60) % 60];
    if (!dag) return false;
    const bl = this.blokkenVan(dag);
    return bl.length > 0 && bl.every(b => this.state.vink[this.vk(dagNr, b.blok)]);
  }

  getal(v) { return parseFloat(String(v == null ? '' : v).replace(',', '.')) || 0; }"""

STATE_OUD = """  state = { d: null, screen: 'home', dag: null, meal: null, vorig: 'home', vink: {}, ing: {}, week: null, bood: {}, eigen: [], nieuw: '', supp: {} };"""
STATE_NIEUW = """  state = { d: null, screen: 'home', dag: null, meal: null, vorig: 'home', vink: {}, ing: {}, week: null, bood: {}, eigen: [], nieuw: '', supp: {},
    gram: {}, profiel: { lengte: '', gewichten: [] }, nieuwGewicht: '', precisieBlok: null };"""

MOUNT_OUD = """      .then(([m, w]) => this.setState({ d: m, w }));"""
MOUNT_NIEUW = """      .then(([m, w]) => this.setState({
        d: m, w,
        vink: this.lees('vink', {}),
        gram: this.lees('gram', {}),
        profiel: this.lees('profiel', { lengte: '', gewichten: [] })
      }));"""

# ── 2. de rail rolt mee met wat je hebt afgevinkt ────────────────────────
DAGNR_OUD = """    const dagNr = st.dag ?? this.vandaagDag();"""
DAGNR_NIEUW = """    // De rail begint bij de eerste dag die nog niet helemaal is afgevinkt.
    // Is vandaag ook al af, dan schuift hij een dag door: heb je maandag
    // gehad, dan staat dinsdag links en de maandag erna rechts.
    const vandaagNr = this.vandaagDag();
    let railStart = vandaagNr;
    for (let k = 6; k >= 1; k--) {
      const n = vandaagNr - k;
      if (n >= 1 && !this.dagKlaar(n)) { railStart = n; break; }
    }
    if (railStart === vandaagNr && this.dagKlaar(vandaagNr)) railStart = vandaagNr + 1;
    const dagNr = st.dag ?? ((((railStart - 1) % 60) + 60) % 60 + 1);"""

RAIL_OUD = """    const rail = d.dagen.slice(weekStart - 1, weekStart + 6).map(x => ({
      wd: x.wd, kies: () => this.setState({ dag: x.d }),
      bg: x.d === dagNr ? acc : 'transparent',
      kleur: x.d === dagNr ? '#f9f4ed' : '#82796a'
    }));"""
RAIL_NIEUW = """    const rail = Array.from({ length: 7 }, (_, i) =>
      d.dagen[(((railStart - 1 + i) % 60) + 60) % 60]).filter(Boolean).map(x => ({
        wd: x.wd, kies: () => this.setState({ dag: x.d }),
        bg: x.d === dagNr ? acc : (this.dagKlaar(x.d) ? '#dcd3c4' : 'transparent'),
        kleur: x.d === dagNr ? '#f9f4ed' : (this.dagKlaar(x.d) ? '#8a8175' : '#82796a')
      }));"""

# ── 3. afvinken bewaren, en optellen wat je gegeten hebt ─────────────────
VINKBLOK_OUD = """    const vinkBlok = (b) => () => this.setState({ vink: { ...st.vink, [dagNr + b.blok]: !st.vink[dagNr + b.blok] } });"""
VINKBLOK_NIEUW = """    const vinkBlok = (b) => () => this.bewaar('vink',
      { ...st.vink, [this.vk(dagNr, b.blok)]: !st.vink[this.vk(dagNr, b.blok)] });"""

BLOKVINK_OUD = """      merk: st.vink[dagNr + b.blok] ? '✓' : '',
      rand: st.vink[dagNr + b.blok] ? sage : '#dcd3c4',
      vulling: st.vink[dagNr + b.blok] ? sage : 'transparent'"""
BLOKVINK_NIEUW = """      merk: st.vink[this.vk(dagNr, b.blok)] ? '✓' : '',
      rand: st.vink[this.vk(dagNr, b.blok)] ? sage : '#dcd3c4',
      vulling: st.vink[this.vk(dagNr, b.blok)] ? sage : 'transparent'"""

MEALVINK_OUD = """    const mealAangevinkt = meal ? !!st.vink[dagNr + meal.blok] : false;"""
MEALVINK_NIEUW = """    const mealAangevinkt = meal ? !!st.vink[this.vk(dagNr, meal.blok)] : false;"""

MEALAF_OUD = """      mealAf: () => meal && this.setState({ vink: { ...st.vink, [dagNr + meal.blok]: !st.vink[dagNr + meal.blok] } }),"""
MEALAF_NIEUW = """      mealAf: () => meal && this.bewaar('vink',
        { ...st.vink, [this.vk(dagNr, meal.blok)]: !st.vink[this.vk(dagNr, meal.blok)] }),"""

# de macro's van een blok, geschaald naar de grammen die je zelf invult
GEGETEN_ANKER = """    const kaarten = blokLijst.map(b => ({"""
GEGETEN = """    // ── wat je vandaag echt gegeten hebt ────────────────────────────────
    // Vul je in Precision een ander gewicht in, dan schalen de macro's van
    // dat ingredient mee. Zonder invoer telt het recept zoals het bedoeld is.
    const gramSleutel = (b, naam) => this.vk(dagNr, b.blok) + '#' + naam;
    const blokMacro = (b) => {
      const r = rid(b) ? d.recept[rid(b)] : null;
      if (!r || !r.ing.length) {
        return { kcal: b.kcal || 0, e: b.e || 0, v: b.v || 0, k: b.k || 0 };
      }
      return r.ing.reduce((a, i) => {
        const ingevoerd = st.gram[gramSleutel(b, i.n)];
        const f = (ingevoerd !== undefined && ingevoerd !== '' && i.g)
          ? this.getal(ingevoerd) / i.g : 1;
        return {
          kcal: a.kcal + (i.kcal || 0) * f, e: a.e + (i.e || 0) * f,
          v: a.v + (i.v || 0) * f, k: a.k + (i.k || 0) * f
        };
      }, { kcal: 0, e: 0, v: 0, k: 0 });
    };
    const optellen = lijst => lijst.reduce((a, b) => {
      const m = blokMacro(b);
      return { kcal: a.kcal + m.kcal, e: a.e + m.e, v: a.v + m.v, k: a.k + m.k };
    }, { kcal: 0, e: 0, v: 0, k: 0 });
    const gegeten = optellen(blokLijst.filter(b => st.vink[this.vk(dagNr, b.blok)]));
    const gepland = optellen(blokLijst);
    const doelen = { kcal: 4050, e: 180, v: 110, k: 580 };

    const kaarten = blokLijst.map(b => ({"""

# ── 4. macro's en micro's per dag ────────────────────────────────────────
PROG_OUD = """    const laatste = Array.from({ length: 7 }, (_, i) =>
      d.dagen[(((dagNr - 7 + i) % 60) + 60) % 60]).filter(Boolean);
    const gem = f => laatste.reduce((a, b) => a + b[f], 0) / (laatste.length || 1);
    const progMacros = [
      { naam: 'Energie', waarde: Math.round(gem('kcal')) + ' kcal', doel: '4.050', pct: Math.min(100, gem('kcal') / 4050 * 100), kleur: acc },
      { naam: 'Eiwit', waarde: Math.round(gem('e')) + ' g', doel: '180 g min.', pct: Math.min(100, gem('e') / 207 * 100), kleur: sage },
      { naam: 'Vet', waarde: Math.round(gem('v')) + ' g', doel: '110 g', pct: Math.min(100, gem('v') / 110 * 100), kleur: '#8fa073' },
      { naam: 'Koolhydraten', waarde: Math.round(gem('k')) + ' g', doel: '580 g', pct: Math.min(100, gem('k') / 580 * 100), kleur: '#f6a06b' }
    ];"""
PROG_NIEUW = """    // Alleen vandaag, en alleen wat is afgevinkt: morgen begint bij nul.
    const progMacros = [
      { naam: 'Energie', waarde: Math.round(gegeten.kcal) + ' kcal', doel: 'van 4.050', pct: Math.min(100, gegeten.kcal / doelen.kcal * 100), kleur: acc },
      { naam: 'Eiwit', waarde: Math.round(gegeten.e) + ' g', doel: 'van 180 g', pct: Math.min(100, gegeten.e / doelen.e * 100), kleur: sage },
      { naam: 'Vet', waarde: Math.round(gegeten.v) + ' g', doel: 'van 110 g', pct: Math.min(100, gegeten.v / doelen.v * 100), kleur: '#8fa073' },
      { naam: 'Koolhydraten', waarde: Math.round(gegeten.k) + ' g', doel: 'van 580 g', pct: Math.min(100, gegeten.k / doelen.k * 100), kleur: '#f6a06b' }
    ];"""

MICRO_OUD = """    const microRijen = laatste.map(x => mi.perDag[x.d]).filter(Boolean);"""
MICRO_NIEUW = """    // De Excel geeft micronutrienten alleen per hele dag, niet per
    // ingredient. Wat je hebt afgevinkt schaalt daarom mee met het deel van
    // de dag dat je op hebt: een schatting, geen meting.
    const deelOp = gepland.kcal > 0 ? Math.min(1, gegeten.kcal / gepland.kcal) : 0;
    const microRijen = mi.perDag[dagNr]
      ? [mi.perDag[dagNr].map(v => v * deelOp)] : [];"""

MICRO_TEKST_OUD = """Gemiddeld over de laatste 7 dagen van je schema, met de referentie-inname en de bovengrens erbij. Groen is genoeg; rood is te weinig of juist te veel."""
MICRO_TEKST_NIEUW = """Wat je vandaag hebt afgevinkt, met de referentie-inname en de bovengrens erbij. Groen is genoeg, rood te weinig of juist te veel. Geschat: het schema geeft micronutrienten per dag, niet per ingredient, dus dit schaalt mee met hoeveel van de dag je op hebt."""

MACRO_TEKST_OUD = """gemiddeld over de laatste 7 dagen van je schema"""
MACRO_TEKST_NIEUW = """vandaag, opgeteld uit wat je hebt afgevinkt"""

MACRO_KOP_OUD = """<p style="font-size:13px;color:#645c50;margin:6px 0 0">Gemiddeld over de laatste 7 dagen van je schema</p>"""
MACRO_KOP_NIEUW = """<p style="font-size:13px;color:#645c50;margin:6px 0 0">Vandaag, opgeteld uit wat je hebt afgevinkt. Morgen begint weer bij nul.</p>"""

# ── 5. Precision: het gerecht wegen ──────────────────────────────────────
PRECISION_SCHERM = """        <!-- ══════ PRECISION ══════ -->
        <sc-if value="{{ isPrecision }}">
        <div style="padding:var(--top) 22px 20px">
          <h2 style="font-family:Caprasimo,system-ui;font-size:28px;margin:0">Precision</h2>
          <p style="font-size:13px;color:#645c50;margin:6px 0 0;line-height:1.55">Vul in wat er echt op de weegschaal lag. Vink je de maaltijd af, dan telt dat gewicht mee in je dag.</p>

          <div style="display:flex;align-items:center;gap:16px;background:#201e1d;border-radius:26px;padding:18px;margin-top:16px">
            <div style="width:104px;height:104px;border-radius:999px;flex:none;background:conic-gradient({{ ringKleur }} {{ ringGraden }}deg, #3d3830 0);display:flex;align-items:center;justify-content:center">
              <div style="width:78px;height:78px;border-radius:999px;background:#201e1d;display:flex;flex-direction:column;align-items:center;justify-content:center">
                <span style="font-family:Caprasimo,system-ui;font-size:20px;color:#f9f4ed">{{ ringPct }}%</span>
                <span style="font-size:9.5px;color:#a19786">van 4.050</span>
              </div>
            </div>
            <div style="flex:1;display:flex;flex-direction:column;gap:7px">
              <sc-for list="{{ ringRijen }}" as="r" hint-placeholder-count="4">
                <div>
                  <div style="display:flex;align-items:baseline;gap:6px">
                    <span style="flex:1;font-size:11.5px;color:#a19786">{{ r.naam }}</span>
                    <span style="font-size:11.5px;font-weight:700;color:#f9f4ed">{{ r.waarde }}</span>
                  </div>
                  <div style="height:6px;border-radius:999px;background:#3d3830;overflow:hidden;margin-top:3px">
                    <div style="height:100%;border-radius:999px;background:{{ r.kleur }};width:{{ r.pct }}%"></div>
                  </div>
                </div>
              </sc-for>
            </div>
          </div>

          <div style="display:flex;gap:7px;overflow-x:auto;padding:16px 0 4px">
            <sc-for list="{{ precisieKnoppen }}" as="p" hint-placeholder-count="5">
              <button sc-camel-on-click="{{ p.kies }}" style="flex:none;border:0;border-radius:999px;padding:9px 14px;font-size:12px;font-weight:700;cursor:pointer;background:{{ p.bg }};color:{{ p.kleur }}">{{ p.naam }}</button>
            </sc-for>
          </div>

          <sc-if value="{{ heeftPrecisie }}">
          <div style="background:#f9f4ed;border-radius:26px;padding:16px 18px;margin-top:8px">
            <div style="display:flex;align-items:baseline;gap:10px">
              <span style="flex:1;font-family:Caprasimo,system-ui;font-size:17px;line-height:1.2">{{ precisieTitel }}</span>
              <span style="font-size:12.5px;font-weight:700;color:#8c491a">{{ precisieKcal }}</span>
            </div>
            <div style="font-size:11.5px;color:#82796a;margin-top:3px">{{ precisieSub }}</div>
            <div style="display:flex;flex-direction:column;gap:7px;margin-top:14px">
              <sc-for list="{{ precisieIng }}" as="i" hint-placeholder-count="5">
                <div style="display:flex;align-items:center;gap:10px">
                  <span style="flex:1;font-size:13px;min-width:0">{{ i.naam }}</span>
                  <span style="font-size:11px;color:#a19786">recept {{ i.recept }}</span>
                  <input value="{{ i.waarde }}" sc-camel-on-change="{{ i.typ }}" type="number" inputmode="decimal" placeholder="{{ i.recept }}" style="width:74px;border:1px solid #dcd3c4;background:#fff;border-radius:999px;padding:8px 10px;font-size:13px;font-family:inherit;text-align:right"></input>
                  <span style="font-size:12px;color:#82796a;width:14px">g</span>
                </div>
              </sc-for>
            </div>
            <button sc-camel-on-click="{{ precisieHerstel }}" style="margin-top:14px;border:0;background:#ebddc5;color:#474238;border-radius:999px;padding:9px 15px;font-size:12.5px;font-weight:700;cursor:pointer">Terug naar de receptgewichten</button>
          </div>
          </sc-if>
        </div>
        </sc-if>

"""

# ── 6. profiel: lengte, gewicht, grafiek en BMI ──────────────────────────
PROFIEL_ANKER = """          <h3 style="font-family:Caprasimo,system-ui;font-size:19px;margin:26px 0 12px">Instellingen</h3>"""
PROFIEL_BLOK = """          <h3 style="font-family:Caprasimo,system-ui;font-size:19px;margin:26px 0 12px">Gewicht en lengte</h3>
          <div style="display:flex;gap:9px;align-items:stretch">
            <div style="flex:1 1 0;min-width:0;background:#f9f4ed;border-radius:20px;padding:14px 15px">
              <div style="font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:#82796a;margin-bottom:7px">Lengte in cm</div>
              <input value="{{ lengte }}" sc-camel-on-change="{{ typLengte }}" type="number" inputmode="decimal" placeholder="188" style="width:100%;min-width:0;box-sizing:border-box;border:1px solid #dcd3c4;background:#fff;border-radius:999px;padding:10px 14px;font-size:14px;font-family:inherit"></input>
            </div>
            <div style="flex:1 1 0;min-width:0;background:#f9f4ed;border-radius:20px;padding:14px 15px">
              <div style="font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:#82796a;margin-bottom:7px">Gewicht in kg</div>
              <div style="display:flex;gap:7px">
                <input value="{{ nieuwGewicht }}" sc-camel-on-change="{{ typGewicht }}" type="number" inputmode="decimal" placeholder="{{ laatsteGewicht }}" style="flex:1 1 0;min-width:0;box-sizing:border-box;border:1px solid #dcd3c4;background:#fff;border-radius:999px;padding:10px 12px;font-size:14px;font-family:inherit"></input>
                <button sc-camel-on-click="{{ weegIn }}" style="flex:none;border:0;border-radius:999px;background:#c67139;color:#f5ead8;font-family:Caprasimo,system-ui;font-size:13px;padding:0 14px;cursor:pointer">Weeg</button>
              </div>
            </div>
          </div>

          <sc-if value="{{ heeftGewichten }}">
          <div style="background:#f9f4ed;border-radius:26px;padding:16px 18px;margin-top:10px">
            <div style="display:flex;align-items:baseline;gap:10px">
              <span style="flex:1;font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:#82796a">Verloop</span>
              <span style="font-size:12px;font-weight:700;color:{{ trendKleur }}">{{ trend }}</span>
            </div>
            <div style="display:flex;align-items:flex-end;gap:4px;height:110px;margin-top:12px">
              <sc-for list="{{ gewichtBalken }}" as="g" hint-placeholder-count="6">
                <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;justify-content:flex-end;height:100%">
                  <span style="font-size:9.5px;color:#82796a">{{ g.kg }}</span>
                  <div style="width:100%;border-radius:6px 6px 0 0;background:{{ g.kleur }};height:{{ g.hoogte }}%"></div>
                  <span style="font-size:8.5px;color:#a19786">{{ g.datum }}</span>
                </div>
              </sc-for>
            </div>
            <div style="display:flex;align-items:baseline;gap:10px;border-top:1px solid #e1d6bf;margin-top:12px;padding-top:12px">
              <span style="flex:1;font-size:13px;color:#474238">BMI</span>
              <span style="font-family:Caprasimo,system-ui;font-size:20px;color:{{ bmiKleur }}">{{ bmi }}</span>
              <span style="font-size:12px;color:#82796a">{{ bmiLabel }}</span>
            </div>
            <div style="font-size:11px;color:#a19786;line-height:1.45;margin-top:6px">{{ bmiUitleg }}</div>
          </div>
          </sc-if>

          <h3 style="font-family:Caprasimo,system-ui;font-size:19px;margin:26px 0 12px">Instellingen</h3>"""

# ── 7. logica voor Precision en het profiel ──────────────────────────────
LOGICA_ANKER = """    const scherm = st.screen;"""
LOGICA = r"""    // ── Precision ────────────────────────────────────────────────────────
    const precisieBlok = st.precisieBlok
      && blokLijst.some(b => b.blok === st.precisieBlok)
      ? st.precisieBlok : (blokLijst[0] ? blokLijst[0].blok : null);
    const precisieKnoppen = blokLijst.map(b => ({
      naam: b.blok.replace(/\s\(.*\)/, ''),
      kies: () => this.setState({ precisieBlok: b.blok }),
      bg: b.blok === precisieBlok ? '#201e1d' : '#ebddc5',
      kleur: b.blok === precisieBlok ? '#f5ead8' : '#474238'
    }));
    const pBlok = blokLijst.find(b => b.blok === precisieBlok);
    const pRec = pBlok && rid(pBlok) ? d.recept[rid(pBlok)] : null;
    const precisieIng = (pRec ? pRec.ing : []).map(i => ({
      naam: i.n, recept: i.g,
      waarde: st.gram[gramSleutel(pBlok, i.n)] ?? '',
      typ: e => this.bewaar('gram', { ...st.gram, [gramSleutel(pBlok, i.n)]: e.target.value })
    }));
    const pMacro = pBlok ? blokMacro(pBlok) : { kcal: 0, e: 0 };

    // ── ring: hoe ver ben je vandaag ────────────────────────────────────
    const ringDeel = Math.min(1, gegeten.kcal / doelen.kcal);
    const ringRijen = [
      ['Eiwit', gegeten.e, doelen.e, sage],
      ['Vet', gegeten.v, doelen.v, '#8fa073'],
      ['Koolhydraten', gegeten.k, doelen.k, '#f6a06b']
    ].map(([naam, nu, doel, kleur]) => ({
      naam, kleur, waarde: Math.round(nu) + ' / ' + doel + ' g',
      pct: Math.min(100, nu / doel * 100)
    }));

    // ── profiel: gewicht, verloop en BMI ────────────────────────────────
    const prof = st.profiel || { lengte: '', gewichten: [] };
    const wegingen = (prof.gewichten || []).slice(-14);
    const kgs = wegingen.map(g => g.kg);
    const laag = Math.min.apply(null, kgs.length ? kgs : [0]);
    const hoog = Math.max.apply(null, kgs.length ? kgs : [1]);
    const spreiding = (hoog - laag) || 1;
    const gewichtBalken = wegingen.map((g, ix) => ({
      kg: g.kg, datum: g.datum.slice(8, 10) + '/' + g.datum.slice(5, 7),
      // de laagste weging houdt een stompje zodat de balk zichtbaar blijft
      hoogte: 18 + (g.kg - laag) / spreiding * 82,
      kleur: ix === wegingen.length - 1 ? acc : '#c0b6a5'
    }));
    const lengteM = this.getal(prof.lengte) / 100;
    const laatsteKg = kgs.length ? kgs[kgs.length - 1] : 0;
    const bmiWaarde = (lengteM > 0 && laatsteKg > 0) ? laatsteKg / (lengteM * lengteM) : 0;
    const bmiLabel = !bmiWaarde ? 'vul je lengte in'
      : bmiWaarde < 18.5 ? 'ondergewicht'
      : bmiWaarde < 25 ? 'gezond gewicht'
      : bmiWaarde < 30 ? 'overgewicht' : 'obesitas';
    const verschil = kgs.length > 1 ? kgs[kgs.length - 1] - kgs[0] : 0;

    const scherm = st.screen;"""

UITVOER_ANKER = """      weekPills, rondes, eigenItems, nieuw: st.nieuw,"""
UITVOER = r"""      isPrecision: scherm === 'precision',
      goPrecision: this.ga('precision'),
      kleurPrecision: nav('precision'),
      precisionBg: scherm === 'precision' ? '#8c491a' : acc,
      naarPrecisie: () => this.setState({
        screen: 'precision', precisieBlok: meal ? meal.blok : null, meal: null }),
      precisieKnoppen, precisieIng,
      heeftPrecisie: !!(pBlok && precisieIng.length),
      precisieTitel: pBlok ? kort(pBlok.wat) : '',
      precisieSub: pBlok ? pBlok.blok + ' · dag ' + dagNr : '',
      precisieKcal: Math.round(pMacro.kcal) + ' kcal · ' + Math.round(pMacro.e) + ' g eiwit',
      precisieHerstel: () => {
        const schoon = { ...st.gram };
        (pRec ? pRec.ing : []).forEach(i => { delete schoon[gramSleutel(pBlok, i.n)]; });
        this.bewaar('gram', schoon);
      },
      ringPct: Math.round(ringDeel * 100),
      ringGraden: Math.round(ringDeel * 360),
      ringKleur: gegeten.kcal > doelen.kcal ? '#b2622d' : acc,
      ringRijen,

      lengte: prof.lengte, nieuwGewicht: st.nieuwGewicht,
      typLengte: e => this.bewaar('profiel', { ...prof, lengte: e.target.value }),
      typGewicht: e => this.setState({ nieuwGewicht: e.target.value }),
      laatsteGewicht: laatsteKg ? String(laatsteKg) : '95',
      weegIn: () => {
        const kg = this.getal(st.nieuwGewicht);
        if (!kg) return;
        const nu = new Date();
        const datum = nu.getFullYear() + '-' + String(nu.getMonth() + 1).padStart(2, '0')
          + '-' + String(nu.getDate()).padStart(2, '0');
        // een tweede weging op dezelfde dag vervangt de eerste
        const rest = (prof.gewichten || []).filter(g => g.datum !== datum);
        this.bewaar('profiel', { ...prof, gewichten: [...rest, { datum, kg }] });
        this.setState({ nieuwGewicht: '' });
      },
      heeftGewichten: wegingen.length > 0,
      gewichtBalken,
      trend: (verschil > 0 ? '+' : '') + verschil.toFixed(1).replace('.', ',') + ' kg',
      trendKleur: verschil > 0 ? sage : verschil < 0 ? rood : '#82796a',
      bmi: bmiWaarde ? bmiWaarde.toFixed(1).replace('.', ',') : '—',
      bmiLabel, bmiKleur: (bmiWaarde >= 18.5 && bmiWaarde < 25) ? sage : acc,
      bmiUitleg: 'BMI kijkt alleen naar gewicht en lengte, niet naar spier. Bij krachttraining valt hij daardoor hoger uit dan hij aanvoelt.',

      weekPills, rondes, eigenItems, nieuw: st.nieuw,"""

# ── 8. personaliseer-knop in het maaltijdscherm ──────────────────────────
# De hele openingstag als anker: alleen het style-deel pakken laat een
# losse <button ...> achter, en dan valt Personaliseer binnen de terugknop.
TERUGKNOP_OUD = """<button sc-camel-on-click="{{ terug }}" style="position:absolute;top:var(--top-knop);left:18px;"""
PERSONALISEER = """<button sc-camel-on-click="{{ naarPrecisie }}" style="position:absolute;top:var(--top-knop);right:18px;border:0;border-radius:999px;background:rgba(46,43,37,.72);color:#f9f4ed;font-size:12px;font-weight:700;padding:10px 15px;cursor:pointer;z-index:5">Personaliseer</button>
            <button sc-camel-on-click="{{ terug }}" style="position:absolute;top:var(--top-knop);left:18px;"""


def vervang(t, oud, nieuw, wat):
    if oud not in t:
        sys.exit("niet gevonden: %s" % wat)
    return t.replace(oud, nieuw, 1)


def knop(t, handler, vanaf):
    """Het hele <button>-blok van een tab, op zijn on-click herkend.

    Zoeken begint pas bij de tabbalk: goBood staat ook op het thuisscherm,
    en dat blok mag hier niet meegenomen worden.
    """
    start = t.find('<button sc-camel-on-click="{{ %s }}"' % handler, vanaf)
    if start < 0:
        sys.exit("tabknop %s niet gevonden" % handler)
    eind = t.find("</button>", start)
    return start, eind + len("</button>")


def tabs_wisselen(t):
    """Week en Lijstje wisselen van plek; Week heet voortaan Precision.

    De vormgeving blijft staan waar hij staat: de middelste knop is de ronde
    met de schaduw. Alleen de inhoud verhuist. De streekkleur van een icoon
    hoort ook bij de plek: de vlakke knoppen volgen hun tekstkleur, de ronde
    knop staat op oranje en heeft een zandkleurig icoon nodig.
    """
    balk = t.find("<!-- \u2550\u2550\u2550\u2550\u2550\u2550 TABBALK \u2550\u2550\u2550\u2550\u2550\u2550 -->")
    if balk < 0:
        sys.exit("tabbalk niet gevonden")
    a0, a1 = knop(t, "goWeek", balk)   # de vlakke knop op plek twee
    b0, b1 = knop(t, "goBood", balk)   # de ronde knop in het midden
    assert a0 < b0, "de tabknoppen staan in een andere volgorde dan verwacht"
    vlak, rond = t[a0:a1], t[b0:b1]

    haal = lambda s: re.search(r"<svg.*?</svg>", s, re.S).group(0)
    kalender, tas = haal(vlak), haal(rond)

    vlak = (vlak.replace(kalender, tas.replace('stroke="#f5ead8"', 'stroke="currentColor"'))
                .replace("{{ goWeek }}", "{{ goBood }}")
                .replace("{{ kleurWeek }}", "{{ kleurBood }}")
                .replace(">Week<", ">Lijstje<"))
    rond = (rond.replace(tas, kalender.replace('stroke="currentColor"', 'stroke="#f5ead8"'))
                .replace("{{ goBood }}", "{{ goPrecision }}")
                .replace("{{ boodBg }}", "{{ precisionBg }}")
                .replace("{{ kleurBood }}", "{{ kleurPrecision }}")
                .replace(">Lijstje<", ">Precision<"))

    return t[:a0] + vlak + t[a1:b0] + rond + t[b1:]


def weekscherm_vervangen(t):
    """De oude weekplanner maakt plaats voor Precision."""
    start = t.find("        <!-- ══════ WEEKPLANNER ══════ -->")
    if start < 0:
        sys.exit("weekplanner niet gevonden")
    eind = t.find("        <!-- ══════ VOORTGANG ══════ -->", start)
    if eind < 0:
        sys.exit("einde van de weekplanner niet gevonden")
    return t[:start] + PRECISION_SCHERM + t[eind:]


def bouw(t):
    # opslag en dagsleutels
    t = vervang(t, VANDAAG_OUD, VANDAAG_NIEUW, "vandaag()")
    t = vervang(t, CYCLUS_OUD, CYCLUS_NIEUW, "cyclusberekening")
    t = vervang(t, STATE_OUD, STATE_NIEUW, "state")
    t = vervang(t, MOUNT_OUD, MOUNT_NIEUW, "componentDidMount")

    # de rail rolt mee
    t = vervang(t, DAGNR_OUD, DAGNR_NIEUW, "dagnummer")
    t = vervang(t, RAIL_OUD, RAIL_NIEUW, "dagrail")

    # afvinken bewaren
    t = vervang(t, VINKBLOK_OUD, VINKBLOK_NIEUW, "blok afvinken")
    t = vervang(t, BLOKVINK_OUD, BLOKVINK_NIEUW, "vinkjes in het dagoverzicht")
    t = vervang(t, MEALVINK_OUD, MEALVINK_NIEUW, "vinkje van de maaltijd")
    t = vervang(t, MEALAF_OUD, MEALAF_NIEUW, "maaltijd afvinken")

    # dagelijkse macro's en micro's
    t = vervang(t, GEGETEN_ANKER, GEGETEN, "plek voor de dagtelling")
    t = vervang(t, PROG_OUD, PROG_NIEUW, "macro's")
    t = vervang(t, MICRO_OUD, MICRO_NIEUW, "micronutrienten")
    t = vervang(t, MICRO_TEKST_OUD, MICRO_TEKST_NIEUW, "uitleg bij de micronutrienten")
    t = vervang(t, MACRO_KOP_OUD, MACRO_KOP_NIEUW, "uitleg bij de macro's")

    # Precision en het profiel
    t = weekscherm_vervangen(t)
    t = vervang(t, PROFIEL_ANKER, PROFIEL_BLOK, "instellingen in het profiel")
    t = vervang(t, LOGICA_ANKER, LOGICA, "plek voor de nieuwe logica")
    t = vervang(t, UITVOER_ANKER, UITVOER, "uitvoer")
    t = vervang(t, TERUGKNOP_OUD, PERSONALISEER, "terugknop in het maaltijdscherm")
    t = tabs_wisselen(t)
    return MERK + t


def main():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(r'(<script type="__bundler/template">)(.*?)(</script>)', html, re.S)
    if not m:
        sys.exit("template-script niet gevonden in index.html")
    t = json.loads(m.group(2))
    if MERK in t:
        print("Precision staat er al in")
        return
    INDEX.write_text(
        html[:m.start(2)] + json.dumps(bouw(t)).replace("</", "<\\/") + html[m.end(2):],
        encoding="utf-8")
    print("Precision, dagtelling en profiel toegevoegd")


if __name__ == "__main__":
    main()
