-- Keeps a running count of how many times each spell has been cast and what
-- those casts cost at Grand Exchange prices. The number of runes used isn't
-- stored, since it can be worked out from the number of casts.
local necro_gear = require("src/tracker/necro_gear")

local SpellTracker = {}
SpellTracker.__index = SpellTracker

local function as_set(list)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
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
--   spells:          the spells to track, as in config.lua
--   necro_gear:      item ids that count as Necromancy gear
--   get_price:       gives the price of a rune by its name, or nil if unknown
--   fallback_prices: optional rough prices by rune name, used when there's no price
--   only_stalls:     optional; returns true when the player only wants Lord of
--                    Bones stalls counted (casts without Necromancy gear on)
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
            gp = 0,
            estimated_gp = 0,
            unpriced_items = {},
            estimated_items = {},
        }
    end
end

-- Picks up from earlier totals, e.g. the ones saved before the plugin was
-- restarted. Saved spells that aren't tracked any more are ignored.
function SpellTracker:restore(saved)
    for _, spell in ipairs(saved) do
        local totals = self.totals_by_key[spell.key]
        if totals then
            totals.casts = spell.casts
            totals.gp = spell.gp
            -- Totals saved before estimated_gp was tracked don't have it.
            totals.estimated_gp = spell.estimated_gp or 0
            totals.unpriced_items = as_set(spell.unpriced_items)
            totals.estimated_items = as_set(spell.estimated_items)
        end
    end
end

-- Adds the cost of some runes to a spell's total. Casts are priced at the
-- moment they happen, so later Grand Exchange price changes don't change what
-- earlier casts cost. If there is no price, the rough price from config.lua is
-- used, and the rune and its cost are marked as estimated.
function SpellTracker:add_cost(totals, item_name, quantity)
    local price = self.get_price(item_name)
    if price == nil then
        price = self.fallback_prices[item_name]
        if price ~= nil then
            totals.estimated_items[item_name] = true
            totals.estimated_gp = totals.estimated_gp + price * quantity
        end
    end

    if price then
        totals.gp = totals.gp + price * quantity
    else
        totals.unpriced_items[item_name] = true
    end
end

-- Counts a cast of the spell and adds its cost.
--
-- Lord of Bones is a Necromancy ability. Cast while wearing Necromancy gear,
-- it is part of normal Necromancy combat. Cast without it, the player is just
-- using it to stall. With only_stalls on, only the stalls are counted.
--
-- worn_equipment: the item ids the player is wearing
-- casts: how many casts to count, e.g. 5 for a multi-cast (1 if left out)
-- Returns the spell if the cast was counted, or nil if it was ignored.
function SpellTracker:on_cast(spell, worn_equipment, casts)
    casts = casts or 1
    if spell.can_stall and self.only_stalls() and necro_gear.is_wearing(worn_equipment, self.necro_gear) then
        return nil
    end

    local totals = self.totals_by_key[spell.key]
    totals.casts = totals.casts + casts
    for item_name, quantity in pairs(spell.runes) do
        self:add_cost(totals, item_name, quantity * casts)
    end
    return spell
end

-- How many of each rune the given number of casts used.
local function runes_used(spell, casts)
    local used = {}
    if casts > 0 then
        for item_name, quantity in pairs(spell.runes) do
            used[item_name] = quantity * casts
        end
    end
    return used
end

-- The totals of one spell. See totals() for what they contain.
function SpellTracker:spell_totals(spell)
    local totals = self.totals_by_key[spell.key]
    return {
        key = spell.key,
        name = spell.name,
        casts = totals.casts,
        runes_used = runes_used(spell, totals.casts),
        gp = totals.gp,
        estimated_gp = totals.estimated_gp,
        unpriced_items = sorted_keys(totals.unpriced_items),
        estimated_items = sorted_keys(totals.estimated_items),
    }
end

-- The totals of every spell, in the same order as config.lua. Each has:
--   key, name:       which spell it is
--   casts:           how many times it was cast
--   runes_used:      how many of each rune those casts used
--   gp:              what they cost
--   estimated_gp:    the part of gp that was priced with rough prices
--   estimated_items: runes that were priced with a rough price at least once
--   unpriced_items:  runes that had no price at all at least once; these
--                    are missing from gp, so the real cost is higher
function SpellTracker:totals()
    local result = {}
    for _, spell in ipairs(self.spells) do
        table.insert(result, self:spell_totals(spell))
    end
    return result
end

return SpellTracker
