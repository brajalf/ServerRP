local createdZones = {}

local function clearZones()
  for _, z in ipairs(createdZones) do
    if z.type == 'qb' then
      exports['qb-target']:RemoveZone(z.id)
    elseif z.type == 'ox' then
      exports.ox_target:removeZone(z.id)
    elseif z.type == 'thread' and z.thread then
      z.thread.stop = true
    end
  end
  createdZones = {}
end

local function registerZone(z)
  local id = tostring(z.id)
  local name = z.label or 'Craft'
  local center = vector3(z.coords.x or 0.0, z.coords.y or 0.0, z.coords.z or 0.0)
  local icon = (z.data and z.data.icon) or 'fa-solid fa-hammer'
  local radius = z.radius or 1.5

  if Config.InteractionType == 'qb' then
    exports['qb-target']:AddCircleZone(id, center, radius, { name = id, useZ = true, debugPoly = Config.Debug }, {
      options = {{ icon = icon, label = name, action = function() TriggerEvent('invictus_craft:client:openStation', id) end }},
      distance = 2.0
    })
    createdZones[#createdZones+1] = { type = 'qb', id = id }
  elseif Config.InteractionType == 'ox' then
    local zone = exports.ox_target:addSphereZone({
      coords = center,
      radius = radius,
      debug = Config.Debug,
      options = {{ name = id, icon = icon, label = name, onSelect = function() TriggerEvent('invictus_craft:client:openStation', id) end }}
    })
    createdZones[#createdZones+1] = { type = 'ox', id = zone }
  elseif Config.InteractionType == 'textui' then
    local data = { stop = false }
    data.thread = CreateThread(function()
      local hintShown = false
      while not data.stop do
        local sleep = 1000
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        if #(p - center) < radius then
          sleep = 0
          if not hintShown then
            hintShown = true
            if lib and lib.showTextUI then lib.showTextUI(('[E] %s'):format(name)) end
          end
          if IsControlJustReleased(0, 38) then
            TriggerEvent('invictus_craft:client:openStation', id)
          end
        else
          if hintShown then
            hintShown = false
            if lib and lib.hideTextUI then lib.hideTextUI() end
          end
        end
        Wait(sleep)
      end
    end)
    createdZones[#createdZones+1] = { type = 'thread', thread = data }
  end
end

RegisterNetEvent('qb-jobcreator:client:rebuildZones', function(zones)
  clearZones()
  for _, z in ipairs(zones or {}) do
    if z.ztype == 'crafting' then
      registerZone(z)
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  clearZones()
end)
