# nb-hunting

Ett fullstack jakt-script för QBCore med dynamiska djur, levelsystem, uppdrag, butik, säljsystem, bait/calls, leaderboard, Discord-logs och exports/events.

## Features
- **Dynamic Hunting**: Konfigurerbara djur per zon med individuell XP + loot.
- **Level System**: Levels baserat på XP med krav för vapen, butik och progression.
- **Hunting License**: Valbar jaktlicens innan funktioner låses upp.
- **Hunter NPC + HTML UI**: NPC med modern HTML-meny i jaktstuga-stil för rutter, uppdrag och leaderboard.
- **Hunting Zones**: Djur spawna i definierade zoner med habitat-beteende.
- **Hunting Shop / Selling**: Sälj med levelbegränsning, jaktutrustning hämtas gratis via NPC-menyn.
- **Animal Baits**: Åtel drar närliggande djur till positionen.
- **Animal Calls**: Markerar kompatibla djur på kartan.
- **Animal Habitat & Behavior**: Djur flyr/attackerar beroende på avstånd och stealth.
- **Missions**: Uppdrag med mål, pengar och XP.
- **Cutting Weapons**: Vapenkrav och reward multipliers vid styckning.
- **Cutting Types**: Stöd i config för keybind/melee/third-eye (ox_target).
- **Highly Configurable**: Nästan allt ligger i `config.lua`.
- **Discord Logs**: Webhook-stöd för viktiga handlingar.
- **Exports & Events**: Enkla integrationspunkter för andra scripts.
- **Fully Translatable**: Locale-system med fallback.
- **Fully Synced**: Nätverkade djur för delad upplevelse.

## Installation
1. Lägg mappen `nb-hunting` i resources.
2. Kör SQL-filen `hunter_progress.sql`.
3. Lägg till i `server.cfg`:
   ```cfg
   ensure nb-hunting
   ```
4. Säkerställ dependencies:
   - qb-core
   - ox_lib
   - ox_target
   - ox_inventory
   - oxmysql

## Exports
- `exports['nb-hunting']:GetHunterLevel(source)`
- `exports['nb-hunting']:GetHunterXP(source)`

## Viktiga events
### Client
- `nb-hunting:client:openHunterMenu`
- `nb-hunting:client:cutAnimal`

### Server
- `nb-hunting:server:registerKill`
- `nb-hunting:server:cutAnimal`
- `nb-hunting:server:startMission`
- `nb-hunting:server:sellItem`

## Konfiguration
Använd `config.lua` för att styra:
- Zoner, djur, spawn rate, max alive
- XP/level trösklar
- Missioner
- Utrustningsuttag i zon + automatisk borttagning utanför jaktområde
- Butik/sälj priser och levelkrav
- Vapenkrav och styckningsmultipliers
- Discord webhook
- Språk

