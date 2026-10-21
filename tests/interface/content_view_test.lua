local content_view = require("src/interface/content_view")
local fake_prettyui = require("tests/helpers/fake_prettyui")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

-- A fake game Event global that keeps track of ContentLayerReady subscriptions.
local function install_fake_event()
    local subscriptions = {}
    Event = {
        ContentLayerReady = {
            Subscribe = function(name, handler)
                subscriptions[name] = handler
            end,
            Unsubscribe = function(name)
                subscriptions[name] = nil
            end,
        },
    }
    return subscriptions
end

local function install_fakes()
    return install_fake_event(), fake_prettyui.install(), fake_persistent_db.install()
end

local function open_page(subscriptions, created)
    for _, handler in pairs(subscriptions) do
        handler({ component = { width = 100, height = 100 } })
    end
    return created[#created]
end

-- Callbacks for content_view.start; pass overrides for the ones a test cares about.
local function callbacks(overrides)
    local result = {
        cost_lines = function() return { "Cost: 4,530 gp" } end,
        settings_changed = function() end,
        open_window = function() end,
    }
    for name, callback in pairs(overrides or {}) do
        result[name] = callback
    end
    return result
end

local tests = {}

function tests.opening_the_page_shows_the_settings_button_and_cost()
    local subscriptions, created = install_fakes()
    content_view.start(callbacks())

    local view = open_page(subscriptions, created)

    assert_helpers.equal(view.title, "Spell Cost Tracker")
    assert_helpers.same_lines(view.checkbox_order, {
        "onlyLordOfBonesStalls", "showCasts", "showRunes", "showCost",
        "showLordOfBonesCost", "showAnimateDeadCost", "showVampyrismCost", "showPenanceCost", "showDarknessCost",
    })
    assert_helpers.equal(view.checkboxes.showCasts.text, "Show cast count")
    assert_helpers.equal(view.checkboxes.showAnimateDeadCost.text, "Show Animate Dead cost")
    assert_helpers.equal(view.buttons["Open cost tracker"] ~= nil, true)
    assert_helpers.same_lines(view:visible_lines(), { "Cost: 4,530 gp" })
    content_view.stop()
end

function tests.only_stalls_checkbox_explains_itself_in_a_tooltip()
    local subscriptions, created = install_fakes()
    content_view.start(callbacks())

    local view = open_page(subscriptions, created)

    assert_helpers.equal(type(view.checkboxes.onlyLordOfBonesStalls.tooltip), "string")
    assert_helpers.equal(view.checkboxes.showCasts.tooltip, nil)
    content_view.stop()
end

function tests.checkboxes_show_the_saved_settings()
    local subscriptions, created, stored = install_fakes()
    stored.showRunes = false
    content_view.start(callbacks())

    local view = open_page(subscriptions, created)

    assert_helpers.equal(view.checkboxes.showCasts.selected, true)
    assert_helpers.equal(view.checkboxes.showRunes.selected, false)
    content_view.stop()
end

function tests.toggling_a_checkbox_saves_it_and_reports_the_change()
    local subscriptions, created, stored = install_fakes()
    local changes = 0
    content_view.start(callbacks({ settings_changed = function() changes = changes + 1 end }))
    local view = open_page(subscriptions, created)

    view.checkboxes.showCost.on_change(nil, nil, nil, false)

    assert_helpers.equal(stored.showCost, false)
    assert_helpers.equal(changes, 1)
    content_view.stop()
end

function tests.open_cost_tracker_button_opens_the_window()
    local subscriptions, created = install_fakes()
    local opened = false
    content_view.start(callbacks({ open_window = function() opened = true end }))
    local view = open_page(subscriptions, created)

    view.buttons["Open cost tracker"]()

    assert_helpers.equal(opened, true)
    content_view.stop()
end

function tests.refresh_updates_the_cost_without_rebuilding_the_page()
    local subscriptions, created = install_fakes()
    local cost = "Cost: 4,530 gp"
    content_view.start(callbacks({ cost_lines = function() return { cost } end }))
    local view = open_page(subscriptions, created)

    cost = "Cost: 9,060 gp"
    content_view.refresh()

    assert_helpers.equal(#created, 1)
    assert_helpers.same_lines(view:visible_lines(), { "Cost: 9,060 gp" })
    content_view.stop()
end

function tests.refresh_does_nothing_before_the_page_is_opened()
    local _, created = install_fakes()
    content_view.start(callbacks())

    content_view.refresh()

    assert_helpers.equal(#created, 0)
    content_view.stop()
end

function tests.stop_unsubscribes_and_destroys_the_view()
    local subscriptions, created = install_fakes()
    content_view.start(callbacks())
    local view = open_page(subscriptions, created)

    content_view.stop()
    content_view.refresh()

    assert_helpers.equal(view.destroyed, true)
    assert_helpers.equal(next(subscriptions), nil)
end

return tests
