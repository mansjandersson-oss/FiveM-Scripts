# NB Destil

A full **QBCore farm-to-shelf distillery resource** designed for immersive roleplay loops.

### Features
- Ingredient collection from multiple world locations (grapes, barley, water, yeast, bottles, cardboard).
- Multi-stage production with dedicated mini-games:
  - Ferment mash route selection: grapes -> Wine Mash, barley -> Beer Mash
  - Distill with product selection + temperature/time profiles to produce Wine, Beer, Vodka, Gin, and Whiskey
  - Bottle liquor by timing your pour mini-game, then naming the bottle + setting purity
  - Pack crates carefully (failure can break bottles)
- Stock multiple liquor stores for bank payouts (with stocking mini-game).
- Uses **ox_target** for all interaction zones.
- Uses **ox_inventory** for item searching, removing, adding, metadata, and carry checks.
- Uses **React/Vite/Tailwind/shadcn-style NUI** for fermentation, distillation, and bottling setup.
- Built with cooldowns, server-side zone validation, optional police requirement, and NPC witness police alerts through `lb-tablet` for unlicensed production.

---

## Dependencies
- `qb-core`
- `ox_lib`
- `ox_inventory`
- `ox_target`
- `lb-tablet` (for dispatch alerts)

## Installation
1. Copy `nb-destil` into your server resources.
2. Build the NUI if you edited `web/src`:
   ```bash
   cd nb-destil/web
   npm install
   npm run build
   ```
3. Add to your server cfg:
   ```cfg
   ensure nb-destil
   ```
4. Restart the server.

## Item Setup
Add these items where your server defines item data (QBCore items table or ox inventory item definitions):

- `grape`
- `barley`
- `yeast`
- `spring_water`
- `wine_mash`
- `beer_mash`
- `distilled_spirit`
- `empty_bottle`
- `cardboard`
- `bottled_liquor`
- `liquor_crate`
- `destileringstillstand`

### Example `items.lua` snippet
```lua
['grape'] = { name = 'grape', label = 'Grapes', weight = 100, type = 'item', image = 'grape.png', unique = false, useable = false, shouldClose = true, description = 'Freshly harvested grapes' },
['barley'] = { name = 'barley', label = 'Barley', weight = 100, type = 'item', image = 'barley.png', unique = false, useable = false, shouldClose = true, description = 'Raw barley stalks' },
['yeast'] = { name = 'yeast', label = 'Yeast', weight = 50, type = 'item', image = 'yeast.png', unique = false, useable = false, shouldClose = true, description = 'Fermentation yeast' },
['spring_water'] = { name = 'spring_water', label = 'Spring Water', weight = 100, type = 'item', image = 'water.png', unique = false, useable = false, shouldClose = true, description = 'Clean spring water' },
['wine_mash'] = { name = 'wine_mash', label = 'Wine Mash', weight = 300, type = 'item', image = 'mash.png', unique = false, useable = false, shouldClose = true, description = 'Grape mash ready for distillation' },
['beer_mash'] = { name = 'beer_mash', label = 'Beer Mash', weight = 300, type = 'item', image = 'mash.png', unique = false, useable = false, shouldClose = true, description = 'Barley mash ready for distillation' },
['distilled_spirit'] = { name = 'distilled_spirit', label = 'Distilled Spirit', weight = 200, type = 'item', image = 'spirit.png', unique = false, useable = false, shouldClose = true, description = 'High-proof spirit' },
['empty_bottle'] = { name = 'empty_bottle', label = 'Empty Bottle', weight = 100, type = 'item', image = 'empty_bottle.png', unique = false, useable = false, shouldClose = true, description = 'Bottle for packaging' },
['cardboard'] = { name = 'cardboard', label = 'Cardboard', weight = 100, type = 'item', image = 'cardboard.png', unique = false, useable = false, shouldClose = true, description = 'Used to pack crates' },
['bottled_liquor'] = { name = 'bottled_liquor', label = 'Bottled Liquor', weight = 200, type = 'item', image = 'liquor.png', unique = false, useable = false, shouldClose = true, description = 'Finished liquor bottle' },
['liquor_crate'] = { name = 'liquor_crate', label = 'Liquor Crate', weight = 1200, type = 'item', image = 'crate.png', unique = false, useable = false, shouldClose = true, description = 'Packed crate ready for stocking' },
['destileringstillstand'] = { name = 'destileringstillstand', label = 'Destileringstillstånd', weight = 10, type = 'item', image = 'license.png', unique = true, useable = false, shouldClose = true, description = 'Tillstånd för laglig destillering' },
```


## Item Pictures
Binary item images are not committed (to avoid PR binary-file limitations).

Generate item images locally:
```bash
python nb-destil/scripts/generate_item_icons.py
```

This creates all required files in `nb-destil/assets/items/`:
- `grape.png`
- `barley.png`
- `yeast.png`
- `water.png`
- `mash.png`
- `spirit.png`
- `empty_bottle.png`
- `cardboard.png`
- `liquor.png`
- `crate.png`

Copy those files into your inventory image folder (for example `qb-inventory/html/images/` or your ox inventory image path).

## Configuration
Tune all behavior in `config.lua`:
- Progress durations
- Cooldowns
- Recipe inputs/outputs
- Harvest/process/store locations
- Payout range
- Police requirement
- Police alert behavior (`Config.PoliceAlert`), including `lb-tablet` dispatch settings, required permit item, police jobs, NPC witness radius/FOV, blip settings, and alert cooldown
- Server-side distance validation (`Config.Security`)
- Locale (`Config.Locale = 'en'`, `'sv'`, `'de'`, or `'es'`)

## Author
- Primary author for ongoing changes: **VikingStickarn**

## Language support
- Translations are separated into `locales/locale.lua`.
- Included locales: English (`en`), Swedish (`sv`), German (`de`), and Spanish (`es`).
- Set `Config.Locale` in `config.lua` to choose language (for Swedish use `sv`).

## Notes
- Bottled liquor receives metadata (`bottleName`, `purity`, `label`) via `ox_inventory`.
- Bottles stack naturally when they share the exact same `bottleName` and `purity` metadata.
- Every major interaction now includes a mini-game (`Config.Minigames`) to make progression more skill-based.
- Fermentation route now determines mash output: **grape => Wine Mash**, **barley => Beer Mash**.
- Distillation supports product-targeted outputs: **Wine, Beer, Vodka, Gin, Whiskey**.
- Temp/time must match the selected product profile to succeed.
- If fermentation temperature is pushed too high, there is a configurable chance of a vat explosion that damages players within 5m.
- Failing the packing mini-game can break bottled liquor from the player inventory.
- If a player manufactures without `Config.PoliceAlert.PermitItem`, police only receive an `lb-tablet` dispatch with the text `Ser en person vid en hembränningsapparat` when a nearby NPC can see the player.
- You can add additional stores and production locations in `Config.StockZones` and `Config.ProcessingStations`.
