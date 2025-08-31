local file = assert(io.open("qb-jobcreator/server/main.lua", "r"))
local src = file:read("*a")
file:close()

local body = src:match("local function CollectCraftingData%([^%)]*%)(.-)\nend")
assert(body, "CollectCraftingData function not found")
local collect = load("return function(src, zoneId)" .. body .. "\nend")()

QBCore = { Functions = { GetPlayer = function(_) return { PlayerData = { job = { name = 'testjob' } } } end }}

checkRecipeJob = function(recipeJob, zoneJob, playerJob)
  return true, false
end

local testZone = {
  id = 1,
  job = 'testjob',
  data = {
    allowedCategories = { 'food' },
    recipes = {}
  }
}

findZoneById = function(id)
  if id == testZone.id then return testZone end
end

playerInJobZone = function(src, zone, ztype)
  assert(zone == testZone and ztype == 'crafting')
  return true, zone
end

Config = {
  LockedItemsDisplay = { showLocked = false },
  CraftingRecipes = {
    applepie = { category = 'food', inputs = {}, time = 1, output = {} },
    salad = { category = 'food', inputs = {}, time = 1, output = {} },
    wrench = { category = 'tools', inputs = {}, time = 1, output = {} }
  }
}

local result = collect(1, 1)
assert(#result == 2, "Expected 2 recipes, got " .. #result)
for _, r in ipairs(result) do
  assert(r.category == 'food', 'Unexpected category '..tostring(r.category))
end

print('CollectCraftingData allowedCategories test passed')
