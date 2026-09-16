# Sell Me This Pen — Roblox simulator

Een simulator in de stijl van *Sell Lemons*, maar met pennen. Je begint met een
pennenkraam aan de straat. Je maakt pennen, loopt naar je toonbank, en dan moet je
de klant écht overtuigen: **"Sell me this pen!"** Je krijgt drie verkoopargumenten
en zeven seconden. Past je praatje bij het type klant, dan betaalt hij dubbel.

Elke rebirth opent een nieuwe zaak. De oude blijft open en blijft passief geld
opleveren — ook als je offline bent:

    Pennenkraam -> Pennenwinkel -> Pennenfabriek -> Groothandel
    -> Pen Street Toren -> Penthouse -> Penjacht -> Pen Orbit

De sfeer is die van een straatverkoper die uitgroeit tot handelaar in pak
(Pen Street, telefoons, pakken) — met eigen namen en teksten, dus zonder iets uit
een film over te nemen.

## Het spel

| plek | wat er gebeurt |
|---|---|
| **blauwe plaat** bij je zaak | zolang je erop staat maak je pennen, tot je tas vol is |
| **groene plaat** bij de toonbank | start de pitch-minigame; kies het juiste argument |
| **gele platen** op het plein | upgrades kopen; blijf staan om te blijven kopen |
| **paarse plaat** op het plein | 2 seconden blijven staan = rebirth |
| **pennenbak** op het plein | mascottes kopen (knop "Mascottes" rechtsonder) |
| **borden** op het plein | top 10 rijkste spelers en meeste rebirths |

**Pitchen.** Elke klant heeft een type: *heeft haast*, *houdt van luxe*, *let op de
prijs*, *gelooft er niets van*, *wil de details*, *zoekt een cadeau*. Perfect
antwoord = **x2**, half raak = x1.15, mis = x0.7, te laat = x0.6. Elke perfecte
pitch op rij geeft +10% bovenop, tot +100%.

**Idle.** Al je geopende zaken verdienen automatisch door, ook als je weg bent
(2 uur offline, 8 uur met de VIP-gamepass). Bij het inloggen zie je wat ze
opgeleverd hebben.

**Rebirth** kost geld en zet je geld én upgrades terug op 0, maar geeft +90% op
alles, opent de volgende zaak en je houdt het passieve inkomen van alle vorige.

**Extra's die er al in zitten:** mascottes (zweven mee, geven boost), dagelijkse
beloning met streak, codes, en drie gamepasses die aan gaan zodra je de ID's invult.

## Tempo

Gesimuleerd met normaal spel (zie `test/balance.py`):

| rebirth | speeltijd tot dan |
|---|---|
| 1 (Pennenwinkel) | ~4 min |
| 2 (Pennenfabriek) | ~8 min |
| 3 (Groothandel) | ~12 min |
| 4 (Pen Street Toren) | ~20 min |
| 5 (Penthouse) | ~32 min |

Te snel of te traag? `Config.Rebirth.growth` omhoog of omlaag, en opnieuw simuleren.

## Bestanden

| bestand | wat |
|---|---|
| `src/shared/Config.luau` | **alle balans en teksten**: zaken, pennen, upgrades, klanten, pitch-argumenten, mascottes, codes, gamepasses |
| `src/shared/Net.luau` | de RemoteEvents tussen server en client |
| `src/server/Game.luau` | de spelregels |
| `src/server/World.luau` | bouwt de hele map met code |
| `src/server/Customers.luau` | de klanten en hun types |
| `src/server/Data.luau` | opslaan/laden met autosave |
| `src/server/Passes.luau` | gamepasses |
| `src/server/Pets.luau` | de zwevende mascotte |
| `src/server/Leaderboards.luau` | de borden op het plein |
| `src/client/init.client.luau` | de hele interface |
| `dist/*.lua` | de gebundelde versie om in Studio te plakken (gegenereerd) |
| `tools/bundle.py` | maakt `dist/` opnieuw na een wijziging in `src/` |
| `test/run.py` | speelt de game na met een nagemaakte Roblox-API (37 controles) |
| `test/balance.py` | simuleert hoe lang rebirths duren |
| `default.project.json` | Rojo-project |

De map wordt met code gebouwd, dus in Studio hoef je niets te bouwen: leeg
Baseplate, scripts erin, Play.

Iets veranderd in `src/`? Draai dan:

    python3 tools/bundle.py   # zet de wijziging in dist/
    python3 test/run.py       # controleert of alles nog werkt

## In Roblox krijgen — manier A: plakken (geen tools nodig)

1. Open **Roblox Studio** → **New** → **Baseplate**.
2. Explorer → rechtermuisknop op **ServerScriptService** → *Insert Object* →
   **Script**. Plak de hele inhoud van `dist/ServerBundle.server.lua`.
3. Rechtermuisknop op **StarterPlayer → StarterPlayerScripts** → *Insert Object* →
   **LocalScript**. Plak de hele inhoud van `dist/ClientBundle.client.lua`.
4. **File → Game Settings → Security**: zet **Enable Studio Access to API Services**
   aan (anders slaat je voortgang in Studio niet op).
5. **Play**. De map bouwt zichzelf.
6. **File → Publish to Roblox** → nieuwe ervaring aanmaken.
7. Op [create.roblox.com](https://create.roblox.com) → je ervaring → **Configure** →
   zet hem op **Public**.

## In Roblox krijgen — manier B: Rojo (fijner om door te ontwikkelen)

1. Installeer [Rojo](https://rojo.space) plus de Rojo-plugin in Studio.
2. In deze map: `rojo serve`, in Studio: plugin → **Connect**.
3. Publiceren zoals stap 4–7 hierboven.

## Wat ik van jou nodig heb

Ik kan hier geen Roblox Studio draaien en niet publiceren; dat laatste stukje is aan jou.

**Sowieso nodig (eenmalig, ~10 minuten):**
- Een **Roblox-account** met geverifieerd e-mailadres (gratis).
- **Roblox Studio** op Windows of Mac — draait niet op mobiel of Linux.
- Eén keer **Publish to Roblox** en de ervaring op **Public** zetten.
- **Enable Studio Access to API Services** aan (voor opslaan, scoreborden en
  offline verdienen).

**Alleen als je die extra's wilt:**
- **Gamepasses**: maak op create.roblox.com → je ervaring → *Associated Items* →
  *Passes* drie passes aan (x2 Geld, VIP-tas, Auto-verkoop), en geef mij de
  drie ID's. Ik zet ze in `Config.Gamepasses`. Zolang ze 0 zijn staan ze netjes
  op "nog niet ingesteld" en werkt de rest gewoon.
- **Codes**: zeg welke codes je wilt uitdelen en wat ze geven, dan zet ik ze erbij.
  Nu staan erin: `PENSTART`, `SELLMETHIS`, `CLIPPIE`, `INKT`.
- **Roblox-groep** (gratis) als de game op naam van een groep moet staan.
- **Eigen modellen of geluiden** uit de Toolbox: geef me de asset-ID's, anders
  houd ik het bij vormen die de code zelf bouwt.
- **Open Cloud API-key** (Creator Dashboard → Open Cloud → API Keys) als ik vanaf
  hier zou moeten publiceren zonder dat jij Studio opent. Deel zo'n sleutel via de
  omgevingsinstellingen, nooit in een chatbericht of in de repo.
- **Robux** alleen voor advertenties; publiceren en spelen is gratis.

**Wat ik nooit nodig heb:** je wachtwoord of je `.ROBLOSECURITY`-cookie. Geef die
aan niemand, ook niet aan mij.
