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

local function send(subscriptions, config_name, old_value, new_value)
    for _, handler in pairs(subscriptions) do
        handler({ var = { configName = config_name }, oldValue = old_value, newValue = new_value })
    end
end

local tests = {}

function tests.reports_casts_of_the_tracked_spells()
    local subscriptions = install_fake_event()
    local lord_of_bones = { key = "LordOfBones", ability_id = 49072 }
    local penance = { key = "Penance", timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0xff, shift = 0 } }
    local casts = {}
    cast_listener.start({ lord_of_bones, penance }, function(spell)
        table.insert(casts, spell)
    end)

    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 0, 49072)
    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 0, 12345)
    send(subscriptions, "SOME_OTHER_VAR", 0, 49072)
    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262240, 262288)

    assert_helpers.equal(#casts, 2)
    assert_helpers.equal(casts[1], lord_of_bones)
    assert_helpers.equal(casts[2], penance)
    Event = nil
end

function tests.stop_removes_the_subscription()
    local subscriptions = install_fake_event()
    cast_listener.start({}, function() end)

    cast_listener.stop()

    assert_helpers.equal(next(subscriptions), nil)
    Event = nil
end

return tests
