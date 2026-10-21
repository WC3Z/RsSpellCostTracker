local saved_totals = require("src/game/saved_totals")
local SpellTracker = require("src/tracker/spell_tracker")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local darkness = {
    key = "Darkness", name = "Darkness", ability_id = 48331,
    runes = { ["Bone rune"] = 20, ["Flesh rune"] = 10 },
}
local penance = { key = "Penance", name = "Penance", ability_id = 1, runes = { ["Law rune"] = 3 } }

local function darkness_totals(overrides)
    local totals = {
        key = "Darkness", name = "Darkness", casts = 2,
        runes_used = { ["Bone rune"] = 40, ["Flesh rune"] = 20 },
        gp = 1234.5,
        unpriced_items = { "Flesh rune" },
        estimated_items = { "Bone rune" },
    }
    for field, value in pairs(overrides or {}) do
        totals[field] = value
    end
    return totals
end

local tests = {}

function tests.saves_each_value_under_its_own_key()
    local stored = fake_persistent_db.install()

    saved_totals.save(darkness, darkness_totals())

    assert_helpers.equal(stored["Darkness.casts"], 2)
    assert_helpers.equal(stored["Darkness.gp"], 1234.5)
    assert_helpers.equal(stored["Darkness.rune.Bone rune"], 40)
    assert_helpers.equal(stored["Darkness.estimated.Bone rune"], true)
    assert_helpers.equal(stored["Darkness.unpriced.Bone rune"], false)
    assert_helpers.equal(stored["Darkness.unpriced.Flesh rune"], true)
end

function tests.loads_what_was_saved()
    fake_persistent_db.install()
    saved_totals.save(darkness, darkness_totals())

    local loaded = saved_totals.load({ darkness })[1]

    assert_helpers.equal(loaded.key, "Darkness")
    assert_helpers.equal(loaded.casts, 2)
    assert_helpers.equal(loaded.gp, 1234.5)
    assert_helpers.equal(loaded.runes_used["Bone rune"], 40)
    assert_helpers.equal(loaded.runes_used["Flesh rune"], 20)
    assert_helpers.same_lines(loaded.estimated_items, { "Bone rune" })
    assert_helpers.same_lines(loaded.unpriced_items, { "Flesh rune" })
end

function tests.a_rune_no_longer_estimated_is_cleared()
    fake_persistent_db.install()
    saved_totals.save(darkness, darkness_totals())

    saved_totals.save(darkness, darkness_totals({ estimated_items = {} }))

    assert_helpers.equal(#saved_totals.load({ darkness })[1].estimated_items, 0)
end

function tests.counts_saved_as_floats_load_as_integers()
    local stored = fake_persistent_db.install()
    stored["Darkness.casts"] = 2.0
    stored["Darkness.rune.Bone rune"] = 40.0

    local loaded = saved_totals.load({ darkness })[1]

    assert_helpers.equal(tostring(loaded.casts), "2")
    assert_helpers.equal(tostring(loaded.runes_used["Bone rune"]), "40")
end

function tests.spells_never_saved_load_as_zero()
    fake_persistent_db.install()

    local loaded = saved_totals.load({ penance })[1]

    assert_helpers.equal(loaded.casts, 0)
    assert_helpers.equal(loaded.gp, 0)
    assert_helpers.equal(next(loaded.runes_used), nil)
    assert_helpers.equal(#loaded.estimated_items, 0)
    assert_helpers.equal(#loaded.unpriced_items, 0)
end

function tests.a_restarted_tracker_continues_where_it_left_off()
    fake_persistent_db.install()
    local options = { spells = { darkness, penance }, get_price = function() return 10 end }
    local before = SpellTracker.new(options)
    local spell = before:on_cast(48331, {})
    saved_totals.save(spell, before:spell_totals(spell))

    local after = SpellTracker.new(options)
    after:restore(saved_totals.load(options.spells))
    after:on_cast(48331, {})

    local totals = after:spell_totals(darkness)
    assert_helpers.equal(totals.casts, 2)
    assert_helpers.equal(totals.runes_used["Bone rune"], 40)
    assert_helpers.equal(totals.gp, 2 * (20 + 10) * 10)
end

return tests
