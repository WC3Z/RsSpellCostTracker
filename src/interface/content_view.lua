-- The plugin's page. The Costs tab has buttons to open the cost tracker window
-- and to reset the totals, and the cost of each spell so far. The Settings tab
-- has the player's settings.
local TextLines = require("src/interface/text_lines")
local player_settings = require("src/interface/player_settings")

local content_view = {}

local subscription_name = "spell-cost-tracker-content"
local get_cost_lines
local on_settings_changed
local on_open_window
local on_reset_totals
local view
local text

-- Adds a checkbox for one setting. Each checkbox is added on its own, so when
-- it changes we know which setting it was. prettyui gives the new on/off state
-- as the 4th argument.
---@param page table The prettyui tab page to add it to
---@param option PlayerSetting
local function add_checkbox(page, option)
    page:AddCheckboxButton({
        {
            text = option.label,
            value = option.db_key,
            selected = player_settings.is_on(option),
            tooltip = option.tooltip,
        },
    }, {
        onChange = function(_, _, _, selected)
            player_settings.set(option, selected)
            on_settings_changed()
        end,
    })
end

-- Asks the player to confirm before the totals are reset, since that can't
-- be undone.
local function confirm_reset(parent)
    prettyui.Confirm.new(parent, {
        title = "Reset totals",
        body = "This sets the casts and cost of every spell back to zero, in the session too. This can't be undone.",
        confirmLabel = "RESET",
        onConfirm = function()
            on_reset_totals()
        end,
    })
end

-- What the page asks main.lua to do.
---@class ContentViewCallbacks
---@field cost_lines fun(): Line[] Gives the cost text to show on the page
---@field settings_changed fun() Called when the player ticks or unticks a checkbox
---@field open_window fun() Called when the player clicks "Open cost tracker"
---@field reset_totals fun() Called when the player confirms "Reset totals"

-- Sets up the page.
---@param callbacks ContentViewCallbacks
function content_view.start(callbacks)
    get_cost_lines = callbacks.cost_lines
    on_settings_changed = callbacks.settings_changed
    on_open_window = callbacks.open_window
    on_reset_totals = callbacks.reset_totals
    Event.ContentLayerReady.Subscribe(subscription_name, function(event)
        -- This runs every time the page is opened, so throw away the old one first.
        if view then view:Destroy() end

        local parent = event.component
        view = prettyui.SimpleView.new(parent, {
            width = parent.width,
            height = parent.height,
            -- The tabs scroll instead, see below.
            scrollable = false,
        })
        -- prettyui tabs keep a fixed height and never grow to fit what is on
        -- them, so they are made to fill the page, and each tab scrolls.
        local tabs = view:AddTabs({ "Costs", "Settings" }, { y = 0, height = 0, heightAnchor = 1.0 })

        local costs = tabs:GetPage(1)
        costs:AddTitle("Spell Cost Tracker")
        -- Wrapped so the extra arguments prettyui passes to button clicks aren't passed on.
        costs:AddSimpleButton("Open cost tracker", function()
            on_open_window()
        end)
        costs:AddSimpleButton("Reset totals", function()
            confirm_reset(parent)
        end)
        text = TextLines.new(costs)
        text:set(get_cost_lines())

        local settings_page = tabs:GetPage(2)
        add_checkbox(settings_page, player_settings.only_stalls_option)
        add_checkbox(settings_page, player_settings.iron_btw_option)
        add_checkbox(settings_page, player_settings.transparent_window_option)
        for _, option in ipairs(player_settings.options) do
            add_checkbox(settings_page, option)
        end
        for _, option in ipairs(player_settings.spell_options) do
            add_checkbox(settings_page, option)
        end
    end)
end

-- Shows the latest cost if the page has been opened.
function content_view.refresh()
    if text then
        text:set(get_cost_lines())
    end
end

function content_view.stop()
    Event.ContentLayerReady.Unsubscribe(subscription_name)
    if view then
        view:Destroy()
        view = nil
        text = nil
    end
end

return content_view
