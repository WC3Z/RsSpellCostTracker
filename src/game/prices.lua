-- Looks up rune prices. Grand Exchange prices come from the gepl plugin
-- (GE Price Library). Shop prices are used instead when the player has the
-- "Iron btw" setting on.
local prices = {}

-- The item's current Grand Exchange price: the middle of its latest high and
-- low price. Returns nil when there is no price, e.g. because gepl hasn't
-- finished loading prices yet, doesn't know the item, or isn't installed.
---@param item_id integer
---@return number?
function prices.average_price(item_id)
    if gepl == nil or not gepl.isReady("latest") then
        return nil
    end

    -- gepl raises an error instead of returning nothing when it has no price.
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

-- What a shop sells the item for when it is fully stocked, e.g. 550 gp for a
-- Blood rune at Baba Yaga. This is the price the game lists for the item.
-- Returns nil when the game doesn't give us a price.
---@param config_name string The game's internal name for the item, e.g. "BLOODRUNE"
---@return number?
function prices.store_price(config_name)
    -- `config` here is the game's own lookup table, not this plugin's src/config.lua.
    local ok, cost = pcall(function()
        return config.Obj[config_name].cost
    end)
    if not ok or type(cost) ~= "number" then
        print("No shop price for item " .. tostring(config_name))
        return nil
    end
    return cost
end

-- Returns a function that gives the Grand Exchange price of a rune by its
-- name, e.g. "Bone rune".
---@param item_ids table<RuneName, integer> The game's item id for each rune
---@return PriceLookup
function prices.by_item_name(item_ids)
    return function(item_name)
        local item_id = item_ids[item_name]
        if item_id == nil then
            return nil
        end
        return prices.average_price(item_id)
    end
end

-- Returns a function that gives the shop price of a rune by its name.
---@param item_config_names table<RuneName, string> The game's internal name for each rune
---@param store_price_multipliers? table<RuneName, number> Runes that shops sell for more than the game's listed price, e.g. { ["Bone rune"] = 10 } for 10 times
---@return PriceLookup
function prices.store_price_by_item_name(item_config_names, store_price_multipliers)
    store_price_multipliers = store_price_multipliers or {}
    return function(item_name)
        local config_name = item_config_names[item_name]
        if config_name == nil then
            return nil
        end
        local price = prices.store_price(config_name)
        if price == nil then
            return nil
        end
        return price * (store_price_multipliers[item_name] or 1)
    end
end

return prices
