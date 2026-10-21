-- What the cost tracker window shows. Saved in PersistentDB, so the choices are
-- kept when the plugin restarts.
local settings = require("src/config")

local display_settings = {}

-- In the order the checkboxes are shown.
-- name:   the part of the totals it controls, as used by totals_text.lines
-- db_key: where the choice is saved in PersistentDB
-- label:  the checkbox text
display_settings.options = {
    { name = "casts", db_key = "showCasts", label = "Show cast count" },
    { name = "runes", db_key = "showRunes", label = "Show rune count" },
    { name = "cost", db_key = "showCost", label = "Show total cost" },
}

-- One option per tracked spell, in the order of settings.spells, e.g.
-- { name = "Darkness", db_key = "showDarknessCost", label = "Show Darkness cost" }.
display_settings.spell_options = {}
for _, spell in ipairs(settings.spells) do
    table.insert(display_settings.spell_options, {
        name = spell.key,
        db_key = "show" .. spell.key .. "Cost",
        label = "Show " .. spell.name .. " cost",
    })
end

-- Every setting is on unless the player has turned it off.
function display_settings.is_on(option)
    return PersistentDB:GetBool(option.db_key) ~= false
end

function display_settings.set(option, on)
    PersistentDB:SetBool(option.db_key, on)
end

-- Which parts the player wants to see, e.g.
-- { casts = true, runes = false, cost = true, spells = { Darkness = true, Penance = false } }.
function display_settings.current()
    local shown = { spells = {} }
    for _, option in ipairs(display_settings.options) do
        shown[option.name] = display_settings.is_on(option)
    end
    for _, option in ipairs(display_settings.spell_options) do
        shown.spells[option.name] = display_settings.is_on(option)
    end
    return shown
end

return display_settings
