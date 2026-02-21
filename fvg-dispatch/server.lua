-- ╔══════════════════════════════════════════════╗
-- ║         fvg-dispatch :: server               ║
-- ╚══════════════════════════════════════════════╝

-- ── Aktív riasztások cache ────────────────────────────────────
-- [alertId] = { id, type, priority, title, message, coords,
--               caller, callerName, units={}, createdAt, expires }
local activeAlerts = {}
local alertCounter = 0

-- ── Segédfüggvények ───────────────────────────────────────────

local function GenAlertId()
    alertCounter = alertCounter + 1
    return string.format('ALT-%05d', alertCounter)
end

local function GetTimestamp()
    return os.date('%H:%M:%S')
end

-- JAVÍTÁS: player.job → player.metadata.job
local function GetJobOf(src)
    local player = exports['fvg-playercore']:GetPlayer(src)
    return player and player.metadata and player.metadata.job or nil
end

local function CanSeeAlert(src, alertType)
    local job     = GetJobOf(src)
    if not job then return false end
    local typeDef = Config.AlertTypes[alertType]
    if not typeDef then return false end
    for _, j in ipairs(typeDef.jobs) do
        if j == job then return true end
    end
    return false
end

local function BroadcastToEligible(alertType, event, payload)
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if CanSeeAlert(src, alertType) then
            TriggerClientEvent(event, src, payload)
        end
    end
end

local function AlertToTable(alert)
    return {
        id         = alert.id,
        type       = alert.type,
        priority   = alert.priority,
        title      = alert.title,
        message    = alert.message,
        coords     = alert.coords,
        street     = alert.street,
        callerName = alert.callerName,
        units      = alert.units,
        createdAt  = alert.createdAt,
        expires    = alert.expires,
        closed     = alert.closed or false,
        icon       = alert.icon or (Config.AlertTypes[alert.type] and Config.AlertTypes[alert.type].icon) or 'hgi-stroke hgi-radio-02',
        color      = Config.AlertTypes[alert.type] and Config.AlertTypes[alert.type].color or '#38bdf8',
        template   = alert.template,
    }
end

-- ── Lejárt riasztások tisztítása ────────────────────────────
CreateThread(function()
    while true do
        Wait(30000)
        if Config.AlertExpiry > 0 then
            local now = os.time()
            for id, alert in pairs(activeAlerts) do
                if not alert.closed and alert.expiresAt and now >= alert.expiresAt then
                    alert.closed = true
                    BroadcastToEligible(alert.type, 'fvg-dispatch:client:AlertClosed', { id = id })
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('CreateAlert', function(data)
    -- data = { type, priority, title, message, coords, callerSrc?, callerName?, icon?, template? }
    if not data or not data.type or not data.coords then return nil end
    if not Config.AlertTypes[data.type] then return nil end

    -- Max riasztás ellenőrzés
    local count = 0
    for _, a in pairs(activeAlerts) do if not a.closed then count = count + 1 end end
    if count >= Config.MaxActiveAlerts then return nil end

    local id   = GenAlertId()
    local prio = math.max(1, math.min(4, tonumber(data.priority) or 2))

    -- Caller neve
    local callerName = data.callerName or 'Ismeretlen'
    if data.callerSrc then
        local identity = exports['fvg-identity']:GetPlayerIdentity(data.callerSrc)
        if identity then
            callerName = identity.firstname .. ' ' .. identity.lastname
        else
            callerName = GetPlayerName(data.callerSrc) or 'Ismeretlen'
        end
    end

    -- Template felülírás
    local icon = data.icon
    if data.template and Config.Templates[data.template] then
        local tpl = Config.Templates[data.template]
        if not icon               then icon       = tpl.icon     end
        if data.title    == nil   then data.title = tpl.title    end
        if data.priority == nil   then prio       = tpl.priority end
    end

    local alert = {
        id         = id,
        type       = data.type,
        priority   = prio,
        title      = data.title   or 'Riasztás',
        message    = data.message or '',
        coords     = data.coords,
        street     = data.street  or '',
        callerName = callerName,
        callerSrc  = data.callerSrc,
        icon       = icon or (Config.AlertTypes[data.type].icon),
        units      = {},
        createdAt  = GetTimestamp(),
        expiresAt  = Config.AlertExpiry > 0 and (os.time() + Config.AlertExpiry) or nil,
        closed     = false,
        template   = data.template,
    }

    activeAlerts[id] = alert

    -- Broadcast
    BroadcastToEligible(data.type, 'fvg-dispatch:client:NewAlert', AlertToTable(alert))

    -- Esemény kiváltás
    TriggerEvent('fvg-dispatch:server:AlertCreated', id, AlertToTable(alert))

    return id
end)

exports('GetActiveAlerts', function(src)
    local result = {}
    local s = tonumber(src)
    for id, alert in pairs(activeAlerts) do
        if not alert.closed then
            if CanSeeAlert(s, alert.type) then
                table.insert(result, AlertToTable(alert))
            end
        end
    end
    -- Rendezés: priority desc
    table.sort(result, function(a, b) return a.priority > b.priority end)
    return result
end)

exports('CloseAlert', function(alertId, closedBy)
    if not activeAlerts[alertId] then return false end
    activeAlerts[alertId].closed   = true
    activeAlerts[alertId].closedBy = closedBy or 'System'
    activeAlerts[alertId].closedAt = GetTimestamp()

    local alert = activeAlerts[alertId]
    BroadcastToEligible(alert.type, 'fvg-dispatch:client:AlertClosed', {
        id       = alertId,
        closedBy = closedBy,
    })
    TriggerEvent('fvg-dispatch:server:AlertClosed', alertId)
    return true
end)

exports('AttachUnit', function(alertId, src)
    if not activeAlerts[alertId] then return false end
    local s      = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(s)
    if not player then return false end

    local identity = exports['fvg-identity']:GetPlayerIdentity(s)
    local unitName = identity
        and (identity.firstname .. ' ' .. identity.lastname)
        or GetPlayerName(s)

    -- Duplikáció ellenőrzés
    for _, u in ipairs(activeAlerts[alertId].units) do
        if u.src == s then return false end
    end

    -- JAVÍTÁS: player.job → player.metadata.job
    table.insert(activeAlerts[alertId].units, {
        src  = s,
        name = unitName,
        job  = player.metadata and player.metadata.job or 'unknown',
    })

    local alert = activeAlerts[alertId]
    BroadcastToEligible(alert.type, 'fvg-dispatch:client:AlertUpdated', AlertToTable(alert))
    TriggerEvent('fvg-dispatch:server:UnitAttached', alertId, s)
    return true
end)

exports('DetachUnit', function(alertId, src)
    if not activeAlerts[alertId] then return false end
    local s = tonumber(src)

    local units = activeAlerts[alertId].units
    for i = #units, 1, -1 do
        if units[i].src == s then table.remove(units, i) end
    end

    local alert = activeAlerts[alertId]
    BroadcastToEligible(alert.type, 'fvg-dispatch:client:AlertUpdated', AlertToTable(alert))
    TriggerEvent('fvg-dispatch:server:UnitDetached', alertId, s)
    return true
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Dispatch panel megnyitás kérés
RegisterNetEvent('fvg-dispatch:server:RequestOpen', function()
    local src     = source
    local job     = GetJobOf(src)
    local allowed = false
    for _, j in ipairs(Config.DispatchJobs) do
        if j == job then allowed = true; break end
    end
    if not allowed then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type = 'error', message = 'Nincs jogosultságod a dispatch panelhez.'
        })
        return
    end

    local alerts = exports['fvg-dispatch']:GetActiveAlerts(src)
    TriggerClientEvent('fvg-dispatch:client:OpenPanel', src, {
        alerts     = alerts,
        alertTypes = Config.AlertTypes,
        priorities = Config.Priorities,
        templates  = Config.Templates,
    })
end)

-- Riasztás létrehozás kliienstől (pl. kézi hívás)
RegisterNetEvent('fvg-dispatch:server:CreateAlert', function(data)
    local src      = source
    data.callerSrc = src

    -- Koordináta keresés, ha nincs megadva
    if not data.coords then
        TriggerClientEvent('fvg-dispatch:client:GetCoordsAndCreate', src, data)
        return
    end

    local id = exports['fvg-dispatch']:CreateAlert(data)
    if id then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type = 'success', message = 'Riasztás elküldve [' .. id .. ']'
        })
    end
end)

-- Koordináta visszaküldés (kliens visszaküldi)
RegisterNetEvent('fvg-dispatch:server:CreateAlertWithCoords', function(data, coords, street)
    local src      = source
    data.callerSrc = src
    data.coords    = coords
    data.street    = street or ''

    local id = exports['fvg-dispatch']:CreateAlert(data)
    if id then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type = 'success', message = 'Riasztás elküldve [' .. id .. ']'
        })
    end
end)

-- Riasztás lezárás kliienstől
RegisterNetEvent('fvg-dispatch:server:CloseAlert', function(alertId)
    local src = source
    local job = GetJobOf(src)
    local ok  = false
    for _, j in ipairs(Config.DispatchJobs) do
        if j == job then ok = true; break end
    end
    if not ok then return end
    exports['fvg-dispatch']:CloseAlert(alertId, GetPlayerName(src))
end)

-- Egység csatlakozás riasztáshoz
RegisterNetEvent('fvg-dispatch:server:AttachUnit', function(alertId)
    local src = source
    local ok  = exports['fvg-dispatch']:AttachUnit(alertId, src)
    if ok then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type = 'info', message = 'Csatlakozva a riasztáshoz: ' .. alertId
        })
    end
end)

-- Egység lecsatolás
RegisterNetEvent('fvg-dispatch:server:DetachUnit', function(alertId)
    local src = source
    exports['fvg-dispatch']:DetachUnit(alertId, src)
end)

-- Pánikgomb
RegisterNetEvent('fvg-dispatch:server:PanicButton', function()
    local src = source
    TriggerClientEvent('fvg-dispatch:client:GetCoordsAndCreate', src, {
        type      = 'police',
        priority  = 4,
        template  = 'panic_button',
        callerSrc = src,
    })
end)

-- Integrált riasztás más scriptektől
AddEventHandler('fvg-dispatch:server:Alert', function(data)
    exports['fvg-dispatch']:CreateAlert(data)
end)

-- fvg-idcard körözés figyelés
AddEventHandler('fvg-idcard:server:WantedChanged', function(src, level, reason)
    if level >= 2 then
        TriggerClientEvent('fvg-dispatch:client:GetCoordsAndCreate', src, {
            type      = 'police',
            priority  = math.min(level, 4),
            template  = 'wanted',
            message   = reason or ('Körözési szint: ' .. level),
            callerSrc = src,
        })
    end
end)
