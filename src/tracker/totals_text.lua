-- Turns the tracker totals into the text lines shown to the player.
local totals_text = {}

-- 1234567 -> "1,234,567 gp"
-- Reversing the digits lets the comma be inserted after every 3 digits from the
-- right; a comma left in front of the number is then removed.
local function format_gp(gp)
    local digits = tostring(math.floor(gp))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (grouped:gsub("^,", "")) .. " gp"
end

-- e.g. "9,060 gp (estimated: Bone rune)". Runes priced with the fallback
-- price, or with no price at all, are named so the player knows the cost is rough.
local function cost_text(spell)
    local text = format_gp(spell.gp)
    if #spell.estimated_items > 0 then
        text = text .. " (estimated: " .. table.concat(spell.estimated_items, ", ") .. ")"
    end
    if #spell.unpriced_items > 0 then
        text = text .. " (no price: " .. table.concat(spell.unpriced_items, ", ") .. ")"
    end
    return text
end

local function plural(count, word)
    if count == 1 then
        return count .. " " .. word
    end
    return count .. " " .. word .. "s"
end

-- Spells that have been cast at least once and that is_shown(spell) allows.
local function cast_spells(spell_totals, is_shown)
    local result = {}
    for _, spell in ipairs(spell_totals) do
        if spell.casts > 0 and is_shown(spell) then
            table.insert(result, spell)
        end
    end
    return result
end

local function total_gp(spells)
    local gp = 0
    for _, spell in ipairs(spells) do
        gp = gp + spell.gp
    end
    return gp
end

local function add_spell_lines(lines, spell, shown)
    if shown.casts then
        table.insert(lines, spell.name .. ": " .. plural(spell.casts, "cast"))
    else
        table.insert(lines, spell.name)
    end

    if shown.runes then
        local item_names = {}
        for item_name in pairs(spell.runes_used) do
            table.insert(item_names, item_name)
        end
        table.sort(item_names)
        for _, item_name in ipairs(item_names) do
            table.insert(lines, "  " .. item_name .. ": " .. spell.runes_used[item_name])
        end
    end

    if shown.cost then
        table.insert(lines, "  Cost: " .. cost_text(spell))
    end
end

-- spell_totals: as returned by SpellTracker:totals()
-- shown picks which parts to include, e.g.
-- { casts = true, runes = false, cost = true, total = true, spells = { Penance = false } }.
-- cost is each spell's cost, total the cost of all shown spells together.
-- A spell missing from shown.spells is shown. Without shown, everything is included.
-- Spells that haven't been cast are left out.
function totals_text.lines(spell_totals, shown)
    shown = shown or { casts = true, runes = true, cost = true, total = true }
    local spells_shown = shown.spells or {}
    local spells = cast_spells(spell_totals, function(spell)
        return spells_shown[spell.key] ~= false
    end)

    if #spells == 0 then
        return { "No spells cast yet" }
    end

    local lines = {}
    for _, spell in ipairs(spells) do
        add_spell_lines(lines, spell, shown)
    end
    if shown.total then
        table.insert(lines, "Total: " .. format_gp(total_gp(spells)))
    end
    return lines
end

-- The cost of each spell cast so far and their total, for the plugin's page.
function totals_text.cost_lines(spell_totals)
    local spells = cast_spells(spell_totals, function() return true end)

    if #spells == 0 then
        return { "No spells cast yet" }
    end

    local lines = {}
    for _, spell in ipairs(spells) do
        table.insert(lines, spell.name .. ": " .. cost_text(spell))
    end
    table.insert(lines, "Total: " .. format_gp(total_gp(spells)))
    return lines
end

return totals_text
