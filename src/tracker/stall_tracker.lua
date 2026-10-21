-- Decides which Invoke Lord of Bones casts count as stalls and keeps the
-- running totals: number of casts, runes used and their Grand Exchange cost.
local necro_gear = require("src/tracker/necro_gear")

local StallTracker = {}
StallTracker.__index = StallTracker

local function copy(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function sorted_keys(source)
    local keys = {}
    for key in pairs(source) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

-- options:
--   runes_per_cast:  { [rune name] = quantity } used by one cast
--   necro_gear:      set of item ids that count as Necromancy gear
--   get_price:       optional function(rune name) -> gp per rune, or nil if unknown
--   fallback_prices: optional { [rune name] = gp }, used when get_price has no price
function StallTracker.new(options)
    local self = setmetatable({}, StallTracker)
    self.runes_per_cast = options.runes_per_cast
    self.necro_gear = options.necro_gear
    self.get_price = options.get_price
    self.fallback_prices = options.fallback_prices or {}
    self:reset()
    return self
end

function StallTracker:reset()
    self.casts = 0
    self.runes_used = {}
    self.gp = 0
    self.unpriced_items = {}
    self.estimated_items = {}
end

-- Each cast is priced when it happens, so later price changes on the
-- Grand Exchange do not change what earlier casts cost. Without a price the
-- configured fallback price is used, and the rune is marked as estimated.
function StallTracker:add_cost(item_name, quantity)
    if not self.get_price then
        return
    end

    local price = self.get_price(item_name)
    if price == nil then
        price = self.fallback_prices[item_name]
        if price ~= nil then
            self.estimated_items[item_name] = true
        end
    end

    if price then
        self.gp = self.gp + price * quantity
    else
        self.unpriced_items[item_name] = true
    end
end

-- Invoke Lord of Bones is a Necromancy ability. Cast while wearing Necromancy
-- gear it is part of normal Necromancy combat; cast without it, the player is
-- only using it to stall, and its runes are the cost this plugin tracks.
-- worn_equipment: { [slot] = item id }
-- Returns true when the cast was counted as a stall.
function StallTracker:on_cast(worn_equipment)
    if necro_gear.is_wearing(worn_equipment, self.necro_gear) then
        return false
    end

    self.casts = self.casts + 1
    for item_name, quantity in pairs(self.runes_per_cast) do
        self.runes_used[item_name] = (self.runes_used[item_name] or 0) + quantity
        self:add_cost(item_name, quantity)
    end
    return true
end

-- gp is nil when no price source is set. unpriced_items lists runes that had
-- no price for at least one cast; those casts' runes are left out of gp.
-- estimated_items lists runes that used the fallback price for at least one cast.
function StallTracker:totals()
    local gp = nil
    if self.get_price then
        gp = self.gp
    end

    return {
        casts = self.casts,
        runes_used = copy(self.runes_used),
        gp = gp,
        unpriced_items = sorted_keys(self.unpriced_items),
        estimated_items = sorted_keys(self.estimated_items),
    }
end

return StallTracker
