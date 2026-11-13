local session_history_window = require("src/interface/session_history_window")
local fake_prettyui = require("tests/helpers/fake_prettyui")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local game_area = { width = 1920, height = 1080 }

-- Fakes for the game's ui and id globals, which give us the main game screen.
-- Also returns the saved values (see fake_persistent_db), after the created list.
local function install_fakes()
    id = { Component = { TOPLEVEL_V2__GAME_AREA = 42 } }
    ui = {
        Interfaces = {
            GetComponent = function(_, component_id)
                if component_id == 42 then return game_area end
            end,
        },
    }
    local stored = fake_persistent_db.install()
    return fake_prettyui.install(), stored
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

function tests.dragging_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    session_history_window.open({ "a" })

    created[1].options.onPositionChange(created[1], 310.6, 205)

    assert_helpers.equal(stored["SessionHistoryWindow.x"], 310)
    assert_helpers.equal(stored["SessionHistoryWindow.y"], 205)
    session_history_window.destroy()
end

function tests.opens_where_it_was_last_dragged_to()
    local created, stored = install_fakes()
    stored["SessionHistoryWindow.x"] = 310
    stored["SessionHistoryWindow.y"] = 205

    session_history_window.open({ "a" })

    assert_helpers.equal(created[1].options.x, 310)
    assert_helpers.equal(created[1].options.y, 205)
    session_history_window.destroy()
end

function tests.opens_in_the_default_spot_when_never_dragged()
    local created = install_fakes()

    session_history_window.open({ "a" })

    assert_helpers.equal(created[1].options.x, nil)
    assert_helpers.equal(created[1].options.y, nil)
    session_history_window.destroy()
end

function tests.closing_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    session_history_window.open({ "a" })
    created[1].root.x, created[1].root.y = 410, 305

    created[1]:Close()

    assert_helpers.equal(stored["SessionHistoryWindow.x"], 410)
    assert_helpers.equal(stored["SessionHistoryWindow.y"], 305)
end

function tests.removing_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    session_history_window.open({ "a" })
    created[1].root.x, created[1].root.y = 410, 305

    session_history_window.destroy()

    assert_helpers.equal(stored["SessionHistoryWindow.x"], 410)
    assert_helpers.equal(stored["SessionHistoryWindow.y"], 305)
end

function tests.closing_the_window_saves_how_big_it_is()
    local created, stored = install_fakes()
    session_history_window.open({ "a" })
    created[1].root.width, created[1].root.height = 400.7, 250

    created[1]:Close()

    assert_helpers.equal(stored["SessionHistoryWindow.width"], 400)
    assert_helpers.equal(stored["SessionHistoryWindow.height"], 250)
end

function tests.removing_the_window_saves_how_big_it_is()
    local created, stored = install_fakes()
    session_history_window.open({ "a" })
    created[1].root.width, created[1].root.height = 400, 250

    session_history_window.destroy()

    assert_helpers.equal(stored["SessionHistoryWindow.width"], 400)
    assert_helpers.equal(stored["SessionHistoryWindow.height"], 250)
end

function tests.opens_as_big_as_it_was_last_left()
    local created, stored = install_fakes()
    stored["SessionHistoryWindow.width"] = 400
    stored["SessionHistoryWindow.height"] = 250

    session_history_window.open({ "a" })

    assert_helpers.equal(created[1].options.width, 400)
    assert_helpers.equal(created[1].options.height, 250)
    session_history_window.destroy()
end

function tests.opens_at_the_default_size_the_first_time()
    local created = install_fakes()

    session_history_window.open({ "a" })

    assert_helpers.equal(created[1].options.width, 260)
    assert_helpers.equal(created[1].options.height, 160)
    session_history_window.destroy()
end

return tests
