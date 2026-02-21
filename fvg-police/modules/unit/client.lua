RegisterClientModule('unit', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'unit', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:UnitsUpdated', function(list)
    SendNUIMessage({ action = 'unitsUpdated', units = list })
end)

RegisterNetEvent('fvg-police:client:UnitJoined', function(unit)
    SendNUIMessage({ action = 'unitJoined', unit = unit })
end)

RegisterNetEvent('fvg-police:client:UnitDisbanded', function()
    SendNUIMessage({ action = 'unitDisbanded' })
end)