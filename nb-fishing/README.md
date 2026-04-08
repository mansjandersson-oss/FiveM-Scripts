# nb-fishing

Ett fullt konfigurerbart fiskescript för QBCore med:

- **Stardew Valley-inspirerat fiskeminispel** (vertikal fiskrörelse + spelarkontrollerad fångstbar)
- **Persistent progression** med nivåer och XP
- **Skillträd** med uppgraderingsbara bonusar
- **Server-topplista** (`/fishlb`) sorterad på XP
- **Turneringssystem** med återkommande event och belöningar
- **Fisk-tiers + storlek + vikt-metadata** med dynamisk försäljning
- **Config-first upplägg** för zoner, arter, belöningar och svårighetsgrad

## Krav

- `qb-core`
- `ox_lib`
- `ox_target`
- `ox_inventory`
- `oxmysql`

## Installation

1. Kopiera mappen till din resources-katalog.
2. Importera `fishing_progress.sql`.
3. Lägg till i `server.cfg`:

```cfg
ensure nb-fishing
```

4. Lägg till fisk- och verktygsitems i ditt inventory (exempel-id:n som används i scriptet):

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

## Kommandon

- Använd item `fishing_rod` — starta fiske i närmaste zon
- `/fishskills` — öppna skillträd
- Sälj fisk via target på Fiskhandlare-NPC
- `/fishlb` — öppna fiske-topplista
- `/fishadmin_start_tourney` — starta turnering manuellt (admin)

## Anpassning

Allt styrs i `config.lua` och `skilltree.lua`:

- Lägg till/ta bort zoner och fiskarter
- Justera rarity, tier, pris, XP, min/max-vikt och svårighetsgrad per fisk
- Justera fysikvärden för minispel globalt
- Anpassa skills, maxnivåer och effekter
- Konfigurera turneringars intervall, längd och belöningar

## Noteringar

- Fiske startar genom att använda fiskespö-item.
- Fisk säljs via target-NPC (`Config.SellNPC`).
- Fisk lagras med metadata (`tier`, `size`, `weight`, `quality`, `zone`, tidstämpel) och säljs med tier-/storleksmultiplikatorer.
- Spö-hållbarhet börjar på 100 användningar (2 tapp vid fångst, 7 tapp vid flykt, reduceras av skillen Spövård).
- Chans för sällsynta arter påverkas av skillträdet.
