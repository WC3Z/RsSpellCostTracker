-- Checks whether the player's worn equipment includes Necromancy gear.
local necro_gear = {}

-- equipment: table of slot -> item id (nil or missing for empty slots)
-- necro_item_ids: set of item ids that count as Necromancy gear
function necro_gear.is_wearing(equipment, necro_item_ids)
    for _, item_id in pairs(equipment or {}) do
        if necro_item_ids[item_id] then
            return true
        end
    end
    return false
end

return necro_gear
