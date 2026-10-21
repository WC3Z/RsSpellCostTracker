-- The plugin's page: choices for what the cost tracker window shows, a button
-- that opens it, and the total cost so far.
local TextLines = require("src/interface/text_lines")
local display_settings = require("src/interface/display_settings")

local content_view = {}

local subscription_name = "stall-cost-tracker-content"
local get_cost_lines
local on_settings_changed
local on_open_window
local view
local text

-- Each setting gets its own single-checkbox group, so onChange always refers
-- to that one setting. prettyui passes the new checked state as the 4th argument.
local function add_checkbox(option)
    view:AddCheckboxButton({
        { text = option.label, value = option.db_key, selected = display_settings.is_on(option) },
    }, {
        onChange = function(_, _, _, selected)
            display_settings.set(option, selected)
            on_settings_changed()
        end,
    })
end

-- callbacks.cost_lines() returns the cost text shown on this page.
-- callbacks.settings_changed() is called after a checkbox is toggled.
-- callbacks.open_window() is called when the player clicks "Open cost tracker".
function content_view.start(callbacks)
    get_cost_lines = callbacks.cost_lines
    on_settings_changed = callbacks.settings_changed
    on_open_window = callbacks.open_window
    Event.ContentLayerReady.Subscribe(subscription_name, function(event)
        -- The game fires this every time the page is shown, so replace any earlier view.
        if view then view:Destroy() end

        local parent = event.component
        view = prettyui.SimpleView.new(parent, {
            width = parent.width,
            height = parent.height,
        })

        view:AddTitle("Stall Cost Tracker")
        for _, option in ipairs(display_settings.options) do
            add_checkbox(option)
        end
        -- Wrapped so prettyui's button arguments (self, active) aren't passed on.
        view:AddSimpleButton("Open cost tracker", function()
            on_open_window()
        end)
        text = TextLines.new(view)
        text:set(get_cost_lines())
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
