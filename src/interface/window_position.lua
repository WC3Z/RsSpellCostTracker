-- Where the player last dragged a window, so it opens in the same spot after
-- logging out or restarting the game. Saved per account like everything else
-- (see account_storage.lua), as "<name>.x" and "<name>.y".
local account_storage = require("src/game/account_storage")

local window_position = {}

-- The saved position, or nil when the window hasn't been moved yet.
---@param name string
---@return number? x
---@return number? y
function window_position.load(name)
    local x = account_storage.get_int(name .. ".x")
    local y = account_storage.get_int(name .. ".y")
    if x == nil or y == nil then
        return nil, nil
    end
    return x, y
end

---@param name string
---@param x number
---@param y number
function window_position.save(name, x, y)
    account_storage.set_int(name .. ".x", math.floor(x))
    account_storage.set_int(name .. ".y", math.floor(y))
end

-- Saves where the prettyui window is now. Done when it's closed or removed,
-- as well as after dragging, since prettyui versions before 1.3.0 don't call
-- onPositionChange.
---@param name string
---@param window table
function window_position.save_from(name, window)
    window_position.save(name, window.root.x, window.root.y)
end

-- A prettyui onPositionChange callback that saves the position under `name`.
-- prettyui calls it once the player lets go after dragging the window.
---@param name string
---@return fun(window: table, x: number, y: number)
function window_position.saver(name)
    return function(_, x, y)
        window_position.save(name, x, y)
    end
end

return window_position
