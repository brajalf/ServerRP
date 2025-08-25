local function normalize(items)
    if not items then return {} end
    local out = {}
    if type(items) == 'string' then
        out[#out+1] = { name = items, amount = 1 }
        return out
    end
    if items.name then
        out[#out+1] = { name = items.name, amount = items.amount or 1, metadata = items.info or items.metadata }
        return out
    end
    for _, it in pairs(items) do
        if type(it) == 'string' then
            out[#out+1] = { name = it, amount = 1 }
        elseif type(it) == 'table' then
            out[#out+1] = { name = it.name or it[1], amount = it.amount or 1, metadata = it.info or it.metadata }
        end
    end
    return out
end

return normalize
