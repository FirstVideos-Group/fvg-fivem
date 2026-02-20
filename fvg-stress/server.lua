-- ╔══════════════════════════════════════════════╗
-- ║         fvg-stress :: server                 ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)
    exports['fvg-database']:RegisterMigration('fvg_stress', [[
        CREATE TABLE IF NOT EXISTS `fvg_stress` (
            `player_id`  INT          NOT NULL,
            `stress`     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
            `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                               ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_stress_player`
                FOREIGN KEY (`player_id`)
                REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Memória cache ─────────────────────────────────────────────
local playerStress = {}
-- [src] = number (0–100)

local function Clamp(v)
    return math.max(0.0, math.min(100.0, v))
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT `stress` FROM `fvg_stress` WHERE `player_id` = ?',
        { player.id }
    )

    if row then
        playerStress[src] = Clamp(tonumber(row.stress) or 0.0)
    else
        playerStress[src] = 0.0
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_stress` (`player_id`, `stress`) VALUES (?, ?)',
            { player.id, 0.0 }
        )
    end

    TriggerClientEvent('fvg-stress:client:SetStress', src, playerStress[src])
end)

-- ── Kilépés + mentés ─────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, player)
    if not playerStress[src] then return end
    exports['fvg-database']:Execute(
        'UPDATE `fvg_stress` SET `stress` = ? WHERE `player_id` = ?',
        { playerStress[src], player.id }
    )
    playerStress[src] = nil
end)

-- ── Szinkron fogadása a klienstől ────────────────────────────
RegisterNetEvent('fvg-stress:server:Sync', function(value)
    local src = source
    if playerStress[src] == nil then return end
    playerStress[src] = Clamp(value)
end)

-- ── Szerver exportok ─────────────────────────────────────────

exports('GetPlayerStress', function(src)
    return playerStress[tonumber(src)]
end)

exports('SetPlayerStress', function(src, value)
    local s = tonumber(src)
    if playerStress[s] == nil then return false end
    playerStress[s] = Clamp(value)
    TriggerClientEvent('fvg-stress:client:SetStress', s, playerStress[s])
    return true
end)

exports('ModifyPlayerStress', function(src, amount)
    local s = tonumber(src)
    if playerStress[s] == nil then return false end
    playerStress[s] = Clamp(playerStress[s] + amount)
    TriggerClientEvent('fvg-stress:client:SetStress', s, playerStress[s])
    return true
end)

-- ── Auto-mentés ───────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(300000)
        local count = 0
        for src, stress in pairs(playerStress) do
            local player = exports['fvg-playercore']:GetPlayer(src)
            if player and player.loaded then
                exports['fvg-database']:Execute(
                    'UPDATE `fvg_stress` SET `stress` = ? WHERE `player_id` = ?',
                    { stress, player.id }
                )
                count = count + 1
            end
        end
        if count > 0 then
            print(string.format('[fvg-stress] Auto-mentés: %d játékos.', count))
        end
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src, stress in pairs(playerStress) do
        local player = exports['fvg-playercore']:GetPlayer(src)
        if player then
            exports['fvg-database']:Execute(
                'UPDATE `fvg_stress` SET `stress` = ? WHERE `player_id` = ?',
                { stress, player.id }
            )
        end
    end
end)