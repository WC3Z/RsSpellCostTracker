-- Watches the game for casts of the tracked spells.
local CastDetection = require("src/tracker/cast_detection")

local cast_listener = {}

local subscription_name = "spell-cost-tracker-spell-cast"

-- Calls on_cast(spell, casts) every time one of the given spells is cast.
-- casts is the number of casts, which is more than 1 for a multi-cast.
-- The game tells us about every value that changes (VarTransmit), and
-- CastDetection works out which of those changes mean a spell was cast.
function cast_listener.start(spells, on_cast)
    local detection = CastDetection.new(spells)
    Event.VarTransmit.Subscribe(subscription_name, function(event)
        local cast = detection:cast_spells(event.var.configName, event.oldValue, event.newValue)
        for _, spell_cast in ipairs(cast) do
            on_cast(spell_cast.spell, spell_cast.casts)
        end
    end)
end

-- Stops listening, so no casts are tracked after the plugin is turned off.
function cast_listener.stop()
    Event.VarTransmit.Unsubscribe(subscription_name)
end

return cast_listener
