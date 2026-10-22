local player_settings = require("src/interface/player_settings")
local fake_persistent_db = require("tests/helpers/fake_persistent_db")
local assert_helpers = require("tests/helpers/assert")

local function find(options, name)
    for _, candidate in ipairs(options) do
        if candidate.name == name then return candidate end
    end
end

local function option(name)
    return find(player_settings.options, name)
end

local function spell_option(key)
    return find(player_settings.spell_options, key)
end

local tests = {}

function tests.everything_is_shown_when_nothing_is_saved()
    fake_persistent_db.install()

    local shown = player_settings.shown()

    assert_helpers.equal(shown.casts, true)
    assert_helpers.equal(shown.runes, true)
    assert_helpers.equal(shown.cost, true)
    assert_helpers.equal(shown.total, true)
    assert_helpers.equal(shown.spells.AnimateDead, true)
    assert_helpers.equal(shown.spells.Vampyrism, true)
    assert_helpers.equal(shown.spells.Penance, true)
    assert_helpers.equal(shown.spells.Darkness, true)
end

function tests.iron_btw_is_off_until_turned_on()
    local stored = fake_persistent_db.install()

    assert_helpers.equal(player_settings.iron_btw(), false)
    player_settings.set(player_settings.iron_btw_option, true)

    assert_helpers.equal(stored.ironBtw, true)
    assert_helpers.equal(player_settings.iron_btw(), true)
end

function tests.a_setting_turned_off_is_saved_and_hidden()
    local stored = fake_persistent_db.install()

    player_settings.set(option("runes"), false)

    assert_helpers.equal(stored.showRunes, false)
    assert_helpers.equal(player_settings.shown().runes, false)
    assert_helpers.equal(player_settings.shown().casts, true)
end

function tests.there_is_a_setting_for_each_spell()
    local option = spell_option("AnimateDead")

    assert_helpers.equal(#player_settings.spell_options, 5)
    assert_helpers.equal(option.db_key, "showAnimateDeadCost")
    assert_helpers.equal(option.label, "Show Animate Dead cost")
end

function tests.a_spell_turned_off_is_saved_and_hidden()
    local stored = fake_persistent_db.install()

    player_settings.set(spell_option("Penance"), false)

    assert_helpers.equal(stored.showPenanceCost, false)
    assert_helpers.equal(player_settings.shown().spells.Penance, false)
    assert_helpers.equal(player_settings.shown().spells.Darkness, true)
end

function tests.only_stalls_is_on_until_turned_off()
    fake_persistent_db.install()
    assert_helpers.equal(player_settings.only_stalls(), true)

    player_settings.set(player_settings.only_stalls_option, false)

    assert_helpers.equal(player_settings.only_stalls(), false)
end

return tests
