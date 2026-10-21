-- Grand Exchange prices from the gepl dependency (GE Price Library).
local prices = {}

-- Average of the latest high and low price of an item, or nil when gepl has
-- no usable price (not loaded yet, unknown item id, or gepl not available).
function prices.average_price(item_id)
    if gepl == nil or not gepl.isReady("latest") then
        return nil
    end

    -- gepl throws when it has no price for the item id.
    local ok, latest = pcall(gepl.getLatest, item_id)
    if not ok then
        print("No price for item " .. tostring(item_id) .. ":", latest)
        return nil
    end
    if latest == nil or type(latest.high) ~= "number" or type(latest.low) ~= "number" then
        print("No price for item " .. tostring(item_id))
        return nil
    end

    return (latest.high + latest.low) / 2
end

-- Returns a function(item_name) -> price for the stall tracker, looking up
-- each item's id in item_ids.
function prices.by_item_name(item_ids)
    return function(item_name)
        local item_id = item_ids[item_name]
        if item_id == nil then
            return nil
        end
        return prices.average_price(item_id)
    end
end

return prices
