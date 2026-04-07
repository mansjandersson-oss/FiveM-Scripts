# nb-fishing

A fully customizable QBCore fishing resource featuring:

- **Stardew Valley-inspired fishing minigame** (vertical fish movement + player-controlled catch bar)
- **Persistent progression** with levels and XP
- **Skill tree** with unlockable bonuses
- **Server leaderboard** (`/fishlb`) ranking by XP
- **Tournament system** with periodic events and rewards
- **Fish tiers + sizes + weights** metadata with dynamic sell values
- **Config-first design** for zones, species, rewards, and difficulty

## Requirements

- `qb-core`
- `ox_lib`
- `ox_target`
- `ox_inventory`
- `oxmysql`

## Installation

1. Copy folder to your resources directory.
2. Import `fishing_progress.sql`.
3. Add to `server.cfg`:

```cfg
ensure nb-fishing
```

4. Add fish + tool items to your inventory item list (example ids used in this script):

- `fishing_rod`
- `fishing_bait`
- `anchovy`
- `mackerel`
- `sea_bass`
- `squid`
- `golden_tuna`
- `perch`
- `pike`
- `salmon`
- `sturgeon`
- `mythic_carp`

## Commands

- Use `fishing_rod` item — cast line in nearby configured zone
- `/fishskills` — open skill tree UI
- Sell fish by targeting the Fish Merchant NPC
- `/fishlb` — open fishing leaderboard
- `/fishadmin_start_tourney` — force start tournament (admin)

## Customization

Everything is configured in `config.lua` and `skilltree.lua`:

- Add/remove zones and fish species.
- Tune rarity, tiers, prices, XP, min/max weights, and minigame difficulty per fish.
- Adjust minigame physics values globally.
- Configure skill perks and max levels.
- Configure tournament frequency, duration, and payout.

## Notes

- Fishing starts by using the fishing rod item (server-side useable item).
- Fish are sold through a target-enabled merchant NPC configured in `Config.SellNPC`.
- Fish are stored with metadata (`tier`, `size`, `weight`, `quality`, `zone`, timestamp) and sold dynamically with tier/size multipliers.
- Rod durability is reduced per attempt and affected by skill bonuses.
- Rare species probabilities are affected by skill tree bonuses.
