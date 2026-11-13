local cost_tracker_window = require("src/interface/cost_tracker_window")
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

-- The lines for the window, with the session tab empty and paused unless given.
---@return WindowPages
local function pages(total, session, session_state)
    return { total = total, session = session or {}, session_state = session_state or "paused" }
end

-- Session controls that record which ones were used.
local function record_session_controls()
    local used = {}
    local function record(name) return function() table.insert(used, name) end end
    cost_tracker_window.set_session_controls({
        pause = record("pause"), resume = record("resume"),
        new_session = record("new_session"), show_history = record("show_history"),
    })
    return used
end

-- The pause/resume button on the Session tab.
local function pause_resume_button(window)
    return window.tabs:GetPage(2).sprite_buttons[1]
end

-- A text button on the Session tab.
local function session_button(window, label)
    return window.tabs:GetPage(2).buttons[label]
end

-- The visible lines on the Total tab (1) or Session tab (2).
local function tab_lines(window, index)
    return window.tabs:GetPage(index):visible_lines()
end

local tests = {}

function tests.opens_a_window_on_the_game_area_with_the_lines()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "Cost: 4,530 gp" }))

    local window = created[1]
    assert_helpers.equal(window.kind, "Window")
    assert_helpers.equal(window.parent, game_area)
    assert_helpers.same_lines(tab_lines(window, 1), { "Cost: 4,530 gp" })
    cost_tracker_window.destroy()
end

function tests.opening_again_reuses_the_window()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "Cost: 4,530 gp" }))

    cost_tracker_window.open(pages({ "Cost: 9,060 gp" }))

    assert_helpers.equal(#created, 1)
    assert_helpers.equal(created[1].shown, 1)
    assert_helpers.same_lines(tab_lines(created[1], 1), { "Cost: 9,060 gp" })
    cost_tracker_window.destroy()
end

function tests.refresh_updates_the_open_window()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "Cost: 4,530 gp" }))

    cost_tracker_window.refresh(pages({ "Cost: 9,060 gp" }))

    assert_helpers.same_lines(tab_lines(created[1], 1), { "Cost: 9,060 gp" })
    cost_tracker_window.destroy()
end

function tests.more_lines_are_added_to_the_same_window()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }))

    cost_tracker_window.refresh(pages({ "a", "b" }))

    assert_helpers.equal(#created, 1)
    assert_helpers.same_lines(tab_lines(created[1], 1), { "a", "b" })
    cost_tracker_window.destroy()
end

function tests.fewer_lines_rebuild_the_window_where_it_was()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a", "b", "c" }))
    created[1].root = { x = 300, y = 200, width = 400, height = 250 }

    cost_tracker_window.refresh(pages({ "a" }))

    local rebuilt = created[2]
    assert_helpers.equal(created[1].destroyed, true)
    assert_helpers.equal(#rebuilt.tabs:GetPage(1).texts, 1)
    assert_helpers.same_lines(tab_lines(rebuilt, 1), { "a" })
    assert_helpers.equal(rebuilt.options.x, 300)
    assert_helpers.equal(rebuilt.options.y, 200)
    assert_helpers.equal(rebuilt.options.width, 400)
    assert_helpers.equal(rebuilt.options.height, 250)
    cost_tracker_window.destroy()
end

function tests.has_a_total_and_a_session_tab()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "Cost: 4,530 gp" }, { "Session running", "Cost: 90 gp" }))

    local window = created[1]
    assert_helpers.same_lines(window.tabs.labels, { "Total", "Session" })
    assert_helpers.equal(window.tabs:GetActiveIndex(), 1)
    assert_helpers.same_lines(tab_lines(window, 1), { "Cost: 4,530 gp" })
    assert_helpers.same_lines(tab_lines(window, 2), { "Session running", "Cost: 90 gp" })
    cost_tracker_window.destroy()
end

function tests.tabs_fill_the_window_and_scroll_instead_of_it()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "a" }))

    local window = created[1]
    assert_helpers.equal(window.options.scrollable, false)
    assert_helpers.equal(window.tabs.options.height, 0)
    assert_helpers.equal(window.tabs.options.heightAnchor, 1.0)
    assert_helpers.equal(window.tabs.options.scrollable, nil)
    cost_tracker_window.destroy()
end

function tests.resizing_the_window_re_measures_the_tabs_on_the_same_tab()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }))
    local window = created[1]
    window.tabs:SetActive(2)
    local refreshes = window.tabs.refreshes

    window:SetSize(300, 200)

    assert_helpers.equal(window.root.width, 300)
    assert_helpers.equal(window.tabs.refreshes, refreshes + 1)
    assert_helpers.equal(window.tabs:GetActiveIndex(), 2)
    cost_tracker_window.destroy()
end

function tests.paused_session_shows_resume()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "a" }, { "Session paused" }, "paused"))

    local button = pause_resume_button(created[1])
    assert_helpers.equal(button.sprite, "PLAY")
    assert_helpers.equal(button.tooltip, "Resume the session")
    cost_tracker_window.destroy()
end

function tests.pause_resume_button_follows_the_session_state()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }, { "s" }, "paused"))
    local button = pause_resume_button(created[1])

    cost_tracker_window.refresh(pages({ "a" }, { "s" }, "running"))
    assert_helpers.equal(button.sprite, "PAUSE")
    assert_helpers.equal(button.tooltip, "Pause the session")

    cost_tracker_window.refresh(pages({ "a" }, { "s" }, "paused"))
    assert_helpers.equal(button.sprite, "PLAY")
    cost_tracker_window.destroy()
end

function tests.pause_resume_button_uses_the_control_for_the_state()
    local created = install_fakes()
    local used = record_session_controls()
    cost_tracker_window.open(pages({ "a" }, { "s" }, "paused"))
    local button = pause_resume_button(created[1])

    button.on_click()
    cost_tracker_window.refresh(pages({ "a" }, { "s" }, "running"))
    button.on_click()

    assert_helpers.same_lines(used, { "resume", "pause" })
    cost_tracker_window.destroy()
end

function tests.new_session_asks_for_confirmation_first()
    local created = install_fakes()
    local used = record_session_controls()
    cost_tracker_window.open(pages({ "a" }))

    session_button(created[1], "New session")()
    assert_helpers.same_lines(used, {})

    local confirm = created[2]
    assert_helpers.equal(confirm.kind, "Confirm")
    assert_helpers.equal(confirm.parent, game_area)
    confirm.options.onConfirm()
    assert_helpers.same_lines(used, { "new_session" })
    cost_tracker_window.destroy()
end

function tests.past_sessions_button_shows_the_history()
    local created = install_fakes()
    local used = record_session_controls()
    cost_tracker_window.open(pages({ "a" }))

    session_button(created[1], "Past sessions")("extra", "arguments")

    assert_helpers.same_lines(used, { "show_history" })
    cost_tracker_window.destroy()
end

function tests.a_rebuilt_window_shows_the_pause_resume_button_for_the_state()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a", "b" }, { "s" }, "paused"))

    cost_tracker_window.refresh(pages({ "a" }, { "s" }, "running"))

    assert_helpers.equal(pause_resume_button(created[2]).sprite, "PAUSE")
    cost_tracker_window.destroy()
end

function tests.fewer_session_lines_rebuild_the_window_on_the_same_tab()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }, { "b", "c" }))
    created[1].tabs:SetActive(2)

    cost_tracker_window.refresh(pages({ "a" }, { "b" }))

    local rebuilt = created[2]
    assert_helpers.equal(created[1].destroyed, true)
    assert_helpers.equal(rebuilt.tabs:GetActiveIndex(), 2)
    assert_helpers.same_lines(tab_lines(rebuilt, 2), { "b" })
    cost_tracker_window.destroy()
end

function tests.a_rebuilt_window_can_still_be_closed_and_reopened()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a", "b" }))
    cost_tracker_window.refresh(pages({ "a" }))

    created[2]:Close()
    cost_tracker_window.open(pages({ "c" }))

    assert_helpers.equal(#created, 3)
    assert_helpers.same_lines(tab_lines(created[3], 1), { "c" })
    cost_tracker_window.destroy()
end

function tests.closing_the_window_lets_it_be_opened_again()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }))

    created[1]:Close()
    cost_tracker_window.refresh(pages({ "b" }))
    cost_tracker_window.open(pages({ "c" }))

    assert_helpers.same_lines(tab_lines(created[1], 1), { "a" })
    assert_helpers.equal(#created, 2)
    assert_helpers.same_lines(tab_lines(created[2], 1), { "c" })
    cost_tracker_window.destroy()
end

function tests.destroy_removes_the_window()
    local created = install_fakes()
    cost_tracker_window.open(pages({ "a" }))

    cost_tracker_window.destroy()
    cost_tracker_window.refresh(pages({ "b" }))

    assert_helpers.equal(created[1].destroyed, true)
    assert_helpers.same_lines(tab_lines(created[1], 1), { "a" })
end

function tests.window_is_solid_by_default()
    local created = install_fakes()
    cost_tracker_window.set_transparent(false)

    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(created[1].background.rgba, 0xFFFFFFFF)
    cost_tracker_window.destroy()
end

function tests.set_transparent_changes_the_open_window()
    local created = install_fakes()
    cost_tracker_window.set_transparent(false)
    cost_tracker_window.open(pages({ "a" }))

    cost_tracker_window.set_transparent(true)

    assert_helpers.equal(created[1].background.rgba < 0xFFFFFFFF, true)
    cost_tracker_window.set_transparent(false)
    assert_helpers.equal(created[1].background.rgba, 0xFFFFFFFF)
    cost_tracker_window.destroy()
end

function tests.stays_transparent_when_rebuilt_or_reopened()
    local created = install_fakes()
    cost_tracker_window.set_transparent(true)
    cost_tracker_window.open(pages({ "a", "b" }))

    cost_tracker_window.refresh(pages({ "a" }))
    cost_tracker_window.destroy()
    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(#created, 3)
    assert_helpers.equal(created[2].background.rgba < 0xFFFFFFFF, true)
    assert_helpers.equal(created[3].background.rgba < 0xFFFFFFFF, true)
    cost_tracker_window.set_transparent(false)
    cost_tracker_window.destroy()
end

function tests.dragging_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    cost_tracker_window.open(pages({ "a" }))

    created[1].options.onPositionChange(created[1], 310.6, 205)

    assert_helpers.equal(stored["CostTrackerWindow.x"], 310)
    assert_helpers.equal(stored["CostTrackerWindow.y"], 205)
    cost_tracker_window.destroy()
end

function tests.opens_where_it_was_last_dragged_to()
    local created, stored = install_fakes()
    stored["CostTrackerWindow.x"] = 310
    stored["CostTrackerWindow.y"] = 205

    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(created[1].options.x, 310)
    assert_helpers.equal(created[1].options.y, 205)
    cost_tracker_window.destroy()
end

function tests.opens_in_the_default_spot_when_never_dragged()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(created[1].options.x, nil)
    assert_helpers.equal(created[1].options.y, nil)
    cost_tracker_window.destroy()
end

function tests.closing_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    cost_tracker_window.open(pages({ "a" }))
    created[1].root.x, created[1].root.y = 410, 305

    created[1]:Close()

    assert_helpers.equal(stored["CostTrackerWindow.x"], 410)
    assert_helpers.equal(stored["CostTrackerWindow.y"], 305)
end

function tests.removing_the_window_saves_where_it_is()
    local created, stored = install_fakes()
    cost_tracker_window.open(pages({ "a" }))
    created[1].root.x, created[1].root.y = 410, 305

    cost_tracker_window.destroy()

    assert_helpers.equal(stored["CostTrackerWindow.x"], 410)
    assert_helpers.equal(stored["CostTrackerWindow.y"], 305)
end

function tests.closing_the_window_saves_how_big_it_is()
    local created, stored = install_fakes()
    cost_tracker_window.open(pages({ "a" }))
    created[1].root.width, created[1].root.height = 400.7, 250

    created[1]:Close()

    assert_helpers.equal(stored["CostTrackerWindow.width"], 400)
    assert_helpers.equal(stored["CostTrackerWindow.height"], 250)
end

function tests.removing_the_window_saves_how_big_it_is()
    local created, stored = install_fakes()
    cost_tracker_window.open(pages({ "a" }))
    created[1].root.width, created[1].root.height = 400, 250

    cost_tracker_window.destroy()

    assert_helpers.equal(stored["CostTrackerWindow.width"], 400)
    assert_helpers.equal(stored["CostTrackerWindow.height"], 250)
end

function tests.opens_as_big_as_it_was_last_left()
    local created, stored = install_fakes()
    stored["CostTrackerWindow.width"] = 400
    stored["CostTrackerWindow.height"] = 250

    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(created[1].options.width, 400)
    assert_helpers.equal(created[1].options.height, 250)
    cost_tracker_window.destroy()
end

function tests.opens_at_the_default_size_the_first_time()
    local created = install_fakes()

    cost_tracker_window.open(pages({ "a" }))

    assert_helpers.equal(created[1].options.width, 260)
    assert_helpers.equal(created[1].options.height, 160)
    cost_tracker_window.destroy()
end

return tests
