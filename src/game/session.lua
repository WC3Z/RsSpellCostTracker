-- A session counts casts from when the player starts it until they stop it,
-- next to the overall totals. While paused, casts aren't counted, but the
-- session can carry on later. A stopped session's totals are kept until a new
-- one is started.
--
-- The totals are saved with the "Session" prefix (see saved_totals.lua) and
-- the state under "sessionState", so a session carries on after a restart or
-- crash.
local SpellTracker = require("src/tracker/spell_tracker")
local saved_totals = require("src/game/saved_totals")

---@alias SessionState "stopped" | "running" | "paused"

---@class Session
---@field spells Spell[]
---@field tracker SpellTracker The session's own totals
local Session = {}
Session.__index = Session

local saved_prefix = "Session"
local state_key = "sessionState"

-- The state is saved as a number, since numbers are known to come back from
-- PersistentDB (as decimals, which still compare equal).
---@type table<SessionState, integer>
local state_numbers = { stopped = 0, running = 1, paused = 2 }

---@param tracker_options SpellTrackerOptions The same options as the main tracker
---@return Session
function Session.new(tracker_options)
    local self = setmetatable({}, Session)
    self.spells = tracker_options.spells
    self.tracker = SpellTracker.new(tracker_options)
    self.tracker:restore(saved_totals.load(self.spells, saved_prefix))
    return self
end

---@return SessionState
function Session:state()
    local saved = PersistentDB:Get(state_key)
    for state, number in pairs(state_numbers) do
        if saved == number then
            return state
        end
    end
    return "stopped"
end

---@param state SessionState
local function set_state(state)
    PersistentDB:Set(state_key, state_numbers[state])
end

-- Sets every spell in the session back to zero, both in the tracker and in
-- what is saved. The state stays as it is.
function Session:reset()
    self.tracker:reset()
    for _, spell in ipairs(self.spells) do
        saved_totals.save(spell, self.tracker:spell_totals(spell), saved_prefix)
    end
end

-- Starts a new session, throwing away the last one.
function Session:start()
    self:reset()
    set_state("running")
end

function Session:stop()
    set_state("stopped")
end

function Session:pause()
    if self:state() == "running" then
        set_state("paused")
    end
end

function Session:resume()
    if self:state() == "paused" then
        set_state("running")
    end
end

-- Counts a cast the main tracker counted, if the session is running.
---@param spell Spell
---@param worn_equipment table<integer, integer> Item id by equipment slot
---@param casts integer
function Session:on_cast(spell, worn_equipment, casts)
    if self:state() ~= "running" then
        return
    end
    if self.tracker:on_cast(spell, worn_equipment, casts) then
        saved_totals.save(spell, self.tracker:spell_totals(spell), saved_prefix)
    end
end

---@return SpellTotals[]
function Session:totals()
    return self.tracker:totals()
end

return Session
