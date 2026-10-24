local game_clock = require("src/game/game_clock")
local assert_helpers = require("tests/helpers/assert")

-- A fake game Event global that keeps track of VarTransmit subscriptions.
local function install_fake_event()
    local subscriptions = {}
    Event = {
        VarTransmit = {
            Subscribe = function(name, handler) subscriptions[name] = handler end,
            Unsubscribe = function(name) subscriptions[name] = nil end,
        },
    }
    return subscriptions
end

local function send(subscriptions, config_name, new_value)
    for _, handler in pairs(subscriptions) do
        handler({ var = { configName = config_name }, oldValue = 0, newValue = new_value })
    end
end

local tests = {}

function tests.reports_clock_changes_and_remembers_the_latest()
    local subscriptions = install_fake_event()
    local seen = {}
    game_clock.start(function(minutes) table.insert(seen, minutes) end)

    send(subscriptions, "CLOCK_TIME_DATE_MINUTES", 1000)
    send(subscriptions, "SOME_OTHER_VAR", 5)
    send(subscriptions, "CLOCK_TIME_DATE_MINUTES", 1001)

    assert_helpers.same_lines(seen, { 1000, 1001 })
    assert_helpers.equal(game_clock.now(), 1001)
    game_clock.stop()
end

function tests.stop_unsubscribes()
    local subscriptions = install_fake_event()
    game_clock.start(function() end)

    game_clock.stop()

    assert_helpers.equal(next(subscriptions), nil)
end

return tests
