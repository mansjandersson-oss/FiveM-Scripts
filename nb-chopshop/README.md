# NB Chopshop

En kriminell FiveM chopshop-resurs för QBCore där spelare får kontrakt på fordon som redan finns ute på gatorna. Inga kontraktsbilar spawnas av scriptet.

## Funktioner

- Kriminell-only access via `Config.RoleCheckExport` eller fallback i `Config.CriminalAccess`.
- Kontrakt med slumpade fordonsmodeller från `Config.ContractVehicles`.
- Spelaren måste hitta matchande gatubilar, köra dem till chopzonen och demontera dem.
- React/Vite/Tailwind/shadcn NUI visar aktivt kontrakt och progress.
- Debugläge i `Config.DebugOptions` för att felsöka utan externa role exports.

## Installation

1. Lägg mappen `nb-chopshop` i din `resources`-katalog.
2. Lägg till `ensure nb-chopshop` i `server.cfg` efter `qb-core`, `ox_inventory`, `ox_target` och `ox_lib`.
3. Lägg till items som matchar `Config.Items` och `Config.MaterialRewards` i ditt inventory.
4. Justera kriminella jobb/gäng i `Config.CriminalAccess`.

## Debug

Sätt detta i `config.lua`:

```lua
Config.Debug = true
```

Med standardvärdena i `Config.DebugOptions` bypassas role-check, cooldown och poliskrav medan extra loggar skrivs i server console/F8.
