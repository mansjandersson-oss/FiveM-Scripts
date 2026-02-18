# Item icons

Binary icon files are **not committed** to keep pull requests text-only.

Generate all required item PNGs locally with:

```bash
python qb-boozebiz/scripts/generate_item_icons.py
```

This creates:
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

Then copy them into your inventory image path (for example `qb-inventory/html/images/`).
