local function GetClosestPlayer(radius)
  local players = QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), radius or 2.0)
  for _, pid in ipairs(players) do if pid ~= PlayerId() then return GetPlayerServerId(pid) end end
end

RegisterNetEvent('qb-jobcreator:client:act:putinveh', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  TriggerServerEvent('police:server:PutPlayerInVehicle', tgt)
end)

RegisterNetEvent('qb-jobcreator:client:act:outveh', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  TriggerServerEvent('police:server:TakeOutPlayerFromVehicle', tgt)
end)

RegisterNetEvent('qb-jobcreator:client:act:bill', function()
  local tgt = GetClosestPlayer(2.0); if not tgt then return end
  -- Hook a tu sistema de facturas (ej. qb-banking / okokBilling)
  TriggerEvent('qb-billing:client:OpenBillMenu', tgt)
end)