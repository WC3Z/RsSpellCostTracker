-- Where the player last left a window and how big it was, so it opens the same
-- way after logging out or restarting the game. Saved per account like
-- everything else (see account_storage.lua), as "<name>.x", "<name>.y",
-- "<name>.width" and "<name>.height".
local account_storage = require("src/game/account_storage")

local window_bounds = {}

-- Where a window is and how big it is. Without x and y prettyui picks the spot.
---@class WindowBounds
---@field x? number
---@field y? number
---@field width number
---@field height number

-- The saved bounds. The position is left out until the window has been moved,
-- and the default size is used until it has been closed once.
---@param name string
---@param default_width number
---@param default_height number
---@return WindowBounds
function window_bounds.load(name, default_width, default_height)
    local bounds = {
        width = account_storage.get_int(name .. ".width") or default_width,
        height = account_storage.get_int(name .. ".height") or default_height,
    }
    local x = account_storage.get_int(name .. ".x")
    local y = account_storage.get_int(name .. ".y")
    if x ~= nil and y ~= nil then
        bounds.x, bounds.y = x, y
    end
    return bounds
end

---@param name string
---@param x number
---@param y number
local function save_position(name, x, y)
    account_storage.set_int(name .. ".x", math.floor(x))
    account_storage.set_int(name .. ".y", math.floor(y))
end

-- Saves where the prettyui window is now and how big it is. Done when it's
-- closed or removed, since prettyui has no callback for resizing, and versions
-- before 1.3.0 don't call onPositionChange either.
---@param name string
---@param window table
function window_bounds.save_from(name, window)
    save_position(name, window.root.x, window.root.y)
    account_storage.set_int(name .. ".width", math.floor(window.root.width))
    account_storage.set_int(name .. ".height", math.floor(window.root.height))
end

-- A prettyui onPositionChange callback that saves the position under `name`.
-- prettyui calls it once the player lets go after dragging the window.
---@param name string
---@return fun(window: table, x: number, y: number)
function window_bounds.position_saver(name)
    return function(_, x, y)
        save_position(name, x, y)
    end
end

return window_bounds
