-- A separate, movable window with the spell totals on the main game screen,
-- opened from the plugin's page.
local TextLines = require("src/interface/text_lines")

local cost_tracker_window = {}

local window
local text
local line_count = 0

-- The main game screen, so the window can be moved anywhere over the game.
local function game_area()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
end

-- bounds: optional position and size; without it the window opens in prettyui's default spot.
local function create(lines, bounds)
    bounds = bounds or { width = 260, height = 160 }
    window = prettyui.Window.new(game_area(), {
        title = "Spell costs",
        x = bounds.x,
        y = bounds.y,
        width = bounds.width,
        height = bounds.height,
        resizable = true,
        -- prettyui's default minimum is 220 x 140, which is bigger than a single cost line needs.
        minWidth = 120,
        minHeight = 60,
        destroyOnClose = true,
        onClose = function()
            window = nil
            text = nil
        end,
    })
    text = TextLines.new(window)
    text:set(lines)
    line_count = #lines
end

local function remove()
    window:Destroy()
    window = nil
    text = nil
end

-- prettyui windows can grow but never shrink their content, and text rows
-- can't be removed. If we just blanked the rows we no longer need, the window
-- would keep a scrollbar for the empty space. So when there are fewer lines
-- than before, the window is rebuilt in the same place and at the same size.
local function show_lines(lines)
    if #lines < line_count then
        local root = window.root
        local bounds = { x = root.x, y = root.y, width = root.width, height = root.height }
        remove()
        create(lines, bounds)
        return
    end
    text:set(lines)
    line_count = #lines
end

-- Opens the window, or brings it to the front if it is already open.
function cost_tracker_window.open(lines)
    if window then
        window:Show()
        show_lines(lines)
        return
    end
    create(lines)
end

-- Shows the latest lines if the window is open.
function cost_tracker_window.refresh(lines)
    if window then
        show_lines(lines)
    end
end

-- Removes the window, e.g. when the plugin is turned off.
function cost_tracker_window.destroy()
    if window then
        remove()
    end
end

return cost_tracker_window
