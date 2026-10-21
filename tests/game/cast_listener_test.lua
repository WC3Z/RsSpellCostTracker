local cast_listener = require("src/game/cast_listener")
local assert_helpers = require("tests/helpers/assert")

-- A fake game Event global that keeps track of VarTransmit subscriptions.
local function install_fake_event()
    local subscriptions = {}
    Event = {
        VarTransmit = {
            Subscribe = function(name, handler)
                subscriptions[name] = handler
            end,
            Unsubscribe = function(name)
                subscriptions[name] = nil
            end,
        },
    }
    return subscriptions
end

local function send(subscriptions, config_name, new_value)
    for _, handler in pairs(subscriptions) do
        handler({ var = { configName = config_name }, newValue = new_value })
    end
end

local tests = {}

function tests.reports_casts_of_the_tracked_abilities()
    local subscriptions = install_fake_event()
    local casts = {}
    cast_listener.start({ [49072] = true, [48331] = true }, function(ability_id)
        table.insert(casts, ability_id)
    end)

    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 49072)
    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 12345)
    send(subscriptions, "SOME_OTHER_VAR", 49072)
    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 48331)

    assert_helpers.equal(#casts, 2)
    assert_helpers.equal(casts[1], 49072)
    assert_helpers.equal(casts[2], 48331)
    Event = nil
end

function tests.stop_removes_the_subscription()
    local subscriptions = install_fake_event()
    cast_listener.start({ [49072] = true }, function() end)

    cast_listener.stop()

    assert_helpers.equal(next(subscriptions), nil)
    Event = nil
end

return tests
