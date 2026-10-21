-- Listens for the game telling us an ability was just used.
local cast_listener = {}

local subscription_name = "spell-cost-tracker-ability-used"

-- Calls on_cast(ability_id) every time one of the given abilities is used.
-- ability_ids: set of ability ids, e.g. { [49072] = true }
-- The game reports each ability use by setting the COMBATV2_JUST_USED_ABILITY
-- variable to the ability's id, and VarTransmit fires for every variable change.
function cast_listener.start(ability_ids, on_cast)
    Event.VarTransmit.Subscribe(subscription_name, function(event)
        if event.var.configName ~= "COMBATV2_JUST_USED_ABILITY" then
            return
        end
        if not ability_ids[event.newValue] then
            return
        end
        on_cast(event.newValue)
    end)
end

-- Stops listening, so no casts are tracked after the plugin is turned off.
function cast_listener.stop()
    Event.VarTransmit.Unsubscribe(subscription_name)
end

return cast_listener
