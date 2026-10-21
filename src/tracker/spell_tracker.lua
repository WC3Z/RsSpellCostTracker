-- Counts the casts of each tracked spell and keeps its running totals: number
-- of casts, runes used and their Grand Exchange cost.
local necro_gear = require("src/tracker/necro_gear")

local SpellTracker = {}
SpellTracker.__index = SpellTracker

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
--   spells:          list of spells, as in config.lua
--   necro_gear:      set of item ids that count as Necromancy gear
--   get_price:       function(rune name) -> gp per rune, or nil if unknown
--   fallback_prices: optional { [rune name] = gp }, used when get_price has no price
--   only_stalls:     optional function() -> true when casts of a can_stall spell
--                    made while wearing Necromancy gear should be ignored
function SpellTracker.new(options)
    local self = setmetatable({}, SpellTracker)
    self.spells = options.spells
    self.necro_gear = options.necro_gear
    self.get_price = options.get_price
    self.fallback_prices = options.fallback_prices or {}
    self.only_stalls = options.only_stalls or function() return false end
    self:reset()
    return self
end

function SpellTracker:reset()
    self.totals_by_key = {}
    for _, spell in ipairs(self.spells) do
        self.totals_by_key[spell.key] = {
            casts = 0,
            runes_used = {},
            gp = 0,
            unpriced_items = {},
            estimated_items = {},
        }
    end
end

-- Returns the ability ids of all spells that have one, as a set.
function SpellTracker:ability_ids()
    local ids = {}
    for _, spell in ipairs(self.spells) do
        if spell.ability_id then
            ids[spell.ability_id] = true
        end
    end
    return ids
end

local function find_spell(spells, ability_id)
    for _, spell in ipairs(spells) do
        if spell.ability_id == ability_id then
            return spell
        end
    end
end

-- Each cast is priced when it happens, so later price changes on the
-- Grand Exchange do not change what earlier casts cost. Without a price the
-- configured fallback price is used, and the rune is marked as estimated.
function SpellTracker:add_cost(totals, item_name, quantity)
    local price = self.get_price(item_name)
    if price == nil then
        price = self.fallback_prices[item_name]
        if price ~= nil then
            totals.estimated_items[item_name] = true
        end
    end

    if price then
        totals.gp = totals.gp + price * quantity
    else
        totals.unpriced_items[item_name] = true
    end
end

-- Lord of Bones is a Necromancy ability. Cast while wearing Necromancy gear it
-- is part of normal Necromancy combat; cast without it, the player is only
-- using it to stall. With only_stalls on, just the stalls are counted.
-- worn_equipment: { [slot] = item id }
-- Returns true when the cast was counted.
function SpellTracker:on_cast(ability_id, worn_equipment)
    local spell = find_spell(self.spells, ability_id)
    if spell == nil then
        return false
    end
    if spell.can_stall and self.only_stalls() and necro_gear.is_wearing(worn_equipment, self.necro_gear) then
        return false
    end

    local totals = self.totals_by_key[spell.key]
    totals.casts = totals.casts + 1
    for item_name, quantity in pairs(spell.runes) do
        totals.runes_used[item_name] = (totals.runes_used[item_name] or 0) + quantity
        self:add_cost(totals, item_name, quantity)
    end
    return true
end

-- One entry per spell, in the order of the spells option:
-- { key, name, casts, runes_used, gp, unpriced_items, estimated_items }
-- unpriced_items lists runes that had no price for at least one cast; those
-- casts' runes are left out of gp. estimated_items lists runes that used the
-- fallback price for at least one cast.
function SpellTracker:totals()
    local result = {}
    for _, spell in ipairs(self.spells) do
        local totals = self.totals_by_key[spell.key]
        table.insert(result, {
            key = spell.key,
            name = spell.name,
            casts = totals.casts,
            runes_used = copy(totals.runes_used),
            gp = totals.gp,
            unpriced_items = sorted_keys(totals.unpriced_items),
            estimated_items = sorted_keys(totals.estimated_items),
        })
    end
    return result
end

return SpellTracker
