# Sell Me This Pen 🖊️🐺

Een Roblox-tycoon rond de beroemde *"Sell me this pen"*-scène uit **The Wolf of Wall Street**.
Je begint met een Bic-pen in een armoedig Investor Center in een strip mall op Long Island. Je pitcht
voorbijgangers, koopt betere pennen en pakken, huurt brokers in en werkt je op via Pen Street en de
Stratton Oakpen-tradingvloer naar een jacht in de haven. Daarna ga je naar de beurs (IPO) voor een
permanente multiplier.

## Snel spelen

**Optie A: meteen openen (geen tools nodig)**
1. Open `SellMeThisPen.rbxlx` in Roblox Studio (dubbelklikken, of via *File → Open from File*).
2. Druk op **Play** (F5).

**Optie B: met Rojo (aanbevolen als je de code gaat aanpassen)**
1. Installeer [Rojo](https://rojo.space) (CLI + de Studio-plugin).
2. In deze map: `rojo serve`
3. In Studio: open een lege Baseplate, verwijder de `Baseplate`, en klik in de Rojo-plugin op **Connect**.
   Of bouw een placefile: `rojo build -o SellMeThisPen.rbxlx`.

**Opslaan werkt pas als de game gepubliceerd is.** Publiceer de place en zet bij *Game Settings →
Security* **Enable Studio Access to API Services** aan. Zonder die instelling werkt alles gewoon,
alleen wordt je voortgang dan niet opgeslagen.

## Gameplay

| Wat | Hoe |
|---|---|
| **Pitchen** | Loop naar een klant en druk op **E** (of tik op de prompt). |
| **Straight Line-meters** | Elke koper moet zeker zijn van de **PEN**, van **JOU** en van je **FIRMA** (Jordan Belforts echte verkoopmethode). |
| **Lines kiezen** | Kies 1 van 3 zinnen (**1/2/3**). Elke zin heeft een type: Rapport, Qualify, Product, Urgency, Authority, Hype, Pressure of Honest. |
| **Tonality** | Stop de naald in het groen (**Spatie**/klik). Goede timing geeft een groter effect. |
| **Klanten lezen** | Elk type klant heeft likes en hates. Een Hedge Fund Bro houdt van Pressure, een Duchess haat het. Hates worden pas zichtbaar als je ze raakt. |
| **Closen** | **C** of de gouden knop. De kans hangt af van je laagste meter. Alle drie op 10 = **PERFECT CLOSE** (×1,5). |
| **Winkel** | **B**: pennen (waarde per verkoop), pakken (startzekerheid + grotere sweet spot), telefoons en brokers (passief inkomen, ook offline). |
| **Zones** | Strip Mall → Pen Street ($2,5K) → Trading Floor ($60K) → Yacht ($1,5M). Een gouden krachtveld blokkeert elke zone tot je hem koopt. |
| **IPO** | Met $10M en de Yacht: alles resetten voor een permanente +×0,5 multiplier. |

### Easter eggs en events
- **Het servet**: soms verschijnt een gouden line: *"Write your name on this napkin for me."* Supply and demand.
- **The Wolf Speech**: elke 7 minuten sales ×2 voor iedereen en ×3 op de tradingvloer, met confetti en geldregen.
- **The Hum** (**H**): de borstklop-hum. Sales ×1,1 en ×1,25 als 3+ spelers tegelijk hummen.
- **Undercover FBI Agent**: gebruik je Pressure, Hype of Urgency, dan krijg je een boete. Blijf eerlijk en hij betaalt ×3.
- Een goudvis in de lobby, de Charging Pen Bull en het **Statue of Pen-erty** in de haven.
- Het leaderboard boven de avenue toont de rijkste spelers aller tijden (globaal, via OrderedDataStore).

## De map
Alles staat in `map/Map.model.json`, gegenereerd door `tools/build_map.py` (ongeveer 3.400 parts):

- **Long Island Strip Mall**: parkeerplaats, een winkelrij (Nail Salon, Pizza, Laundromat, Pawn) en het open
  **Investor Center** met oude computers en een whiteboard "SELL ME THIS PEN". Hier spawn je.
- **De brug**: een Brooklyn-achtige hangbrug met gotische torens en kabels.
- **Pen Street**: avenue met gele taxi's, de **Pen Stock Exchange** met zuilen, een gigantisch gouden
  pen-monument, de Charging Pen Bull, reclameschermen, een subway-ingang en scrollende koerstickers.
- **Stratton Oakpen**: glazen toren van 290 studs met een tradingvloer vol bureaus, monitoren en
  stoelen waarop je kunt zitten, een podium voor de speech en het glazen hoekkantoor van The Wolf.
- **Haven**: promenade, pier, speedboten en het jacht **NAOMI** met helikopter, bar, DJ-booth en hot tub.
- **Achtergrond**: skyline rondom, water (Terrain, gevuld bij het starten) en een zonsondergang met Future lighting.

De map aanpassen? Pas `tools/build_map.py` aan en draai `python3 tools/build_map.py`, of bewerk de map
gewoon in Studio. Houd de klantgebieden (`area`) in `src/shared/Config.luau` gelijk aan de map.

## Code-structuur

```
src/shared/   Config (alle getallen), PitchData (klanttypes + lines), Format
src/server/   DataService (opslag), EconomyService (geld, winkel, IPO, leaderstats),
              CustomerService (NPC's), PitchService (minigame, server-authoritative),
              WorldService (water, gates, speech, hum, leaderboard)
src/client/   Store, World (gates, prompts, tickers), UI/ (Theme, Hud, Shop, Modal, PitchUI, Notifier)
```

De server bepaalt alles: de client kiest alleen een line-index plus hoe goed de tonality was (0–1,
server-side begrensd). Uitbetalingen, meters en aankopen worden op de server berekend.

## Balans aanpassen
Alle prijzen, waardes, multipliers, timers en klantaantallen staan in `src/shared/Config.luau`.
Nieuwe verkooplines of klanttypes voeg je toe in `src/shared/PitchData.luau`.

## Ideeën voor later
- Geluid en muziek: de game gebruikt nu alleen een standaard Roblox-ping. Voeg eigen audio-ID's uit de
  Creator Store toe.
- Game passes (bijv. ×2 cash) en dev products.
- Kleding voor NPC's (Shirt/Pants-asset-ID's) in plaats van alleen body colors.
