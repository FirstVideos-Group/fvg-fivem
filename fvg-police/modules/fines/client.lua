RegisterClientModule('fines', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'fines', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:FinesResult', function(fines)
    SendNUIMessage({ action = 'finesResult', fines = fines })
end)

RegisterNetEvent('fvg-police:client:FineIssued', function(data)
    SendNUIMessage({ action = 'fineIssued', data = data })
end)