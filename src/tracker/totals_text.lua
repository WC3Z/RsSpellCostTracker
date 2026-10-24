-- Turns the spell totals into the lines of text shown to the player.
local totals_text = {}

-- 1234567 -> "1,234,567 gp"
-- Commas go every 3 digits counting from the right, so the digits are
-- reversed, a comma is added after every 3, and then they're reversed back.
-- That can leave a comma at the very front (",123"), which is removed.
---@param gp number
---@return string
function totals_text.format_gp(gp)
    local digits = tostring(math.floor(gp))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (grouped:gsub("^,", "")) .. " gp"
end

local format_gp = totals_text.format_gp

-- e.g. "9,060 gp (no price: Bone rune)". Runes that couldn't be priced at all
-- are listed so the player knows the real cost is higher.
---@param spell SpellTotals
---@return string
local function cost_text(spell)
    local text = format_gp(spell.gp)
    if #spell.unpriced_items > 0 then
        text = text .. " (no price: " .. table.concat(spell.unpriced_items, ", ") .. ")"
    end
    return text
end

---@param count integer
---@param word string
---@return string
local function plural(count, word)
    if count == 1 then
        return count .. " " .. word
    end
    return count .. " " .. word .. "s"
end

-- The spells that have been cast at least once and that the player wants shown.
---@param spell_totals SpellTotals[]
---@param is_shown fun(spell: SpellTotals): boolean
---@return SpellTotals[]
local function cast_spells(spell_totals, is_shown)
    local result = {}
    for _, spell in ipairs(spell_totals) do
        if spell.casts > 0 and is_shown(spell) then
            table.insert(result, spell)
        end
    end
    return result
end

---@param spells SpellTotals[]
---@return number
local function total_gp(spells)
    local gp = 0
    for _, spell in ipairs(spells) do
        gp = gp + spell.gp
    end
    return gp
end

-- A line saying how much of the cost was priced with rough prices, with a
-- tooltip naming the runes. nil when none of it was.
---@param spells SpellTotals[]
---@return LineWithTooltip?
local function estimated_line(spells)
    local gp = 0
    local item_set = {}
    for _, spell in ipairs(spells) do
        gp = gp + spell.estimated_gp
        for _, item_name in ipairs(spell.estimated_items) do
            item_set[item_name] = true
        end
    end
    if gp <= 0 then
        return nil
    end

    local item_names = {}
    for item_name in pairs(item_set) do
        table.insert(item_names, item_name)
    end
    table.sort(item_names)
    return {
        text = "Estimated: " .. format_gp(gp),
        tooltip = "The part of the cost that uses rough prices, because the real price "
            .. "wasn't available for: " .. table.concat(item_names, ", "),
    }
end

---@param lines Line[]
---@param spells SpellTotals[]
local function add_estimated_line(lines, spells)
    local line = estimated_line(spells)
    if line then
        table.insert(lines, line)
    end
end

---@param lines Line[]
---@param spell SpellTotals
---@param shown ShownParts
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

-- The lines for the cost tracker window. Spells that haven't been cast yet
-- are always left out. Each line is a string, except the estimated line,
-- which has a tooltip.
---@param spell_totals SpellTotals[] Every spell's totals, as SpellTracker:totals() gives them
---@param shown? ShownParts Which parts the player wants to see; leave out to show everything
---@return Line[]
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
    if shown.cost or shown.total then
        add_estimated_line(lines, spells)
    end
    return lines
end

-- The cost of each spell cast so far and their total, for the plugin's page.
---@param spell_totals SpellTotals[]
---@return Line[]
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
    add_estimated_line(lines, spells)
    return lines
end

return totals_text
