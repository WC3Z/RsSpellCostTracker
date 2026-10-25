-- Turns session times and the session history into text.
--
-- Times come from the game clock, which counts minutes. They are taken to be
-- minutes since 1 January 1970 in game time (UTC), like Unix time (checked in game).
local totals_text = require("src/tracker/totals_text")

local session_text = {}

local month_names = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- 72 -> "1h 12m", 5 -> "5m"
---@param minutes integer
---@return string
function session_text.duration(minutes)
    local hours = minutes // 60
    if hours == 0 then
        return minutes .. "m"
    end
    return hours .. "h " .. (minutes % 60) .. "m"
end

-- Turns a number of days since 1 January 1970 into a year, month and day.
-- Lua in the game has no os.date, so this is worked out by hand, using
-- Howard Hinnant's civil_from_days. It counts in 400-year "eras" starting in
-- March, so the leap day falls at the end of each year.
---@param days integer
---@return integer year, integer month, integer day
local function date_from_days(days)
    local shifted = days + 719468
    local era = shifted // 146097
    local day_of_era = shifted - era * 146097
    local year_of_era = (day_of_era - day_of_era // 1460 + day_of_era // 36524 - day_of_era // 146096) // 365
    local day_of_year = day_of_era - (365 * year_of_era + year_of_era // 4 - year_of_era // 100)
    local month_from_march = (5 * day_of_year + 2) // 153
    local day = day_of_year - (153 * month_from_march + 2) // 5 + 1
    local month = month_from_march < 10 and month_from_march + 3 or month_from_march - 9
    local year = year_of_era + era * 400 + (month <= 2 and 1 or 0)
    return year, month, day
end

-- A game clock time as e.g. "24 Oct 14:05".
---@param clock_minutes integer
---@return string
function session_text.date(clock_minutes)
    local _, month, day = date_from_days(clock_minutes // (24 * 60))
    local minute_of_day = clock_minutes % (24 * 60)
    return string.format("%d %s %02d:%02d", day, month_names[month], minute_of_day // 60, minute_of_day % 60)
end

-- The first line of the Session tab, e.g. "Session running - 1h 12m".
---@param state SessionState
---@param minutes integer
---@return string
function session_text.status(state, minutes)
    return "Session " .. state .. " - " .. session_text.duration(minutes)
end

-- One line per past session, e.g. "24 Oct 14:05 - 1h 12m - 9,060 gp", with the
-- full gp in a tooltip when it's shortened.
---@param entries PastSession[]
---@return Line[]
function session_text.history_lines(entries)
    if #entries == 0 then
        return { "No past sessions yet" }
    end
    local lines = {}
    for _, entry in ipairs(entries) do
        local started = entry.started_at and session_text.date(entry.started_at) or "Unknown start"
        local label = started .. " - " .. session_text.duration(entry.minutes) .. " - "
        table.insert(lines, totals_text.gp_line(label, entry.gp))
    end
    return lines
end

return session_text
