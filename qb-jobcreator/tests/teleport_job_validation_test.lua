local file = assert(io.open("qb-jobcreator/server/main.lua", "r"))
local src = file:read("*a")
file:close()

local body = src:match("RegisterNetEvent%('qb%-jobcreator:server:teleport', function%([^%)]*%)(.-)\nend%)")
assert(body, "Teleport event not found")

local teleport = load("return function(zoneId, fromIdx, toIdx)\n" .. body .. "\nend")()

local function makeVec(x, y, z)
  local v = { x = x, y = y, z = z }
  return setmetatable(v, {
    __sub = function(a, b) return makeVec(a.x - b.x, a.y - b.y, a.z - b.z) end,
    __len = function(a) return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z) end
  })
end

vector3 = makeVec
GetEntityCoords = function(...) calledGetEntityCoords = true return makeVec(0, 0, 0) end
GetPlayerPed = function(_) return 0 end
SetEntityCoords = function(...) end
SetEntityHeading = function(...) end

Multi_Has = function(cid, job) return false end

local zone
findZoneById = function(id) return zone end

local player
QBCore = { Functions = { GetPlayer = function(_) return player end } }

-- Case 1: job required, player has different job
zone = { id = 1, ztype = 'teleport', job = 'required', coords = { x = 0, y = 0, z = 0 }, radius = 2.0, data = { to = { { x = 1, y = 1, z = 1 } } } }
player = { PlayerData = { job = { name = 'other' }, citizenid = 'cid1' } }
calledGetEntityCoords = false
teleport(1, 0, 1)
assert(not calledGetEntityCoords, 'Unauthorized teleport should not proceed')

-- Case 2: job required, player has correct job
zone.job = 'required'
player.PlayerData.job.name = 'required'
calledGetEntityCoords = false
teleport(1, 0, 1)
assert(calledGetEntityCoords, 'Authorized teleport should proceed')

-- Case 3: job not specified, any player allowed
zone.job = ''
player.PlayerData.job.name = 'other'
calledGetEntityCoords = false
teleport(1, 0, 1)
assert(calledGetEntityCoords, 'Teleport without job restriction should be allowed')

print('Teleport job validation test passed')

