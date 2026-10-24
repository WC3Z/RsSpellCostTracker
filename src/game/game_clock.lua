-- Watches the game's clock, which counts minutes (the CLOCK_TIME_DATE_MINUTES
-- player variable). The plugin API has no date functions yet, so this is the
-- only clock there is. The game only tells us when the value changes, so it
-- isn't known until the first minute ticks over after the plugin starts.
local game_clock = {}

local subscription_name = "spell-cost-tracker-clock"
local clock_var = "CLOCK_TIME_DATE_MINUTES"

---@type integer?
local latest

-- The latest game clock in minutes, or nil if it hasn't been seen yet.
---@return integer?
function game_clock.now()
    return latest
end

-- Calls on_change(minutes) every time the game clock changes.
---@param on_change fun(minutes: integer)
function game_clock.start(on_change)
    Event.VarTransmit.Subscribe(subscription_name, function(event)
        if event.var.configName ~= clock_var then
            return
        end
        latest = event.newValue
        on_change(latest)
    end)
end

function game_clock.stop()
    Event.VarTransmit.Unsubscribe(subscription_name)
end

return game_clock
