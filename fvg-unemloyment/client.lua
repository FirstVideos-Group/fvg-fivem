-- ╔══════════════════════════════════════════════╗
-- ║       fvg-unemployment :: client             ║
-- ╚══════════════════════════════════════════════╝

local localData     = {}
local menuOpen      = false
local officeBlip    = nil
local cooldownTimer = nil

-- inZone flag: csak egyszer küldjünk Notify-t belépéskor
local officeZone = false

-- ── Kliens exportok ───────────────────────────────────────────

exports('GetLocalUnemploymentData', function()
    return localData
end)

exports('IsLocalUnemployed', function()
    return localData.eligible == true
end)

-- ── Adatok szinkronizálása ────────────────────────────────────
RegisterNetEvent('fvg-unemployment:client:SyncData', function(data)
    localData = data or {}
    if menuOpen then
        SendNUIMessage({ action = 'syncData', data = localData })
    end
    TriggerEvent('fvg-unemployment:client:DataUpdated', localData)
end)

-- ── Panel megnyitás ──────────────────────────────────────────
RegisterNetEvent('fvg-unemployment:client:OpenPanel', function(payload)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = payload })
end)

-- ── Iroda blip ──────────────────────────────────────────────
CreateThread(function()
    if not Config.OfficeLocation.blip then return end
    officeBlip = AddBlipForCoord(
        Config.OfficeLocation.coords.x,
        Config.OfficeLocation.coords.y,
        Config.OfficeLocation.coords.z
    )
    SetBlipSprite(officeBlip, Config.OfficeLocation.blipSprite)
    SetBlipColour(officeBlip, Config.OfficeLocation.blipColor)
    SetBlipScale(officeBlip, 0.8)
    SetBlipAsShortRange(officeBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.OfficeLocation.blipLabel)
    EndTextCommandSetBlipName(officeBlip)
end)

-- ── Iroda marker és interakció ────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local office = Config.OfficeLocation.coords
        local dist   = #(coords - vector3(office.x, office.y, office.z))

        if dist < 30.0 then
            sleep = 0

            -- Marker
            if Config.OfficeLocation.marker then
                DrawMarker(1,
                    office.x, office.y, office.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.2, 1.2, 0.5,
                    56, 189, 248, 120,
                    false, true, 2, nil, nil, false
                )
            end

            if dist < 1.8 then
                -- Csak egyszer küldjük a hint-et belépéskor
                if not officeZone then
                    officeZone = true
                    exports['fvg-notify']:Notify({
                        type     = 'info',
                        message  = '[E] Munkaügyi Hivatal megnyitása',
                        duration = 3500,
                        static   = false,
                    })
                end

                if IsControlJustPressed(0, 38) then
                    if not menuOpen then
                        TriggerServerEvent('fvg-unemployment:server:RequestOpen')
                        TriggerServerEvent('fvg-unemployment:server:CheckTask', 'visit_office')
                    end
                end
            else
                officeZone = false
            end
        else
            officeZone = false
        end

        Wait(sleep)
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('claimBenefit', function(_, cb)
    TriggerServerEvent('fvg-unemployment:server:ClaimBenefit')
    cb('ok')
end)

RegisterNUICallback('applyJob', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:ApplyForJob', data.jobId)
    cb('ok')
end)

RegisterNUICallback('checkTask', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:CheckTask', data.taskId)
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        exports['fvg-notify']:Notify({ type='info', message='Úticél beállítva.' })
    end
    cb('ok')
end)

-- ── Parancs ───────────────────────────────────────────────────
RegisterCommand('munkaügy', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-unemployment:server:RequestOpen')
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    if officeBlip then RemoveBlip(officeBlip) end
    menuOpen    = false
    localData   = {}
    officeZone  = false
end)
