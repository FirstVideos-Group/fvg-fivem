-- ╔══════════════════════════════════════════════╗
-- ║       fvg-unemployment :: client             ║
-- ╚══════════════════════════════════════════════╝

local _panelOpen = false

-- ── Panel megnyitás marker-nél ─────────────────────────────
CreateThread(function()
    local loc = Config.OfficeLocation
    if loc.blip then
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, loc.blipSprite)
        SetBlipColour(blip, loc.blipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(loc.blipLabel)
        EndTextCommandSetBlipName(blip)
    end

    while true do
        Wait(0)
        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local dist = #(pos - vector3(loc.coords.x, loc.coords.y, loc.coords.z))

        if loc.marker then
            DrawMarker(2,
                loc.coords.x, loc.coords.y, loc.coords.z - 0.9,
                0, 0, 0, 0, 0, 0,
                0.8, 0.8, 0.5,
                56, 189, 248, 120,
                false, false, 2, false, nil, nil, false
            )
        end

        if dist < 2.0 and not _panelOpen then
            DisplayHelpTextThisFrame('[~INPUT_CONTEXT~] Munkaügyi Hivatal')
            if IsControlJustPressed(0, 38) then -- E
                _panelOpen = true
                TriggerServerEvent('fvg-unemployment:server:RequestOpen')
            end
        end
    end
end)

-- ── Panel megnyitás szervértől ─────────────────────────────
RegisterNetEvent('fvg-unemployment:client:OpenPanel', function(data)
    SendNUIMessage({ action = 'open', payload = data })
    SetNuiFocus(true, true)
end)

-- ── Adat szinkronizálás ────────────────────────────────────
RegisterNetEvent('fvg-unemployment:client:SyncData', function(data)
    SendNUIMessage({ action = 'syncData', data = data })
end)

-- ── Munka leadás visszajelzés ──────────────────────────────
-- Szerver küldi ha sikeres a resign → UI frissítés + panel újratöltése
RegisterNetEvent('fvg-unemployment:client:ResignConfirmed', function(oldJob)
    SendNUIMessage({ action = 'resignConfirmed', oldJob = oldJob })
    -- Kis késleltetés után újra lekérjük az aktuális adatot a panelhez
    Wait(400)
    TriggerServerEvent('fvg-unemployment:server:RequestOpen')
end)

-- ── NUI callback-ek ───────────────────────────────────────
RegisterNUICallback('claimBenefit', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:ClaimBenefit')
    cb('ok')
end)

RegisterNUICallback('applyJob', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:ApplyForJob', data.jobId)
    cb('ok')
end)

RegisterNUICallback('resignJob', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:ResignJob')
    cb('ok')
end)

RegisterNUICallback('checkTask', function(data, cb)
    TriggerServerEvent('fvg-unemployment:server:CheckTask', data.taskId)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    _panelOpen = false
    cb('ok')
end)
