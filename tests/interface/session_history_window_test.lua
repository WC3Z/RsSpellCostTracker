local session_history_window = require("src/interface/session_history_window")
local fake_prettyui = require("tests/helpers/fake_prettyui")
local assert_helpers = require("tests/helpers/assert")

local game_area = { width = 1920, height = 1080 }

-- Fakes for the game's ui and id globals, which give us the main game screen.
local function install_fakes()
    id = { Component = { TOPLEVEL_V2__GAME_AREA = 42 } }
    ui = {
        Interfaces = {
            GetComponent = function(_, component_id)
                if component_id == 42 then return game_area end
            end,
        },
    }
    return fake_prettyui.install()
end

local tests = {}

function tests.opens_a_window_on_the_game_area_with_the_lines()
    local created = install_fakes()

    session_history_window.open({ "a", "b" })

    local window = created[1]
    assert_helpers.equal(window.kind, "Window")
    assert_helpers.equal(window.parent, game_area)
    assert_helpers.same_lines(window:visible_lines(), { "a", "b" })
    session_history_window.destroy()
end

function tests.opening_again_reuses_the_window()
    local created = install_fakes()
    session_history_window.open({ "a" })

    session_history_window.open({ "b", "a" })

    assert_helpers.equal(#created, 1)
    assert_helpers.equal(created[1].shown, 1)
    assert_helpers.same_lines(created[1]:visible_lines(), { "b", "a" })
    session_history_window.destroy()
end

function tests.refresh_only_updates_an_open_window()
    local created = install_fakes()

    session_history_window.refresh({ "a" })
    assert_helpers.equal(#created, 0)

    session_history_window.open({ "a" })
    session_history_window.refresh({ "b", "a" })
    assert_helpers.same_lines(created[1]:visible_lines(), { "b", "a" })
    session_history_window.destroy()
end

function tests.closing_lets_it_be_opened_again()
    local created = install_fakes()
    session_history_window.open({ "a" })

    created[1]:Close()
    session_history_window.open({ "b" })

    assert_helpers.equal(#created, 2)
    session_history_window.destroy()
end

return tests
