-- ╔══════════════════════════════════════════════╗
-- ║         fvg-respawn :: server                ║
-- ╚══════════════════════════════════════════════╝

local deadPlayers = {}   -- [src] = { diedAt, model, coords }

-- ── Segédfüggvény ─────────────────────────────────────────────
local function Notify(src, msg, ntype)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        message = msg,
    })
end

-- ── Modell lekérés a playercore-ból ──────────────────────────
local function GetPlayerModel(src)
    -- fvg-playercore metadata-ban tároljuk a modellt
    local model = exports['fvg-playercore']:GetPlayerData(src, 'model')
    return model or Config.DefaultModel or 'mp_m_freemode_01'
end

-- ── Halál regisztrálás ────────────────────────────────────────
RegisterNetEvent('fvg-respawn:server:PlayerDied', function(coords)
    local src   = source
    local model = GetPlayerModel(src)

    deadPlayers[src] = {
        diedAt = os.time(),
        model  = model,
        coords = coords,
    }

    -- isDead flag mentése
    exports['fvg-playercore']:SetPlayerData(src, 'isDead', true)

    TriggerEvent('fvg-respawn:server:PlayerDied', src, coords)
    print(string.format('[fvg-respawn] Játékos meghalt: src=%d model=%s', src, tostring(model)))
end)

-- ── Respawn feldolgozás ───────────────────────────────────────
RegisterNetEvent('fvg-respawn:server:RequestRespawn', function()
    local src = source

    -- Kórházi számla levonás
    if Config.HospitalBill then
        local cash = exports['fvg-playercore']:GetPlayerData(src, 'cash') or 0
        if cash >= Config.HospitalBillAmount then
            exports['fvg-playercore']:SetPlayerData(src, 'cash', cash - Config.HospitalBillAmount)
            Notify(src, Config.Locale.bill_charged .. Config.HospitalBillAmount, 'warning')
        else
            -- Bankból vonjuk le ha van
            local bankOk = false
            if exports['fvg-banking'] then
                bankOk = exports['fvg-banking']:RemoveBalance(
                    src, Config.HospitalBillAmount, 'checking',
                    'Kórházi számla', 'fee'
                )
            end
            if not bankOk then
                Notify(src, Config.Locale.bill_no_money, 'error')
            else
                Notify(src, Config.Locale.bill_charged .. Config.HospitalBillAmount, 'warning')
            end
        end
    end

    -- Modell lekérés (amit halálakor eltároltunk)
    local dead  = deadPlayers[src]
    local model = (dead and dead.model) or GetPlayerModel(src)

    -- Spawn pont kiválasztás
    local spawnPoints = Config.RespawnPoints
    local spawn = spawnPoints[math.random(#spawnPoints)]

    -- isDead törlés
    exports['fvg-playercore']:SetPlayerData(src, 'isDead', false)
    deadPlayers[src] = nil

    -- Kliens respawn indítás
    TriggerClientEvent('fvg-respawn:client:DoRespawn', src, {
        model  = model,
        spawn  = spawn,
        health = Config.RespawnHealth,
        armour = Config.RespawnArmour,
    })

    TriggerEvent('fvg-respawn:server:PlayerRespawned', src, spawn)
    Notify(src, Config.Locale.respawned, 'success')
    print(string.format('[fvg-respawn] Respawn: src=%d → %s', src, spawn.label or '?'))
end)

-- ── Mentett model frissítés (karakterváltáskor más scriptektől) ─
RegisterNetEvent('fvg-respawn:server:UpdateModel', function(model)
    local src = source
    exports['fvg-playercore']:SetPlayerData(src, 'model', model)
end)

-- ── Revive (más játékos vagy admin) ──────────────────────────
RegisterNetEvent('fvg-respawn:server:Revive', function(targetSrc)
    local src    = source
    targetSrc    = tonumber(targetSrc)
    if not targetSrc then return end

    local dead  = deadPlayers[targetSrc]
    local model = (dead and dead.model) or GetPlayerModel(targetSrc)

    exports['fvg-playercore']:SetPlayerData(targetSrc, 'isDead', false)
    deadPlayers[targetSrc] = nil

    TriggerClientEvent('fvg-respawn:client:DoRespawn', targetSrc, {
        model  = model,
        spawn  = dead and dead.coords or nil,   -- helyszíni revive
        health = 100,
        armour = 0,
        isRevive = true,
    })

    TriggerEvent('fvg-respawn:server:PlayerRevived', src, targetSrc)
    Notify(targetSrc, Config.Locale.revived, 'success')
end)

-- ── Kilépéskor tisztítás ──────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    deadPlayers[src] = nil
end)

-- ══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ══════════════════════════════════════════════════════════════

exports('IsPlayerDead', function(src)
    return deadPlayers[tonumber(src)] ~= nil
end)

exports('GetDeadPlayers', function()
    local result = {}
    for s, data in pairs(deadPlayers) do
        table.insert(result, { src = s, diedAt = data.diedAt, coords = data.coords })
    end
    return result
end)

exports('RevivePlayer', function(src, targetSrc)
    TriggerEvent('fvg-respawn:server:Revive', targetSrc)
    return true
end)

exports('RespawnPlayer', function(targetSrc)
    TriggerEvent('fvg-respawn:server:RequestRespawn_internal', targetSrc)
    return true
end)

AddEventHandler('fvg-respawn:server:RequestRespawn_internal', function(targetSrc)
    local dead  = deadPlayers[targetSrc]
    local model = (dead and dead.model) or GetPlayerModel(targetSrc)
    local spawn = Config.RespawnPoints[math.random(#Config.RespawnPoints)]

    exports['fvg-playercore']:SetPlayerData(targetSrc, 'isDead', false)
    deadPlayers[targetSrc] = nil

    TriggerClientEvent('fvg-respawn:client:DoRespawn', targetSrc, {
        model  = model,
        spawn  = spawn,
        health = Config.RespawnHealth,
        armour = Config.RespawnArmour,
    })
end)
