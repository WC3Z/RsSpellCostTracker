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

-- e.g. "Cost: 9,060 gp (estimated: Bone rune)". Runes priced with the fallback
-- price, or with no price at all, are named so the player knows the total is rough.
local function cost_line(totals)
    local line = "Cost: " .. format_gp(totals.gp)
    if totals.estimated_items and #totals.estimated_items > 0 then
        line = line .. " (estimated: " .. table.concat(totals.estimated_items, ", ") .. ")"
    end
    if #totals.unpriced_items > 0 then
        line = line .. " (no price: " .. table.concat(totals.unpriced_items, ", ") .. ")"
    end
    return line
end

-- shown picks which parts to include, e.g. { casts = true, runes = false, cost = true }.
-- Without it, everything is included.
function totals_text.lines(totals, shown)
    shown = shown or { casts = true, runes = true, cost = true }
    local lines = {}

    if shown.casts then
        table.insert(lines, "Lord of Bones stalls: " .. totals.casts)
    end

    if shown.runes then
        local item_names = {}
        for item_name in pairs(totals.runes_used) do
            table.insert(item_names, item_name)
        end
        table.sort(item_names)
        for _, item_name in ipairs(item_names) do
            table.insert(lines, item_name .. ": " .. totals.runes_used[item_name])
        end
    end

    if shown.cost and totals.gp then
        table.insert(lines, cost_line(totals))
    end

    return lines
end

-- Only the total cost, for the plugin's page.
function totals_text.cost_lines(totals)
    if not totals.gp then
        return { "Cost: unknown" }
    end
    return { cost_line(totals) }
end

return totals_text
