# qb-boozebiz

A full **QBCore farm-to-shelf booze manufacturing resource** designed for immersive roleplay loops.

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
- Built with cooldowns and optional police requirement.

---

## Dependencies
- `qb-core`
- `ox_lib`
- `ox_inventory`
- `ox_target`
- `oxmysql`

## Installation
1. Copy `qb-boozebiz` into your server resources.
2. Add to your server cfg:
   ```cfg
   ensure qb-boozebiz
   ```
3. Restart the server.

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
```

## Configuration
Tune all behavior in `config.lua`:
- Progress durations
- Cooldowns
- Recipe inputs/outputs
- Harvest/process/store locations
- Payout range
- Police requirement
- Locale (`Config.Locale = 'en'`, `'sv'`, `'de'`, or `'es'`)

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
- You can add additional stores and production locations in `Config.StockZones` and `Config.ProcessingStations`.
