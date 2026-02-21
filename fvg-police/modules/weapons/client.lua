local activeLoadout = {}

RegisterClientModule('weapons', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'weapons', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:GiveLoadout', function(loadout)
    local ped = PlayerPedId()
    activeLoadout = loadout
    for _, weapon in ipairs(loadout) do
        local hash = GetHashKey(weapon)
        GiveWeaponToPed(ped, hash, 250, false, false)
    end
    exports['fvg-notify']:Notify({
        type='success',
        message='Fegyverek kiosztva: ' .. #loadout .. ' db.',
        title='🔫'
    })
end)

RegisterNetEvent('fvg-police:client:RemoveLoadout', function()
    local ped = PlayerPedId()
    for _, weapon in ipairs(activeLoadout) do
        RemoveWeaponFromPed(ped, GetHashKey(weapon))
    end
    activeLoadout = {}
end)