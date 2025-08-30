local createdZones = {}

local function addQBTargetBox(station)
  exports['qb-target']:AddBoxZone(station.id, station.center, station.length, station.width, {
    name = station.id,
    heading = station.heading or 0.0,
    minZ = station.minZ or (station.center.z - 1.0),
    maxZ = station.maxZ or (station.center.z + 1.0),
    debugPoly = Config.Debug
  }, {
    options = {{
      icon = 'fa-solid fa-hammer',
      label = station.name or 'Craft',
      action = function() TriggerEvent('invictus_craft:client:openStation', station.id) end
    }},
    distance = 2.0
  })
  createdZones[#createdZones+1] = { type = 'qb', id = station.id }
end

local function addQBTargetCircle(station)
  exports['qb-target']:AddCircleZone(station.id, station.center, station.radius or 1.4, {
    name = station.id, useZ = true, debugPoly = Config.Debug
  }, {
    options = {{
      icon = 'fa-solid fa-hammer',
      label = station.name or 'Craft',
      action = function() TriggerEvent('invictus_craft:client:openStation', station.id) end
    }},
    distance = 2.0
  })
  createdZones[#createdZones+1] = { type = 'qb', id = station.id }
end

local function addOxTargetBox(station)
  local zone = exports.ox_target:addBoxZone({
    coords = station.center,
    size = vec3(station.length, station.width, (station.maxZ or (station.center.z+1))- (station.minZ or (station.center.z-1))),
    rotation = station.heading or 0.0,
    debug = Config.Debug,
    options = {{
      name = station.id,
      icon = 'fa-solid fa-hammer',
      label = station.name or 'Craft',
      onSelect = function() TriggerEvent('invictus_craft:client:openStation', station.id) end
    }}
  })
  createdZones[#createdZones+1] = { type = 'ox', id = zone }
end

CreateThread(function()
  for _, st in ipairs(Config.Stations) do
    if Config.InteractionType == 'qb' then
      if st.type == 'circle' then addQBTargetCircle(st) else addQBTargetBox(st) end
    elseif Config.InteractionType == 'ox' then
      addOxTargetBox(st)
    elseif Config.InteractionType == 'textui' then
      local hintShown = false
      CreateThread(function()
        while true do
          local sleep = 1000
          local ped = PlayerPedId()
          local p = GetEntityCoords(ped)
          if #(p - st.center) < 2.0 then
            sleep = 0
            if not hintShown then
              hintShown = true
              if lib and lib.showTextUI then lib.showTextUI(('[E] %s'):format(st.name or 'Craft')) end
            end
            if IsControlJustReleased(0, 38) then -- E
              TriggerEvent('invictus_craft:client:openStation', st.id)
            end
          else
            if hintShown then hintShown = false; if lib and lib.hideTextUI then lib.hideTextUI() end end
          end
          Wait(sleep)
        end
      end)
    end
  end
end)
