local file = assert(io.open("qb-jobcreator/server/main.lua", "r"))
local src = file:read("*a")
file:close()

local alphaBody = src:match("local function IsAlphaNum%([^%)]*%)(.-)\nend")
assert(alphaBody, "IsAlphaNum function not found")
_G.IsAlphaNum = load("return function(str)" .. alphaBody .. "\nend")()

local jobBody = src:match("local function ValidateJobData%([^%)]*%)(.-)\nend")
assert(jobBody, "ValidateJobData function not found")
local validateJob = load("return function(data)" .. jobBody .. "\nend")()

local zoneBody = src:match("local function ValidateZoneData%([^%)]*%)(.-)\nend")
assert(zoneBody, "ValidateZoneData function not found")
local ztypeBody = src:match("local function IsValidZoneType%([^%)]*%)(.-)\nend")
assert(ztypeBody, "IsValidZoneType function not found")
_G.IsValidZoneType = load("return function(ztype)" .. ztypeBody .. "\nend")()
local validateZone = load("return function(zone)" .. zoneBody .. "\nend")()

Config = { ZoneTypes = { 'shop', 'crafting' } }

local ok, err = validateJob({ name = 'valid1' })
assert(ok, "Expected valid job to pass")

ok, err = validateJob({ name = 'bad name' })
assert(not ok, "Job name with spaces should fail")

ok, err = validateZone({ job = 'test', ztype = 'shop', coords = { x=0, y=0, z=0 }, radius = 1 })
assert(ok, "Valid zone should pass")

ok, err = validateZone({ job = 'test', ztype = 'shop', coords = { x=0, y=0, z=0 }, radius = 0 })
assert(not ok, "Zone with zero radius should fail")

ok, err = validateZone({ job = 'test', ztype = 'unknown', coords = { x=0, y=0, z=0 }, radius = 1 })
assert(not ok, "Zone with invalid type should fail")

print("Validation tests passed")
