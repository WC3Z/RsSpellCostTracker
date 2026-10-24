-- The list of past sessions, saved in the game's plugin storage. Only when
-- each one started, how long it ran and what it cost are kept.
--
-- Entries are saved oldest first under numbered keys, e.g.
-- "SessionHistory.3.gp", with the number of entries in "SessionHistory.count".
-- Only the newest ones are kept, so the list doesn't grow forever.
local session_history = {}

-- One past session.
---@class PastSession
---@field started_at? integer The game clock (in minutes) when it started, nil if not known
---@field minutes integer How long it ran, not counting pauses
---@field gp number What it cost

local prefix = "SessionHistory"
local count_key = prefix .. ".count"
local max_entries = 30

-- Saved instead of a start time that isn't known.
local unknown_time = -1

---@param index integer
---@param field string
---@return string
local function key(index, field)
    return prefix .. "." .. index .. "." .. field
end

-- Saved numbers come back as decimals, so whole numbers are rounded back.
---@param db_key string
---@return integer
local function load_whole_number(db_key)
    local value = PersistentDB:Get(db_key) or 0
    return math.floor(value + 0.5)
end

---@return integer
local function count()
    return load_whole_number(count_key)
end

---@param index integer
---@return PastSession
local function load_entry(index)
    local started_at = load_whole_number(key(index, "startedAt"))
    return {
        started_at = started_at ~= unknown_time and started_at or nil,
        minutes = load_whole_number(key(index, "minutes")),
        gp = PersistentDB:Get(key(index, "gp")) or 0,
    }
end

---@param index integer
---@param entry PastSession
local function save_entry(index, entry)
    PersistentDB:Set(key(index, "startedAt"), entry.started_at or unknown_time)
    PersistentDB:Set(key(index, "minutes"), entry.minutes)
    PersistentDB:Set(key(index, "gp"), entry.gp)
end

-- Adds a session to the end of the list. When the list is full, the oldest
-- one is dropped by moving every other entry down one place.
---@param entry PastSession
function session_history.add(entry)
    local entries = count()
    if entries >= max_entries then
        for index = 2, entries do
            save_entry(index - 1, load_entry(index))
        end
        entries = entries - 1
    end
    save_entry(entries + 1, entry)
    PersistentDB:Set(count_key, entries + 1)
end

-- The past sessions, newest first.
---@return PastSession[]
function session_history.list()
    local entries = {}
    for index = count(), 1, -1 do
        table.insert(entries, load_entry(index))
    end
    return entries
end

return session_history
