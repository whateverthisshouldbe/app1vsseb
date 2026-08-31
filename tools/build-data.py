#!/usr/bin/env python3
"""Genereert schemaData.js en winkelData.js uit het Excel-bronbestand.

Gebruik:  python3 tools/build-data.py <pad naar Seb60dagenvoedingsschema.xlsx>

De app leest de gegenereerde modules via dynamische imports in index.html.
Prijzen en winkelindeling staan in tools/winkels.json, want die staan niet
in het Excel-bestand.
"""
import json
import re
import sys
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parent.parent
WINKELS = ROOT / "tools" / "winkels.json"


def tekst(v):
    return "" if v is None else str(v).strip()


def getal(v):
    if v is None or v == "":
        return 0
    try:
        return round(float(v), 1)
    except (TypeError, ValueError):
        return 0


def lees_recepten(ws, prefix_strip=True):
    """Leest een receptenblad: Nr | Gerecht | Ingredient | Gram | kcal | E | V | K."""
    recepten = {}
    huidig = None
    for r in ws.iter_rows(min_row=2, values_only=True):
        nr, gerecht, ing = tekst(r[0]), tekst(r[1]), tekst(r[2])
        if nr:
            huidig = nr
            recepten[nr] = {"naam": gerecht, "ing": [], "tot": {}}
        if not huidig or not ing:
            continue
        rec = recepten[huidig]
        if ing.lower() == "portie totaal":
            rec["tot"] = {
                "kcal": getal(r[4]), "e": getal(r[5]),
                "v": getal(r[6]), "k": getal(r[7]),
            }
        else:
            rec["ing"].append({
                "n": ing, "q": getal(r[3]), "eh": "g",
                "kcal": getal(r[4]), "e": getal(r[5]),
                "v": getal(r[6]), "k": getal(r[7]),
            })
    return recepten


def lees_dagen(wb):
    """Combineert '60-dagen schema' (dagregels) met 'Dagdetails' (blokken)."""
    blokken = {}
    totalen = {}
    for r in wb["Dagdetails"].iter_rows(min_row=2, values_only=True):
        if r[0] is None:
            continue
        d, blok = int(r[0]), tekst(r[2])
        macro = {
            "kcal": getal(r[4]), "e": getal(r[5]),
            "v": getal(r[6]), "k": getal(r[7]), "vezel": getal(r[8]),
        }
        if blok == "TOTAAL":
            totalen[d] = macro
            continue
        wat = tekst(r[3])
        if not wat or wat == "-":
            continue
        blokken.setdefault(d, []).append({"blok": blok, "wat": wat, **macro})

    dagen = []
    for r in wb["60-dagen schema"].iter_rows(min_row=2, values_only=True):
        if not isinstance(r[0], (int, float)):
            continue  # slaat de 'Gemiddeld'-regel onderaan over
        d = int(r[0])
        tot = totalen.get(d, {})
        dagen.append({
            "d": d,
            "wd": tekst(r[1]),
            "tr": tekst(r[2]),
            "lunch": tekst(r[5]),
            "diner": tekst(r[7]),
            "kcal": tot.get("kcal", getal(r[10])),
            "e": tot.get("e", getal(r[11])),
            "v": tot.get("v", getal(r[12])),
            "k": tot.get("k", getal(r[13])),
            "vezel": tot.get("vezel", getal(r[14])),
            "blokken": blokken.get(d, []),
        })
    return dagen


def lees_supplementen(ws):
    """Het dagprotocol staat onder de kop 'Middel'; daarna volgt een tweede tabel."""
    supp, aandacht, sectie = [], [], None
    for r in ws.iter_rows(values_only=True):
        cellen = [tekst(c) for c in r]
        eerste = next((c for c in cellen if c), "")
        if eerste == "Middel":
            sectie = "protocol"
            continue
        if eerste == "Dag":
            sectie = "aandacht"
            continue
        if "DAGEN DIE EXTRA" in eerste:
            continue
        rij = [c for c in cellen[1:] if c]
        if sectie == "protocol" and len(rij) >= 4:
            supp.append({
                "naam": rij[0], "dosis": rij[1],
                "wanneer": rij[2], "waarom": rij[3],
                "moment": moment_van(rij[2]),
            })
        elif sectie == "aandacht" and len(rij) >= 3 and rij[0].isdigit():
            aandacht.append({
                "d": int(rij[0]), "wd": rij[1],
                "tekort": rij[2], "fix": rij[3] if len(rij) > 3 else "",
            })
    return supp, aandacht


def lees_micros(ws):
    """Rij met 'Referentie' geeft de norm; daarna per dag de absolute waarden."""
    rijen = list(ws.iter_rows(values_only=True))
    ref_rij = next(r for r in rijen if tekst(r[0]) == "Referentie")
    kop = next(r for r in rijen if tekst(r[0]) == "Dag")
    namen = [tekst(c) for c in kop[2:] if tekst(c)]
    ref = [getal(c) for c in ref_rij[2:2 + len(namen)]]
    per_dag = {}
    for r in rijen:
        if not isinstance(r[0], (int, float)):
            continue
        per_dag[int(r[0])] = [getal(c) for c in r[2:2 + len(namen)]]
    return {"namen": namen, "ref": ref, "perDag": per_dag}


# Waar een supplement in de dag valt; 'Losse dagen' hoort niet bij een
# vast moment en telt dus niet mee in het dagelijkse rijtje.
MOMENTEN = [
    ("bij het ontbijt", "Ontbijt"),
    ("bij een maaltijd", "Lunch"),
    ("bij het eten", "Diner"),
    ("bij het koken", "Diner"),
    ("timing maakt niet uit", "Wanneer je wilt"),
]


def moment_van(wanneer):
    w = wanneer.lower()
    for sleutel, moment in MOMENTEN:
        if sleutel in w:
            return moment
    return ""


def lees_boodschappen(ws):
    weken, week, dagen = [], None, ""
    for r in ws.iter_rows(min_row=2, values_only=True):
        if r[0] is not None:
            week, dagen = int(r[0]), tekst(r[1])
            weken.append({"week": week, "dagen": dagen, "items": []})
        naam = tekst(r[2])
        # 'einde week N' zijn scheidingsregels, geen boodschappen
        if not naam or naam.lower().startswith("einde week") or not weken:
            continue
        weken[-1]["items"].append({
            "n": naam, "q": getal(r[3]),
            "eh": tekst(r[4]), "opm": tekst(r[5]),
        })
    return weken


def hernoem_items(weken, hernoem):
    """Past de naamwijzigingen toe en telt dubbelen binnen een week op.

    Na het hernoemen kan hetzelfde product twee keer in een week staan
    (rundergehakt 5% en 15% worden allebei 'rundergehakt'), dus die regels
    moeten samengevoegd worden.
    """
    # gram en kilo (en liter) van hetzelfde product zijn dezelfde regel
    naar_basis = {"kg": ("g", 1000), "l": ("liter", 1)}
    for w in weken:
        samen = {}
        for i in w["items"]:
            i["n"] = hernoem.get(i["n"], i["n"])
            eh, factor = naar_basis.get(i["eh"], (i["eh"], 1))
            i["eh"], i["q"] = eh, i["q"] * factor
            sleutel = (i["n"], eh)
            if sleutel in samen:
                samen[sleutel]["q"] = round(samen[sleutel]["q"] + i["q"], 1)
                # de opmerking van de eerste regel blijft staan
            else:
                samen[sleutel] = i
        for i in samen.values():
            if i["eh"] == "g" and i["q"] >= 1000:
                i["eh"], i["q"] = "kg", round(i["q"] / 1000, 2)
            else:
                i["q"] = round(i["q"], 1)
        w["items"] = list(samen.values())


def hernoem_recepten(recept, hernoem):
    for r in recept.values():
        for i in r["ing"]:
            i["n"] = hernoem.get(i["n"], i["n"])


def naar_basis(q, eh):
    """Rekent een regel om naar kilo of liter; None als dat niet kan."""
    e = eh.lower()
    if e == "kg":
        return q
    if e == "g":
        return q / 1000
    if e in ("liter", "l"):
        return q
    return None


def bulk_verdelen(weken, bulk):
    """Zet bulkproducten alleen op het lijstje in de week dat ze opraken.

    Een zak van een kilo gaat meerdere weken mee, dus die hoort niet elke week
    op de lijst. Per product loopt de voorraad door over de negen weken: pas
    als er te weinig in huis is komen er zoveel verpakkingen bij als nodig.
    """
    voorraad = {}
    for w in weken:
        houden = []
        for i in w["items"]:
            regel = bulk.get(i["n"])
            nodig = naar_basis(i["q"], i["eh"]) if regel else None
            if not regel or nodig is None:
                houden.append(i)
                continue

            verpakking, eenheid, enkel, meervoud = regel
            hebben = voorraad.get(i["n"], 0.0)
            aantal = 0
            if nodig > hebben + 1e-9:
                aantal = int(-(-(nodig - hebben) // verpakking))  # naar boven af
                hebben += aantal * verpakking
            voorraad[i["n"]] = hebben - nodig

            if aantal:
                i["q"] = aantal
                i["eh"] = enkel if aantal == 1 else meervoud
                houden.append(i)
        w["items"] = houden


def bulk_prijzen(prijzen, bulk):
    """Bij bulk rekent de app per verpakking, dus de prijs mee omrekenen."""
    for naam, (verpakking, eenheid, enkel, _) in bulk.items():
        if naam not in prijzen:
            continue
        prijs, groep, bio, winkel = prijzen[naam]
        maat = ("%g kg" if eenheid == "kg" else "%g liter") % verpakking
        prijzen[naam] = [round(prijs * verpakking, 2), groep, bio,
                         "%s · %s per %s" % (winkel, maat, enkel)]


def js(naam, data):
    return "export const %s = %s;\n" % (naam, json.dumps(data, ensure_ascii=False, indent=1))


def main():
    if len(sys.argv) < 2:
        sys.exit("gebruik: build-data.py <xlsx>")
    wb = openpyxl.load_workbook(sys.argv[1], data_only=True, read_only=True)

    recept = {}
    for blad in ("Diners", "Lunches", "Vaste modules"):
        recept.update(lees_recepten(wb[blad]))

    dagen = lees_dagen(wb)
    weken = lees_boodschappen(wb["Boodschappenlijst"])
    supplementen, aandacht = lees_supplementen(wb["Supplementen"])
    micros = lees_micros(wb["Micronutrienten"])

    winkels = json.loads(WINKELS.read_text(encoding="utf-8"))
    hernoem = winkels["hernoem"]
    hernoem_items(weken, hernoem)
    hernoem_recepten(recept, hernoem)

    bulk_verdelen(weken, winkels["bulk"])
    bulk_prijzen(winkels["prijzen"], winkels["bulk"])

    cats = {hernoem.get(k, k): v for k, v in winkels["categorieen"].items()}
    for w in weken:
        for i in w["items"]:
            i["cat"] = cats.get(i["n"], "Overig")

    (ROOT / "schemaData.js").write_text(
        "// GEGENEREERD door tools/build-data.py — niet met de hand aanpassen.\n"
        + js("dagen", dagen) + js("weken", weken) + js("recept", recept)
        + js("supplementen", supplementen) + js("aandacht", aandacht)
        + js("micros", micros),
        encoding="utf-8")

    (ROOT / "winkelData.js").write_text(
        "// GEGENEREERD door tools/build-data.py uit tools/winkels.json.\n"
        + js("prijzen", winkels["prijzen"]) + js("winkels", winkels["groepen"]),
        encoding="utf-8")

    onbekend = sorted({i["n"] for w in weken for i in w["items"]
                       if i["n"] not in winkels["prijzen"]})
    print("dagen: %d | recepten: %d | weken: %d | supplementen: %d"
          % (len(dagen), len(recept), len(weken), len(supplementen)))
    if onbekend:
        print("LET OP, geen prijs/winkel voor: " + ", ".join(onbekend))


if __name__ == "__main__":
    main()
