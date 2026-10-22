-- The settings the player picks on the plugin's page. They are saved in the
-- game's plugin storage (PersistentDB), so they're kept between restarts.
local settings = require("src/config")

local player_settings = {}

-- Each setting has:
-- name:           which part of the cost tracker window it shows or hides
-- db_key:         the name it is saved under
-- label:          the checkbox text
-- tooltip:        optional text shown when hovering over the checkbox
-- off_by_default: optional; true if the setting starts off instead of on

-- Whether Lord of Bones casts made while wearing Necromancy gear are ignored.
player_settings.only_stalls_option = {
    db_key = "onlyLordOfBonesStalls",
    label = "Only track Lord of Bones stalls",
    tooltip = "Only counts Lord of Bones casts made without any Necromancy gear on, "
        .. "i.e. when it is cast to stall. Turn off to count every cast.",
}

-- Whether runes are priced at what shops sell them for instead of GE prices.
player_settings.iron_btw_option = {
    db_key = "ironBtw",
    label = "Iron Btw",
    tooltip = "Tracks shop cost instead of GE prices",
    off_by_default = true,
}

-- Whether the cost tracker window's background is see-through.
player_settings.transparent_window_option = {
    db_key = "transparentWindow",
    label = "Transparent window",
    off_by_default = true,
}

-- What the cost tracker window shows, in the order the checkboxes are shown.
player_settings.options = {
    { name = "casts", db_key = "showCasts", label = "Show cast count" },
    { name = "runes", db_key = "showRunes", label = "Show rune count" },
    { name = "cost", db_key = "showCost", label = "Show cost" },
    { name = "total", db_key = "showTotalCost", label = "Show total cost" },
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

-- A setting the player hasn't changed is on, unless it is off_by_default.
function player_settings.is_on(option)
    local saved = PersistentDB:GetBool(option.db_key)
    if saved == nil then
        return not option.off_by_default
    end
    return saved
end

function player_settings.set(option, on)
    PersistentDB:SetBool(option.db_key, on)
end

function player_settings.only_stalls()
    return player_settings.is_on(player_settings.only_stalls_option)
end

function player_settings.iron_btw()
    return player_settings.is_on(player_settings.iron_btw_option)
end

function player_settings.transparent_window()
    return player_settings.is_on(player_settings.transparent_window_option)
end

-- Which parts the player wants to see in the cost tracker window, e.g.
-- { casts = true, runes = false, cost = true, total = true, spells = { Darkness = true, Penance = false } }.
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
