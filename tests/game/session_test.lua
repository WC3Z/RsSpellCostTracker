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

function tests.starts_stopped_and_ignores_casts()
    fake_persistent_db.install()
    local session = new_session()

    session:on_cast(penance, {}, 1)

    assert_helpers.equal(session:state(), "stopped")
    assert_helpers.equal(penance_casts(session), 0)
end

function tests.counts_casts_while_running()
    fake_persistent_db.install()
    local session = new_session()

    session:start()
    session:on_cast(penance, {}, 5)

    assert_helpers.equal(session:state(), "running")
    assert_helpers.equal(penance_casts(session), 5)
    assert_helpers.equal(session:totals()[1].gp, 150)
end

function tests.ignores_casts_while_paused_and_carries_on_when_resumed()
    fake_persistent_db.install()
    local session = new_session()
    session:start()
    session:on_cast(penance, {}, 1)

    session:pause()
    session:on_cast(penance, {}, 1)
    session:resume()
    session:on_cast(penance, {}, 1)

    assert_helpers.equal(penance_casts(session), 2)
end

function tests.stopping_keeps_the_totals_until_the_next_start()
    fake_persistent_db.install()
    local session = new_session()
    session:start()
    session:on_cast(penance, {}, 1)

    session:stop()

    assert_helpers.equal(session:state(), "stopped")
    assert_helpers.equal(penance_casts(session), 1)
    session:start()
    assert_helpers.equal(penance_casts(session), 0)
end

function tests.pause_and_resume_do_nothing_when_stopped()
    fake_persistent_db.install()
    local session = new_session()

    session:pause()
    assert_helpers.equal(session:state(), "stopped")
    session:resume()
    assert_helpers.equal(session:state(), "stopped")
end

function tests.state_and_totals_survive_a_restart()
    local stored = fake_persistent_db.install()
    local session = new_session()
    session:start()
    session:on_cast(penance, {}, 2)
    session:pause()
    -- Saved numbers come back as decimals.
    stored.sessionState = stored.sessionState + 0.0

    local restarted = new_session()

    assert_helpers.equal(restarted:state(), "paused")
    assert_helpers.equal(penance_casts(restarted), 2)
    assert_helpers.equal(stored["Session.Penance.casts"], 2)
end

function tests.reset_zeroes_the_totals_but_keeps_running()
    fake_persistent_db.install()
    local session = new_session()
    session:start()
    session:on_cast(penance, {}, 2)

    session:reset()

    assert_helpers.equal(session:state(), "running")
    assert_helpers.equal(penance_casts(session), 0)
    assert_helpers.equal(penance_casts(new_session()), 0)
end

return tests
