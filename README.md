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
| `tools/Seb60dagenvoedingsschema.xlsx` | het bronbestand |

## Data bijwerken

```sh
pip install openpyxl
python3 tools/build-data.py tools/Seb60dagenvoedingsschema.xlsx
```

Na een nieuwe export van de standalone HTML ook eenmalig:

```sh
python3 tools/patch-index.py
```

Die patch is nodig omdat de bundler de component vanuit een `blob:`-URL
draait, waar de relatieve import `./schemaData.js` niet geresolved kan
worden. De patch maakt er een absolute URL van via `document.baseURI`.

## Prijzen

De boodschappenlijst rekent met `tools/winkels.json` → `prijzen`:

```json
"kipfilet": [11.50, "Slager", 0, "vers"]
```

Dat is `[prijs per kg/liter/stuk, winkel, bio (0 of 1), opmerking]`. Het
Excel-bestand bevat geen prijzen; zolang een ingredient hier ontbreekt telt
het voor 0 euro mee en valt het onder "Supermarkt".

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
