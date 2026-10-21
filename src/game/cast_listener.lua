-- Listens for game variable changes that show a tracked spell was cast.
local cast_detection = require("src/tracker/cast_detection")

local cast_listener = {}

local subscription_name = "spell-cost-tracker-spell-cast"

-- Calls on_cast(spell) every time one of the given spells is cast.
-- VarTransmit fires for every variable change; cast_detection decides which
-- changes are casts.
function cast_listener.start(spells, on_cast)
    Event.VarTransmit.Subscribe(subscription_name, function(event)
        local cast = cast_detection.cast_spells(spells, event.var.configName, event.oldValue, event.newValue)
        for _, spell in ipairs(cast) do
            on_cast(spell)
        end
    end)
end

-- Stops listening, so no casts are tracked after the plugin is turned off.
function cast_listener.stop()
    Event.VarTransmit.Unsubscribe(subscription_name)
end

return cast_listener
