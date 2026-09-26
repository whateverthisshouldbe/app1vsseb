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

**Bezoekers.** Los van de klanten aan de toonbank lopen er bezoekers je terrein op
(maximaal drie tegelijk, elk met een eigen bestelling en een eigen aflooptijd). Ze vragen
een aantal pennen van een bepaald soort - "40 markers" - en betalen daar een veelvoud voor.
Je tas houdt daarom per soort bij wat erin zit. Wie je getrade hebt komt in je **index**.

| zeldzaamheid | kans | betaalt | dagloon als personeel |
|---|---|---|---|
| Common | 1 op 2 | 3x | $250 |
| Rare | 1 op 4 | 7x | $1.2K |
| Super Rare | 1 op 11 | 15x | $6K |
| Epic | 1 op 38 | 34x | $32K |
| Mythic | 1 op 143 | 85x | $180K |
| Legendary | 1 op 606 | 220x | $1.1M |
| Exotic | 1 op 3.753 | 650x | $7.5M |
| **Ultra Exotic** (Beldan Jolfort) | **1 op 49.252** | 6000x | $90M |

Elke rebirth maakt zeldzame bezoekers iets waarschijnlijker (tot 2,5x). Zeldzamere bezoekers
vragen ook pennen uit je duurdere zaken. Komt er een **Legendary of hoger** langs, dan ziet
de hele server een banner in beeld - ook al is de bezoeker van jou alleen.

**Personeel.** Een bezoeker die in je index staat kun je inhuren. Personeel maakt pennen
voor je (het telt op bij je passieve inkomen), raakt vermoeid van doorwerken en rust dan
zelf even uit. Elke 24 uur willen ze loon; betaal je twaalf uur na de vervaldag nog niet,
dan nemen ze ontslag. Ze blijven wel in je index, dus je kunt ze opnieuw inhuren. Je begint
met één plek en krijgt er elke twee rebirths een bij, tot zes.

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

## De map

Pen Street is een stadsstraat die zichzelf bouwt: een plein met een fontein (een reuzenpen
in het water), een klokzuil, marktkraampjes voor de upgrades, een rebirth-portaal en twee
scoreborden. Vanaf het plein loopt de straat met stoepen, lantaarns, bomen, bankjes en
winkelpuien langs je zaken, met stadsblokken eromheen zodat je nooit op een leeg veld
uitkijkt. Elke zaak heeft een eigen terrein met bestrating, hek, poortje en aankleding:
de kraam heeft een gestreepte luifel en kratten, de fabriek schoorstenen met rook, silo's
en een lopende band, de toren een glazen gevel van 150 studs met verlichte ramen, het
penthouse een zwembad op kolommen, het jacht een haven met steiger, en Pen Orbit een
zwevend platform met ringen en sterren.

Licht en sfeer worden ook door de code gezet: Atmosphere, Bloom, kleurcorrectie, zonnestralen
en een middagstand van de zon. Eén ding kan een script niet: zet in Studio bij **Lighting**
de eigenschap **Technology** op **Future** (of ShadowMap) voor echte schaduwen.

**Vier wijken.** Hoe verder je komt, hoe rijker de stad. Elke twee zaken schuif je een
wijk op: marktstraat met kraampjes en luifels, dan de handelswijk met loodsen, kratten en
een watertoren, dan Pen Street met marmeren kantoren, zuilen, een koersenzuil en gele
taxi's, en tot slot de penthousewijk met glazen torens, rode lopers, palmen, limousines en
helikopterdeks. Ook de auto's langs de stoeprand veranderen mee.

**Bouwputten.** Een zaak die jij nog niet hebt vrijgespeeld staat in de steigers: bouwhekken,
een kraan, pionnen, een keet en een bord "opent na rebirth 3". Zodra jij hem opent haalt de
client die bouwput weg - alleen voor jou, want de wereld is gedeeld maar rebirths zijn
persoonlijk. Zo zie je de stad met je meegroeien.

Onderweg lopen kost tijd, dus er is een **Reizen**-knop: die brengt je direct naar elke
zaak die je al geopend hebt.

De hele map is ongeveer 6.600 onderdelen. Te zwaar voor oudere telefoons? Zet in
`World.build()` de aantallen bij `Scenery.skyline(...)` lager.

## Vormgeving bekijken zonder Studio

`python3 tools/preview.py` draait de wereldcode met een nagemaakte Roblox-API en tekent de
map als isometrische plaatjes en plattegronden in `preview/`. Handig om de indeling te
beoordelen (en om te zien of er niets doorheen staat) voordat je Studio opent. De plaatjes
zijn een benadering: bollen en cilinders worden als blokken getekend, en materialen,
schaduwen en neon-gloed ontbreken. In Roblox ziet het er zachter uit.

## Bestanden

| bestand | wat |
|---|---|
| `src/shared/Config.luau` | **alle balans en teksten**: zaken, pennen, upgrades, klanten, pitch-argumenten, mascottes, codes, gamepasses |
| `src/shared/Net.luau` | de RemoteEvents tussen server en client |
| `src/server/Game.luau` | de spelregels |
| `src/server/World.luau` | bouwt de hele map met code |
| `src/server/Scenery.luau` | bouwstenen voor de aankleding: gevels, luifels, lantaarns, bomen, fontein |
| `src/server/Customers.luau` | de klanten en hun types |
| `src/server/Visitors.luau` | bezoekers: zeldzaamheid, bestelling en aflooptijd |
| `src/server/Staff.luau` | personeel: stamina, loon en ontslag |
| `src/server/Data.luau` | opslaan/laden met autosave |
| `src/server/Passes.luau` | gamepasses |
| `src/server/Pets.luau` | de zwevende mascotte |
| `src/server/Leaderboards.luau` | de borden op het plein |
| `src/client/init.client.luau` | de hele interface |
| `dist/*.lua` | de gebundelde versie om in Studio te plakken (gegenereerd) |
| `tools/bundle.py` | maakt `dist/` opnieuw na een wijziging in `src/` |
| `test/run.py` | speelt de game na met een nagemaakte Roblox-API (57 controles) |
| `test/balance.py` | simuleert hoe lang rebirths duren |
| `tools/preview.py` | tekent de map als plaatjes en plattegronden in `preview/` |
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
4. **Experience Settings** (heette vroeger Game Settings; tandwiel bovenin of via het
   menu linksboven) → **Security** → **Enable Studio Access to API Services** aan.
   Zonder dit werkt de game wel, maar wordt je voortgang niet bewaard.
5. **Play**. De map bouwt zichzelf.
6. **File → Publish to Roblox** → nieuwe ervaring aanmaken.
7. Op [create.roblox.com](https://create.roblox.com) → je ervaring → **Configure** →
   zet hem op **Public**.

## In Roblox krijgen — manier B: Rojo (fijner om door te ontwikkelen)

1. Installeer [Rojo](https://rojo.space) plus de Rojo-plugin in Studio.
2. In deze map: `rojo serve`, in Studio: plugin → **Connect**.
3. Publiceren zoals stap 4–7 hierboven.

## Automatisch publiceren bij elke push

In `.github/workflows/roblox-publish.yml` staat een GitHub Action die bij elke push naar
deze branch:

1. de bundels opnieuw maakt en de 39 controles draait (mislukt de test, dan stopt het hier),
2. met **Rojo** een compleet plaatsbestand `penstreet.rbxl` bouwt,
3. dat als download bewaart onder *Actions -> de run -> Artifacts*,
4. en het publiceert naar je ervaring via de Roblox Open Cloud API.

Stap 4 wordt overgeslagen zolang je de gegevens hieronder niet hebt ingevuld; stap 1 t/m 3
werken meteen. Je kunt dat plaatsbestand dus ook gewoon downloaden en in Studio openen.

### Eenmalig instellen

1. Publiceer de game één keer vanuit Studio (**File -> Publish to Roblox**).
2. Zoek je ID's op [create.roblox.com](https://create.roblox.com): klik je ervaring aan.
   In de URL staat het **universe-ID**; onder *Places* vind je het **place-ID** van de
   hoofdplaats (of via de drie puntjes -> *Copy Place ID*).
3. Maak een sleutel: **Creator Dashboard -> Open Cloud -> API Keys -> Create API Key**.
   - Voeg het systeem **Place Management** (of *universe-places*) toe.
   - Kies je ervaring en geef de rechten **Write**.
   - Zet bij *Accepted IP Addresses* `0.0.0.0/0` - GitHub-servers hebben geen vast IP-adres.
   - Kopieer de sleutel meteen; hij wordt maar één keer getoond.
4. In GitHub: **Settings -> Secrets and variables -> Actions**
   - Tabblad *Secrets*: `ROBLOX_API_KEY` = de sleutel.
   - Tabblad *Variables*: `ROBLOX_UNIVERSE_ID` en `ROBLOX_PLACE_ID`.

Vanaf dan is elke push genoeg. Let op drie dingen:

- **Publiceren overschrijft de hele plaats.** Wat je met de hand in Studio bouwt en niet in
  deze repo staat, is na de volgende push weg. De repo is de baas.
- **Spelers die al in een server zitten, houden de oude versie.** Nieuwe servers draaien de
  nieuwe. Wil je het meteen overal: Creator Dashboard -> je ervaring -> *Migrate to latest
  update*.
- De API-sleutel hoort alleen in GitHub Secrets. Niet in de code, niet in een chatbericht.

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
- **Open Cloud API-key** voor automatisch publiceren bij elke push - zie het hoofdstuk
  hierboven. Die sleutel zet je zelf in GitHub Secrets; ik hoef hem niet te zien.
- **Robux** alleen voor advertenties; publiceren en spelen is gratis.

**Wat ik nooit nodig heb:** je wachtwoord of je `.ROBLOSECURITY`-cookie. Geef die
aan niemand, ook niet aan mij.
