-- Reads the player's worn equipment from the game.
local equipment = {}

-- How many equipment slots the player has (head, body, weapon and so on).
local worn_slot_count = 18

-- Returns the item id of everything the player is wearing, by slot.
function equipment.worn_item_ids()
    -- `config` here is the game's own lookup table, not this plugin's src/config.lua.
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
