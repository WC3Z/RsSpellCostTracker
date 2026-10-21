-- Works out which tracked spells were cast from a change to a game variable.
--
-- Abilities (Lord of Bones, Darkness) are reported by COMBATV2_JUST_USED_ABILITY,
-- which is set to the ability's id. The aspect spells (Animate Dead, Vampyrism,
-- Penance) are not abilities, so they are detected by their timer instead: each
-- cast adds 12 minutes to it, while the countdown and other aspects replacing
-- it only ever lower it.
local cast_detection = {}

local just_used_ability_var = "COMBATV2_JUST_USED_ABILITY"

-- A spell's timer is packed into a larger variable together with other values.
-- timer: { var, mask, shift } as in config.lua
local function timer_value(var_value, timer)
    return (var_value & timer.mask) >> timer.shift
end

local function was_cast(spell, var_name, old_value, new_value)
    if var_name == just_used_ability_var then
        return spell.ability_id ~= nil and spell.ability_id == new_value
    end

    local timer = spell.timer
    if timer == nil or timer.var ~= var_name or old_value == nil or new_value == nil then
        return false
    end
    return timer_value(new_value, timer) > timer_value(old_value, timer)
end

-- spells: list of spells, as in config.lua
-- Returns the spells this variable change shows were cast, usually none or one.
function cast_detection.cast_spells(spells, var_name, old_value, new_value)
    local cast = {}
    for _, spell in ipairs(spells) do
        if was_cast(spell, var_name, old_value, new_value) then
            table.insert(cast, spell)
        end
    end
    return cast
end

return cast_detection
