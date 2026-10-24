local Session = require("src/game/session")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local penance = { key = "Penance", name = "Penance", runes = { ["Law rune"] = 3 } }

local function new_session()
    return Session.new({
        spells = { penance },
        necro_gear = {},
        get_price = function() return 10 end,
    })
end

local function penance_casts(session)
    return session:totals()[1].casts
end

local tests = {}

function tests.starts_paused_and_ignores_casts()
    fake_persistent_db.install()
    local session = new_session()

    session:on_cast(penance, {}, 1)

    assert_helpers.equal(session:state(), "paused")
    assert_helpers.equal(penance_casts(session), 0)
end

function tests.counts_casts_while_running()
    fake_persistent_db.install()
    local session = new_session()

    session:start(1000)
    session:on_cast(penance, {}, 5)

    assert_helpers.equal(session:state(), "running")
    assert_helpers.equal(penance_casts(session), 5)
    assert_helpers.equal(session:totals()[1].gp, 150)
end

function tests.ignores_casts_while_paused_and_carries_on_when_resumed()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)
    session:on_cast(penance, {}, 1)

    session:pause()
    session:on_cast(penance, {}, 1)
    session:resume()
    session:on_cast(penance, {}, 1)

    assert_helpers.equal(penance_casts(session), 2)
end

function tests.starting_a_new_session_clears_the_last_one()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)
    session:on_cast(penance, {}, 1)
    session:on_clock(1000)
    session:on_clock(1001)

    session:start(2000)

    assert_helpers.equal(penance_casts(session), 0)
    assert_helpers.equal(session:minutes(), 0)
    assert_helpers.equal(session:started_at(), 2000)
    assert_helpers.equal(session:has_anything(), false)
end

function tests.sessions_saved_as_stopped_by_older_versions_load_as_paused()
    local stored = fake_persistent_db.install()
    stored.sessionState = 0.0

    assert_helpers.equal(new_session():state(), "paused")
end

function tests.counts_running_minutes_but_not_paused_ones()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)

    session:on_clock(1000)
    session:on_clock(1001)
    session:on_clock(1002)
    session:pause()
    session:on_clock(1003)
    session:resume()
    session:on_clock(1004)

    assert_helpers.equal(session:minutes(), 3)
end

function tests.big_clock_jumps_are_not_counted()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)

    session:on_clock(1000)
    session:on_clock(1300)
    session:on_clock(1301)

    assert_helpers.equal(session:minutes(), 1)
end

function tests.first_clock_update_after_a_restart_is_not_counted()
    fake_persistent_db.install()
    new_session():start(1000)

    local restarted = new_session()
    restarted:on_clock(1010)

    assert_helpers.equal(restarted:minutes(), 0)
end

function tests.start_time_is_filled_in_when_the_clock_was_not_known()
    fake_persistent_db.install()
    local session = new_session()

    session:start(nil)
    assert_helpers.equal(session:started_at(), nil)
    session:on_clock(1234)

    assert_helpers.equal(session:started_at(), 1234)
end

function tests.resuming_a_never_started_session_uses_the_clock_as_start()
    fake_persistent_db.install()
    local session = new_session()
    session:on_clock(1234)

    session:resume()

    assert_helpers.equal(session:state(), "running")
    assert_helpers.equal(session:started_at(), 1234)
end

function tests.has_anything_after_a_cast()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)
    assert_helpers.equal(session:has_anything(), false)

    session:on_cast(penance, {}, 1)

    assert_helpers.equal(session:has_anything(), true)
end

function tests.state_and_totals_survive_a_restart()
    local stored = fake_persistent_db.install()
    local session = new_session()
    session:start(1000)
    session:on_clock(1000)
    session:on_clock(1002)
    session:on_cast(penance, {}, 2)
    session:pause()
    -- Saved numbers come back as decimals.
    stored.sessionState = stored.sessionState + 0.0

    local restarted = new_session()

    assert_helpers.equal(restarted:state(), "paused")
    assert_helpers.equal(penance_casts(restarted), 2)
    assert_helpers.equal(stored["Session.Penance.casts"], 2)
    assert_helpers.equal(restarted:started_at(), 1000)
    assert_helpers.equal(restarted:minutes(), 2)
end

function tests.reset_zeroes_the_totals_but_keeps_running()
    fake_persistent_db.install()
    local session = new_session()
    session:start(1000)
    session:on_cast(penance, {}, 2)

    session:reset()

    assert_helpers.equal(session:state(), "running")
    assert_helpers.equal(penance_casts(session), 0)
    assert_helpers.equal(penance_casts(new_session()), 0)
end

return tests
