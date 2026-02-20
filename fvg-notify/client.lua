-- ╔══════════════════════════════════════╗
-- ║        fvg-notify :: client          ║
-- ╚══════════════════════════════════════╝

local activeCount = 0

-- Helyi notify függvény
local function SendNotify(data)
    if activeCount >= Config.MaxNotifications then return end

    local ntype    = data.type     or 'info'
    local title    = data.title    or (Config.Types[ntype] and Config.Types[ntype].label) or 'Értesítés'
    local message  = data.message  or ''
    local duration = data.duration or Config.DefaultDuration
    local icon     = data.icon     or (Config.Types[ntype] and Config.Types[ntype].icon) or 'hgi-stroke hgi-information-circle'

    activeCount = activeCount + 1

    SendNUIMessage({
        action   = 'notify',
        type     = ntype,
        title    = title,
        message  = message,
        duration = duration,
        icon     = icon,
        position = Config.Position,
        sound    = Config.PlaySound
    })

    SetTimeout(duration + Config.AnimationSpeed + 100, function()
        activeCount = math.max(0, activeCount - 1)
    end)
end

-- ── Exportált függvény ──────────────────────────────────────
-- exports['fvg-notify']:Notify(data)
-- data = { type, title, message, duration, icon }
exports('Notify', function(data)
    if type(data) == 'string' then
        data = { message = data }
    end
    SendNotify(data)
end)

-- ── Hálózati esemény (szerverről) ───────────────────────────
RegisterNetEvent('fvg-notify:client:Notify', function(data)
    SendNotify(data)
end)

-- ── NUI visszajelzés ────────────────────────────────────────
RegisterNUICallback('notifyClosed', function(data, cb)
    activeCount = math.max(0, activeCount - 1)
    cb('ok')
end)