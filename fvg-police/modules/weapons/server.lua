RegisterModule('weapons', {
    checkAccess = function(off)
        return Config.HasPermission(off.grade, 'can_weapons')
    end
})

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'weapons' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end
    if not Config.HasPermission(off.grade, 'can_weapons') then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='error', message='Nincs jogod fegyvert kivenni.'
        }); return
    end

    if action == 'getLoadout' then
        local rank   = Config.GetRank(off.grade)
        local loadout= rank and rank.weapon_loadout or {}
        TriggerClientEvent('fvg-police:client:GiveLoadout', src, loadout)

    elseif action == 'returnLoadout' then
        TriggerClientEvent('fvg-police:client:RemoveLoadout', src)
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='info', message='Fegyverek leadva.'
        })
    end
end)