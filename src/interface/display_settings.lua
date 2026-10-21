-- What the cost tracker window shows. Saved in PersistentDB, so the choices are
-- kept when the plugin restarts.
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

-- Every setting is on unless the player has turned it off.
function display_settings.is_on(option)
    return PersistentDB:GetBool(option.db_key) ~= false
end

function display_settings.set(option, on)
    PersistentDB:SetBool(option.db_key, on)
end

-- Which parts the player wants to see, e.g. { casts = true, runes = false, cost = true }.
function display_settings.current()
    local shown = {}
    for _, option in ipairs(display_settings.options) do
        shown[option.name] = display_settings.is_on(option)
    end
    return shown
end

return display_settings
