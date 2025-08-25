local called = {}

exports = setmetatable({
    ox_inventory = {
        Search = function(...)
            print('ox_inventory:Search', ...)
            return 1
        end
    }
}, {
    __call = function(t, name, fn)
        rawset(t, name, fn)
    end
})

function RegisterNetEvent(name, fn)
    -- stub for event registration
end

function TriggerEvent(name, data)
    print('TriggerEvent', name, data[1] and data[1].name, data[2], data[3])
end

function SendNUIMessage(data)
    print('SendNUIMessage', data.action, data.state)
end

-- load the qb-inventory client script
package.path = package.path .. ';./qb-inventory/client/?.lua'
dofile('qb-inventory/client/main.lua')

-- invoke exports to verify
exports.ItemBox({ name = 'bread', amount = 2 }, 'ui_used', 1)
exports.ShowHotbar()
exports.HideHotbar()
