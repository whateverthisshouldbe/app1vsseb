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
| `tools/build-icons.py` | genereert de app-iconen |
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
```

`patch-index.py` is nodig omdat de bundler de component vanuit een `blob:`-URL
draait, waar de relatieve import `./schemaData.js` niet geresolved kan worden;
de patch maakt er een absolute URL van via `document.baseURI`.

`app-shell.py` haalt de kop met uitleg, de iPhone-mockup en de voettekst weg,
laat de app `100dvh` vullen, en vervangt de vaste marges die de nep-statusbalk
vrijhielden door `env(safe-area-inset-*)`.

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
