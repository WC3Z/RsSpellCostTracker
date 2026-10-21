local SpellTracker = require("src/tracker/spell_tracker")
local assert_helpers = require("tests/helpers/assert")

local no_gear = {}
local necro_helmet = { [1] = 55488 } -- NECRO_RASIAL_HEAD_T95

local stall_spell = {
    key = "LordOfBones", name = "Lord of Bones", ability_id = 49072, can_stall = true,
    runes = { ["Bone rune"] = 8, ["Soul rune"] = 6 },
}
local other_spell = {
    key = "Darkness", name = "Darkness", ability_id = 48331,
    runes = { ["Bone rune"] = 20 },
}
local third_spell = { key = "Penance", name = "Penance", runes = { ["Law rune"] = 3 } }

-- A get_price function that looks prices up in the given table, which tests may change later.
local function price_list(prices)
    return function(item_name)
        return prices[item_name]
    end
end

-- A tracker for the spells above with no prices. overrides replaces any of the options.
local function new_tracker(overrides)
    local options = {
        spells = { stall_spell, other_spell, third_spell },
        necro_gear = { [55488] = true },
        get_price = price_list({}),
    }
    for name, value in pairs(overrides or {}) do
        options[name] = value
    end
    return SpellTracker.new(options)
end

local function totals_for(tracker, key)
    for _, spell in ipairs(tracker:totals()) do
        if spell.key == key then return spell end
    end
end

local function only_stalls()
    return true
end

local tests = {}

function tests.counts_casts_per_spell()
    local tracker = new_tracker()

    assert_helpers.equal(tracker:on_cast(stall_spell, no_gear), stall_spell)
    tracker:on_cast(other_spell, no_gear)
    tracker:on_cast(other_spell, no_gear)

    local lord_of_bones = totals_for(tracker, "LordOfBones")
    local darkness = totals_for(tracker, "Darkness")
    assert_helpers.equal(lord_of_bones.casts, 1)
    assert_helpers.equal(lord_of_bones.runes_used["Bone rune"], 8)
    assert_helpers.equal(lord_of_bones.runes_used["Soul rune"], 6)
    assert_helpers.equal(darkness.casts, 2)
    assert_helpers.equal(darkness.runes_used["Bone rune"], 40)
end

function tests.totals_follow_the_order_of_the_spells()
    local totals = new_tracker():totals()

    assert_helpers.equal(totals[1].key, "LordOfBones")
    assert_helpers.equal(totals[1].name, "Lord of Bones")
    assert_helpers.equal(totals[2].key, "Darkness")
    assert_helpers.equal(totals[3].key, "Penance")
    assert_helpers.equal(totals[3].casts, 0)
end

function tests.counts_stall_spell_in_necro_gear_when_only_stalls_is_off()
    local tracker = new_tracker()

    assert_helpers.equal(tracker:on_cast(stall_spell, necro_helmet), stall_spell)
end

function tests.ignores_stall_spell_in_necro_gear_when_only_stalls_is_on()
    local tracker = new_tracker({ only_stalls = only_stalls })

    assert_helpers.equal(tracker:on_cast(stall_spell, necro_helmet), nil)
    assert_helpers.equal(tracker:on_cast(stall_spell, no_gear), stall_spell)
    assert_helpers.equal(totals_for(tracker, "LordOfBones").casts, 1)
end

function tests.only_stalls_does_not_affect_other_spells()
    local tracker = new_tracker({ only_stalls = only_stalls })

    assert_helpers.equal(tracker:on_cast(other_spell, necro_helmet), other_spell)
end

function tests.ignored_casts_are_not_priced()
    local price_lookups = 0
    local tracker = new_tracker({
        only_stalls = only_stalls,
        get_price = function()
            price_lookups = price_lookups + 1
            return 1
        end,
    })

    tracker:on_cast(stall_spell, necro_helmet)

    assert_helpers.equal(price_lookups, 0)
    assert_helpers.equal(totals_for(tracker, "LordOfBones").gp, 0)
end

function tests.prices_known_runes_and_lists_unknown_ones()
    local tracker = new_tracker({ get_price = price_list({ ["Bone rune"] = 100 }) })

    tracker:on_cast(stall_spell, no_gear)

    local totals = totals_for(tracker, "LordOfBones")
    assert_helpers.equal(totals.gp, 800)
    assert_helpers.equal(#totals.unpriced_items, 1)
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.prices_each_cast_when_it_happens()
    local prices = { ["Bone rune"] = 100, ["Soul rune"] = 10 }
    local tracker = new_tracker({ get_price = price_list(prices) })

    tracker:on_cast(stall_spell, no_gear)
    prices["Bone rune"] = 200
    tracker:on_cast(stall_spell, no_gear)

    assert_helpers.equal(totals_for(tracker, "LordOfBones").gp, 8 * 100 + 8 * 200 + 2 * 6 * 10)
end

function tests.keeps_listing_rune_that_was_unpriced_for_an_earlier_cast()
    local prices = { ["Bone rune"] = 100 }
    local tracker = new_tracker({ get_price = price_list(prices) })

    tracker:on_cast(stall_spell, no_gear)
    prices["Soul rune"] = 10
    tracker:on_cast(stall_spell, no_gear)

    local totals = totals_for(tracker, "LordOfBones")
    assert_helpers.equal(totals.gp, 2 * 8 * 100 + 6 * 10)
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.unpriced_runes_are_kept_per_spell()
    local tracker = new_tracker({ get_price = price_list({ ["Bone rune"] = 100 }) })

    tracker:on_cast(stall_spell, no_gear)
    tracker:on_cast(other_spell, no_gear)

    assert_helpers.equal(#totals_for(tracker, "Darkness").unpriced_items, 0)
end

function tests.uses_fallback_price_when_price_is_missing()
    local tracker = new_tracker({
        get_price = price_list({ ["Bone rune"] = 100 }),
        fallback_prices = { ["Bone rune"] = 350, ["Soul rune"] = 50 },
    })

    tracker:on_cast(stall_spell, no_gear)

    local totals = totals_for(tracker, "LordOfBones")
    assert_helpers.equal(totals.gp, 8 * 100 + 6 * 50)
    assert_helpers.equal(#totals.unpriced_items, 0)
    assert_helpers.equal(#totals.estimated_items, 1)
    assert_helpers.equal(totals.estimated_items[1], "Soul rune")
end

function tests.lists_rune_as_unpriced_when_it_has_no_fallback_price()
    local tracker = new_tracker({ fallback_prices = { ["Bone rune"] = 350 } })

    tracker:on_cast(stall_spell, no_gear)

    local totals = totals_for(tracker, "LordOfBones")
    assert_helpers.equal(totals.gp, 8 * 350)
    assert_helpers.equal(totals.estimated_items[1], "Bone rune")
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.keeps_listing_rune_that_was_estimated_for_an_earlier_cast()
    local prices = {}
    local tracker = new_tracker({
        get_price = price_list(prices),
        fallback_prices = { ["Bone rune"] = 350 },
    })

    tracker:on_cast(other_spell, no_gear)
    prices["Bone rune"] = 100
    tracker:on_cast(other_spell, no_gear)

    local totals = totals_for(tracker, "Darkness")
    assert_helpers.equal(totals.gp, 20 * 350 + 20 * 100)
    assert_helpers.equal(totals.estimated_items[1], "Bone rune")
end

function tests.reset_clears_totals()
    local tracker = new_tracker({ get_price = price_list({ ["Bone rune"] = 100 }) })
    tracker:on_cast(stall_spell, no_gear)

    tracker:reset()

    local totals = totals_for(tracker, "LordOfBones")
    assert_helpers.equal(totals.casts, 0)
    assert_helpers.equal(next(totals.runes_used), nil)
    assert_helpers.equal(totals.gp, 0)
    assert_helpers.equal(#totals.unpriced_items, 0)
    assert_helpers.equal(#totals.estimated_items, 0)
end

function tests.totals_cannot_modify_tracker_state()
    local tracker = new_tracker()
    tracker:on_cast(stall_spell, no_gear)

    totals_for(tracker, "LordOfBones").runes_used["Bone rune"] = 0

    assert_helpers.equal(totals_for(tracker, "LordOfBones").runes_used["Bone rune"], 8)
end

function tests.restore_continues_from_saved_totals()
    local tracker = new_tracker({ get_price = price_list({ ["Bone rune"] = 100 }) })

    tracker:restore({
        {
            key = "Darkness", casts = 3, gp = 6000,
            unpriced_items = {}, estimated_items = { "Bone rune" },
        },
    })
    tracker:on_cast(other_spell, no_gear)

    local totals = totals_for(tracker, "Darkness")
    assert_helpers.equal(totals.casts, 4)
    assert_helpers.equal(totals.runes_used["Bone rune"], 80)
    assert_helpers.equal(totals.gp, 6000 + 20 * 100)
    assert_helpers.equal(totals.estimated_items[1], "Bone rune")
end

function tests.restore_skips_spells_that_are_not_tracked()
    local tracker = new_tracker()

    tracker:restore({
        { key = "Gone", casts = 1, gp = 0, unpriced_items = {}, estimated_items = {} },
    })

    assert_helpers.equal(totals_for(tracker, "Gone"), nil)
end

function tests.spell_totals_match_the_entry_in_totals()
    local tracker = new_tracker()
    tracker:on_cast(other_spell, no_gear)

    local totals = tracker:spell_totals(other_spell)

    assert_helpers.equal(totals.key, "Darkness")
    assert_helpers.equal(totals.casts, 1)
    assert_helpers.equal(totals.runes_used["Bone rune"], 20)
end

return tests
