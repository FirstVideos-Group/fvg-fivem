RegisterClientModule('storage', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'storage', action, payload)
        cb('ok')
    end
})