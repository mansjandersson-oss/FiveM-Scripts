# interactive_carheist

Interaktivt FiveM/QBCore-uppdrag:

1. Spelaren pratar med en NPC och accepterar uppdraget.
2. En bil markeras på GPS som ska stjälas.
3. När spelaren kapar bilen startas en dekryptering (10 minuter).
4. Under färden skickas GPS-ping till polis med jämna intervall.
5. När dekrypteringen är klar levereras bilen vid polisstationen för belöning.

## Krav

- `qb-core`
- `ox_lib`
- `ox_target`

## Installation

1. Lägg mappen `interactive_carheist` i din resources-katalog.
2. Lägg till i `server.cfg`:

```cfg
ensure interactive_carheist
```

3. Justera koordinater, bilar, belöning och tider i `config.lua`.
