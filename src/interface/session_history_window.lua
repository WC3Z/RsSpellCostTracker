-- A small, movable window listing past sessions, opened from the Session tab
-- of the cost tracker window.
local TextLines = require("src/interface/text_lines")
local window_bounds = require("src/interface/window_bounds")

local session_history_window = {}

local window
---@type TextLines
local text

local bounds_key = "SessionHistoryWindow"

-- The main game screen, so the window can be moved anywhere over the game.
local function game_area()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
end

-- Opens the window, or brings it to the front if it is already open.
---@param lines Line[]
function session_history_window.open(lines)
    if window then
        window:Show()
        text:set(lines)
        return
    end
    local bounds = window_bounds.load(bounds_key, 260, 160)
    window = prettyui.Window.new(game_area(), {
        categoryID = "auto",
        title = "Past sessions",
        x = bounds.x,
        y = bounds.y,
        width = bounds.width,
        height = bounds.height,
        resizable = true,
        minWidth = 120,
        minHeight = 60,
        destroyOnClose = true,
        onClose = function(closing)
            window_bounds.save_from(bounds_key, closing)
            window = nil
            text = nil
        end,
        onPositionChange = window_bounds.position_saver(bounds_key),
    })
    text = TextLines.new(window)
    text:set(lines)
end

-- Shows the latest list if the window is open. The list never gets shorter
-- (old sessions are only dropped to make room for new ones), so the lines can
-- just be updated in place.
---@param lines Line[]
function session_history_window.refresh(lines)
    if window then
        text:set(lines)
    end
end

-- Removes the window, e.g. when the plugin is turned off.
function session_history_window.destroy()
    if window then
        window_bounds.save_from(bounds_key, window)
        window:Destroy()
        window = nil
        text = nil
    end
end

return session_history_window
