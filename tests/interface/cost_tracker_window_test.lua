local cost_tracker_window = require("src/interface/cost_tracker_window")
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

    cost_tracker_window.open({ "Cost: 4,530 gp" })

    local window = created[1]
    assert_helpers.equal(window.kind, "Window")
    assert_helpers.equal(window.parent, game_area)
    assert_helpers.same_lines(window:visible_lines(), { "Cost: 4,530 gp" })
    cost_tracker_window.destroy()
end

function tests.opening_again_reuses_the_window()
    local created = install_fakes()
    cost_tracker_window.open({ "Cost: 4,530 gp" })

    cost_tracker_window.open({ "Cost: 9,060 gp" })

    assert_helpers.equal(#created, 1)
    assert_helpers.equal(created[1].shown, 1)
    assert_helpers.same_lines(created[1]:visible_lines(), { "Cost: 9,060 gp" })
    cost_tracker_window.destroy()
end

function tests.refresh_updates_the_open_window()
    local created = install_fakes()
    cost_tracker_window.open({ "Cost: 4,530 gp" })

    cost_tracker_window.refresh({ "Cost: 9,060 gp" })

    assert_helpers.same_lines(created[1]:visible_lines(), { "Cost: 9,060 gp" })
    cost_tracker_window.destroy()
end

function tests.closing_the_window_lets_it_be_opened_again()
    local created = install_fakes()
    cost_tracker_window.open({ "a" })

    created[1]:Close()
    cost_tracker_window.refresh({ "b" })
    cost_tracker_window.open({ "c" })

    assert_helpers.same_lines(created[1]:visible_lines(), { "a" })
    assert_helpers.equal(#created, 2)
    assert_helpers.same_lines(created[2]:visible_lines(), { "c" })
    cost_tracker_window.destroy()
end

function tests.destroy_removes_the_window()
    local created = install_fakes()
    cost_tracker_window.open({ "a" })

    cost_tracker_window.destroy()
    cost_tracker_window.refresh({ "b" })

    assert_helpers.equal(created[1].destroyed, true)
    assert_helpers.same_lines(created[1]:visible_lines(), { "a" })
end

return tests
