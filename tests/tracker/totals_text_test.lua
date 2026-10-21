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
    local lines = totals_text.cost_lines({ spell("Darkness", "Darkness", { gp = 1234567 }) })

    assert_helpers.same_lines(lines, { "Darkness: 1,234,567 gp", "Total: 1,234,567 gp" })
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

function tests.notes_items_priced_with_fallback_price()
    local lines = totals_text.cost_lines({
        spell("Darkness", "Darkness", { gp = 4530, estimated_items = { "Bone rune", "Flesh rune" } }),
    })

    assert_helpers.equal(lines[1], "Darkness: 4,530 gp (estimated: Bone rune, Flesh rune)")
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

return tests
