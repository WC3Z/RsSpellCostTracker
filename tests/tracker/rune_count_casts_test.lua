local RuneCountCasts = require("src/tracker/rune_count_casts")
local assert_helpers = require("tests/helpers/assert")

local penance = { key = "Penance", runes = { ["Soul rune"] = 10 }, counted_by_rune = "Soul rune" }
local vampyrism = { key = "Vampyrism", runes = { ["Soul rune"] = 6 }, counted_by_rune = "Soul rune" }

local function new_counter(start_count)
    local counter = RuneCountCasts.new(5)
    counter:rune_count("Soul rune", start_count or 1000)
    return counter
end

local tests = {}

function tests.waits_until_the_deadline()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 1 }, 100)
    counter:rune_count("Soul rune", 990)

    assert_helpers.equal(#counter:finished(104), 0)
    local done = counter:finished(105)
    assert_helpers.equal(#done, 1)
    assert_helpers.equal(done[1].spell, penance)
    assert_helpers.equal(done[1].casts, 1)
    assert_helpers.equal(#counter:finished(106), 0)
end

-- From the in-game log: 96 -> 240 on the timer looks like a multi-cast, but only 30 souls were used.
function tests.runes_used_override_the_timer_guess()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 5 }, 100)
    counter:rune_count("Soul rune", 970)

    assert_helpers.equal(counter:finished(105)[1].casts, 3)
end

function tests.uses_the_runes_per_cast_of_the_spell()
    local counter = new_counter()

    counter:timer_cast({ spell = vampyrism, casts = 1 }, 100)
    counter:rune_count("Soul rune", 982)

    assert_helpers.equal(counter:finished(105)[1].casts, 3)
end

function tests.adds_up_drops_over_several_ticks()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 1 }, 100)
    counter:rune_count("Soul rune", 990)
    counter:rune_count("Soul rune", 970)

    assert_helpers.equal(counter:finished(105)[1].casts, 3)
end

function tests.another_cast_while_waiting_is_added_and_waits_longer()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 1 }, 100)
    counter:rune_count("Soul rune", 990)
    counter:timer_cast({ spell = penance, casts = 1 }, 103)
    counter:rune_count("Soul rune", 980)

    assert_helpers.equal(#counter:finished(105), 0)
    assert_helpers.equal(counter:finished(108)[1].casts, 2)
end

function tests.falls_back_to_the_timer_when_no_runes_are_used()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 2 }, 100)

    assert_helpers.equal(counter:finished(105)[1].casts, 2)
end

function tests.a_partly_saved_cast_still_counts_as_one()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 1 }, 100)
    counter:rune_count("Soul rune", 996)

    assert_helpers.equal(counter:finished(105)[1].casts, 1)
end

function tests.drops_with_nothing_waiting_are_ignored()
    local counter = new_counter()
    counter:rune_count("Soul rune", 900)

    counter:timer_cast({ spell = penance, casts = 1 }, 100)

    assert_helpers.equal(counter:finished(105)[1].casts, 1)
end

function tests.more_runes_are_not_a_cast()
    local counter = new_counter()

    counter:timer_cast({ spell = penance, casts = 1 }, 100)
    counter:rune_count("Soul rune", 1500)
    counter:rune_count("Soul rune", 1490)

    assert_helpers.equal(counter:finished(105)[1].casts, 1)
end

return tests
