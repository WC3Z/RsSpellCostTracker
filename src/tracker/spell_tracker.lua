-- Keeps a running count of how many times each spell has been cast and what
-- those casts cost at Grand Exchange prices. The number of runes used isn't
-- stored, since it can be worked out from the number of casts.
local necro_gear = require("src/tracker/necro_gear")

-- Gives the price of a rune, or nil when it isn't known.
---@alias PriceLookup fun(item_name: RuneName): number?

-- A spell's totals as they are saved between restarts.
---@class SavedTotals
---@field key string Which spell, see Spell.key
---@field casts integer How many times it was cast
---@field gp number What those casts cost
---@field estimated_gp number The part of gp that was priced with rough prices
---@field estimated_items RuneName[] Runes priced with a rough price at least once
---@field unpriced_items RuneName[] Runes with no price at all at least once; these are missing from gp

-- A spell's totals as shown to the player: the saved totals plus its name and runes used.
---@class SpellTotals: SavedTotals
---@field name string
---@field runes_used table<RuneName, integer> How many of each rune the casts used

-- The totals SpellTracker keeps while running. Runes are kept as sets
-- ({ ["Bone rune"] = true }) so adding one twice doesn't list it twice.
---@class RunningTotals
---@field casts integer
---@field gp number
---@field estimated_gp number
---@field estimated_items table<RuneName, true>
---@field unpriced_items table<RuneName, true>

---@class SpellTrackerOptions
---@field spells Spell[] The spells to track
---@field necro_gear table<integer, true> Item ids that count as Necromancy gear
---@field get_price PriceLookup
---@field fallback_prices? table<RuneName, number> Rough prices, used when there's no price
---@field only_stalls? fun(): boolean True when only Lord of Bones stalls should be counted

---@class SpellTracker
---@field spells Spell[]
---@field necro_gear table<integer, true>
---@field get_price PriceLookup
---@field fallback_prices table<RuneName, number>
---@field only_stalls fun(): boolean
---@field totals_by_key table<string, RunningTotals> Each spell's totals, by Spell.key
local SpellTracker = {}
SpellTracker.__index = SpellTracker

---@param list RuneName[]
---@return table<RuneName, true>
local function as_set(list)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

---@param source table<RuneName, true>
---@return RuneName[]
local function sorted_keys(source)
    local keys = {}
    for key in pairs(source) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

---@param options SpellTrackerOptions
---@return SpellTracker
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
---@param saved SavedTotals[]
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
---@param totals RunningTotals
---@param item_name RuneName
---@param quantity integer
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
-- Returns the spell if the cast was counted, or nil if it was ignored.
---@param spell Spell
---@param worn_equipment table<integer, integer> Item id by equipment slot
---@param casts? integer How many casts to count, e.g. 5 for a multi-cast (1 if left out)
---@return Spell?
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
---@param spell Spell
---@param casts integer
---@return table<RuneName, integer>
local function runes_used(spell, casts)
    local used = {}
    if casts > 0 then
        for item_name, quantity in pairs(spell.runes) do
            used[item_name] = quantity * casts
        end
    end
    return used
end

---@param spell Spell
---@return SpellTotals
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

-- The totals of every spell, in the same order as config.lua.
---@return SpellTotals[]
function SpellTracker:totals()
    local result = {}
    for _, spell in ipairs(self.spells) do
        table.insert(result, self:spell_totals(spell))
    end
    return result
end

return SpellTracker
