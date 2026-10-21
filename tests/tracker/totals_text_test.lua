local totals_text = require("src/tracker/totals_text")
local assert_helpers = require("tests/helpers/assert")

local tests = {}

function tests.lists_runes_alphabetically_without_cost_when_unpriced()
    local lines = totals_text.lines({
        casts = 2,
        runes_used = { ["Soul rune"] = 12, ["Bone rune"] = 16 },
        gp = nil,
        unpriced_items = {},
    })

    assert_helpers.same_lines(lines, {
        "Lord of Bones stalls: 2",
        "Bone rune: 16",
        "Soul rune: 12",
    })
end

function tests.formats_cost_with_thousand_separators()
    local lines = totals_text.lines({ casts = 0, runes_used = {}, gp = 1234567, unpriced_items = {} })

    assert_helpers.equal(lines[2], "Cost: 1,234,567 gp")
end

function tests.formats_small_cost_without_leading_separator()
    local lines = totals_text.lines({ casts = 0, runes_used = {}, gp = 414, unpriced_items = {} })

    assert_helpers.equal(lines[2], "Cost: 414 gp")
end

function tests.notes_items_without_a_price()
    local lines = totals_text.lines({ casts = 0, runes_used = {}, gp = 0, unpriced_items = { "Astral rune", "Soul rune" } })

    assert_helpers.equal(lines[2], "Cost: 0 gp (no price: Astral rune, Soul rune)")
end

function tests.notes_items_priced_with_fallback_price()
    local lines = totals_text.lines({
        casts = 1,
        runes_used = {},
        gp = 4530,
        unpriced_items = {},
        estimated_items = { "Bone rune", "Flesh rune" },
    })

    assert_helpers.equal(lines[2], "Cost: 4,530 gp (estimated: Bone rune, Flesh rune)")
end

function tests.cost_lines_only_show_the_cost()
    local lines = totals_text.cost_lines({
        casts = 3,
        runes_used = { ["Bone rune"] = 18 },
        gp = 13590,
        estimated_items = { "Bone rune" },
        unpriced_items = {},
    })

    assert_helpers.same_lines(lines, { "Cost: 13,590 gp (estimated: Bone rune)" })
end

function tests.cost_lines_say_unknown_without_a_price_source()
    local lines = totals_text.cost_lines({ casts = 1, runes_used = {}, gp = nil, unpriced_items = {} })

    assert_helpers.same_lines(lines, { "Cost: unknown" })
end

local totals = {
    casts = 2,
    runes_used = { ["Bone rune"] = 12, ["Spirit rune"] = 16 },
    gp = 9060,
    unpriced_items = {},
}

function tests.can_leave_out_the_cast_count()
    local lines = totals_text.lines(totals, { casts = false, runes = true, cost = true })

    assert_helpers.same_lines(lines, { "Bone rune: 12", "Spirit rune: 16", "Cost: 9,060 gp" })
end

function tests.can_leave_out_the_runes()
    local lines = totals_text.lines(totals, { casts = true, runes = false, cost = true })

    assert_helpers.same_lines(lines, { "Lord of Bones stalls: 2", "Cost: 9,060 gp" })
end

function tests.can_leave_out_the_cost()
    local lines = totals_text.lines(totals, { casts = true, runes = true, cost = false })

    assert_helpers.same_lines(lines, { "Lord of Bones stalls: 2", "Bone rune: 12", "Spirit rune: 16" })
end

return tests
