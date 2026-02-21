-- ╔══════════════════════════════════════════════╗
-- ║         fvg-respawn :: client                ║
-- ╚══════════════════════════════════════════════╝

local isDead          = false
local selfRespawnTimer= 0
local deathTime       = 0
local nuiOpen         = false

-- ── Halál detektálás ─────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(500)

        -- Csak betöltött karakternél figyelünk
        if not exports['fvg-playercore']:IsLoaded() then goto continue end

        local ped    = PlayerPedId()
        local health = GetEntityHealth(ped)

        -- GTA: 0 = halott, <100 = sebesült
        if not isDead and (health <= 0 or IsEntityDead(ped)) then
            isDead    = true
            deathTime = GetGameTimer()

            -- Natív respawn és wasted képernyő blokkolása
            SetMaxWantedLevel(0)
            NetworkSetRichPresence('dead')

            -- Koordináta mentés + szerver értesítés
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('fvg-respawn:server:PlayerDied', {
                x = coords.x, y = coords.y, z = coords.z
            })

            -- NUI halál képernyő megjelenítés
            _ShowDeathScreen()

            TriggerEvent('fvg-respawn:client:PlayerDied')
        end

        -- Halott állapotban: folyamatosan blokkoljuk a natív respawnt
        if isDead then
            -- Megakadályozzuk hogy a GTA automatikusan respawnoljon
            if IsEntityDead(ped) then
                NetworkResurrectLocalPlayer(
                    GetEntityCoords(ped), 0.0, false, false
                )
                SetEntityHealth(ped, 1)   -- minimálisan életben tartjuk
                TaskPlayAnim(ped, 'dead', 'dead_a', 1.0, 1.0, -1, 1, 0, false, false, false)
            end

            -- Önrespawn számláló
            if Config.AllowSelfRespawn then
                local elapsed = (GetGameTimer() - deathTime) / 1000
                selfRespawnTimer = math.floor(elapsed)

                if elapsed >= Config.SelfRespawnDelay then
                    -- Értesítés a NUI-nak hogy engedélyezett az önrespawn
                    SendNUIMessage({
                        action      = 'selfRespawnAvailable',
                        timeElapsed = math.floor(elapsed),
                        maxTime     = Config.InjuredTimeout,
                    })
                end

                -- Timeout: automatikus respawn
                if elapsed >= Config.InjuredTimeout then
                    TriggerServerEvent('fvg-respawn:server:RequestRespawn')
                end
            end
        end

        ::continue::
    end
end)

-- ── NUI Halál képernyő megjelenítés ──────────────────────────
function _ShowDeathScreen()
    nuiOpen = true
    SetNuiFocus(false, false)   -- nem blokkoljuk a játékot
    SendNUIMessage({
        action      = 'showDeath',
        selfRespawn = Config.AllowSelfRespawn,
        delay       = Config.SelfRespawnDelay,
        timeout     = Config.InjuredTimeout,
    })
end

-- ── Önrespawn gomb (NUI) ──────────────────────────────────────
RegisterNUICallback('selfRespawn', function(_, cb)
    if not isDead then cb('not_dead'); return end
    local elapsed = (GetGameTimer() - deathTime) / 1000
    if elapsed < Config.SelfRespawnDelay then
        cb('too_early'); return
    end
    TriggerServerEvent('fvg-respawn:server:RequestRespawn')
    cb('ok')
end)

-- ── Respawn végrehajtás (szervertől jön) ─────────────────────
RegisterNetEvent('fvg-respawn:client:DoRespawn', function(data)
    isDead         = false
    selfRespawnTimer = 0
    nuiOpen        = false

    -- NUI bezárás
    SendNUIMessage({ action = 'hideDeath' })
    SetNuiFocus(false, false)

    -- Fade out
    DoScreenFadeOut(Config.FadeOutTime)
    Wait(Config.FadeOutTime + 100)

    local ped = PlayerPedId()

    -- ── KARAKTER MODELL VISSZAÁLLÍTÁS ─────────────────────────
    -- Ez a kulcs: a szerver elküldi a mentett modellt, nem a defaultot
    if Config.PreserveModel and data.model then
        local modelHash = GetHashKey(data.model)
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(50)
            timeout = timeout + 50
        end
        if HasModelLoaded(modelHash) then
            SetPlayerModel(PlayerId(), modelHash)
            SetModelAsNoLongerNeeded(modelHash)
            ped = PlayerPedId()   -- új ped a modellváltás után
        end
    end

    -- ── Spawn koordináták ─────────────────────────────────────
    local spawn = data.spawn
    local isRevive = data.isRevive or false

    if spawn then
        -- Kórház / revive helyszín
        NetworkResurrectLocalPlayer(
            spawn.x or spawn.coords and spawn.coords.x or 0,
            spawn.y or spawn.coords and spawn.coords.y or 0,
            spawn.z or spawn.coords and spawn.coords.z or 0,
            spawn.heading or 0.0,
            true, false
        )
        SetEntityCoords(ped,
            spawn.x or 0,
            spawn.y or 0,
            spawn.z or 0,
            false, false, false, false
        )
        SetEntityHeading(ped, spawn.heading or 0.0)
    else
        -- Helyszíni revive – nem teleportálunk
        NetworkResurrectLocalPlayer(
            GetEntityCoords(ped), 0.0, true, false
        )
    end

    -- ── HP / Armour ───────────────────────────────────────────
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, data.health or Config.RespawnHealth)
    SetPedArmour(ped, data.armour or 0)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_UNARMED'), 1, false, true)
    RemoveAllPedWeapons(ped, true)

    -- Wanted szint visszaállítás
    SetMaxWantedLevel(5)
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)

    Wait(300)
    DoScreenFadeIn(Config.FadeInTime)

    TriggerEvent('fvg-respawn:client:PlayerRespawned', isRevive)
end)

-- ── Exportok ─────────────────────────────────────────────────
exports('IsDead', function()
    return isDead
end)

exports('GetDeathTime', function()
    if not isDead then return nil end
    return deathTime
end)

exports('ForceRespawn', function()
    if not isDead then return false end
    TriggerServerEvent('fvg-respawn:server:RequestRespawn')
    return true
end)

-- ── Karakter model mentés betöltéskor ────────────────────────
-- Ha más script (pl. karakterváltó) megváltoztatja a modellt,
-- ezt kell hívni hogy a respawn rendszer is tudjon róla
AddEventHandler('fvg-playercore:client:PlayerLoaded', function(data)
    local model = data.model or 'mp_m_freemode_01'
    TriggerServerEvent('fvg-respawn:server:UpdateModel', model)
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    isDead = false
    if nuiOpen then
        SendNUIMessage({ action = 'hideDeath' })
        SetNuiFocus(false, false)
    end
end)
