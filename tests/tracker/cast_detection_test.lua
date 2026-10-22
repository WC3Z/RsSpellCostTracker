local CastDetection = require("src/tracker/cast_detection")
local assert_helpers = require("tests/helpers/assert")

local lord_of_bones = { key = "LordOfBones", ability_id = 49072 }
local animate_dead = { key = "AnimateDead", timer = { var = "COMBATV2_GENERIC_BASE_VAR_7", mask = 0xff000000, shift = 24, per_cast = 48 } }
local vampyrism = { key = "Vampyrism", timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0x3ff00, shift = 8, per_cast = 48 } }
local penance = { key = "Penance", timer = { var = "COMBATV2_GENERIC_BASE_VAR_8", mask = 0xff, shift = 0, per_cast = 48 } }
local darkness = {
    key = "Darkness",
    timer = {
        var = "COMBATV2_BUFF_NECROMANCY_DARKNESS_END",
        per_cast = 1200,
        cast_tick_var = "COMBATV2_COOLDOWN_NECROMANCY_DARKNESS_START",
    },
}
local spells = { lord_of_bones, animate_dead, vampyrism, penance, darkness }

local function cast_keys(var_name, old_value, new_value)
    local keys = {}
    for _, spell_cast in ipairs(CastDetection.new(spells):cast_spells(var_name, old_value, new_value)) do
        table.insert(keys, spell_cast.spell.key)
    end
    return keys
end

-- How many times each spell was cast, e.g. { "Penance x5" }.
local function counts_of(cast)
    local counts = {}
    for _, spell_cast in ipairs(cast) do
        table.insert(counts, spell_cast.spell.key .. " x" .. spell_cast.casts)
    end
    return counts
end

local function cast_counts(var_name, old_value, new_value)
    return counts_of(CastDetection.new(spells):cast_spells(var_name, old_value, new_value))
end

-- Sends each { var_name, old_value, new_value } change to one detection and
-- returns the cast counts of the last change.
local function counts_after(changes)
    local detection = CastDetection.new(spells)
    local cast
    for _, change in ipairs(changes) do
        cast = detection:cast_spells(change[1], change[2], change[3])
    end
    return counts_of(cast)
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

function tests.a_single_cast_counts_once()
    assert_helpers.same_lines(cast_counts("COMBATV2_JUST_USED_ABILITY", 0, 49072), { "LordOfBones x1" })
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 262240, 262288), { "Penance x1" })
end

-- The multi-cast values below are made up from the 48-per-cast rule, not
-- logged in game. In game, a multi-cast right after a single Penance cast used
-- the runes of 5 casts.

function tests.a_multi_cast_always_counts_5_casts()
    -- Penance from 12 to 60 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 48, 240), { "Penance x5" })
    -- Vampyrism from 0 to 60 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 0, 240 << 8), { "Vampyrism x5" })
    -- Animate Dead from 24 to 60 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_7", 96 << 24, 240 << 24), { "AnimateDead x5" })
end

function tests.single_casts_in_the_same_tick_count_each_cast()
    -- Penance from 0 to 24 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 0, 96), { "Penance x2" })
    -- Penance from 12 to 48 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 48, 192), { "Penance x3" })
end

function tests.a_rise_is_rounded_to_the_nearest_cast()
    -- The timer had ticked down to 47 when it was filled up to 60 minutes.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 47, 240), { "Penance x5" })
    -- The timer ticked down once in the same update as a single cast.
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 100, 147), { "Penance x1" })
end

function tests.topping_up_an_almost_full_timer_is_one_cast()
    assert_helpers.same_lines(cast_counts("COMBATV2_GENERIC_BASE_VAR_8", 230, 240), { "Penance x1" })
end

-- Darkness values logged in game. The cooldown start is set to the current
-- tick just before the end tick changes.

local darkness_end = "COMBATV2_BUFF_NECROMANCY_DARKNESS_END"
local darkness_cast_tick = "COMBATV2_COOLDOWN_NECROMANCY_DARKNESS_START"

function tests.darkness_cast_while_inactive_counts_from_the_cast_tick()
    assert_helpers.same_lines(counts_after({
        { darkness_cast_tick, 166205, 166382 },
        { darkness_end, 0, 167582 },
    }), { "Darkness x1" })
end

function tests.darkness_multi_cast_while_inactive_counts_every_cast()
    assert_helpers.same_lines(counts_after({
        { darkness_cast_tick, 166382, 166419 },
        { darkness_end, 0, 172419 },
    }), { "Darkness x5" })
end

function tests.darkness_cast_after_it_ran_out_counts_from_the_cast_tick()
    assert_helpers.same_lines(counts_after({
        { darkness_cast_tick, 160000, 170000 },
        { darkness_end, 165000, 171200 },
    }), { "Darkness x1" })
end

function tests.darkness_cast_while_inactive_without_a_cast_tick_counts_once()
    assert_helpers.same_lines(cast_counts(darkness_end, 0, 165911), { "Darkness x1" })
end

function tests.darkness_recast_counts_one_cast()
    assert_helpers.same_lines(cast_counts(darkness_end, 165911, 167111), { "Darkness x1" })
end

-- Without the cast tick it isn't known whether the timer is full, so the
-- added time is all there is to go by.
function tests.darkness_top_up_without_a_cast_tick_counts_the_time_added()
    assert_helpers.same_lines(cast_counts(darkness_end, 167111, 170719), { "Darkness x3" })
end

function tests.darkness_single_casts_in_the_same_tick_count_each_cast()
    assert_helpers.same_lines(counts_after({
        { darkness_cast_tick, 166205, 166382 },
        { darkness_end, 0, 166382 + 2 * 1200 },
    }), { "Darkness x2" })
end

function tests.darkness_top_up_counts_from_the_old_end_tick_while_active()
    assert_helpers.same_lines(counts_after({
        { darkness_cast_tick, 164711, 164719 },
        { darkness_end, 167111, 170719 },
    }), { "Darkness x5" })
end

function tests.darkness_ending_is_not_a_cast()
    assert_helpers.same_lines(cast_counts(darkness_end, 170719, 0), {})
end

function tests.the_cast_tick_changing_is_not_a_cast()
    assert_helpers.same_lines(cast_counts(darkness_cast_tick, 166382, 166419), {})
end

function tests.darkness_is_not_counted_from_the_just_used_ability()
    assert_helpers.same_lines(cast_keys("COMBATV2_JUST_USED_ABILITY", 1874, 48331), {})
end

function tests.values_given_as_floats_are_read_too()
    assert_helpers.same_lines(cast_keys("COMBATV2_GENERIC_BASE_VAR_8", 262144.0, 274432.0), { "Vampyrism" })
end

return tests
