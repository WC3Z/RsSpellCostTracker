local display_settings = require("src/interface/display_settings")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local function option(name)
    for _, candidate in ipairs(display_settings.options) do
        if candidate.name == name then return candidate end
    end
end

local tests = {}

function tests.everything_is_shown_when_nothing_is_saved()
    fake_persistent_db.install()

    local shown = display_settings.current()

    assert_helpers.equal(shown.casts, true)
    assert_helpers.equal(shown.runes, true)
    assert_helpers.equal(shown.cost, true)
end

function tests.a_setting_turned_off_is_saved_and_hidden()
    local stored = fake_persistent_db.install()

    display_settings.set(option("runes"), false)

    assert_helpers.equal(stored.showRunes, false)
    assert_helpers.equal(display_settings.current().runes, false)
    assert_helpers.equal(display_settings.current().casts, true)
end

return tests
