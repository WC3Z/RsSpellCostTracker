-- Watches the game for casts of the tracked spells.
local CastDetection = require("src/tracker/cast_detection")
local RuneCountCasts = require("src/tracker/rune_count_casts")

local cast_listener = {}

local var_subscription_name = "spell-cost-tracker-spell-cast"
local logic_subscription_name = "spell-cost-tracker-rune-count"

-- How long to wait for the rune count to drop after a timer goes up. In game
-- it drops 1-2 logic ticks later.
local rune_count_wait_ticks = 5

-- Reads how many of a rune the player has in the backpack and rune pouches.
-- Returns nil if the game can't give it to us.
---@param var_id integer
---@return integer?
local function read_rune_count(var_id)
    local ok, count = pcall(function() return var.VarClient.FromID(var_id).value end)
    if ok and type(count) == "number" then
        return count
    end
    return nil
end

-- Calls on_cast(spell, casts) every time one of the given spells is cast.
-- casts is the number of casts, which is more than 1 for a multi-cast.
--
-- The game tells us about every value that changes (VarTransmit), and
-- CastDetection works out which of those changes mean a spell was cast.
-- Spells with counted_by_rune are held back a few logic ticks, until
-- RuneCountCasts has seen how many runes were used.
---@param spells Spell[]
---@param rune_count_var_ids table<RuneName, integer> See config.lua
---@param on_cast fun(spell: Spell, casts: integer)
function cast_listener.start(spells, rune_count_var_ids, on_cast)
    local detection = CastDetection.new(spells)
    local rune_counts = RuneCountCasts.new(rune_count_wait_ticks)
    ---@type integer?
    local logic_tick

    ---@param spell_cast SpellCast
    local function counted_by_runes(spell_cast)
        local rune = spell_cast.spell.counted_by_rune
        return rune ~= nil and rune_count_var_ids[rune] ~= nil and logic_tick ~= nil
    end

    Event.VarTransmit.Subscribe(var_subscription_name, function(event)
        local cast = detection:cast_spells(event.var.configName, event.oldValue, event.newValue)
        for _, spell_cast in ipairs(cast) do
            if counted_by_runes(spell_cast) then
                rune_counts:timer_cast(spell_cast, logic_tick)
            else
                on_cast(spell_cast.spell, spell_cast.casts)
            end
        end
    end)

    -- The rune counts are worked out by the game client, so they aren't
    -- reliably sent through VarTransmit. They are read on every logic tick.
    Event.Logic.Subscribe(logic_subscription_name, function(event)
        logic_tick = event.logicTick
        for rune, var_id in pairs(rune_count_var_ids) do
            local count = read_rune_count(var_id)
            if count ~= nil then
                rune_counts:rune_count(rune, count)
            end
        end
        for _, spell_cast in ipairs(rune_counts:finished(logic_tick)) do
            on_cast(spell_cast.spell, spell_cast.casts)
        end
    end)
end

-- Stops listening, so no casts are tracked after the plugin is turned off.
function cast_listener.stop()
    Event.VarTransmit.Unsubscribe(var_subscription_name)
    Event.Logic.Unsubscribe(logic_subscription_name)
end

return cast_listener
