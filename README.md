# Spell Cost Tracker

A RuneScape 3 plugin that keeps track of how much your spells cost in runes, priced from the Grand Exchange, or from rune shops for ironmen.

## Usage
Build the plugin. You'll also need the GEPL dev plugin until it has been approved and uploaded to the plugin hub. Install PrettyUI. Add gepl and Spell-Cost-Tracker folders to the dev_plugins folder located in  the RuneScape-BETA folder. 

## Tracked spells

| Spell | Runes per cast |
|---|---|
| Lord of Bones | 8 Spirit, 6 Bone, 2 Flesh, 1 Miasma |
| Animate Dead | 30 Earth, 15 Death, 15 Blood, 6 Soul |
| Vampyrism | 40 Fire, 10 Death, 15 Blood, 6 Soul |
| Penance | 30 Body, 20 Chaos, 3 Law, 10 Soul |
| Darkness | 40 Spirit, 20 Bone, 10 Flesh, 5 Miasma |

Rune costs live in `src/config.lua`.

Animate Dead, Vampyrism, Penance and Darkness last up to an hour. A multi-cast always uses the runes of 5 casts, even when the timer has time left and fewer casts would fill it, so only multi-cast when the timer is empty or nearly empty. With 12 minutes left, for example, the 5th cast is wasted.

## Features

- Counts casts, runes used and their cost for each spell, including multi-casts of Animate Dead, Vampyrism, Penance and Darkness (see Known limitations).
- Animate Dead, Vampyrism and Penance are counted by the soul runes they use (backpack and rune pouches together), so quick casts that land in the same moment and multi-casts are counted correctly. If no soul runes are used (e.g. something saved them), the cast is counted from the spell's timer instead.
- Prices each cast when it happens, using the average of the latest high and low Grand Exchange price. If a price isn't available, a fallback price from `src/config.lua` is used, and that part of the cost is shown as "Estimated" under the total (hover it to see which runes).
- With **Iron btw** on, the cost is shown at rune shop prices instead (see below).
- Keeps the totals when the plugin or the game is restarted.
- A movable window with the totals, opened from the plugin's page. It has a **Total** tab and a **Session** tab.
- Sessions, controlled with the buttons on the window's Session tab: ▶ resumes the session and ⏸ pauses it. Casts are counted in the session only while it runs, and always in the totals. **New session** (after a confirm) starts again from zero and moves the current session to the past sessions. The Session tab shows how long the session has been running, not counting pauses. The session, paused or not, carries on after the plugin or the game is restarted.
- **Past sessions** opens a small window listing the last 30 sessions, newest first, with when each started, how long it ran and what it cost (at shop prices if "Iron btw" was on when it ended). Times come from the game clock (`CLOCK_TIME_DATE_MINUTES`), which the plugin only sees once its first minute ticks over, so a session started right after login gets its start time a minute late; minutes when the game wasn't running aren't counted.
- The plugin's page has a **Costs** tab (open the window, cost so far) and a **Settings** tab:
  - **Only track Lord of Bones stalls**: only counts Lord of Bones casts made without Necromancy gear on.
  - **Iron btw** (off by default): shows the cost at rune shop prices instead of Grand Exchange prices.
  - **Transparent window** (off by default): makes the window's background see-through.
  - What the window shows: cast count, rune count, cost per spell and total cost.
  - Which spells the window shows.

## Iron btw

Ironmen can't buy runes on the Grand Exchange, so with **Iron btw** on, runes are priced at what shops sell them for:

- Standard runes at Baba Yaga's price on Lunar Isle.
- Necromancy runes at Thalmund's Wares in Um, which sells them at 10 times their item value (`store_price_multipliers` in `src/config.lua`).

Shop prices are read from the game's item data.

The Grand Exchange cost is always tracked and saved. Shop prices don't change, so the shop cost is worked out from the runes used. Turning Iron btw on or off reprices all casts, including earlier ones.

## Known limitations

- **Darkness multi-casts with time left on the timer are undercounted.** A multi-cast always uses the runes of 5 casts, but the casts that don't fit in the hour leave no trace in the game: the timer only goes up by the casts that fit, and only those give XP. With 48 minutes left, for example, a multi-cast uses the runes of 5 casts but is counted as 1. A multi-cast from an empty timer is counted correctly. The other timed spells are counted by their soul runes instead, but the game has no rune count for Necromancy runes.

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
src/config.lua     spells, rune costs, item ids, shop price multipliers, fallback prices, Necromancy gear
src/game/          code that talks to the game and gepl
src/tracker/       cast detection (timers and rune counts), totals, shop pricing and their text (plain Lua, no game calls)
src/interface/     the plugin's page, the window and the settings
tests/             tests, mirroring src/
```

## Types

Lua has no types of its own, so the code describes them in `---@` comments,
which editors with the Lua Language Server (or EmmyLua) understand. For example
`---@param spells Spell[]` means `spells` is a list of `Spell`, and hovering over
`Spell` shows its fields. The shared types are defined where they belong:

- `Spell`, `SpellTimer`, `RuneName`: `src/config.lua`
- `SavedTotals`, `SpellTotals`, `PriceLookup`: `src/tracker/spell_tracker.lua`
- `SpellCast`: `src/tracker/cast_detection.lua`
- `PendingCast`: `src/tracker/rune_count_casts.lua`
- `PlayerSetting`, `ShownParts`: `src/interface/player_settings.lua`
- `Line`: `src/interface/text_lines.lua`

A `?` means the value can be missing (`nil`), and `table<RuneName, integer>`
is a table from rune name to a number, e.g. `{ ["Bone rune"] = 6 }`.
