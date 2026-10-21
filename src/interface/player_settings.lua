-- The choices the player makes on the plugin's page. Saved in PersistentDB, so
-- they are kept when the plugin restarts.
local settings = require("src/config")

local player_settings = {}

-- Each option:
-- name:   the part of the totals it controls, as used by totals_text.lines
-- db_key: where the choice is saved in PersistentDB
-- label:  the checkbox text
-- tooltip: optional text shown when hovering over the checkbox

-- Whether Lord of Bones casts made while wearing Necromancy gear are ignored.
player_settings.only_stalls_option = {
    db_key = "onlyLordOfBonesStalls",
    label = "Only track Lord of Bones stalls",
    tooltip = "Only counts Lord of Bones casts made without any Necromancy gear on, "
        .. "i.e. when it is cast to stall. Turn off to count every cast.",
}

-- What the cost tracker window shows, in the order the checkboxes are shown.
player_settings.options = {
    { name = "casts", db_key = "showCasts", label = "Show cast count" },
    { name = "runes", db_key = "showRunes", label = "Show rune count" },
    { name = "cost", db_key = "showCost", label = "Show cost" },
}

-- One option per tracked spell, in the order of settings.spells, e.g.
-- { name = "Darkness", db_key = "showDarknessCost", label = "Show Darkness cost" }.
player_settings.spell_options = {}
for _, spell in ipairs(settings.spells) do
    table.insert(player_settings.spell_options, {
        name = spell.key,
        db_key = "show" .. spell.key .. "Cost",
        label = "Show " .. spell.name .. " cost",
    })
end

-- Every setting is on unless the player has turned it off.
function player_settings.is_on(option)
    return PersistentDB:GetBool(option.db_key) ~= false
end

function player_settings.set(option, on)
    PersistentDB:SetBool(option.db_key, on)
end

function player_settings.only_stalls()
    return player_settings.is_on(player_settings.only_stalls_option)
end

-- Which parts the player wants to see in the cost tracker window, e.g.
-- { casts = true, runes = false, cost = true, spells = { Darkness = true, Penance = false } }.
function player_settings.shown()
    local shown = { spells = {} }
    for _, option in ipairs(player_settings.options) do
        shown[option.name] = player_settings.is_on(option)
    end
    for _, option in ipairs(player_settings.spell_options) do
        shown.spells[option.name] = player_settings.is_on(option)
    end
    return shown
end

return player_settings
