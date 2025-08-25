local function serialize(val)
    local t = type(val)
    if t == 'string' then
        return string.format('%q', val)
    elseif t == 'number' or t == 'boolean' then
        return tostring(val)
    elseif t == 'table' then
        local out = {}
        for k, v in pairs(val) do
            out[#out+1] = '[' .. serialize(k) .. '] = ' .. serialize(v)
        end
        return '{' .. table.concat(out, ', ') .. '}'
    else
        return 'nil'
    end
end

dofile('qb-core/shared/items.lua')
local qbItems = QBShared.Items or {}
local names = {}
for name in pairs(qbItems) do
    names[#names+1] = name
end
table.sort(names)

local file = assert(io.open('ox_inventory/data/items.lua', 'w'))
file:write('return {\n')
for _, name in ipairs(names) do
    local v = qbItems[name]
    local fields = {}
    fields[#fields+1] = 'label = ' .. serialize(v.label or name)
    fields[#fields+1] = 'weight = ' .. serialize(tonumber(v.weight) or 0)
    local stack = (v.unique == nil) and true or (not v.unique)
    fields[#fields+1] = 'stack = ' .. tostring(stack)
    local close = v.shouldClose ~= false
    fields[#fields+1] = 'close = ' .. tostring(close)
    fields[#fields+1] = 'description = ' .. serialize(v.description or '')
    if v.client then
        fields[#fields+1] = 'client = ' .. serialize(v.client)
    end
    if v.server then
        fields[#fields+1] = 'server = ' .. serialize(v.server)
    end
    file:write(string.format("    ['%s'] = { %s },\n", name, table.concat(fields, ', ')))
end
file:write('}\n')
file:close()
