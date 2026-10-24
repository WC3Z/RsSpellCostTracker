-- A session counts casts from when the player starts it, next to the overall
-- totals. It can be paused and resumed any time; while paused, casts aren't
-- counted. Starting a new session throws the current one away (main.lua first
-- adds it to the session history).
--
-- The session also keeps when it started and how many minutes it has been
-- running, from the game's clock (see game_clock.lua). Paused minutes aren't
-- counted. If the clock hasn't been seen yet when the session starts, the
-- start time is filled in at the first clock update.
--
-- The totals are saved with the "Session" prefix (see saved_totals.lua), and
-- the state and times under their own keys, so a session carries on after a
-- restart or crash.
local SpellTracker = require("src/tracker/spell_tracker")
local saved_totals = require("src/game/saved_totals")

---@alias SessionState "running" | "paused"

---@class Session
---@field spells Spell[]
---@field tracker SpellTracker The session's own totals
---@field last_clock? integer The game clock at its last update, nil until the first one
local Session = {}
Session.__index = Session

local saved_prefix = "Session"
local state_key = "sessionState"
local started_at_key = "sessionStartedAt"
local minutes_key = "sessionMinutes"

-- Saved instead of a start time that isn't known.
local unknown_time = -1

-- The clock should move one minute at a time. A bigger jump means the game
-- wasn't running in between (e.g. logged out), so that time isn't counted.
local max_clock_step = 5

-- The state is saved as a number, since numbers are known to come back from
-- PersistentDB (as decimals, which still compare equal). Sessions saved as
-- stopped (0) by older versions load as paused, so they can be resumed.
---@type table<SessionState, integer>
local state_numbers = { running = 1, paused = 2 }

---@param db_key string
---@return integer?
local function load_whole_number(db_key)
    local value = PersistentDB:Get(db_key)
    if value == nil then
        return nil
    end
    return math.floor(value + 0.5)
end

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
    if PersistentDB:Get(state_key) == state_numbers.running then
        return "running"
    end
    return "paused"
end

---@param state SessionState
local function set_state(state)
    PersistentDB:Set(state_key, state_numbers[state])
end

-- The game clock (in minutes) when the session started, or nil if not known.
---@return integer?
function Session:started_at()
    local started_at = load_whole_number(started_at_key)
    if started_at == nil or started_at == unknown_time then
        return nil
    end
    return started_at
end

-- How many minutes the session has been running, not counting pauses.
---@return integer
function Session:minutes()
    return load_whole_number(minutes_key) or 0
end

-- Sets every spell in the session back to zero, both in the tracker and in
-- what is saved. The state and times stay as they are.
function Session:reset()
    self.tracker:reset()
    for _, spell in ipairs(self.spells) do
        saved_totals.save(spell, self.tracker:spell_totals(spell), saved_prefix)
    end
end

-- Starts a new running session from zero, throwing away the current one.
---@param now integer? The game clock, nil if not known yet
function Session:start(now)
    self:reset()
    PersistentDB:Set(started_at_key, now or unknown_time)
    PersistentDB:Set(minutes_key, 0)
    set_state("running")
end

function Session:pause()
    set_state("paused")
end

function Session:resume()
    if self:started_at() == nil and self.last_clock then
        PersistentDB:Set(started_at_key, self.last_clock)
    end
    set_state("running")
end

-- Whether there is anything worth keeping in the session history.
---@return boolean
function Session:has_anything()
    if self:minutes() > 0 then
        return true
    end
    for _, spell in ipairs(self:totals()) do
        if spell.casts > 0 then
            return true
        end
    end
    return false
end

-- Called every time the game clock changes. Counts the minutes that passed
-- while running.
---@param now integer The game clock, in minutes
function Session:on_clock(now)
    local last = self.last_clock
    self.last_clock = now
    if self:state() ~= "running" then
        return
    end
    if self:started_at() == nil then
        PersistentDB:Set(started_at_key, now)
    end
    if last == nil then
        return
    end
    local step = now - last
    if step > 0 and step <= max_clock_step then
        PersistentDB:Set(minutes_key, self:minutes() + step)
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
