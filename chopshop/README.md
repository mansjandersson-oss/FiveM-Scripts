# Chop Shop

A FiveM resource that adds an immersive chop-shop experience for both **criminals** and **civilians**, built on top of QBCore, OX-Inventory, OX-Target and OX-Lib.

## Features

### 🔴 Criminal Route
1. Talk to the **Shady Contact** NPC to receive a contract for **3 vehicles**.
2. Contract vehicles spawn at randomised locations on the map — blips appear on the minimap.
3. Break in, steal and drive each vehicle to the **Chop Zone**.
4. Park and exit the vehicle inside the zone, then use **OX-Target** to strip each part:
   - Driver Door
   - Passenger Door
   - Hood
   - Trunk Lid
5. Once all parts are removed, the **Strip Frame** option appears — complete it to despawn the vehicle.
6. The contact NPC tracks your progress after each vehicle is finished.
7. Return to the NPC when all vehicles are done and **Turn In** the contract for a cash reward.

### 🔵 Civilian Route
1. Talk to the **Auto Dismantler** NPC to receive a random vehicle to dismantle.
2. The vehicle spawns near the NPC — drive it to the **Chop Zone**.
3. Strip all parts (same process as criminal). Each part gives `auto_parts` items instead of the individual part items.
4. Stripping the frame awards a small bonus cash payment automatically.
5. Return to the NPC and **Turn In Auto Parts** to exchange them for cash.

## Skill Checks & Animations
- Every strip action requires a **lib.skillCheck** minigame (difficulty increases for the final frame strip).
- Animated progress bars play during each action using `lib.progressCircle`.

## Dependencies
| Resource | Purpose |
|---|---|
| `qb-core` | Player data, money functions |
| `ox_inventory` | Item management |
| `ox_target` | NPC & vehicle interaction |
| `ox_lib` | Notifications, progress circles, skill checks, zones |

## OX Inventory Items
Add the following items to your OX Inventory `items.lua`:

```lua
['car_door'] = {
    label = 'Car Door',
    weight = 8000,
    stack = true,
    close = true,
},
['car_hood'] = {
    label = 'Car Hood',
    weight = 6000,
    stack = true,
    close = true,
},
['car_trunk_lid'] = {
    label = 'Trunk Lid',
    weight = 5000,
    stack = true,
    close = true,
},
['scrap_metal'] = {
    label = 'Scrap Metal',
    weight = 3000,
    stack = true,
    close = true,
},
['auto_parts'] = {
    label = 'Auto Parts',
    weight = 2000,
    stack = true,
    close = true,
},
```

## Configuration

All tuneable values are in `config.lua`:

| Section | Key | Description |
|---|---|---|
| `Config.Criminal` | `vehicleCount` | Number of vehicles per contract (default 3) |
| `Config.Criminal` | `cooldown` | Seconds between new contracts (default 1800) |
| `Config.Criminal` | `minReward` / `maxReward` | Cash range for a completed contract |
| `Config.Criminal` | `policeRequired` | Minimum police online to get a contract |
| `Config.Civilian` | `cooldown` | Seconds between civilian jobs (default 600) |
| `Config.Civilian` | `rewardPerPart` | Cash per `auto_parts` item turned in |
| `Config.Civilian` | `frameBonus` | Bonus cash for completing the frame strip |
| `Config.NPCs` | — | Coords and ped models for both NPCs |
| `Config.ChopZone` | — | Location, size and rotation of the chop area |
| `Config.ContractVehicles` | — | Pool of vehicle models for criminal contracts |
| `Config.ContractSpawnPoints` | — | Map positions where contract vehicles spawn |
| `Config.CivilianVehicles` | — | Pool of vehicles handed out to civilians |
| `Config.StripParts` | — | Parts, items, durations and icons |
| `Config.Minigames` | — | Skill-check difficulty stages and keys |

## Locales
English (`en`) and Swedish (`sv`) are included. Add new locales in `locales/locale.lua` following the existing pattern.

## Installation
1. Drop the `chopshop` folder into your `resources` directory.
2. Add `ensure chopshop` to your `server.cfg` **after** `qb-core`, `ox_inventory`, `ox_target` and `ox_lib`.
3. Add the items listed above to your OX Inventory configuration.
4. Adjust coordinates and reward values in `config.lua` for your server.
