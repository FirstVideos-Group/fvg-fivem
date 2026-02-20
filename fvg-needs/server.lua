-- ╔══════════════════════════════════════════════╗
-- ║         fvg-needs :: server                  ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció regisztrálása ────────────────────────────────────
CreateThread(function()
    Wait(200)
    exports['fvg-database']:RegisterMigration('fvg_needs', [[
        CREATE TABLE IF NOT EXISTS `fvg_needs` (
            `player_id`  INT           NOT NULL,
            `food`       DECIMAL(6,2)  NOT NULL DEFAULT 100.00,
            `water`      DECIMAL(6,2)  NOT NULL DEFAULT 100.00,
            `updated_at` TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_needs_player`
                FOREIGN KEY (`player_id`)
                REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Memória cache ─────────────────────────────────────────────
local playerNeeds = {}
-- [src] = { food = 100.0, water = 100.0 }

-- ── Segédfüggvény: érték clamp ────────────────────────────────
local function Clamp(val)
    return math.max(0.0, math.min(100.0, val))
end

-- ── Játékos betöltésekor szükségletek lekérdezése ────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT `food`, `water` FROM `fvg_needs` WHERE `player_id` = ?',
        { player.id }
    )

    if row then
        playerNeeds[src] = {
            food  = tonumber(row.food)  or 100.0,
            water = tonumber(row.water) or 100.0,
        }
    else
        -- Első belépés – alapértelmezett értékek
        playerNeeds[src] = { food = 100.0, water = 100.0 }
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_needs` (`player_id`, `food`, `water`) VALUES (?, ?, ?)',
            { player.id, 100.0, 100.0 }
        )
    end

    -- Kliens szinkronizálás
    TriggerClientEvent('fvg-needs:client:SetNeeds', src, playerNeeds[src])
end)

-- ── Kilépéskor mentés ─────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, player)
    local needs = playerNeeds[src]
    if not needs then return end

    exports['fvg-database']:Execute(
        'UPDATE `fvg_needs` SET `food` = ?, `water` = ? WHERE `player_id` = ?',
        { needs.food, needs.water, player.id }
    )

    playerNeeds[src] = nil
end)

-- ── Kliens szinkron fogadása ──────────────────────────────────
RegisterNetEvent('fvg-needs:server:Sync', function(food, water)
    local src = source
    if not playerNeeds[src] then return end
    playerNeeds[src].food  = Clamp(food)
    playerNeeds[src].water = Clamp(water)
end)

-- ── Szerver exportok ─────────────────────────────────────────

exports('GetPlayerNeeds', function(src)
    return playerNeeds[tonumber(src)]
end)

exports('SetPlayerNeed', function(src, need, value)
    local p = playerNeeds[tonumber(src)]
    if not p then return false end
    if p[need] == nil then return false end
    p[need] = Clamp(value)
    TriggerClientEvent('fvg-needs:client:SetNeeds', src, p)
    return true
end)

exports('ModifyPlayerNeed', function(src, need, amount)
    local p = playerNeeds[tonumber(src)]
    if not p then return false end
    if p[need] == nil then return false end
    p[need] = Clamp(p[need] + amount)
    TriggerClientEvent('fvg-needs:client:SetNeeds', src, p)
    return true
end)

-- ── Szerver oldali tömeg mentés (auto-save) ───────────────────
CreateThread(function()
    while true do
        Wait(300000)   -- 5 percenként
        local count = 0
        for src, needs in pairs(playerNeeds) do
            local player = exports['fvg-playercore']:GetPlayer(src)
            if player and player.loaded then
                exports['fvg-database']:Execute(
                    'UPDATE `fvg_needs` SET `food` = ?, `water` = ? WHERE `player_id` = ?',
                    { needs.food, needs.water, player.id }
                )
                count = count + 1
            end
        end
        if count > 0 then
            print(string.format('[fvg-needs] Auto-mentés: %d játékos.', count))
        end
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Mentés szerver leálláskor
    for src, needs in pairs(playerNeeds) do
        local player = exports['fvg-playercore']:GetPlayer(src)
        if player then
            exports['fvg-database']:Execute(
                'UPDATE `fvg_needs` SET `food` = ?, `water` = ? WHERE `player_id` = ?',
                { needs.food, needs.water, player.id }
            )
        end
    end
end)