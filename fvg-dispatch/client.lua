-- ╔══════════════════════════════════════════════╗
-- ║         fvg-dispatch :: client               ║
-- ╚══════════════════════════════════════════════╝

local localAlerts   = {}
local activeBlips   = {}   -- [alertId] = blipHandle
local menuOpen      = false

-- Az egység jelenleg melyik riasztáshoz csatlakozva (src-oldalon tárolt)
-- A HUD-ot ez vezérli
local myActiveAlert = nil   -- alert táblázat vagy nil

-- ── HUD szinkron ─────────────────────────────────────────────
local function SyncDispatchHud(alert)
    -- Elküldi a fvg-hud-nak az aktív riasztás adatait
    -- Ha alert == nil, elrejti a widgetet
    SendNUIMessage({
        action = 'dispatchAlert',
        alert  = alert,  -- nil = rejtés
    })
end

-- ── Kliens exportok ───────────────────────────────────────────

exports('OpenDispatch', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-dispatch:server:RequestOpen')
end)

exports('GetLocalAlerts', function()
    return localAlerts
end)

exports('GetMyActiveAlert', function()
    return myActiveAlert
end)

-- ── Panel megnyitás ──────────────────────────────────────────
RegisterNetEvent('fvg-dispatch:client:OpenPanel', function(data)
    localAlerts = {}
    for _, a in ipairs(data.alerts or {}) do
        localAlerts[a.id] = a
    end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'open',
        alerts     = data.alerts,
        alertTypes = data.alertTypes,
        priorities = data.priorities,
        templates  = data.templates,
    })
end)

-- ── Új riasztás fogadás ───────────────────────────────────────
RegisterNetEvent('fvg-dispatch:client:NewAlert', function(alert)
    localAlerts[alert.id] = alert

    -- Hang
    if Config.EnableSound then
        PlaySoundFrontend(-1, Config.SoundName, Config.SoundRef, true)
    end

    -- Blip
    CreateAlertBlip(alert)

    -- Értesítés
    exports['fvg-notify']:Notify({
        type     = 'warning',
        title    = '[' .. alert.id .. '] ' .. alert.title,
        message  = alert.message,
        duration = 8000,
        icon     = alert.icon,
    })

    -- Ha a panel nyitva van, frissítjük
    if menuOpen then
        SendNUIMessage({ action = 'addAlert', alert = alert })
    end

    TriggerEvent('fvg-dispatch:client:AlertReceived', alert)
end)

-- ── Riasztás frissítés ────────────────────────────────────────
RegisterNetEvent('fvg-dispatch:client:AlertUpdated', function(alert)
    localAlerts[alert.id] = alert

    -- Ha a saját aktív riasztásunk frissült, szinkronizáljuk a HUD-ot
    if myActiveAlert and myActiveAlert.id == alert.id then
        myActiveAlert = alert
        SyncDispatchHud(alert)
    end

    if menuOpen then
        SendNUIMessage({ action = 'updateAlert', alert = alert })
    end
end)

-- ── Riasztás lezárás ─────────────────────────────────────────
RegisterNetEvent('fvg-dispatch:client:AlertClosed', function(data)
    if localAlerts[data.id] then
        localAlerts[data.id].closed = true
    end
    RemoveAlertBlip(data.id)

    -- Ha a saját aktív riasztásunkat zárták le → HUD elrejtés
    if myActiveAlert and myActiveAlert.id == data.id then
        myActiveAlert = nil
        SyncDispatchHud(nil)
        exports['fvg-notify']:Notify({
            type    = 'info',
            title   = 'Riasztás lezárva',
            message = 'A(z) [' .. data.id .. '] riasztás lezárásra került.',
            duration = 5000,
        })
    end

    if menuOpen then
        SendNUIMessage({ action = 'closeAlert', id = data.id })
    end
end)

-- ── Saját csatlakozás / lecsatolás HUD szinkron (szerver küldi) ──
RegisterNetEvent('fvg-dispatch:client:MyUnitAttached', function(alert)
    myActiveAlert = alert
    SyncDispatchHud(alert)
end)

RegisterNetEvent('fvg-dispatch:client:MyUnitDetached', function(alertId)
    if myActiveAlert and myActiveAlert.id == alertId then
        myActiveAlert = nil
        SyncDispatchHud(nil)
    end
end)

-- ── Koordináta visszaküldés ───────────────────────────────────
RegisterNetEvent('fvg-dispatch:client:GetCoordsAndCreate', function(alertData)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    if crossHash ~= 0 then
        streetName = streetName .. ' / ' .. GetStreetNameFromHashKey(crossHash)
    end

    TriggerServerEvent('fvg-dispatch:server:CreateAlertWithCoords',
        alertData,
        { x = coords.x, y = coords.y, z = coords.z },
        streetName
    )
end)

-- ── Blip kezelés ─────────────────────────────────────────────

function CreateAlertBlip(alert)
    if not alert.coords then return end
    RemoveAlertBlip(alert.id)

    local typeDef = Config.AlertTypes[alert.type] or Config.AlertTypes.all
    local blip    = AddBlipForCoord(alert.coords.x, alert.coords.y, alert.coords.z)

    SetBlipSprite(blip, typeDef.blip or 161)
    SetBlipColour(blip, typeDef.blipColor or 3)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('[' .. alert.id .. '] ' .. alert.title)
    EndTextCommandSetBlipName(blip)

    local prioData = Config.Priorities[alert.priority] or {}
    if prioData.pulse then
        ShowHeadingIndicatorOnBlip(blip, true)
    end

    activeBlips[alert.id] = blip

    if Config.BlipTimeout > 0 then
        SetTimeout(Config.BlipTimeout * 1000, function()
            RemoveAlertBlip(alert.id)
        end)
    end
end

function RemoveAlertBlip(alertId)
    if activeBlips[alertId] then
        RemoveBlip(activeBlips[alertId])
        activeBlips[alertId] = nil
    end
end

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('createAlert', function(data, cb)
    TriggerServerEvent('fvg-dispatch:server:CreateAlert', data)
    cb('ok')
end)

RegisterNUICallback('closeAlert', function(data, cb)
    TriggerServerEvent('fvg-dispatch:server:CloseAlert', data.id)
    cb('ok')
end)

RegisterNUICallback('attachUnit', function(data, cb)
    TriggerServerEvent('fvg-dispatch:server:AttachUnit', data.id)
    cb('ok')
end)

RegisterNUICallback('detachUnit', function(data, cb)
    TriggerServerEvent('fvg-dispatch:server:DetachUnit', data.id)
    cb('ok')
end)

RegisterNUICallback('waypointAlert', function(data, cb)
    if data.coords then
        SetNewWaypoint(data.coords.x, data.coords.y)
        exports['fvg-notify']:Notify({ type='info', message='Úticél beállítva.' })
    end
    cb('ok')
end)

-- ── Parancsok ─────────────────────────────────────────────────

RegisterCommand('dispatch', function()
    if menuOpen then return end
    exports['fvg-dispatch']:OpenDispatch()
end, false)

RegisterKeyMapping('dispatch', 'Dispatch panel megnyitása', 'keyboard', 'F6')

RegisterCommand(Config.PanicButtonCmd, function()
    TriggerServerEvent('fvg-dispatch:server:PanicButton')
    exports['fvg-notify']:Notify({
        type='error', message='Pánikgomb aktiválva! Segítség úton.'
    })
end, false)

RegisterKeyMapping(Config.PanicButtonCmd, 'Pánikgomb', 'keyboard', Config.PanicButtonKey)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for id, _ in pairs(activeBlips) do RemoveAlertBlip(id) end
    localAlerts   = {}
    menuOpen      = false
    myActiveAlert = nil
    SyncDispatchHud(nil)
end)
