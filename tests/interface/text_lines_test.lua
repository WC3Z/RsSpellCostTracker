local TextLines = require("src/interface/text_lines")
local fake_prettyui = require("tests/helpers/fake_prettyui")
local assert_helpers = require("tests/helpers/assert")

local function new_view()
    fake_prettyui.install()
    return prettyui.SimpleView.new()
end

local tests = {}

function tests.adds_a_row_per_line()
    local view = new_view()
    local text = TextLines.new(view)

    text:set({ "a", "b" })

    assert_helpers.same_lines(view:visible_lines(), { "a", "b" })
end

function tests.updates_existing_rows_in_place()
    local view = new_view()
    local text = TextLines.new(view)
    text:set({ "a" })
    local first_row = view.texts[1]

    text:set({ "b", "c" })

    assert_helpers.equal(view.texts[1], first_row)
    assert_helpers.same_lines(view:visible_lines(), { "b", "c" })
end

function tests.blanks_rows_that_are_no_longer_needed()
    local view = new_view()
    local text = TextLines.new(view)
    text:set({ "a", "b", "c" })

    text:set({ "only cost" })

    assert_helpers.equal(#view.texts, 3)
    assert_helpers.same_lines(view:visible_lines(), { "only cost" })
end

function tests.shows_a_line_with_a_tooltip()
    local view = new_view()
    local text = TextLines.new(view)

    text:set({ "a", { text = "b", tooltip = "about b" } })

    assert_helpers.same_lines(view:visible_lines(), { "a", "b" })
    assert_helpers.equal(view.texts[1].tooltip, nil)
    assert_helpers.equal(view.texts[2].tooltip, "about b")
    assert_helpers.equal(view.texts[2].tooltip_parent, view.content)
    assert_helpers.equal(view.texts[2].enabled, true)
end

function tests.moves_the_tooltip_along_with_its_line()
    local view = new_view()
    local text = TextLines.new(view)
    text:set({ "a", { text = "b", tooltip = "about b" } })

    text:set({ "a", "c", { text = "b", tooltip = "about b" } })

    assert_helpers.equal(view.texts[2].tooltip, nil)
    assert_helpers.equal(view.texts[3].tooltip, "about b")
end

function tests.updates_a_changed_tooltip()
    local view = new_view()
    local text = TextLines.new(view)
    text:set({ { text = "b", tooltip = "old" } })

    text:set({ { text = "b", tooltip = "new" } })

    assert_helpers.equal(view.texts[1].tooltip, "new")
end

function tests.removes_the_tooltip_of_a_blanked_row()
    local view = new_view()
    local text = TextLines.new(view)
    text:set({ "a", { text = "b", tooltip = "about b" } })

    text:set({ "a" })

    assert_helpers.equal(view.texts[2].tooltip, nil)
end

return tests
