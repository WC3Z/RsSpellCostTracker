local cast_listener = require("src/game/cast_listener")
local assert_helpers = require("tests/helpers/assert")

-- A fake game Event global that keeps the VarTransmit and Logic subscriptions.
local function install_fake_event()
    local subscriptions = { var = {}, logic = {} }
    local function event_type(handlers)
        return {
            Subscribe = function(name, handler) handlers[name] = handler end,
            Unsubscribe = function(name) handlers[name] = nil end,
        }
    end
    Event = { VarTransmit = event_type(subscriptions.var), Logic = event_type(subscriptions.logic) }
    return subscriptions
end

-- A fake game var global whose VarClient values are taken from the given table.
local function install_fake_var(var_client_values)
    var = {
        VarClient = {
            FromID = function(var_id) return { value = var_client_values[var_id] } end,
        },
    }
end

local function send(subscriptions, config_name, old_value, new_value)
    for _, handler in pairs(subscriptions.var) do
        handler({ var = { configName = config_name }, oldValue = old_value, newValue = new_value })
    end
end

local function logic_tick(subscriptions, tick)
    for _, handler in pairs(subscriptions.logic) do
        handler({ logicTick = tick })
    end
end

local function cleanup()
    Event = nil
    var = nil
end

local soul_count_var = 5905
local penance = {
    key = "Penance",
    timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0xff, shift = 0, per_cast = 48 },
    runes = { ["Soul rune"] = 10 },
    counted_by_rune = "Soul rune",
}

-- Starts the listener for Penance, counted by soul runes, and returns what it saw.
local function start_penance_listener()
    local subscriptions = install_fake_event()
    local values = { [soul_count_var] = 1000 }
    install_fake_var(values)
    local casts = {}
    cast_listener.start({ penance }, { ["Soul rune"] = soul_count_var }, function(spell, times)
        table.insert(casts, { spell = spell, times = times })
    end)
    return subscriptions, values, casts
end

local tests = {}

function tests.reports_casts_of_the_tracked_spells()
    local subscriptions = install_fake_event()
    local lord_of_bones = { key = "LordOfBones", ability_id = 49072 }
    local timer_only_penance = { key = "Penance", timer = penance.timer }
    local casts = {}
    cast_listener.start({ lord_of_bones, timer_only_penance }, {}, function(spell, times)
        table.insert(casts, { spell = spell, times = times })
    end)

    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 0, 49072)
    send(subscriptions, "COMBATV2_JUST_USED_ABILITY", 0, 12345)
    send(subscriptions, "SOME_OTHER_VAR", 0, 49072)
    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262240, 262288)
    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 48, 240)

    assert_helpers.equal(#casts, 3)
    assert_helpers.equal(casts[1].spell, lord_of_bones)
    assert_helpers.equal(casts[1].times, 1)
    assert_helpers.equal(casts[2].spell, timer_only_penance)
    assert_helpers.equal(casts[2].times, 1)
    assert_helpers.equal(casts[3].spell, timer_only_penance)
    assert_helpers.equal(casts[3].times, 5)
    cleanup()
end

-- From the in-game log: Penance at 48, then 4 quick casts in the same tick
-- filled the timer (looks like a multi-cast) and used 40 soul runes.
function tests.counts_quick_casts_by_the_soul_runes_used()
    local subscriptions, values, casts = start_penance_listener()
    logic_tick(subscriptions, 100)

    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262192, 262384)
    assert_helpers.equal(#casts, 0)
    values[soul_count_var] = 960
    logic_tick(subscriptions, 101)
    logic_tick(subscriptions, 102)
    assert_helpers.equal(#casts, 0)
    logic_tick(subscriptions, 105)

    assert_helpers.equal(#casts, 1)
    assert_helpers.equal(casts[1].spell, penance)
    assert_helpers.equal(casts[1].times, 4)
    cleanup()
end

function tests.uses_the_timer_when_no_runes_are_used()
    local subscriptions, _, casts = start_penance_listener()
    logic_tick(subscriptions, 100)

    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262192, 262240)
    logic_tick(subscriptions, 105)

    assert_helpers.equal(#casts, 1)
    assert_helpers.equal(casts[1].times, 1)
    cleanup()
end

function tests.uses_the_timer_when_the_rune_count_cant_be_read()
    local subscriptions, values, casts = start_penance_listener()
    values[soul_count_var] = nil
    logic_tick(subscriptions, 100)

    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262192, 262384)
    logic_tick(subscriptions, 105)

    assert_helpers.equal(#casts, 1)
    assert_helpers.equal(casts[1].times, 5)
    cleanup()
end

function tests.reports_at_once_before_the_first_logic_tick()
    local subscriptions, _, casts = start_penance_listener()

    send(subscriptions, "COMBATV2_GENERIC_BASE_VAR_8", 262192, 262240)

    assert_helpers.equal(#casts, 1)
    cleanup()
end

function tests.stop_removes_the_subscriptions()
    local subscriptions = install_fake_event()
    cast_listener.start({}, {}, function() end)

    cast_listener.stop()

    assert_helpers.equal(next(subscriptions.var), nil)
    assert_helpers.equal(next(subscriptions.logic), nil)
    cleanup()
end

return tests
