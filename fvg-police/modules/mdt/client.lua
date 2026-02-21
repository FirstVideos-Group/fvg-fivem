RegisterClientModule('mdt', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'mdt', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:MDTResults', function(results)
    SendNUIMessage({ action = 'mdtResults', results = results })
end)