-- ╔══════════════════════════════════════════════╗
-- ║        fvg-inventory :: server               ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    -- Játékos inventory tábla
    exports['fvg-database']:RegisterMigration('fvg_inventory', [[
        CREATE TABLE IF NOT EXISTS `fvg_inventory` (
            `id`         INT          NOT NULL AUTO_INCREMENT,
            `player_id`  INT          NOT NULL,
            `item`       VARCHAR(64)  NOT NULL,
            `amount`     INT          NOT NULL DEFAULT 1,
            `slot`       TINYINT      NOT NULL DEFAULT 0,
            `metadata`   LONGTEXT              DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_player` (`player_id`),
            KEY `idx_item`   (`item`),
            CONSTRAINT `fk_inv_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Stash tábla
    exports['fvg-database']:RegisterMigration('fvg_stashes', [[
        CREATE TABLE IF NOT EXISTS `fvg_stashes` (
            `id`         INT          NOT NULL AUTO_INCREMENT,
            `stash_id`   VARCHAR(100) NOT NULL,
            `stash_type` VARCHAR(20)  NOT NULL DEFAULT 'shared',
            `item`       VARCHAR(64)  NOT NULL,
            `amount`     INT          NOT NULL DEFAULT 1,
            `slot`       TINYINT      NOT NULL DEFAULT 0,
            `metadata`   LONGTEXT              DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_stash` (`stash_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Drop tábla
    exports['fvg-database']:RegisterMigration('fvg_drops', [[
        CREATE TABLE IF NOT EXISTS `fvg_drops` (
            `id`         INT          NOT NULL AUTO_INCREMENT,
            `drop_id`    VARCHAR(40)  NOT NULL,
            `item`       VARCHAR(64)  NOT NULL,
            `amount`     INT          NOT NULL DEFAULT 1,
            `metadata`   LONGTEXT              DEFAULT NULL,
            `x`          FLOAT        NOT NULL,
            `y`          FLOAT        NOT NULL,
            `z`          FLOAT        NOT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` TIMESTAMP    NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL 300 SECOND),
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_drop_id` (`drop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Szerver cache ─────────────────────────────────────────────
-- [src] = { [slot] = { item, amount, metadata } }
local inventories = {}

-- Aktív dropok: { [dropId] = { item, amount, metadata, x, y, z, expires } }
local drops = {}

-- ── Segédfüggvények ───────────────────────────────────────────

local function GetItemDef(itemName)
    return Config.Items[itemName]
end

local function CalcWeight(inv)
    local total = 0.0
    for _, slot in pairs(inv) do
        local def = GetItemDef(slot.item)
        if def then total = total + (def.weight * slot.amount) end
    end
    return total
end

local function InvToArray(inv)
    local arr = {}
    for slot, data in pairs(inv) do
        table.insert(arr, {
            slot     = slot,
            item     = data.item,
            amount   = data.amount,
            metadata = data.metadata or {},
            label    = (GetItemDef(data.item) or {}).label or data.item,
            weight   = (GetItemDef(data.item) or {}).weight or 0,
            category = (GetItemDef(data.item) or {}).category or 'misc',
            image    = (GetItemDef(data.item) or {}).image or 'default.png',
            usable   = (GetItemDef(data.item) or {}).usable or false,
            stackable= (GetItemDef(data.item) or {}).stackable or false,
        })
    end
    return arr
end

local function FindFreeSlot(inv)
    for i = 1, Config.MaxSlots do
        if not inv[i] then return i end
    end
    return nil
end

local function FindItemSlot(inv, itemName)
    for slot, data in pairs(inv) do
        if data.item == itemName then
            local def = GetItemDef(itemName)
            if def and def.stackable then return slot end
        end
    end
    return nil
end

local function Notify(src, msg, ntype)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        message = msg
    })
end

local function SyncInventory(src)
    if not inventories[src] then return end
    TriggerClientEvent('fvg-inventory:client:SyncInventory', src, {
        slots    = InvToArray(inventories[src]),
        weight   = CalcWeight(inventories[src]),
        maxWeight= Config.MaxWeight,
        maxSlots = Config.MaxSlots,
    })
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local rows = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_inventory` WHERE `player_id` = ? ORDER BY `slot` ASC',
        { player.id }
    )
    inventories[src] = {}
    if rows then
        for _, row in ipairs(rows) do
            local meta = {}
            if row.metadata then
                local ok, decoded = pcall(json.decode, row.metadata)
                meta = ok and decoded or {}
            end
            inventories[src][row.slot] = {
                item     = row.item,
                amount   = row.amount,
                metadata = meta,
            }
        end
    end
    SyncInventory(src)
end)

-- ── Mentés ────────────────────────────────────────────────────
local function SaveInventory(src)
    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player or not inventories[src] then return end

    exports['fvg-database']:Execute(
        'DELETE FROM `fvg_inventory` WHERE `player_id` = ?',
        { player.id }
    )

    for slot, data in pairs(inventories[src]) do
        exports['fvg-database']:Insert(
            'INSERT INTO `fvg_inventory` (`player_id`,`item`,`amount`,`slot`,`metadata`) VALUES (?,?,?,?,?)',
            { player.id, data.item, data.amount, slot, json.encode(data.metadata or {}) }
        )
    end
end

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    SaveInventory(src)
    inventories[src] = nil
end)

-- ═════════════════════════════════════════════════════════════
--  SZERVER EXPORT LOGIKA
-- ═════════════════════════════════════════════════════════════

local function ServerAddItem(src, itemName, amount, metadata, slot)
    local def = GetItemDef(itemName)
    if not def then return false, 'Ismeretlen item: ' .. tostring(itemName) end
    if not inventories[src] then return false, 'Nincs inventory' end

    amount = tonumber(amount) or 1
    if amount <= 0 then return false, 'Érvénytelen mennyiség' end

    -- Súly ellenőrzés
    local currentWeight = CalcWeight(inventories[src])
    local addWeight     = def.weight * amount
    if currentWeight + addWeight > Config.MaxWeight then
        return false, 'Túl nehéz!'
    end

    -- Stack keresés (ha stackable)
    if def.stackable then
        local existSlot = FindItemSlot(inventories[src], itemName)
        if existSlot then
            inventories[src][existSlot].amount = inventories[src][existSlot].amount + amount
            SyncInventory(src)
            return true
        end
    end

    -- Szabad slot keresés
    local targetSlot = slot or FindFreeSlot(inventories[src])
    if not targetSlot then return false, 'Tele az inventory!' end

    inventories[src][targetSlot] = {
        item     = itemName,
        amount   = amount,
        metadata = metadata or {},
    }
    SyncInventory(src)
    return true
end

local function ServerRemoveItem(src, itemName, amount)
    if not inventories[src] then return false, 'Nincs inventory' end
    amount = tonumber(amount) or 1

    local totalHas = 0
    for _, data in pairs(inventories[src]) do
        if data.item == itemName then totalHas = totalHas + data.amount end
    end
    if totalHas < amount then return false, 'Nincs elég item' end

    local toRemove = amount
    for slot, data in pairs(inventories[src]) do
        if data.item == itemName and toRemove > 0 then
            if data.amount <= toRemove then
                toRemove = toRemove - data.amount
                inventories[src][slot] = nil
            else
                inventories[src][slot].amount = data.amount - toRemove
                toRemove = 0
            end
        end
    end

    SyncInventory(src)
    return true
end

local function ServerGetItemCount(src, itemName)
    if not inventories[src] then return 0 end
    local count = 0
    for _, data in pairs(inventories[src]) do
        if data.item == itemName then count = count + data.amount end
    end
    return count
end

local function ServerHasItem(src, itemName, amount)
    return ServerGetItemCount(src, itemName) >= (tonumber(amount) or 1)
end

-- ═════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═════════════════════════════════════════════════════════════

exports('GetInventory', function(src)
    if not inventories[tonumber(src)] then return {} end
    return InvToArray(inventories[tonumber(src)])
end)

exports('GetItemCount', function(src, itemName)
    return ServerGetItemCount(tonumber(src), itemName)
end)

exports('AddItem', function(src, itemName, amount, metadata, slot)
    return ServerAddItem(tonumber(src), itemName, amount, metadata, slot)
end)

exports('RemoveItem', function(src, itemName, amount)
    return ServerRemoveItem(tonumber(src), itemName, amount)
end)

exports('HasItem', function(src, itemName, amount)
    return ServerHasItem(tonumber(src), itemName, amount)
end)

exports('ClearInventory', function(src)
    local s = tonumber(src)
    if inventories[s] then
        inventories[s] = {}
        SyncInventory(s)
    end
end)

-- ── Stash exportok ────────────────────────────────────────────

exports('GetStash', function(stashId)
    local rows = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_stashes` WHERE `stash_id` = ? ORDER BY `slot` ASC',
        { stashId }
    )
    local stash = {}
    if rows then
        for _, row in ipairs(rows) do
            local meta = {}
            if row.metadata then
                local ok, d = pcall(json.decode, row.metadata)
                meta = ok and d or {}
            end
            stash[row.slot] = { item = row.item, amount = row.amount, metadata = meta }
        end
    end
    return stash
end)

exports('AddToStash', function(stashId, itemName, amount, metadata)
    local def = GetItemDef(itemName)
    if not def then return false end
    local stash = exports['fvg-inventory']:GetStash(stashId)
    local cfg   = Config.StashTypes.shared

    -- Stack keresés
    if def.stackable then
        for slot, data in pairs(stash) do
            if data.item == itemName then
                exports['fvg-database']:Execute(
                    'UPDATE `fvg_stashes` SET `amount`=? WHERE `stash_id`=? AND `slot`=?',
                    { data.amount + (tonumber(amount) or 1), stashId, slot }
                )
                return true
            end
        end
    end

    -- Szabad slot
    local freeSlot = 1
    while stash[freeSlot] do freeSlot = freeSlot + 1 end
    if freeSlot > cfg.slots then return false end

    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_stashes` (`stash_id`,`stash_type`,`item`,`amount`,`slot`,`metadata`) VALUES (?,?,?,?,?,?)',
        { stashId, 'shared', itemName, tonumber(amount) or 1, freeSlot, json.encode(metadata or {}) }
    )
    return true
end)

exports('RemoveFromStash', function(stashId, itemName, amount)
    local stash    = exports['fvg-inventory']:GetStash(stashId)
    local toRemove = tonumber(amount) or 1
    for slot, data in pairs(stash) do
        if data.item == itemName and toRemove > 0 then
            if data.amount <= toRemove then
                toRemove = toRemove - data.amount
                exports['fvg-database']:Execute(
                    'DELETE FROM `fvg_stashes` WHERE `stash_id`=? AND `slot`=?',
                    { stashId, slot }
                )
            else
                exports['fvg-database']:Execute(
                    'UPDATE `fvg_stashes` SET `amount`=? WHERE `stash_id`=? AND `slot`=?',
                    { data.amount - toRemove, stashId, slot }
                )
                toRemove = 0
            end
        end
    end
    return toRemove == 0
end)

-- ═════════════════════════════════════════════════════════════
--  NET EVENTS – NUI CALLBACK-EK KISZOLGÁLÁSA
-- ═════════════════════════════════════════════════════════════

-- Inventory megnyitás kérés
RegisterNetEvent('fvg-inventory:server:RequestOpen', function()
    local src = source
    if not inventories[src] then return end
    SyncInventory(src)
    TriggerClientEvent('fvg-inventory:client:OpenInventory', src, {
        slots    = InvToArray(inventories[src]),
        weight   = CalcWeight(inventories[src]),
        maxWeight= Config.MaxWeight,
        maxSlots = Config.MaxSlots,
        categories = Config.Categories,
    })
end)

-- Item use
RegisterNetEvent('fvg-inventory:server:UseItem', function(slot)
    local src  = source
    local inv  = inventories[src]
    if not inv or not inv[slot] then return end

    local itemName = inv[slot].item
    local def      = GetItemDef(itemName)
    if not def or not def.usable then return end

    -- Use callback keresés
    local cb = Config.UseCallbacks[itemName]
    if cb then
        cb(src, slot, inv[slot])
        return
    end

    -- Beépített use logikák
    if def.category == 'food' then
        if itemName == 'bread' or itemName == 'sandwich' then
            if Config.UseNeeds then exports['fvg-needs']:AddNeed(src, 'food', 25) end
        elseif itemName == 'water' or itemName == 'coffee' then
            if Config.UseNeeds then exports['fvg-needs']:AddNeed(src, 'water', 30) end
        end
        ServerRemoveItem(src, itemName, 1)
        if Config.NotifyOnUse then Notify(src, def.label .. ' elfogyasztva.', 'success') end

    elseif itemName == 'bandage' then
        TriggerClientEvent('fvg-inventory:client:UseHeal', src, 25)
        ServerRemoveItem(src, itemName, 1)
        if Config.NotifyOnUse then Notify(src, 'Kötszer felrakva.', 'success') end

    elseif itemName == 'medkit' then
        TriggerClientEvent('fvg-inventory:client:UseHeal', src, 100)
        ServerRemoveItem(src, itemName, 1)
        if Config.NotifyOnUse then Notify(src, 'Elsősegélycsomag felhasználva.', 'success') end

    elseif itemName == 'painkillers' then
        if Config.UseStress then exports['fvg-stress']:RemoveStress(src, 20) end
        ServerRemoveItem(src, itemName, 1)
        if Config.NotifyOnUse then Notify(src, 'Fájdalomcsillapító bevéve.', 'success') end

    elseif def.category == 'weapon' then
        TriggerClientEvent('fvg-inventory:client:EquipWeapon', src, itemName, inv[slot].metadata or {})

    else
        -- Generikus use – más script reagálhat
        TriggerEvent('fvg-inventory:server:ItemUsed', src, itemName, inv[slot].metadata or {})
        if Config.NotifyOnUse then Notify(src, def.label .. ' használva.', 'info') end
    end
end)

-- Item drop
RegisterNetEvent('fvg-inventory:server:DropItem', function(slot, amount)
    local src = source
    local inv = inventories[src]
    if not inv or not inv[slot] then return end

    local itemName = inv[slot].item
    local def      = GetItemDef(itemName)
    if not def then return end

    amount = math.min(tonumber(amount) or 1, inv[slot].amount)

    -- Koordináta lekérés
    TriggerClientEvent('fvg-inventory:client:GetDropCoords', src, slot, amount)
end)

RegisterNetEvent('fvg-inventory:server:ConfirmDrop', function(slot, amount, coords)
    local src = source
    local inv = inventories[src]
    if not inv or not inv[slot] then return end

    local itemName = inv[slot].item
    local ok, err  = ServerRemoveItem(src, itemName, amount)
    if not ok then Notify(src, err, 'error') return end

    -- Drop ID generálás
    local dropId = string.format('drop_%d_%d', GetGameTimer(), src)

    drops[dropId] = {
        item     = itemName,
        amount   = amount,
        metadata = (inv[slot] and inv[slot].metadata) or {},
        x        = coords.x, y = coords.y, z = coords.z,
        expires  = GetGameTimer() + Config.DropTimeout * 1000,
    }

    -- DB mentés
    exports['fvg-database']:Insert(
        'INSERT INTO `fvg_drops` (`drop_id`,`item`,`amount`,`metadata`,`x`,`y`,`z`) VALUES (?,?,?,?,?,?,?)',
        { dropId, itemName, amount, json.encode({}), coords.x, coords.y, coords.z }
    )

    -- Mindenki kliensnek elküldjük a drop adatot
    TriggerClientEvent('fvg-inventory:client:AddDrop', -1, dropId, drops[dropId])
    if Config.NotifyOnDrop then
        Notify(src, (GetItemDef(itemName) or {}).label .. ' eldobva.', 'warning')
    end
end)

-- Item felvétel (drop)
RegisterNetEvent('fvg-inventory:server:PickupDrop', function(dropId)
    local src = source
    if not drops[dropId] then return end

    local drop  = drops[dropId]
    local ok, err = ServerAddItem(src, drop.item, drop.amount, drop.metadata)
    if not ok then Notify(src, err, 'error') return end

    -- Drop törlés
    drops[dropId] = nil
    exports['fvg-database']:Execute('DELETE FROM `fvg_drops` WHERE `drop_id`=?', { dropId })
    TriggerClientEvent('fvg-inventory:client:RemoveDrop', -1, dropId)

    local def = GetItemDef(drop.item)
    if Config.NotifyOnPickup then
        Notify(src, (def and def.label or drop.item) .. ' felvéve (x' .. drop.amount .. ')', 'success')
    end
end)

-- Slot mozgatás (drag & drop)
RegisterNetEvent('fvg-inventory:server:MoveSlot', function(fromSlot, toSlot)
    local src = source
    local inv = inventories[src]
    if not inv then return end

    fromSlot = tonumber(fromSlot)
    toSlot   = tonumber(toSlot)
    if not fromSlot or not toSlot or fromSlot == toSlot then return end
    if not inv[fromSlot] then return end

    local fromData = inv[fromSlot]
    local toData   = inv[toSlot]

    -- Ha a célban ugyanolyan stackable item van
    if toData and toData.item == fromData.item then
        local def = GetItemDef(fromData.item)
        if def and def.stackable then
            inv[toSlot].amount = inv[toSlot].amount + fromData.amount
            inv[fromSlot]      = nil
            SyncInventory(src)
            return
        end
    end

    -- Csere
    inv[fromSlot] = toData
    inv[toSlot]   = fromData
    SyncInventory(src)
end)

-- Drop timeout tisztítás
CreateThread(function()
    while true do
        Wait(30000)
        local now = GetGameTimer()
        for dropId, drop in pairs(drops) do
            if drop.expires and now > drop.expires then
                drops[dropId] = nil
                exports['fvg-database']:Execute(
                    'DELETE FROM `fvg_drops` WHERE `drop_id`=?', { dropId }
                )
                TriggerClientEvent('fvg-inventory:client:RemoveDrop', -1, dropId)
            end
        end
    end
end)

-- ── Use callback regisztráció (más scripteknek) ───────────────
-- pl. exports['fvg-inventory']:RegisterUseCallback('item_name', function(src, slot, data) end)
RegisterNetEvent('fvg-inventory:server:RegisterUse', function() end)

-- Belső API függvény – más Lua scriptek hívhatják
function RegisterUseCallback(itemName, callback)
    Config.UseCallbacks[itemName] = callback
end