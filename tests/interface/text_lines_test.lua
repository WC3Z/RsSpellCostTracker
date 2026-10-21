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

return tests
