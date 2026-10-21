local prices = require("src/game/prices")
local assert_helpers = require("tests/helpers/assert")

-- Runs test_body with a fake global gepl, then removes it again.
local function with_gepl(fake_gepl, test_body)
    local original = gepl
    gepl = fake_gepl
    local ok, err = pcall(test_body)
    gepl = original
    if not ok then
        error(err, 0)
    end
end

local function fake_gepl(is_ready, latest_by_id)
    return {
        isReady = function()
            return is_ready
        end,
        getLatest = function(item_id)
            local latest = latest_by_id[item_id]
            if latest == nil then
                error("Price not found for itemId: " .. item_id)
            end
            return latest
        end,
    }
end

-- The real code prints why a price is missing; keep the test output clean.
local function silently(test_body)
    local original_print = print
    print = function() end
    local ok, err = pcall(test_body)
    print = original_print
    if not ok then
        error(err, 0)
    end
end

local tests = {}

function tests.averages_high_and_low_price()
    with_gepl(fake_gepl(true, { [55338] = { high = 400, low = 300 } }), function()
        assert_helpers.equal(prices.average_price(55338), 350)
    end)
end

function tests.has_no_price_before_gepl_is_ready()
    with_gepl(fake_gepl(false, { [55338] = { high = 400, low = 300 } }), function()
        assert_helpers.equal(prices.average_price(55338), nil)
    end)
end

function tests.has_no_price_when_gepl_is_missing()
    with_gepl(nil, function()
        assert_helpers.equal(prices.average_price(55338), nil)
    end)
end

function tests.has_no_price_when_gepl_does_not_know_the_item()
    with_gepl(fake_gepl(true, {}), function()
        silently(function()
            assert_helpers.equal(prices.average_price(55338), nil)
        end)
    end)
end

function tests.has_no_price_when_one_side_has_no_trades()
    with_gepl(fake_gepl(true, { [55338] = { high = 400 } }), function()
        silently(function()
            assert_helpers.equal(prices.average_price(55338), nil)
        end)
    end)
end

function tests.looks_up_price_by_item_name()
    with_gepl(fake_gepl(true, { [55338] = { high = 400, low = 300 } }), function()
        local get_price = prices.by_item_name({ ["Bone rune"] = 55338 })

        assert_helpers.equal(get_price("Bone rune"), 350)
        assert_helpers.equal(get_price("Soul rune"), nil)
    end)
end

return tests
