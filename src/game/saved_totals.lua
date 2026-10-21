-- Saves each spell's totals in PersistentDB, so they are kept when the plugin
-- or the game is restarted.
--
-- Every value gets its own key, e.g. "LordOfBones.casts", "LordOfBones.gp",
-- "LordOfBones.estimated.Bone rune" and "LordOfBones.unpriced.Bone rune". The
-- runes come from each spell's runes in config.lua, so a spell's keys are known
-- without listing what was saved. The runes used aren't saved, because the
-- tracker works them out from the number of casts.
local saved_totals = {}

local function key(spell_key, ...)
    return table.concat({ spell_key, ... }, ".")
end

-- PersistentDB gives numbers back as floats, which Lua prints as e.g. "2.0".
-- The cast count is always whole, so it is turned back into an integer.
local function load_count(db_key)
    local value = PersistentDB:Get(db_key) or 0
    return math.floor(value + 0.5)
end

local function as_set(list)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

-- spell: { key, runes } as in config.lua
-- totals: the spell's entry from SpellTracker:totals()
function saved_totals.save(spell, totals)
    local estimated = as_set(totals.estimated_items)
    local unpriced = as_set(totals.unpriced_items)

    PersistentDB:Set(key(spell.key, "casts"), totals.casts)
    PersistentDB:Set(key(spell.key, "gp"), totals.gp)
    for item_name in pairs(spell.runes) do
        PersistentDB:SetBool(key(spell.key, "estimated", item_name), estimated[item_name] == true)
        PersistentDB:SetBool(key(spell.key, "unpriced", item_name), unpriced[item_name] == true)
    end
end

-- Returns the saved totals of each spell, in the shape SpellTracker:restore
-- takes. Spells that were never saved come back with everything at zero.
function saved_totals.load(spells)
    local result = {}
    for _, spell in ipairs(spells) do
        local totals = {
            key = spell.key,
            casts = load_count(key(spell.key, "casts")),
            gp = PersistentDB:Get(key(spell.key, "gp")) or 0,
            estimated_items = {},
            unpriced_items = {},
        }
        for item_name in pairs(spell.runes) do
            if PersistentDB:GetBool(key(spell.key, "estimated", item_name)) then
                table.insert(totals.estimated_items, item_name)
            end
            if PersistentDB:GetBool(key(spell.key, "unpriced", item_name)) then
                table.insert(totals.unpriced_items, item_name)
            end
        end
        table.insert(result, totals)
    end
    return result
end

return saved_totals
