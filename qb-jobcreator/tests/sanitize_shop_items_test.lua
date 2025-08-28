local file = assert(io.open("qb-jobcreator/server/main.lua", "r"))
local src = file:read("*a")
file:close()

local body = src:match("local function SanitizeShopItems%([^%)]*%)(.-)\nend")
assert(body, "SanitizeShopItems function not found")

local sanitize = load("return function(items)" .. body .. "\nend")()

local function assertEqual(actual, expected, msg)
  if actual ~= expected then
    error((msg or "assertion failed") .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")", 2)
  end
end

-- negative price -> discarded
local result1 = sanitize({{name='apple', price=-5, count=2}})
assertEqual(#result1, 0, "Item with negative price should be discarded")

-- negative count -> sanitized to 1
local result2 = sanitize({{name='banana', price=10, count=-3}})
assertEqual(result2[1].count, 1, "Negative count should be sanitized to 1")

-- zero price -> discarded
local result3 = sanitize({{name='free', price=0, count=1}})
assertEqual(#result3, 0, "Item with zero price should be discarded")

print("All tests passed")
