-- ── Egység cache ──────────────────────────────────────────────
-- { unitId → { id, name, leader, members[src], channel } }
local units = {}
local unitCounter = 0

RegisterModule('unit', {
    checkAccess = function(off) return off.duty end
})

local function GetUnit(unitId)
    return units[unitId]
end

local function BroadcastUnits()
    local list = {}
    for id, u in pairs(units) do
        table.insert(list, {
            id      = id,
            name    = u.name,
            leader  = u.leader,
            members = u.members,
            count   = #u.members,
        })
    end
    TriggerClientEvent('fvg-police:client:UnitsUpdated', -1, list)
end

AddEventHandler('fvg-police:server:LeaveUnit', function(src)
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.unit then return end
    local unit = units[off.unit]
    if not unit then off.unit = nil; return end

    for i, m in ipairs(unit.members) do
        if m == src then table.remove(unit.members, i); break end
    end

    if #unit.members == 0 then
        units[off.unit] = nil
    elseif unit.leader == src and #unit.members > 0 then
        unit.leader = unit.members[1]
    end
    off.unit = nil
    BroadcastUnits()
end)

RegisterNetEvent('fvg-police:server:ModuleAction', function(module, action, payload)
    if module ~= 'unit' then return end
    local src = source
    local off = exports['fvg-police']:GetOfficer(src)
    if not off or not off.duty then return end

    if action == 'create' then
        if not Config.HasPermission(off.grade, 'can_manage_units') then
            TriggerClientEvent('fvg-notify:client:Notify', src, {
                type='error', message='Nincs jogod egységet létrehozni.'
            }); return
        end
        unitCounter = unitCounter + 1
        local unitId = unitCounter
        units[unitId] = {
            id      = unitId,
            name    = payload.name or ('Adam-' .. unitId),
            leader  = src,
            members = { src },
            channel = payload.channel or 1,
        }
        off.unit = unitId
        BroadcastUnits()
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message='Egység létrehozva: ' .. units[unitId].name, title='👮'
        })
        TriggerClientEvent('fvg-police:client:UnitJoined', src, units[unitId])

    elseif action == 'join' then
        local unitId = tonumber(payload.unitId)
        local unit   = GetUnit(unitId)
        if not unit then
            TriggerClientEvent('fvg-notify:client:Notify', src, {
                type='error', message='Az egység nem létezik.'
            }); return
        end
        if off.unit then
            TriggerEvent('fvg-police:server:LeaveUnit', src)
        end
        table.insert(unit.members, src)
        off.unit = unitId
        BroadcastUnits()
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='success', message='Csatlakoztál: ' .. unit.name
        })
        TriggerClientEvent('fvg-police:client:UnitJoined', src, unit)

    elseif action == 'leave' then
        TriggerEvent('fvg-police:server:LeaveUnit', src)
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type='info', message='Elhagytad az egységet.'
        })

    elseif action == 'disband' then
        local unit = off.unit and units[off.unit]
        if not unit or unit.leader ~= src then
            TriggerClientEvent('fvg-notify:client:Notify', src, {
                type='error', message='Csak az egység vezető oszlathatja fel.'
            }); return
        end
        for _, m in ipairs(unit.members) do
            local mOff = exports['fvg-police']:GetOfficer(m)
            if mOff then mOff.unit = nil end
            TriggerClientEvent('fvg-notify:client:Notify', m, {
                type='warning', message='Az egység feloszlott.'
            })
            TriggerClientEvent('fvg-police:client:UnitDisbanded', m)
        end
        units[off.unit] = nil
        off.unit = nil
        BroadcastUnits()
    end
end)

-- Export
exports('GetOfficerUnit', function(src)
    local off = exports['fvg-police']:GetOfficer(tonumber(src))
    return off and off.unit and units[off.unit] or nil
end)