-- A separate, movable window with the spell totals on the main game screen,
-- opened from the plugin's page.
local TextLines = require("src/interface/text_lines")

local cost_tracker_window = {}

local window
local text

-- The main game screen, so the window can be moved anywhere over the game.
local function game_area()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
end

-- Opens the window, or brings it to the front if it is already open.
function cost_tracker_window.open(lines)
    if window then
        window:Show()
        text:set(lines)
        return
    end

    window = prettyui.Window.new(game_area(), {
        title = "Spell costs",
        width = 260,
        height = 160,
        resizable = true,
        -- prettyui's default minimum is 220 x 140, which is bigger than a single cost line needs.
        minWidth = 120,
        minHeight = 60,
        -- The content is a handful of lines, so it is resized rather than scrolled.
        scrollable = false,
        destroyOnClose = true,
        onClose = function()
            window = nil
            text = nil
        end,
    })
    text = TextLines.new(window)
    text:set(lines)
end

-- Shows the latest lines if the window is open.
function cost_tracker_window.refresh(lines)
    if text then
        text:set(lines)
    end
end

-- Removes the window, e.g. when the plugin is turned off.
function cost_tracker_window.destroy()
    if window then
        window:Destroy()
        window = nil
        text = nil
    end
end

return cost_tracker_window
