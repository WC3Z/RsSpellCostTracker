local totals_text = require("src/tracker/totals_text")
local assert_helpers = require("tests/helpers/assert")

-- Totals for one spell, as SpellTracker:totals() returns them. overrides replaces any field.
local function spell(key, name, overrides)
    local result = {
        key = key,
        name = name,
        casts = 2,
        runes_used = { ["Spirit rune"] = 16, ["Bone rune"] = 12 },
        gp = 9060,
        estimated_gp = 0,
        unpriced_items = {},
        estimated_items = {},
    }
    for field, value in pairs(overrides or {}) do
        result[field] = value
    end
    return result
end

local lord_of_bones = spell("LordOfBones", "Lord of Bones")
local darkness = spell("Darkness", "Darkness", { casts = 1, runes_used = { ["Flesh rune"] = 10 }, gp = 6400 })
local penance_not_cast = spell("Penance", "Penance", { casts = 0, runes_used = {}, gp = 0 })

local tests = {}

function tests.lists_each_cast_spell_with_runes_alphabetically_and_cost()
    local lines = totals_text.lines({ lord_of_bones })

    assert_helpers.same_lines(lines, {
        "Lord of Bones: 2 casts",
        "  Bone rune: 12",
        "  Spirit rune: 16",
        "  Cost: 9,060 gp",
        "Total: 9,060 gp",
    })
end

function tests.says_cast_for_a_single_cast()
    local lines = totals_text.lines({ darkness }, { casts = true })

    assert_helpers.same_lines(lines, { "Darkness: 1 cast" })
end

function tests.leaves_out_spells_that_have_not_been_cast()
    local lines = totals_text.lines({ penance_not_cast, darkness }, { casts = true })

    assert_helpers.same_lines(lines, { "Darkness: 1 cast" })
end

function tests.says_so_when_nothing_has_been_cast()
    local lines = totals_text.lines({ penance_not_cast })

    assert_helpers.same_lines(lines, { "No spells cast yet" })
end

function tests.total_adds_up_the_shown_spells()
    local lines = totals_text.lines({ lord_of_bones, darkness }, { casts = true, cost = true, total = true })

    assert_helpers.same_lines(lines, {
        "Lord of Bones: 2 casts",
        "  Cost: 9,060 gp",
        "Darkness: 1 cast",
        "  Cost: 6,400 gp",
        "Total: 15,460 gp",
    })
end

function tests.leaves_out_hidden_spells_and_their_cost()
    local lines = totals_text.lines({ lord_of_bones, darkness }, {
        casts = true, cost = true, total = true, spells = { LordOfBones = false },
    })

    assert_helpers.same_lines(lines, { "Darkness: 1 cast", "  Cost: 6,400 gp", "Total: 6,400 gp" })
end

function tests.shows_the_total_without_each_spells_cost()
    local lines = totals_text.lines({ lord_of_bones, darkness }, { casts = true, cost = false, total = true })

    assert_helpers.same_lines(lines, { "Lord of Bones: 2 casts", "Darkness: 1 cast", "Total: 15,460 gp" })
end

function tests.can_hide_the_total()
    local lines = totals_text.lines({ lord_of_bones, darkness }, { casts = true, cost = true, total = false })

    assert_helpers.same_lines(lines, {
        "Lord of Bones: 2 casts",
        "  Cost: 9,060 gp",
        "Darkness: 1 cast",
        "  Cost: 6,400 gp",
    })
end

function tests.shows_only_the_name_without_the_cast_count()
    local lines = totals_text.lines({ darkness }, { casts = false, cost = true })

    assert_helpers.same_lines(lines, { "Darkness", "  Cost: 6,400 gp" })
end

function tests.can_leave_out_the_runes_and_cost()
    local lines = totals_text.lines({ lord_of_bones }, { casts = true, runes = false, cost = false })

    assert_helpers.same_lines(lines, { "Lord of Bones: 2 casts" })
end

function tests.formats_cost_with_thousand_separators()
    local lines = totals_text.cost_lines({ spell("Darkness", "Darkness", { gp = 12345 }) })

    assert_helpers.same_lines(lines, { "Darkness: 12,345 gp", "Total: 12,345 gp" })
end

function tests.shortens_large_costs_with_the_full_amount_in_a_tooltip()
    local lines = totals_text.cost_lines({ spell("Darkness", "Darkness", { gp = 1234567 }) })

    assert_helpers.same_lines(lines, { "Darkness: 1234K", "Total: 1234K" })
    assert_helpers.equal(lines[1].tooltip, "1,234,567 gp")
    assert_helpers.equal(lines[2].tooltip, "1,234,567 gp")
end

function tests.shortened_cost_still_notes_items_without_a_price()
    local lines = totals_text.cost_lines({
        spell("Darkness", "Darkness", { gp = 23456789, unpriced_items = { "Bone rune" } }),
    })

    assert_helpers.equal(lines[1].text, "Darkness: 23M (no price: Bone rune)")
    assert_helpers.equal(lines[1].tooltip, "23,456,789 gp")
end

function tests.puts_the_full_estimated_amount_before_the_runes_in_its_tooltip()
    local big_estimate = spell("Darkness", "Darkness", { estimated_gp = 150000, estimated_items = { "Bone rune" } })

    local lines = totals_text.cost_lines({ big_estimate })

    assert_helpers.equal(lines[#lines].text, "Estimated: 150K")
    assert_helpers.equal(
        lines[#lines].tooltip,
        "150,000 gp. The part of the cost that uses rough prices, because the real price wasn't available for: Bone rune"
    )
end

function tests.formats_small_cost_without_leading_separator()
    local lines = totals_text.cost_lines({ spell("Darkness", "Darkness", { gp = 414 }) })

    assert_helpers.equal(lines[1], "Darkness: 414 gp")
end

function tests.notes_items_without_a_price()
    local lines = totals_text.cost_lines({
        spell("Darkness", "Darkness", { gp = 0, unpriced_items = { "Bone rune", "Spirit rune" } }),
    })

    assert_helpers.equal(lines[1], "Darkness: 0 gp (no price: Bone rune, Spirit rune)")
end

local estimated_darkness = spell("Darkness", "Darkness", {
    casts = 1, runes_used = { ["Bone rune"] = 20 }, gp = 4530,
    estimated_gp = 1400, estimated_items = { "Flesh rune", "Bone rune" },
})

function tests.cost_does_not_mention_the_estimate()
    local lines = totals_text.cost_lines({ estimated_darkness })

    assert_helpers.equal(lines[1], "Darkness: 4,530 gp")
end

function tests.adds_the_estimated_part_under_the_total_with_the_runes_in_a_tooltip()
    local lines = totals_text.lines({ lord_of_bones, estimated_darkness }, { cost = true, total = true })

    assert_helpers.same_lines(lines, {
        "Lord of Bones",
        "  Cost: 9,060 gp",
        "Darkness",
        "  Cost: 4,530 gp",
        "Total: 13,590 gp",
        "Estimated: 1,400 gp",
    })
    assert_helpers.equal(
        lines[6].tooltip,
        "The part of the cost that uses rough prices, because the real price wasn't available for: Bone rune, Flesh rune"
    )
end

function tests.adds_up_the_estimated_part_of_each_shown_spell()
    local other = spell("Penance", "Penance", { estimated_gp = 100, estimated_items = { "Soul rune" } })

    local lines = totals_text.lines({ other, estimated_darkness }, { total = true })

    assert_helpers.equal(lines[#lines].text, "Estimated: 1,500 gp")
end

function tests.leaves_out_the_estimate_of_hidden_spells()
    local lines = totals_text.lines({ lord_of_bones, estimated_darkness }, {
        cost = true, total = true, spells = { Darkness = false },
    })

    assert_helpers.same_lines(lines, { "Lord of Bones", "  Cost: 9,060 gp", "Total: 9,060 gp" })
end

function tests.leaves_out_the_estimate_when_no_cost_is_shown()
    local lines = totals_text.lines({ estimated_darkness }, { casts = true, cost = false, total = false })

    assert_helpers.same_lines(lines, { "Darkness: 1 cast" })
end

function tests.cost_lines_end_with_the_estimate()
    local lines = totals_text.cost_lines({ estimated_darkness })

    assert_helpers.same_lines(lines, { "Darkness: 4,530 gp", "Total: 4,530 gp", "Estimated: 1,400 gp" })
end

function tests.cost_lines_show_every_cast_spell_and_the_total()
    local lines = totals_text.cost_lines({ lord_of_bones, penance_not_cast, darkness })

    assert_helpers.same_lines(lines, {
        "Lord of Bones: 9,060 gp",
        "Darkness: 6,400 gp",
        "Total: 15,460 gp",
    })
end

function tests.cost_lines_say_so_when_nothing_has_been_cast()
    local lines = totals_text.cost_lines({ penance_not_cast })

    assert_helpers.same_lines(lines, { "No spells cast yet" })
end

function tests.short_gp_keeps_amounts_below_100k_in_full()
    assert_helpers.equal(totals_text.format_gp_short(99999), "99,999 gp")
end

function tests.short_gp_rounds_down_to_whole_units_like_the_game()
    assert_helpers.equal(totals_text.format_gp_short(100000), "100K")
    assert_helpers.equal(totals_text.format_gp_short(9999999), "9999K")
    assert_helpers.equal(totals_text.format_gp_short(10000000), "10M")
    assert_helpers.equal(totals_text.format_gp_short(2147483647), "2147M")
    assert_helpers.equal(totals_text.format_gp_short(9999999999), "9999M")
    assert_helpers.equal(totals_text.format_gp_short(10000000000), "10B")
    assert_helpers.equal(totals_text.format_gp_short(12345678901), "12B")
end

return tests
