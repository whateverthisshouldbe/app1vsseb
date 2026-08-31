#!/usr/bin/env python3
"""Schrijft fotos/PROMPTS.md: een promptregel per gerecht.

Bedoeld om de voorbeeldfoto's mee te laten maken in een AI-beeldgenerator.
De porties staan erbij omdat de foto als maatstaf voor de opmaak dient, maar
reken erop dat een beeldmodel grammen niet nauwkeurig aanhoudt: gebruik ze
als richting, niet als weegschaal.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOTOS = ROOT / "fotos"

STIJL = ("overhead food photograph, plain off-white ceramic plate or bowl on a warm "
         "cream linen surface, soft natural daylight from the left, gentle shadows, "
         "realistic home-cooked portion, appetising but not styled like an advert, "
         "no text, no hands, no cutlery in frame")


def hoofdzaken(ing, hoeveel=6):
    """De grootste ingredienten eerst; die bepalen wat je op het bord ziet."""
    echte = [i for i in ing if i["n"] != "portie totaal"]
    groot = sorted(echte, key=lambda i: -i.get("g", 0))[:hoeveel]
    return ", ".join("%s %s g" % (i["n"], round(i.get("g", 0))) for i in groot)


def main():
    tekst = (ROOT / "schemaData.js").read_text(encoding="utf-8")
    recept = json.loads(re.search(r"export const recept = (\{.*?\n\});", tekst, re.S).group(1))

    FOTOS.mkdir(exist_ok=True)
    regels = ["# Fotoprompts", "",
              "Een prompt per gerecht. Bewaar het resultaat als `fotos/<code>.jpg`",
              "(bijvoorbeeld `fotos/D14.jpg`) en draai daarna `build-data.py` opnieuw;",
              "de app pakt de foto's dan vanzelf op.", "",
              "De grammen staan erbij als richting voor de portiegrootte. Een",
              "beeldmodel houdt die niet nauwkeurig aan.", ""]
    for code, r in recept.items():
        naam = re.sub(r"^[A-Z\- ]+ - ", "", r["naam"])
        regels.append("## %s — %s" % (code, naam))
        regels.append("")
        regels.append("```")
        regels.append("%s. Ingredients visible: %s. %s."
                      % (naam, hoofdzaken(r["ing"]), STIJL))
        regels.append("```")
        regels.append("")

    (FOTOS / "PROMPTS.md").write_text("\n".join(regels), encoding="utf-8")
    print("fotos/PROMPTS.md geschreven: %d gerechten" % len(recept))


if __name__ == "__main__":
    main()
