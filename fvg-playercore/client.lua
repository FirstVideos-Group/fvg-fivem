-- ╔══════════════════════════════════════════════╗
-- ║       fvg-playercore :: client               ║
-- ╚══════════════════════════════════════════════╝

local _playerData = nil
local _isLoaded   = false

-- ── Exportok ─────────────────────────────────────────────────

-- Helyi játékos adatainak lekérdezése
exports('GetLocalPlayerData', function(key)
    if not _playerData then return nil end
    if key then return _playerData[key] end
    return _playerData
end)

-- Be van-e töltve a karakter
exports('IsLoaded', function()
    return _isLoaded
end)

-- ── Spawn indítása ────────────────────────────────────────────

-- Jelezzük a szervernek hogy készen állunk
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Kis várakozás hogy a szerver oldal is inicializálódjon
    Citizen.SetTimeout(1000, function()
        TriggerServerEvent('fvg-playercore:server:RequestSpawn')
    end)
end)

-- ── Szerver küldi a betöltési adatokat ───────────────────────
RegisterNetEvent('fvg-playercore:client:OnPlayerLoaded', function(data)
    _playerData = data

    -- ── 1. Ped modell betöltése ────────────────────────────
    local model = GetHashKey(data.model or Config.DefaultModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(50)
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    -- ── 2. Spawn koordináták beállítása ────────────────────
    local pos = data.spawnPos or Config.DefaultSpawn
    local ped = PlayerPedId()

    -- Fade out → teleport → fade in
    DoScreenFadeOut(500)
    Citizen.Wait(600)

    SetEntityCoords(ped,
        pos.x, pos.y, pos.z,
        false, false, false, false
    )
    SetEntityHeading(ped, pos.heading or 0.0)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, pos.heading or 0.0, true, false)

    -- Fegyver és HP reset
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, 200)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_UNARMED'), 1, false, true)

    Citizen.Wait(500)
    DoScreenFadeIn(800)

    -- ── 3. Betöltött állapot jelzése ────────────────────────
    _isLoaded = true

    -- Szerver értesítése
    TriggerServerEvent('fvg-playercore:server:PlayerReady')

    -- Helyi esemény – más fvg- scriptek figyelhetik
    TriggerEvent('fvg-playercore:client:PlayerLoaded', _playerData)
end)

-- ── Adat szinkronizálás a szerverről ─────────────────────────
RegisterNetEvent('fvg-playercore:client:SyncData', function(key, value)
    if not _playerData then return end
    if not _playerData.metadata then _playerData.metadata = {} end
    _playerData.metadata[key] = value
    -- Helyi esemény: más scriptek reagálhatnak
    TriggerEvent('fvg-playercore:client:DataUpdated', key, value)
end)

-- ── Pozíció mentés periodikusan ──────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)   -- 30 másodpercenként
        if _isLoaded then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local hdg = GetEntityHeading(ped)
            TriggerServerEvent('fvg-playercore:server:SavePosition', {
                x       = pos.x,
                y       = pos.y,
                z       = pos.z,
                heading = hdg
            })
        end
    end
end)

-- ── Cleanup resource leálláskor ───────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    _playerData = nil
    _isLoaded   = false
end)