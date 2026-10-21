local necro_gear = require("src/tracker/necro_gear")
local config = require("src/config")
local assert_helpers = require("tests/helpers/assert")

local tests = {}

function tests.empty_equipment_is_not_necro()
    assert_helpers.equal(necro_gear.is_wearing({}, config.necro_item_ids), false)
    assert_helpers.equal(necro_gear.is_wearing(nil, config.necro_item_ids), false)
end

function tests.non_necro_gear_is_not_necro()
    local equipment = { [2] = 52504, [18] = 37445 }
    assert_helpers.equal(necro_gear.is_wearing(equipment, config.necro_item_ids), false)
end

function tests.any_necro_item_counts()
    local equipment = { [2] = 52504, [6] = 55485 } -- 55485 = NECRO_RASIAL_LANTERN_T95_AUGMENTED
    assert_helpers.equal(necro_gear.is_wearing(equipment, config.necro_item_ids), true)
end

function tests.unaugmented_and_augmented_versions_both_count()
    assert_helpers.equal(necro_gear.is_wearing({ [6] = 55482 }, config.necro_item_ids), true)
    assert_helpers.equal(necro_gear.is_wearing({ [6] = 55485 }, config.necro_item_ids), true)
end

return tests
