-- ox_bridge.lua: helper utilities bridging qb-inventory with ox_inventory style helpers

--- Syncs all inventory slots with a single player.
--- @param src number
function SyncSlotsWithPlayer(src)
    if not src then return end
    TriggerClientEvent('qb-inventory:client:updateInventory', src)
end

--- Syncs inventory slots with all clients looking at the inventory.
--- Since qb-inventory tracks a single viewer per inventory via `isOpen`,
--- this will fall back to syncing only the owner when additional viewers
--- cannot be determined.
--- @param ownerId number
--- @param slots table|nil currently unused but kept for compatibility
function SyncSlotsWithClients(ownerId, slots)
    if ownerId then
        TriggerClientEvent('qb-inventory:client:updateInventory', ownerId)
    end
end

--- Retrieves an inventory's items based on type and owner identifier.
--- Falls back to the legacy single-argument identifier behaviour.
--- @param inv string|nil inventory type or identifier
--- @param owner any owner identifier (player id, stash name, vehicle plate)
--- @return table inventory items table
function GetInventory(inv, owner)
    -- Legacy support: treat the first argument as an identifier
    if owner == nil then
        if Inventories and Inventories[inv] then
            return Inventories[inv].items or Inventories[inv]
        end
        if Inventories and Inventories['drop'] and Inventories['drop'][inv] then
            local drop = Inventories['drop'][inv]
            return drop.items or drop
        end
        if inv == 'player' or tonumber(inv) then
            local ply = QBCore.Functions.GetPlayer(inv)
            return ply and ply.PlayerData.items or {}
        end
        return {}
    end

    if inv == 'player' then
        local ply = QBCore.Functions.GetPlayer(owner)
        return ply and ply.PlayerData.items or {}
    elseif inv == 'stash' then
        local stash = Inventories and Inventories[owner]
        return stash and stash.items or {}
    elseif inv == 'drop' then
        local drop = Inventories and Inventories['drop'] and Inventories['drop'][owner]
        return drop and drop.items or {}
    elseif inv == 'trunk' then
        local trunk = Inventories and Inventories['trunk-' .. owner]
        return trunk and trunk.items or {}
    elseif inv == 'glovebox' or inv == 'glove' then
        local glove = Inventories and Inventories['glovebox-' .. owner]
        return glove and glove.items or {}
    else
        local inventory = Inventories and Inventories[inv]
        if not inventory and Inventories and Inventories['drop'] then
            inventory = Inventories['drop'][inv]
        end
        return inventory and inventory.items or {}
    end
end

--- Wrapper to directly retrieve items from an inventory.
--- @param inv string inventory type or identifier
--- @param owner any owner identifier
--- @return table inventory items
function GetInventoryItems(inv, owner)
    local items = GetInventory(inv, owner)
    return items or {}
end

exports('GetInventory', GetInventory)
exports('GetInventoryItems', GetInventoryItems)
