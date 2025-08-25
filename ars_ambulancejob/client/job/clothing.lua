if not Config.ClothingScript then return end

local FreezeEntityPosition            = FreezeEntityPosition
local SetEntityInvincible             = SetEntityInvincible
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents

local function openClothingMenu()
    lib.registerContext({
        id = 'ambulance_clothing_menu',
        title = 'Clothing Store',
        options = {
            {
                title = '🧥 Civil/Work Clothes',
                description = 'Open the wardrobe to change your look',
                onSelect = function()
                    exports['illenium-appearance']:startPlayerCustomization(function(app)
                        -- guardar/usar la apariencia si se desea
                    end, { components = true, props = true, headBlend = false, faceFeatures = false,
                           headOverlays = false, hair = false, tattoos = false })
                end,
            },
        }
    })

    lib.showContext('ambulance_clothing_menu')
end

function initClothes(data, jobs)
    local ped = utils.createPed(data.model, data.pos)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    addLocalEntity(ped, {
        {
            label = locale('clothing_interact_label'),
            icon = 'fa-solid fa-road',
            groups = jobs,
            fn = function()
                openClothingMenu()
            end
        }
    })
end

-- © 𝐴𝑟𝑖𝑢𝑠 𝐷𝑒𝑣𝑒𝑙𝑜𝑝𝑚𝑒𝑛𝑡
