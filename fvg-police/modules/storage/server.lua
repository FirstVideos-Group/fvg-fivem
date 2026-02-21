RegisterModule('storage', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_storage')
    end
})

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'storage' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end

    if action == 'openPersonal' then
        if not Config.HasPermission(off.grade, 'can_storage') then return end
        local storageId = 'police_personal_' .. off.id
        exports['fvg-inventory']:OpenStorage(src, storageId, {
            label  = 'Személyes tároló – ' .. off.rankLabel,
            slots  = 20,
            weight = 50,
        })

    elseif action == 'openShared' then
        if not Config.HasPermission(off.grade, 'can_shared_storage') then
            TriggerClientEvent('fvg-notify:client:Notify', src, {
                type='error', message='Nincs jogosultságod a közös tárolóhoz.'
            }); return
        end
        local stationId = payload.stationId or 'mission_row'
        local storageId = 'police_shared_' .. stationId
        exports['fvg-inventory']:OpenStorage(src, storageId, {
            label  = 'Közös tároló – ' .. stationId,
            slots  = 100,
            weight = 500,
            shared = true,
        })
    end
end)