-- Reads the player's worn equipment from the game.
local equipment = {}

-- Number of slots in the game's worn equipment inventory.
local worn_slot_count = 18

-- Returns { [slot] = item id } for everything the player is wearing.
function equipment.worn_item_ids()
    -- `config` here is the game's global, not this plugin's src/config.lua.
    local worn = Inventory.Find(config.Inv["WORN"])
    local item_ids = {}

    for slot = 1, worn_slot_count do
        local item = worn:GetSlot(slot)
        if item ~= nil then
            item_ids[slot] = item.obj.id
        end
    end

    return item_ids
end

return equipment
