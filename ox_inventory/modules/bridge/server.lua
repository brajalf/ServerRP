---@todo separate module into smaller submodules to handle each framework
---starting to get bulky

function server.hasGroup(inv, group)
	if type(group) == 'table' then
		for name, rank in pairs(group) do
			local groupRank = inv.player.groups[name]
			if groupRank and groupRank >= (rank or 0) then
				return name, groupRank
			end
		end
	else
		local groupRank = inv.player.groups[group]
		if groupRank then
			return group, groupRank
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
	if not player.groups then
		warn(("server.setPlayerData did not receive any groups for '%s'"):format(player?.name or GetPlayerName(player)))
	end

	return {
		source = player.source,
		name = player.name,
		groups = player.groups or {},
		sex = player.sex,
		dateofbirth = player.dateofbirth,
	}
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense()
	warn('Licenses are not supported for the current framework.')
end

local Inventory = require 'modules.inventory.server'

function server.playerDropped(source)
	local inv = Inventory(source) --[[@as OxInventory]]

	if inv?.player then
		inv:closeInventory()
		Inventory.Remove(inv)
	end
end

local success, result = pcall(lib.load, ('modules.bridge.%s.server'):format(shared.framework))

if not success then
    lib = nil
    error(result, 0)
end

if server.convertInventory then exports('ConvertItems', server.convertInventory) end

exports('OpenStash', function(src, id, opts)
    if shared.framework == 'qb' then
        local state = GetResourceState('qb-inventory')
        if state == 'started' or state == 'starting' then
            local o = opts or {}
            return exports['qb-inventory']:OpenStash(src, id, o.slots, o.weight, o.owner, o.groups)
        else
            warn("qb-inventory is not available, falling back to ox_inventory")
        end
    end

    return exports.ox_inventory:forceOpenInventory(src, 'stash', id)
end)

exports('OpenShop', function(src, id)
    if shared.framework == 'qb' then
        local state = GetResourceState('qb-inventory')
        if state == 'started' or state == 'starting' then
            return exports['qb-inventory']:OpenShop(src, id)
        else
            warn("qb-inventory is not available, falling back to ox_inventory")
        end
    end

    return exports.ox_inventory:forceOpenInventory(src, 'shop', id)
end)
