RegisterModule('clothing', {
    checkAccess = function(off) return off.duty end
})

-- Ruhakészlet ranghoz
local ClothingSets = {
    [0] = { label='Újonc egyenruha',    components = {
        { component=11, drawable=55, texture=0 },
        { component=8,  drawable=58, texture=0 },
        { component=6,  drawable=24, texture=0 },
        { component=4,  drawable=35, texture=0 },
        { component=3,  drawable=28, texture=0 },
    }},
    [1] = { label='Rendőr egyenruha', components = {
        { component=11, drawable=55, texture=0 },
        { component=8,  drawable=58, texture=0 },
        { component=6,  drawable=24, texture=0 },
        { component=4,  drawable=35, texture=0 },
        { component=3,  drawable=28, texture=0 },
    }},
    [2] = { label='Vezető rendőr',    components = {
        { component=11, drawable=49, texture=0 },
        { component=8,  drawable=58, texture=0 },
        { component=6,  drawable=25, texture=0 },
        { component=4,  drawable=35, texture=0 },
        { component=3,  drawable=28, texture=0 },
    }},
    [3] = { label='Őrmester',         components = {
        { component=11, drawable=49, texture=1 },
        { component=8,  drawable=58, texture=0 },
        { component=6,  drawable=25, texture=0 },
        { component=4,  drawable=35, texture=0 },
        { component=3,  drawable=28, texture=0 },
    }},
}

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'clothing' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end

    if action == 'wear' then
        local set = ClothingSets[off.grade] or ClothingSets[1]
        TriggerClientEvent('fvg-police:client:WearClothing', src, set)
    elseif action == 'civilian' then
        TriggerClientEvent('fvg-police:client:WearCivilian', src)
    end
end)