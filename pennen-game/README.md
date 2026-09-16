# Sell Me This Pen — Roblox simulator

Een simulator in de stijl van *Sell Lemons*, maar met pennen: je maakt pennen bij de
pennenpers, sleept ze naar de balie en verkoopt ze aan een klant die steeds roept
"Sell me this pen!". Elke klant betaalt een andere multiplier, dus wanneer je verkoopt
maakt uit. Met het geld koop je upgrades, en met een rebirth speel je een duurdere pen vrij.

## Hoe het speelt

| plek | wat er gebeurt |
|---|---|
| **Pennenpers** (blauwe plaat) | zolang je erop staat maak je pennen, tot je tas vol is |
| **Verkoopbalie** (groene plaat) | verkoopt je hele tas aan de klant die er staat |
| **Kiosk** (gele platen) | upgrade kopen; blijf staan om te blijven kopen |
| **Rebirth** (paarse plaat) | 2 seconden blijven staan = rebirth |

Upgrades: **grotere tas**, **snellere pers**, **verkooppraatje** (hogere prijs) en
**snellere schoenen**. Rebirth kost geld, zet je pennen op 0, maar geeft +75% verkoopprijs
per rebirth en speelt de volgende pen vrij: balpen → gelpen → marker → vulpen →
zilveren → gouden → diamanten → sterrenpen.

De map wordt met code gebouwd, dus je hoeft in Studio niets te bouwen. Je begint met een leeg
Baseplate en drukt op Play.

## Bestanden

| bestand | wat |
|---|---|
| `src/shared/Config.luau` | **alle balans**: pennen, prijzen, upgrades, rebirth, klanten |
| `src/shared/Net.luau` | de RemoteEvents tussen server en client |
| `src/server/init.server.luau` | startpunt op de server |
| `src/server/Game.luau` | spelregels: maken, verkopen, upgraden, rebirthen |
| `src/server/World.luau` | bouwt de map (vloer, pers, balie, kiosk, rebirth) |
| `src/server/Customers.luau` | de klant achter de balie en zijn multiplier |
| `src/server/Data.luau` | opslaan/laden via DataStore, met autosave |
| `src/client/init.client.luau` | de hele interface |
| `dist/*.lua` | de gebundelde versie om te plakken (gegenereerd) |
| `tools/bundle.py` | maakt `dist/` opnieuw na een wijziging in `src/` |
| `default.project.json` | Rojo-project |

Balans aanpassen doe je in `src/shared/Config.luau`, daarna `python3 tools/bundle.py`.

## In Roblox krijgen — manier A: plakken (geen tools nodig)

1. Open **Roblox Studio** → **New** → **Baseplate**.
2. In de Explorer: rechtermuisknop op **ServerScriptService** → *Insert Object* → **Script**.
   Verwijder de voorbeeldregel en plak de hele inhoud van `dist/ServerBundle.server.lua`.
3. Rechtermuisknop op **StarterPlayer → StarterPlayerScripts** → *Insert Object* →
   **LocalScript**. Plak daar de hele inhoud van `dist/ClientBundle.client.lua`.
4. **File → Game Settings → Security** → zet **Enable Studio Access to API Services** aan
   (anders slaat je voortgang in Studio niet op).
5. Druk op **Play**. De map bouwt zichzelf.
6. **File → Publish to Roblox** → nieuwe ervaring aanmaken.
7. Op [create.roblox.com](https://create.roblox.com) → je ervaring → **Configure →
   Places/Permissions** → zet hem op **Public** zodat anderen kunnen spelen.

## In Roblox krijgen — manier B: Rojo (fijner om door te ontwikkelen)

1. Installeer [Rojo](https://rojo.space) (`cargo install rojo` of via Aftman/Rokit) en de
   **Rojo-plugin** in Studio.
2. In deze map: `rojo serve`
3. In Studio: Rojo-plugin → **Connect**. Alles wordt automatisch op de juiste plek gezet.
4. Publiceren zoals bij stap 4–7 hierboven.

## Wat ik van jou nodig heb

Ik kan hier geen Roblox Studio draaien en niet publiceren — dat laatste stukje moet jij doen
(of je geeft me de toegang hieronder). Dit is wat er nodig is:

**Sowieso nodig (jij, eenmalig, 10 minuten):**
- Een **Roblox-account** (gratis). Voor de Creator Dashboard hoort je account geverifieerd
  te zijn (e-mail) — anders kun je niet publiceren.
- **Roblox Studio** op een Windows-pc of Mac. Draait niet op mobiel/Linux, en ik kan het
  hier ook niet draaien.
- Eén keer **Publish to Roblox** doen, en in Game Settings de ervaring op **Public** zetten.
- **Enable Studio Access to API Services** aanzetten (voor opslaan van voortgang).

**Alleen nodig als je bepaalde dingen wilt:**
- **Robux** — alleen als je wilt adverteren of een thumbnail/icon wilt uploaden via betaalde
  Sponsored Ads. Spelen en publiceren is gratis.
- **Roblox-groep** (gratis aan te maken) — als de game op naam van een groep moet staan,
  bijvoorbeeld om later inkomsten te delen of met meer mensen te beheren.
- **Gamepasses / developer products** (betaalde extra's zoals "x2 geld" of "VIP-tas") —
  die maak je aan op het Creator Dashboard; ik bouw de code ernaartoe als je de ID's geeft.
- **Open Cloud API-key** (Creator Dashboard → Open Cloud → API Keys) — dan kan ik vanaf hier
  plaatsbestanden publiceren en DataStores uitlezen zonder dat jij Studio opent. Alleen doen
  als je dat wilt; deel zo'n sleutel dan via de omgevingsinstellingen en niet in de chat.
- **Modellen/geluiden uit de Toolbox** — wil je echte pennen-modellen in plaats van de
  simpele blokken, dan heb ik de asset-ID's nodig (of ik houd het bij code-geometrie).

**Wat ik NIET nodig heb:** je Roblox-wachtwoord, je .ROBLOSECURITY-cookie of toegang tot je
account. Vraag daar nooit iemand om, ook mij niet.
