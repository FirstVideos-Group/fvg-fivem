-- ╔══════════════════════════════════════════════╗
-- ║          fvg-admin :: client                 ║
-- ╚══════════════════════════════════════════════╝

local menuOpen    = false
local noclipOn    = false
local spectateOn  = false
local spectateTarget = nil

-- ── Menü megnyitás ────────────────────────────────────────────
RegisterCommand('adminmenu', function()
    TriggerServerEvent('fvg-admin:server:OpenMenu')
end, false)

RegisterKeyMapping('adminmenu', 'Admin menü megnyitás', 'keyboard', 'F10')

-- ── Menü adatok fogadása ──────────────────────────────────────
RegisterNetEvent('fvg-admin:client:OpenMenu', function(data)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('fvg-admin:client:UpdatePlayers', function(playerList)
    SendNUIMessage({ action = 'updatePlayers', playerList = playerList })
end)

-- ── NUI Callback-ek ──────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:KickPlayer', tonumber(data.src), data.reason)
    cb('ok')
end)

RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:BanPlayer', tonumber(data.src), data.reason, tonumber(data.minutes))
    cb('ok')
end)

RegisterNUICallback('unbanPlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:UnbanPlayer', data.identifier)
    cb('ok')
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:RevivePlayer', tonumber(data.src))
    cb('ok')
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:FreezePlayer', tonumber(data.src), data.state == true or data.state == 'true')
    cb('ok')
end)

RegisterNUICallback('teleportTo', function(data, cb)
    TriggerServerEvent('fvg-admin:server:TeleportTo', tonumber(data.src))
    cb('ok')
end)

RegisterNUICallback('teleportToMe', function(data, cb)
    TriggerServerEvent('fvg-admin:server:TeleportToMe', tonumber(data.src))
    cb('ok')
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SpectatePlayer', tonumber(data.src))
    cb('ok')
end)

RegisterNUICallback('setGodmode', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetGodmode', tonumber(data.src), data.state == true or data.state == 'true')
    cb('ok')
end)

RegisterNUICallback('setNeeds', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetNeeds', tonumber(data.src), tonumber(data.food), tonumber(data.water))
    cb('ok')
end)

RegisterNUICallback('setStress', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetStress', tonumber(data.src), tonumber(data.stress))
    cb('ok')
end)

RegisterNUICallback('setPlayerInfo', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetPlayerInfo', tonumber(data.src), data)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SpawnVehicle', data.model)
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    TriggerServerEvent('fvg-admin:server:DeleteVehicle')
    cb('ok')
end)

RegisterNUICallback('fixVehicle', function(data, cb)
    TriggerServerEvent('fvg-admin:server:FixVehicle')
    cb('ok')
end)

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetWeather', data.weather)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetTime', tonumber(data.hour), tonumber(data.minute))
    cb('ok')
end)

RegisterNUICallback('announce', function(data, cb)
    TriggerServerEvent('fvg-admin:server:Announce', data.message)
    cb('ok')
end)

RegisterNUICallback('toggleNoclip', function(data, cb)
    TriggerServerEvent('fvg-admin:server:SetNoclip', data.state == true or data.state == 'true')
    cb('ok')
end)

RegisterNUICallback('getBanList', function(_, cb)
    TriggerServerEvent('fvg-admin:server:GetBanList')
    cb('ok')
end)

RegisterNUICallback('refreshPlayers', function(_, cb)
    TriggerServerEvent('fvg-admin:server:RefreshPlayers')
    cb('ok')
end)

-- ── Revive fogadása ───────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:Revive', function()
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(
        GetEntityCoords(ped), 0.0, true, false
    )
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
end)

-- ── Freeze fogadása ───────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:SetFreeze', function(state)
    FreezeEntityPosition(PlayerPedId(), state)
    exports['fvg-notify']:Notify({
        type    = state and 'warning' or 'info',
        message = state and 'Lefagyasztottak.' or 'Felengedtek.'
    })
end)

-- ── Teleport to player ────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:TeleportToPlayer', function(targetSrc)
    -- Kér a céltól koordinátát
    TriggerServerEvent('fvg-admin:server:GetCoords', targetSrc)
end)

RegisterNetEvent('fvg-admin:client:ReceiveCoords', function(coords, heading)
    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), heading)
    Wait(300)
    DoScreenFadeIn(500)
end)

-- Koordináta kérés kiszolgálása
RegisterNetEvent('fvg-admin:server:GetCoords', function(targetSrc)
    -- Ezt a szerver triggereli ide kliens oldalra a koordináta kérőnek
end)

AddEventHandler('fvg-admin:server:GetCoords', function(requesterSrc)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hdg    = GetEntityHeading(ped)
    TriggerServerEvent('fvg-admin:server:SendCoords', requesterSrc, { x = coords.x, y = coords.y, z = coords.z }, hdg)
end)

RegisterNetEvent('fvg-admin:server:SendCoords', function(requesterSrc, coords, heading)
    TriggerClientEvent('fvg-admin:client:ReceiveCoords', requesterSrc, coords, heading)
end)

-- ── Teleport to me fogadása ───────────────────────────────────
RegisterNetEvent('fvg-admin:client:TeleportToMe', function(adminSrc)
    -- Koordinátát kapjuk az admintól
    TriggerServerEvent('fvg-admin:server:GetAdminCoords', adminSrc)
end)

-- ── Godmode ───────────────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:SetGodmode', function(state)
    SetEntityInvincible(PlayerPedId(), state)
    exports['fvg-notify']:Notify({
        type    = state and 'success' or 'info',
        message = state and 'God mód bekapcsolva.' or 'God mód kikapcsolva.'
    })
end)

-- ── Jármű spawn ───────────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:SpawnVehicle', function(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(50) end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading= GetEntityHeading(ped)
    local veh    = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)

    SetPedIntoVehicle(ped, veh, -1)
    SetEntityAsNoLongerNeeded(veh)
    SetModelAsNoLongerNeeded(hash)

    exports['fvg-notify']:Notify({ type = 'success', message = 'Jármű spawolva: ' .. model })
end)

-- ── Jármű törlés ─────────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:DeleteVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) then
        veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end
    if DoesEntityExist(veh) then
        DeleteEntity(veh)
        exports['fvg-notify']:Notify({ type = 'success', message = 'Jármű törölve.' })
    end
end)

-- ── Jármű javítás ─────────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:FixVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(veh) then
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        exports['fvg-notify']:Notify({ type = 'success', message = 'Jármű megjavítva.' })
    end
end)

-- ── Időjárás szerver fogadás ──────────────────────────────────
RegisterNetEvent('fvg-admin:client:SetWeather', function(weather)
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end)

-- ── Idő fogadása ──────────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:SetTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

-- ── Ban lista fogadása ────────────────────────────────────────
RegisterNetEvent('fvg-admin:client:ReceiveBanList', function(bans)
    SendNUIMessage({ action = 'receiveBanList', bans = bans })
end)

-- ══════════════════════════════════════════════════════════════
--  NOCLIP
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-admin:client:SetNoclip', function(state)
    noclipOn = state
    if not state then
        SetEntityCollision(PlayerPedId(), true, true)
    end
    exports['fvg-notify']:Notify({
        type    = state and 'info' or 'warning',
        message = state and 'Noclip bekapcsolva.' or 'Noclip kikapcsolva.'
    })
end)

CreateThread(function()
    while true do
        Wait(0)
        if not noclipOn then goto continue end

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)

        SetEntityCollision(ped, false, false)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)

        local speed = IsControlPressed(0, 21) and Config.NoclipSpeedFast or Config.NoclipSpeed

        -- Irányok
        local fwd = GetEntityForwardVector(ped)
        local x, y, z = 0.0, 0.0, 0.0

        if IsControlPressed(0, 32) then x = fwd.x * speed y = fwd.y * speed end  -- W előre
        if IsControlPressed(0, 33) then x = -fwd.x * speed y = -fwd.y * speed end -- S hátra
        if IsControlPressed(0, 44) then z = -speed end  -- leszáll
        if IsControlPressed(0, 22) then z =  speed end  -- felszáll

        SetEntityVelocity(ped, x, y, z)

        ::continue::
    end
end)

-- ══════════════════════════════════════════════════════════════
--  SPECTATE
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-admin:client:StartSpectate', function(targetSrc)
    if spectateOn then
        -- Már spectate van, leállítás
        NetworkSetInSpectatorMode(false, PlayerPedId())
        spectateOn = false
        exports['fvg-notify']:Notify({ type = 'info', message = 'Spectate leállítva.' })
        return
    end
    spectateTarget = targetSrc
    spectateOn     = true
    -- A célpont PedId-jét a hálózaton kell megszerezni
    local netId  = GetPlayerServerId(GetPlayerFromServerId(targetSrc))
    local ped    = GetPlayerPed(GetPlayerFromServerId(targetSrc))
    NetworkSetInSpectatorMode(true, ped)
    exports['fvg-notify']:Notify({ type = 'info', message = 'Spectate elindítva. Nyomj F10-et a leállításhoz.' })
end)