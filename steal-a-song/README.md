# Steal A Song

Een Roblox-game in het "Steal a …"-genre: je koopt songs die over de rode
loper voorbij zweven, zet ze in je studio en verdient elke seconde geld. Hoe
meer streams een song heeft, hoe beter hij is. Andere spelers kunnen je songs
stelen, en jij kunt die van hen stelen.

De hele game staat in code: de map, de modellen en de interface worden bij het
starten gebouwd. Er zijn geen losse modellen of assets nodig.

## Openen en spelen

**Snel:** open `StealASong.rbxlx` in Roblox Studio en druk op **Play**. Wil je
met meerdere spelers testen, kies dan in het tabblad *Test* voor *Clients and
Servers* met 2 of 3 spelers.

**Met Rojo** (als je de code in een editor wilt aanpassen):

```sh
rojo serve          # daarna in Studio de Rojo-plugin koppelen
rojo build -o StealASong.rbxlx   # of een nieuwe place bouwen
```

### Voor je publiceert

1. *Game Settings → Security → Enable Studio Access to API Services* aanzetten.
   Zonder deze instelling slaat de game niets op. Je ziet dan in-game de melding
   "Saving is off", maar verder werkt alles.
2. *Game Settings → Places → Max Players* op **8** zetten, want er zijn 8 studio's.
3. Optioneel kun je game passes aanmaken op create.roblox.com en de ID's invullen
   in `Config.GamePasses`. Er verschijnt dan een 💎 Store-knop.
4. Optioneel kun je achtergrondmuziek toevoegen: zet een `rbxassetid://…` van
   een track met licentie in `Config.MusicId`.

## Hoe het werkt

1. **De rode loper.** Elke 2,2 seconden verschijnt er een song bij *NEW DROPS*.
   Hij zweeft langzaam naar *OLD NEWS*. Wie als eerste op **E** drukt en genoeg
   geld heeft, krijgt hem. De song vliegt dan in een boog je studio in.
2. **Streams = kwaliteit.** Een song verdient $0,001 per stream per seconde,
   dus 1M streams levert $1K/s op. De prijs is inkomen × terugverdientijd, en
   die terugverdientijd wordt langer naarmate de song zeldzamer is.
3. **Songs groeien.** Zolang een song in je studio staat, krijgt hij er streams
   bij: 3% per minuut, tot 3× zijn startaantal (🔥 = piek bereikt). Hoe langer
   je een song hebt, hoe waardevoller hij wordt, en hoe interessanter om te
   stelen.
4. **Geld ophalen.** Inkomen stapelt zich op bij elke pedestal. Loop over het
   groene pad ervoor om het op te halen.
5. **Stelen.** Houd **E** ingedrukt bij de song van een ander. Je draagt hem
   dan boven je hoofd, loopt 20% langzamer en een lichtstraal wijst naar je
   studio. Kom je binnen, dan is hij van jou.
6. **Verdedigen.**
   - Je krijgt een alarm met rode randen zodra iemand steelt.
   - Met je 🎸 gitaar mep je de dief weg. Hij laat de song vallen en die vliegt
     terug.
   - De rode knop in je studio zet een laserpoort aan (60 s, langer met
     upgrades). Wie binnen staat wordt eruit gezet, en een dief verliest zijn
     buit.
7. **Verkopen.** Houd **F** ingedrukt bij je eigen song. Je krijgt 50% van de
   prijs.

### Wat je blijft terugbrengen

| haak | wat |
|---|---|
| Zeldzaamheden | Common → Rare → Epic → Legendary → Mythic → **Chart God** → **Secret** (1 op ~8.300 drops) |
| Mutaties | Gold ×2, Platinum ×3, Diamond ×5, **Viral** ×10 (regenboog) |
| Aankondigingen | iedereen ziet het als er een Legendary of beter dropt, gekocht of gestolen wordt |
| LIVE CHART | bord boven de loper met de 10 songs met de meeste streams in de server, plus eigenaar: een doelwittenlijst |
| Server-events | elke 6–9 min, 2,5 min lang: Concert Night (nacht, mutaties ×4), Label Frenzy (2× drops), Viral Hour (Epic+ ×3), Double Royalties (2× geld) |
| Rebirth | +50% inkomen voor altijd, +2 plekken (8 → max 20); je **beste song blijft** |
| Upgrades | Sneakers (snelheid), Laser Lock (langer slot), Promo Team (snellere groei, hogere piek) |
| Index | verzamel alle 25 songs en mutaties; elke volle zeldzaamheid geeft +10% inkomen |
| Playtime-cadeaus | na 1, 3, 5, 10, 15, 25, 40 en 60 min, met onder andere een Legendary na 40 min en een Mythic na 60 min |
| Daily streak | 7 dagen op rij, dag 7 is een Legendary |
| Offline | je songs verdienen 20% door terwijl je weg bent (max 4 uur) |
| Vrienden | +10% inkomen per vriend in de server (max +50%) |
| Leaderboard | all-time top 10 op totaal verdiend geld |

Alle songs hebben verzonnen namen zoals *Kazoo Solo*, *Trap Goblin* en *Eternal
#1*. Echte songtitels en artiesten zouden problemen geven met auteursrecht en de
regels van Roblox.

## Testcommando's

In Studio (of als maker van de game) kun je in de chat typen:

| commando | doet |
|---|---|
| `!cash 1e9` | geld erbij |
| `!event ConcertNight` | event starten (zonder naam: willekeurig) |
| `!drop secret viral` | song op de loper zetten |
| `!give mythic` | song direct in je studio |

## Aanpassen

Bijna alles wat je wilt tunen staat in `src/shared/Config.luau`: prijzen,
kansen, groei, lock-tijd, cadeaus, events, kleuren en geluiden. De songs zelf
staan in `src/shared/Songs.luau`. Een nieuwe song toevoegen is één regel.

## Bestanden

| bestand | wat |
|---|---|
| `StealASong.rbxlx` | de gebouwde place, direct te openen in Studio |
| `default.project.json` | Rojo-project |
| `src/shared/Config.luau` | alle instellingen |
| `src/shared/Songs.luau` | de 25 songs |
| `src/shared/Economy.luau` | rekenregels: inkomen, prijzen, kansen, groei |
| `src/shared/Format.luau` | 1.23M, $4.5K/s, 1:30 |
| `src/server/init.server.luau` | start alles en regelt joinen/vertrekken |
| `src/server/MapBuilder.luau` | bouwt de wereld |
| `src/server/SongModel.luau` | het 3D-model van een song |
| `src/server/Plots.luau` | studio's, pedestals, inkomen, ophalen, verkopen, lock |
| `src/server/Conveyor.luau` | de rode loper en kopen |
| `src/server/Stealing.luau` | stelen, dragen, laten vallen |
| `src/server/Combat.luau` | de gitaar |
| `src/server/Progression.luau` | upgrades en rebirth |
| `src/server/Rewards.luau` | cadeaus, daily, offline |
| `src/server/Events.luau` | server-events |
| `src/server/Boards.luau` | LIVE CHART en leaderboard |
| `src/server/PlayerData.luau` | opslaan en laden, multipliers |
| `src/server/Monetization.luau` | game passes |
| `src/server/DevCommands.luau` | testcommando's |
| `src/client/` | interface (HUD, vensters) en effecten (draaiende platen, straal, knockback) |
| `tests/` | testharnas en tests |

## Tests

Met [Lune](https://github.com/lune-org/lune) en Rojo geïnstalleerd:

```sh
lune run tests/run
```

Dit bouwt de place en test de rekenregels. Daarna speelt het een hele sessie na
met twee spelers: kopen, ophalen, stelen, slaan, locken, verkopen, upgrades,
cadeaus, rebirth, opslaan en opnieuw joinen. Ook de interface wordt gebouwd en
elk venster geopend. Lune controleert daarbij elke eigenschap die de code zet
tegen de Roblox-API.

## Nog niet in Studio gezien

De code is getest buiten Roblox, niet in Studio zelf. Een paar dingen zijn
daarom nog een gok:

- **Hoe de gitaar in de hand ligt.** De grip-instellingen komen van het klassieke
  zwaard. Als hij scheef zit, pas dan `GripPos` en de `Grip*`-vectoren aan in
  `Combat.luau`.
- **Geluiden.** Dit zijn ingebouwde `rbxasset://sounds/…`-bestanden. Laadt er
  een niet, dan zie je alleen een waarschuwing. Vervang ze gerust in
  `Config.Sounds`.
