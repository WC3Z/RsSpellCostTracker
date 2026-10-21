local StallTracker = require("src/tracker/stall_tracker")
local assert_helpers = require("tests/helpers/assert")

local no_gear = {}
local necro_helmet = { [1] = 55488 } -- NECRO_RASIAL_HEAD_T95

-- A tracker for 8 Bone runes and 6 Soul runes per cast. overrides replaces any of the options.
local function new_tracker(overrides)
    local options = {
        runes_per_cast = { ["Bone rune"] = 8, ["Soul rune"] = 6 },
        necro_gear = { [55488] = true },
    }
    for name, value in pairs(overrides or {}) do
        options[name] = value
    end
    return StallTracker.new(options)
end

-- A get_price function that looks prices up in the given table, which tests may change later.
local function price_list(prices)
    return function(item_name)
        return prices[item_name]
    end
end

local tests = {}

function tests.counts_cast_without_necro_gear()
    local tracker = new_tracker()

    assert_helpers.equal(tracker:on_cast(no_gear), true)

    local totals = tracker:totals()
    assert_helpers.equal(totals.casts, 1)
    assert_helpers.equal(totals.runes_used["Bone rune"], 8)
    assert_helpers.equal(totals.runes_used["Soul rune"], 6)
    assert_helpers.equal(totals.gp, nil)
end

function tests.ignores_cast_while_wearing_necro_gear()
    local tracker = new_tracker()

    local counted = tracker:on_cast(necro_helmet)

    assert_helpers.equal(counted, false)
    assert_helpers.equal(tracker:totals().casts, 0)
end

function tests.accumulates_over_several_casts()
    local tracker = new_tracker()

    tracker:on_cast(no_gear)
    tracker:on_cast(no_gear)
    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.casts, 3)
    assert_helpers.equal(totals.runes_used["Bone rune"], 24)
end

function tests.prices_known_runes_and_lists_unknown_ones()
    local prices = { ["Bone rune"] = 100 }
    local tracker = new_tracker({ get_price = price_list(prices) })

    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.gp, 800)
    assert_helpers.equal(#totals.unpriced_items, 1)
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.prices_each_cast_when_it_happens()
    local prices = { ["Bone rune"] = 100, ["Soul rune"] = 10 }
    local tracker = new_tracker({ get_price = price_list(prices) })

    tracker:on_cast(no_gear)
    prices["Bone rune"] = 200
    tracker:on_cast(no_gear)

    assert_helpers.equal(tracker:totals().gp, 8 * 100 + 8 * 200 + 2 * 6 * 10)
end

function tests.keeps_listing_rune_that_was_unpriced_for_an_earlier_cast()
    local prices = { ["Bone rune"] = 100 }
    local tracker = new_tracker({ get_price = price_list(prices) })

    tracker:on_cast(no_gear)
    prices["Soul rune"] = 10
    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.gp, 2 * 8 * 100 + 6 * 10)
    assert_helpers.equal(#totals.unpriced_items, 1)
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.ignored_casts_are_not_priced()
    local price_lookups = 0
    local tracker = new_tracker({
        get_price = function()
            price_lookups = price_lookups + 1
            return 1
        end,
    })

    tracker:on_cast(necro_helmet)

    assert_helpers.equal(price_lookups, 0)
    assert_helpers.equal(tracker:totals().gp, 0)
end

function tests.reset_clears_totals()
    local tracker = new_tracker({ get_price = price_list({ ["Bone rune"] = 100 }) })
    tracker:on_cast(no_gear)

    tracker:reset()

    local totals = tracker:totals()
    assert_helpers.equal(totals.casts, 0)
    assert_helpers.equal(next(totals.runes_used), nil)
    assert_helpers.equal(totals.gp, 0)
    assert_helpers.equal(#totals.unpriced_items, 0)
    assert_helpers.equal(#totals.estimated_items, 0)
end

function tests.uses_fallback_price_when_price_is_missing()
    local tracker = new_tracker({
        get_price = price_list({ ["Bone rune"] = 100 }),
        fallback_prices = { ["Bone rune"] = 350, ["Soul rune"] = 50 },
    })

    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.gp, 8 * 100 + 6 * 50)
    assert_helpers.equal(#totals.unpriced_items, 0)
    assert_helpers.equal(#totals.estimated_items, 1)
    assert_helpers.equal(totals.estimated_items[1], "Soul rune")
end

function tests.lists_rune_as_unpriced_when_it_has_no_fallback_price()
    local tracker = new_tracker({
        get_price = price_list({}),
        fallback_prices = { ["Bone rune"] = 350 },
    })

    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.gp, 8 * 350)
    assert_helpers.equal(totals.estimated_items[1], "Bone rune")
    assert_helpers.equal(totals.unpriced_items[1], "Soul rune")
end

function tests.keeps_listing_rune_that_was_estimated_for_an_earlier_cast()
    local prices = {}
    local tracker = new_tracker({
        runes_per_cast = { ["Bone rune"] = 8 },
        get_price = price_list(prices),
        fallback_prices = { ["Bone rune"] = 350 },
    })

    tracker:on_cast(no_gear)
    prices["Bone rune"] = 100
    tracker:on_cast(no_gear)

    local totals = tracker:totals()
    assert_helpers.equal(totals.gp, 8 * 350 + 8 * 100)
    assert_helpers.equal(totals.estimated_items[1], "Bone rune")
end

function tests.totals_cannot_modify_tracker_state()
    local tracker = new_tracker()
    tracker:on_cast(no_gear)

    tracker:totals().runes_used["Bone rune"] = 0

    assert_helpers.equal(tracker:totals().runes_used["Bone rune"], 8)
end

return tests
