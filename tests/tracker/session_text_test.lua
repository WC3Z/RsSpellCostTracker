local session_text = require("src/tracker/session_text")
local assert_helpers = require("tests/helpers/assert")

-- 24 Oct 2026 14:05 UTC, in minutes since 1970.
local october_24_2026_1405 = 1792850700 // 60

local tests = {}

function tests.duration_in_minutes_and_hours()
    assert_helpers.equal(session_text.duration(0), "0m")
    assert_helpers.equal(session_text.duration(45), "45m")
    assert_helpers.equal(session_text.duration(60), "1h 0m")
    assert_helpers.equal(session_text.duration(72), "1h 12m")
end

function tests.date_from_game_clock()
    assert_helpers.equal(session_text.date(0), "1 Jan 00:00")
    assert_helpers.equal(session_text.date(october_24_2026_1405), "24 Oct 14:05")
end

function tests.date_handles_leap_days()
    -- 29 Feb 2024 23:59 UTC
    assert_helpers.equal(session_text.date(1709251140 // 60), "29 Feb 23:59")
end

function tests.status_line()
    assert_helpers.equal(session_text.status("running", 72), "Session running - 1h 12m")
end

function tests.history_lines()
    local lines = session_text.history_lines({
        { started_at = october_24_2026_1405, minutes = 72, gp = 1234567 },
        { started_at = nil, minutes = 5, gp = 90 },
    })

    assert_helpers.same_lines(lines, {
        "24 Oct 14:05 - 1h 12m - 1234K",
        "Unknown start - 5m - 90 gp",
    })
    assert_helpers.equal(lines[1].tooltip, "1,234,567 gp")
    assert_helpers.equal(lines[2], "Unknown start - 5m - 90 gp")
end

function tests.history_lines_when_empty()
    assert_helpers.same_lines(session_text.history_lines({}), { "No past sessions yet" })
end

return tests
