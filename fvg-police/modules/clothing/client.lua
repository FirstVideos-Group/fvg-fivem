local savedCivComponents = {}

RegisterClientModule('clothing', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'clothing', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:WearClothing', function(set)
    local ped = PlayerPedId()
    -- Mentjük a civil ruhákat
    savedCivComponents = {}
    for _, comp in ipairs(set.components) do
        savedCivComponents[comp.component] = {
            drawable = GetPedDrawableVariation(ped, comp.component),
            texture  = GetPedTextureVariation(ped, comp.component),
        }
        SetPedComponentVariation(ped, comp.component, comp.drawable, comp.texture, 0)
    end
    exports['fvg-notify']:Notify({ type='success', message=set.label .. ' felöltve.' })
end)

RegisterNetEvent('fvg-police:client:WearCivilian', function()
    local ped = PlayerPedId()
    for comp, data in pairs(savedCivComponents) do
        SetPedComponentVariation(ped, comp, data.drawable, data.texture, 0)
    end
    exports['fvg-notify']:Notify({ type='info', message='Civil ruha visszaállítva.' })
end)