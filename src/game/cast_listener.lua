-- Listens for the game telling us an ability was just used.
local cast_listener = {}

local subscription_name = "stall-tracker-ability-used"

-- Calls on_cast() every time the ability with the given id is used.
-- The game reports each ability use by setting the COMBATV2_JUST_USED_ABILITY
-- variable to the ability's id, and VarTransmit fires for every variable change.
function cast_listener.start(ability_id, on_cast)
    Event.VarTransmit.Subscribe(subscription_name, function(event)
        if event.var.configName ~= "COMBATV2_JUST_USED_ABILITY" then
            return
        end
        if event.newValue ~= ability_id then
            return
        end
        on_cast()
    end)
end

-- Stops listening, so no casts are tracked after the plugin is turned off.
function cast_listener.stop()
    Event.VarTransmit.Unsubscribe(subscription_name)
end

return cast_listener
