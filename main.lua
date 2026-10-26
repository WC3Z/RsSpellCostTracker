local settings = require("src/config")
local SpellTracker = require("src/tracker/spell_tracker")
local prices = require("src/game/prices")
local equipment = require("src/game/equipment")
local cast_listener = require("src/game/cast_listener")
local saved_totals = require("src/game/saved_totals")
local Session = require("src/game/session")
local session_history = require("src/game/session_history")
local game_clock = require("src/game/game_clock")
local totals_text = require("src/tracker/totals_text")
local session_text = require("src/tracker/session_text")
local shop_cost = require("src/tracker/shop_cost")
local player_settings = require("src/interface/player_settings")
local content_view = require("src/interface/content_view")
local cost_tracker_window = require("src/interface/cost_tracker_window")
local session_history_window = require("src/interface/session_history_window")

---@type SpellTrackerOptions
local tracker_options = {
    spells = settings.spells,
    necro_gear = settings.necro_item_ids,
    get_price = prices.by_item_name(settings.item_ids),
    fallback_prices = settings.fallback_prices,
    only_stalls = player_settings.only_stalls,
}

local tracker = SpellTracker.new(tracker_options)
tracker:restore(saved_totals.load(settings.spells))

local session = Session.new(tracker_options)

local get_store_price = prices.store_price_by_item_name(settings.item_config_names, settings.store_price_multipliers)

-- The trackers keep the Grand Exchange cost. With "Iron btw" on, the totals
-- are shown at shop prices instead, for earlier casts too.
---@param from SpellTracker | Session
---@return SpellTotals[]
local function shown_totals(from)
    if player_settings.iron_btw() then
        return shop_cost.reprice(from:totals(), get_store_price, settings.fallback_prices)
    end
    return from:totals()
end

-- The cost tracker window shows what the player picked on the plugin's page,
-- for all casts on one tab and for the session on the other.
---@return WindowPages
local function window_pages()
    local shown = player_settings.shown()
    local session_lines = totals_text.lines(shown_totals(session), shown)
    table.insert(session_lines, 1, session_text.status(session:state(), session:minutes()))
    return {
        total = totals_text.lines(shown_totals(tracker), shown),
        session = session_lines,
        session_state = session:state(),
    }
end

-- The plugin's page always shows the cost of every spell cast.
local function page_lines()
    return totals_text.cost_lines(shown_totals(tracker))
end

-- Shows the latest totals on the plugin's page and in the window, if they are open.
local function refresh_views()
    content_view.refresh()
    cost_tracker_window.refresh(window_pages())
end

local function open_cost_tracker()
    cost_tracker_window.open(window_pages())
end

local function settings_changed()
    cost_tracker_window.set_transparent(player_settings.transparent_window())
    refresh_views()
end

-- The cost of everything cast in the session, as it is shown (so at shop
-- prices with "Iron btw" on).
---@return number
local function session_gp()
    local gp = 0
    for _, spell in ipairs(shown_totals(session)) do
        gp = gp + spell.gp
    end
    return gp
end

local function history_lines()
    return session_text.history_lines(session_history.list())
end

-- Moves the current session to the history and starts a new one from zero.
local function new_session()
    if session:has_anything() then
        session_history.add({ started_at = session:started_at(), minutes = session:minutes(), gp = session_gp() })
        session_history_window.refresh(history_lines())
    end
    session:start(game_clock.now())
    refresh_views()
end

local function pause_session()
    session:pause()
    refresh_views()
end

local function resume_session()
    session:resume()
    refresh_views()
end

local function show_history()
    session_history_window.open(history_lines())
end

-- Counts the session's running time, and shows it in the window.
---@param minutes integer
local function on_clock(minutes)
    session:on_clock(minutes)
    cost_tracker_window.refresh(window_pages())
end

---@param spell Spell
---@param casts integer
local function on_cast(spell, casts)
    local worn_item_ids = equipment.worn_item_ids()
    if not tracker:on_cast(spell, worn_item_ids, casts) then
        return
    end
    saved_totals.save(spell, tracker:spell_totals(spell))
    session:on_cast(spell, worn_item_ids, casts)
    refresh_views()
end

cost_tracker_window.set_transparent(player_settings.transparent_window())
cost_tracker_window.set_session_controls({
    pause = pause_session,
    resume = resume_session,
    new_session = new_session,
    show_history = show_history,
})
cast_listener.start(settings.spells, settings.rune_count_var_ids, on_cast)
game_clock.start(on_clock)

content_view.start({
    cost_lines = page_lines,
    settings_changed = settings_changed,
    open_window = open_cost_tracker,
})

-- Called by the game when the plugin is turned off.
function PluginShutdown()
    content_view.stop()
    cost_tracker_window.destroy()
    session_history_window.destroy()
    cast_listener.stop()
    game_clock.stop()
end
