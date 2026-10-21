# Spell Cost Tracker

A RuneScape 3 plugin that keeps track of how much your spells cost in runes, priced from the Grand Exchange.

## Tracked spells

| Spell | Runes per cast |
|---|---|
| Lord of Bones | 8 Spirit, 6 Bone, 2 Flesh, 1 Miasma |
| Animate Dead | 30 Earth, 15 Death, 15 Blood, 6 Soul |
| Vampyrism | 40 Fire, 10 Death, 15 Blood, 6 Soul |
| Penance | 30 Body, 20 Chaos, 3 Law, 10 Soul |
| Darkness | 40 Spirit, 20 Bone, 10 Flesh, 5 Miasma |

Rune costs are from the RuneScape Wiki and live in `src/config.lua`.

## Features

- Counts casts, runes used and their cost for each spell.
- Prices each cast when it happens, using the average of the latest high and low Grand Exchange price. If a price isn't available, a fallback price from `src/config.lua` is used and the cost is marked as estimated.
- Keeps the totals when the plugin or the game is restarted.
- A movable window with the totals, opened from the plugin's page.
- Settings on the plugin's page:
  - **Only track Lord of Bones stalls**: only counts Lord of Bones casts made without Necromancy gear on.
  - What the window shows: cast count, rune count, cost per spell and total cost.
  - Which spells the window shows.

## Dependencies

- gepl (GE Price Library) for Grand Exchange prices
- [prettyui](https://prettyui.j3.gg/) for the interface

## Building

```
./build.sh           # dev build
./build.sh release   # release build
```

Both copy the plugin, without the tests, into `Spell-Cost-Tracker/`. The release build depends on the published gepl plugin (6414886) instead of a locally installed one.

## Tests

The tests need Lua 5.4. Run them from the repository root:

```
lua tests/run.lua
```

## Project layout

```
main.lua           wires everything together
src/config.lua     spells, rune costs, item ids, fallback prices, Necromancy gear
src/game/          code that talks to the game and gepl
src/tracker/       cast detection, totals and their text (plain Lua, no game calls)
src/interface/     the plugin's page, the window and the settings
tests/             tests, mirroring src/
```
