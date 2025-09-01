-- Shared seat occupancy check to ensure client and server filter vehicles identically.
-- This routine is used in both local and server cleanups to avoid future divergence.

GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers or function(vehicle)
  return Citizen.InvokeNative(0xA7C4F2C6E744A1E8, vehicle)
end

GetVehicleNumberOfPassengers = GetVehicleNumberOfPassengers or function(vehicle)
  return Citizen.InvokeNative(0x24CB213773B00F79, vehicle)
end

IsVehicleSeatFree = IsVehicleSeatFree or function(vehicle, seatIndex)
  return Citizen.InvokeNative(0x22AC59A870E6A669, vehicle, seatIndex)
end

function isAnySeatOccupied(veh, logFn)
  local max = GetVehicleMaxNumberOfPassengers(veh)
  if type(max) ~= "number" or max < -1 then
    if logFn then
      logFn(('Unexpected max passenger value %s for vehicle %s'):format(tostring(max), veh))
    end
    max = GetVehicleNumberOfPassengers(veh)
    if type(max) ~= "number" or max < -1 then
      max = 0
    end
  end

  if max > 7 then max = 7 end

  for seat = -1, max do
    local seatFree = IsVehicleSeatFree(veh, seat)
    seatFree = seatFree == true or seatFree == 1
    if not seatFree then return true end
  end

  return false
end

return {
  isAnySeatOccupied = isAnySeatOccupied
}
