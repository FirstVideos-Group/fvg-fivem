RegisterModule('garage', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_garage')
    end
})

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'garage' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end
    if not Config.HasPermission(off.grade, 'can_garage') then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='error', message='Nincs jogosultságod járművet kivenni.'
        }); return
    end

    if action == 'spawn' then
        local model  = payload.model
        local vehDef = nil
        for _, v in ipairs(Config.Vehicles) do
            if v.model == model then vehDef = v; break end
        end
        if not vehDef then return end

        -- Rang ellenőrzés
        local rank = Config.GetRank(off.grade)
        local allowed = false
        for _, cls in ipairs(rank.vehicle_classes) do
            if cls == vehDef.class then allowed = true; break end
        end
        if not allowed then
            TriggerClientEvent('fvg-notify:client:Notify', src, {
                type='error', message='Ez a jármű nem érhető el a te rangodhoz.'
            }); return
        end

        TriggerClientEvent('fvg-police:client:SpawnVehicle', src, {
            vehDef    = vehDef,
            stationId = payload.stationId,
        })

        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message=vehDef.label .. ' kivéve a garázsból.', title='🚔'
        })
    end
end)