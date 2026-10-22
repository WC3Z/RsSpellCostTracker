local shop_cost = require("src/tracker/shop_cost")
local assert_helpers = require("tests/helpers/assert")

local function store_prices(prices)
    return function(item_name)
        return prices[item_name]
    end
end

-- One spell's totals as SpellTracker:totals() returns them, tracked at GE prices.
local function lord_of_bones(casts)
    return {
        key = "LordOfBones",
        name = "Lord of Bones",
        casts = casts,
        runes_used = { ["Spirit rune"] = 8 * casts, ["Bone rune"] = 6 * casts },
        gp = 9999,
        estimated_items = { "Bone rune" },
        unpriced_items = { "Spirit rune" },
    }
end

local tests = {}

function tests.prices_the_runes_used_at_shop_prices()
    local repriced = shop_cost.reprice({ lord_of_bones(2) }, store_prices({ ["Spirit rune"] = 100, ["Bone rune"] = 200 }))

    local spell = repriced[1]
    assert_helpers.equal(spell.gp, 16 * 100 + 12 * 200)
    assert_helpers.equal(spell.estimated_gp, 0)
    assert_helpers.equal(#spell.estimated_items, 0)
    assert_helpers.equal(#spell.unpriced_items, 0)
    assert_helpers.equal(spell.casts, 2)
    assert_helpers.equal(spell.name, "Lord of Bones")
end

function tests.uses_fallback_price_without_a_shop_price()
    local repriced = shop_cost.reprice(
        { lord_of_bones(1) },
        store_prices({ ["Spirit rune"] = 100 }),
        { ["Bone rune"] = 350 }
    )

    assert_helpers.equal(repriced[1].gp, 8 * 100 + 6 * 350)
    assert_helpers.equal(repriced[1].estimated_gp, 6 * 350)
    assert_helpers.same_lines(repriced[1].estimated_items, { "Bone rune" })
end

function tests.lists_runes_without_any_price_as_unpriced()
    local repriced = shop_cost.reprice({ lord_of_bones(1) }, store_prices({ ["Spirit rune"] = 100 }))

    assert_helpers.equal(repriced[1].gp, 8 * 100)
    assert_helpers.same_lines(repriced[1].unpriced_items, { "Bone rune" })
end

function tests.spells_not_cast_cost_nothing()
    local spell = lord_of_bones(0)
    spell.runes_used = {}

    local repriced = shop_cost.reprice({ spell }, store_prices({}))

    assert_helpers.equal(repriced[1].gp, 0)
end

function tests.does_not_change_the_tracked_totals()
    local spell = lord_of_bones(1)

    shop_cost.reprice({ spell }, store_prices({ ["Spirit rune"] = 100, ["Bone rune"] = 200 }))

    assert_helpers.equal(spell.gp, 9999)
    assert_helpers.same_lines(spell.estimated_items, { "Bone rune" })
end

return tests
