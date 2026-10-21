local cast_detection = require("src/tracker/cast_detection")
local assert_helpers = require("tests/helpers/assert")

local lord_of_bones = { key = "LordOfBones", ability_id = 49072 }
local animate_dead = { key = "AnimateDead", timer = { var = "COMBATV2_GENERIC_BASE_VAR_7", mask = 0xff000000, shift = 24 } }
local vampyrism = { key = "Vampyrism", timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0x3ff00, shift = 8 } }
local penance = { key = "Penance", timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0xff, shift = 0 } }
local spells = { lord_of_bones, animate_dead, vampyrism, penance }

local function cast_keys(var_name, old_value, new_value)
    local keys = {}
    for _, spell in ipairs(cast_detection.cast_spells(spells, var_name, old_value, new_value)) do
        table.insert(keys, spell.key)
    end
    return keys
end

local tests = {}

function tests.an_ability_is_cast_when_it_is_the_just_used_ability()
    assert_helpers.same_lines(cast_keys("COMBATV2_JUST_USED_ABILITY", 0, 49072), { "LordOfBones" })
    assert_helpers.same_lines(cast_keys("COMBATV2_JUST_USED_ABILITY", 0, 12345), {})
end

-- The values below were logged in game while casting.

function tests.animate_dead_is_cast_when_its_timer_goes_up()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", 67, 805306435), { "AnimateDead" })
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", 805306435, 1610612803), { "AnimateDead" })
end

function tests.animate_dead_timer_above_128_is_read_from_a_negative_value()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", 1610612803, -1879048125), { "AnimateDead" })
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", -1879048125, -1073741757), { "AnimateDead" })
end

function tests.vampyrism_is_cast_when_its_timer_goes_up()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262144, 274432), { "Vampyrism" })
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 274432, 286720), { "Vampyrism" })
end

function tests.penance_is_cast_when_its_timer_goes_up()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262240, 262288), { "Penance" })
end

function tests.a_timer_going_down_is_not_a_cast()
    -- Penance ending (130 -> 0) when Animate Dead replaced it.
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262274, 262144), {})
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", 1610612803, 805306435), {})
end

function tests.other_bits_changing_is_not_a_cast()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", 67, 68), {})
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262144, 262144), {})
end

function tests.timer_change_without_an_old_value_is_not_a_cast()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_7", nil, 805306435), {})
end

function tests.values_given_as_floats_are_read_too()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262144.0, 274432.0), { "Vampyrism" })
end

return tests
