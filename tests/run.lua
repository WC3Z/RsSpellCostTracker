-- Run from the repository root: lua tests/run.lua
package.path = "./?.lua;" .. package.path

local test_files = {
    "tests/tracker/necro_gear_test",
    "tests/tracker/spell_tracker_test",
    "tests/tracker/totals_text_test",
    "tests/game/prices_test",
    "tests/game/cast_listener_test",
    "tests/game/saved_totals_test",
    "tests/interface/player_settings_test",
    "tests/interface/text_lines_test",
    "tests/interface/content_view_test",
    "tests/interface/cost_tracker_window_test",
}

local passed, failed = 0, 0
for _, module_name in ipairs(test_files) do
    for test_name, test in pairs(require(module_name)) do
        local ok, err = pcall(test)
        if ok then
            passed = passed + 1
        else
            failed = failed + 1
            print("FAIL " .. module_name .. " > " .. test_name .. "\n    " .. tostring(err))
        end
    end
end

print(passed .. " passed, " .. failed .. " failed")
if failed > 0 then
    os.exit(1)
end
