# Chop Shop

En FiveM-resurs som lägger till en immersiv chop shop-upplevelse för både **kriminella** och **civila**, byggd på QBCore, OX-Inventory, OX-Target och OX-Lib.

## Funktioner

### 🔴 Kriminell väg
1. Prata med NPC:n **Skum Kontakt** för att få ett kontrakt på **3 fordon**.
2. Ett **Kontrakt**-item läggs i ditt inventory — kontrollera status via `visa kontrakt` hos NPC:n, eller använd itemet efter en krasch för att återställa progression.
3. Kontraktet listar fordonsmodellerna du ska hitta — de kör redan runt i staden (inga kartblips).
4. Hitta ett fordon som matchar kontraktet, stjäl det och kör till **Chop-zonen**.
5. Parkera och gå ur fordonet i zonen, använd sedan **OX-Target** för att demontera delar:
   - Förardörr
   - Passagerardörr
   - Vänster bakdörr (på 4-dörrars)
   - Höger bakdörr (på 4-dörrars)
   - Motorhuv
   - Bagagelucka
6. När alla relevanta delar är demonterade visas valet **Demontera ram** — slutför det för att despawna fordonet.
7. Kontakt-NPC:n spårar progression efter varje slutfört kontraktsfordon.
8. Om du kraschar mitt i kontraktet kan du **använda kontraktsitemet** för att återställa progression.
9. När alla fordon är klara, återvänd till NPC:n och **Lämna in** kontraktet för betalning.

### 🔵 Civil väg
1. Prata med **Bilskrotare** NPC för att få ett slumpmässigt fordon att demontera.
2. Fordonet spawnar nära NPC:n — kör det till **Chop-zonen**.
3. Demontera delar på samma sätt som den kriminella vägen.
4. Ramen ger en mindre bonusbetalning automatiskt.
5. Lämna in material hos NPC:n för att få pengar.

## Skill checks & animationer
- Varje demonteringssteg kräver ett **lib.skillCheck**-minispel (svårare på sista ramsteget).
- Animerade progress-cirklar visas under varje handling via `lib.progressCircle`.

## Beroenden
| Resource | Syfte |
|---|---|
| `qb-core` | Spelardata, pengafunktioner |
| `ox_inventory` | Itemhantering |
| `ox_target` | NPC- och fordonsinteraktion |
| `ox_lib` | Notifieringar, progress-cirklar, skill checks, zoner |

## OX Inventory-items
Lägg till följande items i OX Inventory `items.lua`:

```lua
['car_door'] = {
    label = 'Bildörr',
    weight = 8000,
    stack = true,
    close = true,
},
['car_hood'] = {
    label = 'Motorhuv',
    weight = 6000,
    stack = true,
    close = true,
},
['car_trunk_lid'] = {
    label = 'Bagagelucka',
    weight = 5000,
    stack = true,
    close = true,
},
['scrap_metal'] = {
    label = 'Skrotmetall',
    weight = 3000,
    stack = true,
    close = true,
},
['auto_parts'] = {
    label = 'Bildelar',
    weight = 2000,
    stack = true,
    close = true,
},
['chop_contract'] = {
    label = 'Fordonskontrakt',
    weight = 100,
    stack = false,
    close = true,
},
-- Betalningsitem (namn måste matcha Config.Items.money)
['money'] = {
    label = 'Pengar',
    weight = 500,
    stack = true,
    close = true,
},
-- Materialbelöningar från fordon
['rubber'] = {
    label = 'Gummi',
    weight = 300,
    stack = true,
    close = true,
},
['steel'] = {
    label = 'Stål',
    weight = 2000,
    stack = true,
    close = true,
},
['aluminum'] = {
    label = 'Aluminium',
    weight = 1500,
    stack = true,
    close = true,
},
['copper'] = {
    label = 'Koppar',
    weight = 1000,
    stack = true,
    close = true,
},
['plastic'] = {
    label = 'Plast',
    weight = 400,
    stack = true,
    close = true,
},
['glass'] = {
    label = 'Glas',
    weight = 800,
    stack = true,
    close = true,
},
```

## Konfiguration

Alla justerbara värden finns i `config.lua`:

| Sektion | Nyckel | Beskrivning |
|---|---|---|
| `Config.Criminal` | `vehicleCount` | Antal fordon per kontrakt (standard 3) |
| `Config.Criminal` | `cooldown` | Sekunder mellan nya kontrakt (standard 1800) |
| `Config.Criminal` | `minReward` / `maxReward` | Intervall för antal pengar-item vid kontraktsinlämning |
| `Config.Criminal` | `policeRequired` | Minsta antal poliser online för att få kontrakt |
| `Config.Civilian` | `cooldown` | Sekunder mellan civila jobb (standard 600) |
| `Config.Civilian` | `rewardPerPart` | Antal pengar-item per sålt material-item |
| `Config.Civilian` | `frameBonus` | Bonus i pengar-item för slutförd ramdemontering |
| `Config.Civilian` | `sellableParts` | Materialitems som kan säljas hos civil NPC |
| `Config.Items` | `money` | Itemnamn som används som betalning (nu `'money'`) |
| `Config.Items` | `chop_contract` | Item som ges när kontrakt utfärdas (återställning efter krasch) |
| `Config.MaterialRewards` | — | Pool av fordonsmaterial som kan delas ut slumpmässigt |
| `Config.NPCs` | — | Koordinater och pedmodeller för båda NPC:er |
| `Config.ChopZone` | — | Position, storlek och rotation för chop-zonen |
| `Config.ContractVehicles` | — | Pool med fordonsmodeller för kriminella kontrakt |
| `Config.CivilianVehicles` | — | Pool med fordon för civila jobb |
| `Config.StripParts` | — | Delar, items, tider och ikoner |
| `Config.Minigames` | — | Svårighetsnivåer och tangenter för skill checks |

## Språk
Svenska (`sv`) och engelska (`en`) finns inkluderat. Standardspråk är svenska via `Config.Locale = 'sv'`.

## Installation
1. Lägg mappen `chopshop` i din `resources`-katalog.
2. Lägg till `ensure chopshop` i `server.cfg` **efter** `qb-core`, `ox_inventory`, `ox_target` och `ox_lib`.
3. Lägg till items ovan i din OX Inventory-konfiguration.
4. Justera koordinater, belöningar och övriga värden i `config.lua` efter din server.
