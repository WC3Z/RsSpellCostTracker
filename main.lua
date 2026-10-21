local settings = require("src/config")
local SpellTracker = require("src/tracker/spell_tracker")
local prices = require("src/game/prices")
local equipment = require("src/game/equipment")
local cast_listener = require("src/game/cast_listener")
local saved_totals = require("src/game/saved_totals")
local totals_text = require("src/tracker/totals_text")
local player_settings = require("src/interface/player_settings")
local content_view = require("src/interface/content_view")
local cost_tracker_window = require("src/interface/cost_tracker_window")

local tracker = SpellTracker.new({
    spells = settings.spells,
    necro_gear = settings.necro_item_ids,
    get_price = prices.by_item_name(settings.item_ids),
    fallback_prices = settings.fallback_prices,
    only_stalls = player_settings.only_stalls,
})
tracker:restore(saved_totals.load(settings.spells))

-- The cost tracker window shows what the player picked on the plugin's page.
local function window_lines()
    return totals_text.lines(tracker:totals(), player_settings.shown())
end

-- The plugin's page always shows the cost of every spell cast.
local function page_lines()
    return totals_text.cost_lines(tracker:totals())
end

-- Shows the latest totals on the plugin's page and in the window, if they are open.
local function refresh_views()
    content_view.refresh()
    cost_tracker_window.refresh(window_lines())
end

local function open_cost_tracker()
    cost_tracker_window.open(window_lines())
end

local function on_cast(ability_id)
    local spell = tracker:on_cast(ability_id, equipment.worn_item_ids())
    if spell then
        saved_totals.save(spell, tracker:spell_totals(spell))
        refresh_views()
    end
end

cast_listener.start(tracker:ability_ids(), on_cast)
content_view.start({
    cost_lines = page_lines,
    settings_changed = refresh_views,
    open_window = open_cost_tracker,
})

-- Called by the game when the plugin is turned off.
function PluginShutdown()
    content_view.stop()
    cost_tracker_window.destroy()
    cast_listener.stop()
end
