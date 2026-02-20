-- ╔══════════════════════════════════════╗
-- ║        fvg-notify :: server          ║
-- ╚══════════════════════════════════════╝

-- ── Egy adott játékosnak küld értesítést ────────────────────
-- exports['fvg-notify']:NotifyPlayer(source, data)
exports('NotifyPlayer', function(source, data)
    if not source or source <= 0 then return end
    if type(data) == 'string' then
        data = { message = data }
    end
    TriggerClientEvent('fvg-notify:client:Notify', source, data)
end)

-- ── Minden játékosnak küld értesítést ───────────────────────
-- exports['fvg-notify']:NotifyAll(data)
exports('NotifyAll', function(data)
    if type(data) == 'string' then
        data = { message = data }
    end
    TriggerClientEvent('fvg-notify:client:Notify', -1, data)
end)

-- ── Hálózati esemény más scriptektől ───────────────────────
RegisterServerEvent('fvg-notify:server:Notify', function(source, data)
    if type(data) == 'string' then
        data = { message = data }
    end
    TriggerClientEvent('fvg-notify:client:Notify', source, data)
end)