-- Checks whether the player's worn equipment includes Necromancy gear.
local necro_gear = {}

---@param equipment table<integer, integer>? Item id by equipment slot; empty slots are missing
---@param necro_item_ids table<integer, true> Item ids that count as Necromancy gear
---@return boolean
function necro_gear.is_wearing(equipment, necro_item_ids)
    for _, item_id in pairs(equipment or {}) do
        if necro_item_ids[item_id] then
            return true
        end
    end
    return false
end

return necro_gear
