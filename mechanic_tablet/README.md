# mechanic_tablet

Detta resource lägger till en NUI-surfplatta som fungerar som en enkel webbläsare i spelet.

## Installation

1. Lägg mappen `mechanic_tablet` i din resources-katalog.
2. Lägg till `ensure mechanic_tablet` i din `server.cfg`.
3. Starta om servern eller resourcen.

## Lägg in item manuellt (ox_inventory)

Lägg in detta i `ox_inventory/data/items.lua` (inne i `return { ... }`):

```lua
['surfplatta_mekaniker'] = {
    label = 'Surfplatta Mekaniker',
    weight = 650,
    stack = false,
    consume = 0,
    client = {
        export = 'mechanic_tablet.useMechanicTablet'
    }
},
```

## Funktioner

När itemet används öppnas surfplattan med startsidan:

- `https://bennysnewbridge.page.gd/`

Webbläsaren har:

- Bakåt
- Framåt
- Ladda om
- Hem-knapp
- Adressfält (skriv valfri URL och tryck Enter eller **Gå**)

## Stäng surfplattan

- Klicka på `✕`
- Tryck `ESC`
- Eller kör kommandot `/stangmekplatta`

## Viktigt

Vissa hemsidor blockerar inbäddning i `iframe` (t.ex. via `X-Frame-Options` / `CSP`).
Om en sida inte visas är det en begränsning från sidan själv, inte från scriptet.
