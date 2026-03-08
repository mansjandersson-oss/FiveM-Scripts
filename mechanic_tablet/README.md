# mechanic_tablet

Detta resource lägger till stöd för itemet **Surfplatta Mekaniker** i `ox_inventory`.

## Installation

1. Säkerställ att resourcemappen `mechanic_tablet` ligger i din resources-katalog.
2. Lägg till `ensure mechanic_tablet` i din `server.cfg`.
3. Starta om servern eller resourcen.

## Item

Itemet är definierat i `ox_inventory/data/items.lua` som:

- namn: `surfplatta_mekaniker`
- label: `Surfplatta Mekaniker`

När itemet används öppnas en NUI-surfplatta som visar:

- https://bennysnewbridge.page.gd/

## Stäng surfplattan

- Klicka på `X` i hörnet, eller
- Tryck `ESC`, eller
- Kör kommandot `/stangmekplatta`.
