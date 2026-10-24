-- Saves each spell's totals in the game's plugin storage (PersistentDB), so
-- they aren't lost when the plugin or the game is restarted.
--
-- Each number is saved under its own name, e.g. "LordOfBones.casts",
-- "LordOfBones.gp" and "LordOfBones.estimated_gp", plus a yes/no for each rune saying whether its price was
-- estimated ("LordOfBones.estimated.Bone rune") or missing
-- ("LordOfBones.unpriced.Bone rune"). The rune counts aren't saved, because
-- they can be worked out from the number of casts.
--
-- A prefix keeps a second set of totals apart from the first, e.g. the current
-- session's totals are saved as "Session.LordOfBones.casts".
local saved_totals = {}

---@param prefix string? Put in front of every key, or nil for none
---@param spell_key string
---@param ... string
---@return string
local function key(prefix, spell_key, ...)
    local parts = { spell_key, ... }
    if prefix then
        table.insert(parts, 1, prefix)
    end
    return table.concat(parts, ".")
end

-- Saved numbers come back as decimals, which would show up as "2.0 casts".
-- A cast count is always a whole number, so it is turned back into one.
---@param db_key string
---@return integer
local function load_count(db_key)
    local value = PersistentDB:Get(db_key) or 0
    return math.floor(value + 0.5)
end

---@param list RuneName[]
---@return table<RuneName, true>
local function as_set(list)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

-- Saves one spell's totals.
---@param spell Spell
---@param totals SavedTotals
---@param prefix? string Saves them apart from the main totals, see the top of this file
function saved_totals.save(spell, totals, prefix)
    local estimated = as_set(totals.estimated_items)
    local unpriced = as_set(totals.unpriced_items)

    PersistentDB:Set(key(prefix, spell.key, "casts"), totals.casts)
    PersistentDB:Set(key(prefix, spell.key, "gp"), totals.gp)
    PersistentDB:Set(key(prefix, spell.key, "estimated_gp"), totals.estimated_gp)
    for item_name in pairs(spell.runes) do
        PersistentDB:SetBool(key(prefix, spell.key, "estimated", item_name), estimated[item_name] == true)
        PersistentDB:SetBool(key(prefix, spell.key, "unpriced", item_name), unpriced[item_name] == true)
    end
end

-- Loads the saved totals of each spell, ready to hand to SpellTracker:restore.
-- Spells that were never saved start at zero.
---@param spells Spell[]
---@param prefix? string The prefix they were saved with
---@return SavedTotals[]
function saved_totals.load(spells, prefix)
    local result = {}
    for _, spell in ipairs(spells) do
        local totals = {
            key = spell.key,
            casts = load_count(key(prefix, spell.key, "casts")),
            gp = PersistentDB:Get(key(prefix, spell.key, "gp")) or 0,
            estimated_gp = PersistentDB:Get(key(prefix, spell.key, "estimated_gp")) or 0,
            estimated_items = {},
            unpriced_items = {},
        }
        for item_name in pairs(spell.runes) do
            if PersistentDB:GetBool(key(prefix, spell.key, "estimated", item_name)) then
                table.insert(totals.estimated_items, item_name)
            end
            if PersistentDB:GetBool(key(prefix, spell.key, "unpriced", item_name)) then
                table.insert(totals.unpriced_items, item_name)
            end
        end
        table.insert(result, totals)
    end
    return result
end

return saved_totals
