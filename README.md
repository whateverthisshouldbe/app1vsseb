# Voedingsschema App

Standalone HTML-app met het 60-daagse voedingsschema. Geen build-stap nodig.

## Bestanden

| bestand | wat |
|---|---|
| `index.html` | de app (gebundeld: React, Babel, fonts, component) |
| `schemaData.js` | 60 dagen, 104 recepten, 9 weeklijsten, supplementen |
| `winkelData.js` | prijzen en winkelindeling |
| `tools/build-data.py` | genereert beide modules uit het Excel-bestand |
| `tools/winkels.json` | categorieen, winkels en prijzen (met de hand bij te houden) |
| `tools/patch-index.py` | maakt de data-imports in een nieuwe bundle werkend |
| `tools/app-shell.py` | haalt de prototype-chrome weg, maakt het schermvullend |
| `tools/ui-tweaks.py` | aanpassingen aan de schermen zelf |
| `tools/ui-loop.py` | de 60-daagse lus, weektabs en de inslaanpagina |
| `tools/ui-rondes.py` | de zondag- en woensdagronde in het lijstje |
| `tools/ui-micros.py` | micronutrienten met gehaltes in plaats van vaste percentages |
| `tools/build-icons.py` | genereert de app-iconen |
| `tools/bereiding.json` | de bereidingswijze per recept |
| `tools/build-fotoprompts.py` | schrijft `fotos/PROMPTS.md` |
| `fotos/` | foto's per receptcode, zie `fotos/LEESMIJ.md` |
| `manifest.webmanifest`, `sw.js`, `icon-*.png` | installeerbaar en offline bruikbaar |
| `tools/Seb60dagenvoedingsschema.xlsx` | het bronbestand |

## Data bijwerken

```sh
pip install openpyxl
python3 tools/build-data.py tools/Seb60dagenvoedingsschema.xlsx
```

## Na een nieuwe export van de designtool

De export is een presentatiepagina, geen app. Twee patches maken er weer een
app van; beide zijn idempotent, dus dubbel draaien kan geen kwaad:

```sh
cp ~/Downloads/Voedingsschema_App_standalone.html index.html
python3 tools/patch-index.py   # data-imports werkend maken
python3 tools/app-shell.py     # chrome eruit, schermvullend, PWA-meta's
python3 tools/ui-tweaks.py     # aanpassingen aan de schermen
python3 tools/ui-loop.py       # lus, weektabs, inslaanpagina
python3 tools/ui-rondes.py     # zondag- en woensdagronde
python3 tools/ui-micros.py     # micronutrienten met gehaltes
```

`patch-index.py` is nodig omdat de bundler de component vanuit een `blob:`-URL
draait, waar de relatieve import `./schemaData.js` niet geresolved kan worden;
de patch maakt er een absolute URL van via `document.baseURI`.

`app-shell.py` haalt de kop met uitleg, de iPhone-mockup en de voettekst weg,
laat de app `100dvh` vullen, en vervangt de vaste marges die de nep-statusbalk
vrijhielden door `env(safe-area-inset-*)`.

## De 60-daagse lus

Het schema herhaalt zich: 60 verschillende dagen, daarna weer dag 1. Welke
dag het vandaag is volgt uit een startdatum in `localStorage`
(`voedingsschema.start`), die bij de eerste keer openen op vandaag wordt
gezet. Wil je opnieuw beginnen of op een andere dag instappen, pas die sleutel
dan aan in de browser.

Het boodschappenlijstje toont daarom deze week en een week vooruit, in plaats
van alle negen weken.

## De twee boodschapronden

De indeling volgt wanneer je iets nodig hebt, niet wat voor product het is.
`build-data.py` leidt uit de recepten af op welke weekdagen elk ingredient
gebruikt wordt (ook uit de aanvulblokken, die vrije tekst zijn) en zet per
regel een `ronde`:

- **zondag** — alles wat de week uitzingt, plus alle verse groente van de
  markt, plus het vlees van Sanderkoe.nl dat de vriezer in gaat
- **woensdag** — alleen wat in `kort_houdbaar` staat en pas vanaf donderdag
  nodig is. Wordt iets zowel voor als na woensdag gebruikt, dan wordt de
  hoeveelheid over beide rondes verdeeld.

`tweewekelijks_winkel` (Sanderkoe.nl) wordt in oneven weken voor twee weken
tegelijk ingekocht; in even weken staat dat vlees er niet op. De totalen over
60 dagen blijven daarbij gelijk.

## Micronutrienten

Het tabblad Micronutrienten geeft per dag de verhouding tot de
referentie-inname, niet het gehalte zelf: 2,39 betekent 239% van de
referentie. Maal de referentierij bovenaan geeft dat het gehalte, en zo staat
het in de app. Negentien stoffen, gemiddeld over de laatste zeven dagen van
de lus.

Die verhoudingen worden op vier decimalen ingelezen. Op een decimaal
afronden ging bij vitamine D (0,09) ruim tien procent mis.

## Bereiding en foto's

De bereidingswijze staat in `tools/bereiding.json`, met de receptcode als
sleutel (`D14`, `L4`, `O1`). Die is er niet uit het Excel-bestand gekomen —
dat bevat alleen ingredienten en grammen — maar geschreven op basis van die
ingredienten. Pas hem gerust aan; `build-data.py` waarschuwt als een recept
geen bereiding heeft of andersom.

Foto's gaan per receptcode in `fotos/`, zie `fotos/LEESMIJ.md`.

## Op de telefoon zetten

Open de Netlify-URL in Safari (iOS) of Chrome (Android) en kies "Zet op
beginscherm". Je krijgt dan een echte app zonder browserbalk, met eigen icoon,
die dankzij `sw.js` ook offline werkt. Bij een nieuwe versie: verhoog `CACHE`
in `sw.js`, anders blijft de oude versie in de cache staan.

## Boodschappen: groepen, winkels en prijzen

Alles staat in `tools/winkels.json` → `prijzen`:

```json
"kipfilet": [11.00, "Vlees", 0, "Hanos, bulk"]
```

Dat is `[prijs per kg/liter/stuk, groep, bio (0 of 1), winkel]`. De groep is
de kop in het lijstje: `Upfront`, `Vlees`, `Groentes` of `Overig`; de tekst
onder elke kop staat in `groepen`.

**De prijzen zijn schattingen.** Het Excel-bestand bevat geen prijzen, dus ze
zijn gebaseerd op gangbare Nederlandse winkelprijzen en niet gecontroleerd.
Pas ze aan in dit bestand en draai `build-data.py` opnieuw. Een product dat
hier ontbreekt telt voor 0 euro mee.

`bulk` bepaalt welke producten per verpakking gaan: `[verpakking, kg of
liter, enkelvoud, meervoud]`. Die komen alleen op het lijstje in de week dat
de voorraad opraakt — een zak rijst van 5 kg staat dus niet elke week op de
lijst. De voorraad loopt door over alle negen weken heen. Blik staat er
bewust niet bij, want een geopend blik gaat niet weken mee.

`hernoem` in hetzelfde bestand vervangt namen uit het Excel-bestand (en telt
regels op die daardoor samenvallen), bijvoorbeeld rundergehakt 5% en 15% naar
gewoon rundergehakt.

## Netlify

`netlify.toml` publiceert de repo-root als statische site. Koppelen: Netlify
-> Add new site -> Import an existing project -> GitHub ->
`whateverthisshouldbe/app1vsseb` -> branch `main`. Build command leeg,
publish directory `.`. Elke push naar `main` deployt automatisch.

## Lokaal bekijken

```sh
python3 -m http.server 8000
```

Openen via `file://` werkt niet: de browser blokkeert dan de module-imports.
