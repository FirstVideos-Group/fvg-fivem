-- ╔══════════════════════════════════════════════╗
-- ║          fvg-idcard :: client                ║
-- ╚══════════════════════════════════════════════╝

local localCard = { licenses = {}, wanted = { level = 0 } }
local menuOpen  = false

-- ── Kliens exportok ───────────────────────────────────────────

exports('GetLocalCard', function()
    return localCard
end)

exports('HasLocalLicense', function(licenseType)
    local lic = localCard.licenses[licenseType]
    if not lic then return false end
    if lic.suspended then return false end
    return true
end)

-- ── Szinkron fogadása ─────────────────────────────────────────
RegisterNetEvent('fvg-idcard:client:SyncCard', function(data)
    localCard.licenses = data.licenses or {}
    localCard.wanted   = data.wanted   or { level = 0 }
    TriggerEvent('fvg-idcard:client:CardUpdated', localCard)
end)

-- ── Igazolvány megnyitása ─────────────────────────────────────
RegisterNetEvent('fvg-idcard:client:OpenCard', function(payload)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openCard', payload = payload })
end)

-- ── Legközelebbi játékos keresés és felmutatás ────────────────
RegisterNetEvent('fvg-idcard:client:FindNearestAndShow', function(maxDist)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local nearest, nearestDist = nil, maxDist + 1

    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local targetPed  = GetPlayerPed(pid)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(coords - targetCoords)
            if dist < nearestDist then
                nearestDist = dist
                nearest     = pid
            end
        end
    end

    if nearest then
        local targetSrc = GetPlayerServerId(nearest)
        TriggerServerEvent('fvg-idcard:server:ShowCardTo', targetSrc)
        exports['fvg-notify']:Notify({ type = 'info', message = 'Igazolvány felmutatva.' })
    else
        exports['fvg-notify']:Notify({ type = 'warning', message = 'Nincs közelben senki.' })
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('showToNearest', function(_, cb)
    TriggerServerEvent('fvg-idcard:server:ShowToNearest')
    cb('ok')
end)

RegisterNUICallback('suspendLicense', function(data, cb)
    TriggerServerEvent('fvg-idcard:server:SuspendLicense',
        tonumber(data.targetSrc), data.licenseType, data.state == true or data.state == 'true')
    cb('ok')
end)

RegisterNUICallback('setWanted', function(data, cb)
    TriggerServerEvent('fvg-idcard:server:SetWantedFromClient',
        tonumber(data.targetSrc), tonumber(data.level), data.reason)
    cb('ok')
end)

-- ── Parancsok ────────────────────────────────────────────────

-- Saját igazolvány
RegisterCommand('idcard', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-idcard:server:OpenOwnCard')
end, false)

RegisterKeyMapping('idcard', 'Személyi igazolvány megnyitása', 'keyboard', 'F3')

-- Legközelebbi játékosnak mutatás
RegisterCommand('showid', function()
    TriggerServerEvent('fvg-idcard:server:ShowToNearest')
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    menuOpen  = false
    localCard = { licenses = {}, wanted = { level = 0 } }
end)