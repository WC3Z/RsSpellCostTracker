local session_history = require("src/game/session_history")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local tests = {}

function tests.is_empty_at_first()
    fake_persistent_db.install()

    assert_helpers.equal(#session_history.list(), 0)
end

function tests.lists_the_newest_first()
    fake_persistent_db.install()

    session_history.add({ started_at = 1000, minutes = 30, gp = 500 })
    session_history.add({ started_at = 2000, minutes = 45, gp = 900 })

    local list = session_history.list()
    assert_helpers.equal(#list, 2)
    assert_helpers.equal(list[1].started_at, 2000)
    assert_helpers.equal(list[1].minutes, 45)
    assert_helpers.equal(list[1].gp, 900)
    assert_helpers.equal(list[2].started_at, 1000)
end

function tests.keeps_an_unknown_start_time_unknown()
    fake_persistent_db.install()

    session_history.add({ started_at = nil, minutes = 5, gp = 10 })

    assert_helpers.equal(session_history.list()[1].started_at, nil)
end

function tests.saved_decimals_come_back_as_whole_numbers()
    local stored = fake_persistent_db.install()
    session_history.add({ started_at = 1000, minutes = 30, gp = 500 })
    stored["SessionHistory.count"] = 1.0
    stored["SessionHistory.1.minutes"] = 30.0

    local entry = session_history.list()[1]

    assert_helpers.equal(math.type(entry.minutes), "integer")
    assert_helpers.equal(entry.minutes, 30)
end

function tests.drops_the_oldest_when_full()
    fake_persistent_db.install()

    for index = 1, 31 do
        session_history.add({ started_at = index, minutes = index, gp = index })
    end

    local list = session_history.list()
    assert_helpers.equal(#list, 30)
    assert_helpers.equal(list[1].started_at, 31)
    assert_helpers.equal(list[30].started_at, 2)
end

return tests
