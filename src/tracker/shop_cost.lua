-- Works out what the spells cost at shop prices, for the "Iron btw" setting.
-- Costs are always tracked at Grand Exchange prices; this recalculates them.
-- Shop prices never change, so every cast, old or new, costs the same.
local shop_cost = {}

local function sorted_keys(source)
    local keys = {}
    for key in pairs(source) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

-- Returns a copy of one spell's totals with the cost worked out at shop
-- prices. If a rune has no shop price, its rough price from config.lua is
-- used and the rune is marked as estimated, just like for GE prices.
local function shop_priced(spell, get_store_price, fallback_prices)
    local gp = 0
    local estimated_gp = 0
    local estimated = {}
    local unpriced = {}
    for item_name, quantity in pairs(spell.runes_used) do
        local price = get_store_price(item_name)
        if price == nil then
            price = fallback_prices[item_name]
            if price ~= nil then
                estimated[item_name] = true
                estimated_gp = estimated_gp + price * quantity
            end
        end

        if price then
            gp = gp + price * quantity
        else
            unpriced[item_name] = true
        end
    end

    local priced = {}
    for field, value in pairs(spell) do
        priced[field] = value
    end
    priced.gp = gp
    priced.estimated_gp = estimated_gp
    priced.estimated_items = sorted_keys(estimated)
    priced.unpriced_items = sorted_keys(unpriced)
    return priced
end

-- spell_totals: every spell's totals, as SpellTracker:totals() gives them
-- get_store_price: gives the shop price of a rune by its name, or nil
-- fallback_prices: optional rough prices by rune name, for runes with no shop price
function shop_cost.reprice(spell_totals, get_store_price, fallback_prices)
    local result = {}
    for _, spell in ipairs(spell_totals) do
        table.insert(result, shop_priced(spell, get_store_price, fallback_prices or {}))
    end
    return result
end

return shop_cost
