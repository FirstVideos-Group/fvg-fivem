-- ╔══════════════════════════════════════════════╗
-- ║         fvg-shops :: server                  ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    exports['fvg-database']:RegisterMigration('fvg_shop_stock', [[
        CREATE TABLE IF NOT EXISTS `fvg_shop_stock` (
            `id`         INT         NOT NULL AUTO_INCREMENT,
            `shop_id`    VARCHAR(50) NOT NULL,
            `item`       VARCHAR(50) NOT NULL,
            `stock`      INT         NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
                                               ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_shop_item` (`shop_id`, `item`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_shop_transactions', [[
        CREATE TABLE IF NOT EXISTS `fvg_shop_transactions` (
            `id`          INT         NOT NULL AUTO_INCREMENT,
            `player_id`   INT         NOT NULL,
            `shop_id`     VARCHAR(50) NOT NULL,
            `item`        VARCHAR(50) NOT NULL,
            `quantity`    SMALLINT    NOT NULL DEFAULT 1,
            `price_each`  INT         NOT NULL,
            `total_price` INT         NOT NULL,
            `payment`     ENUM('cash','bank') NOT NULL DEFAULT 'cash',
            `created_at`  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_player`  (`player_id`),
            KEY `idx_shop`    (`shop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ───────────────────────────────────────────────────
-- shopId → { itemName → stock }
local stockCache    = {}
-- id → shopConfig
local shopRegistry  = {}

-- ── Segédfüggvények ───────────────────────────────────────────
local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type = ntype or 'info', title = title, message = msg
    })
end

local function GetItemDef(itemName)
    for _, item in ipairs(Config.Items) do
        if item.item == itemName then return item end
    end
    return nil
end

local function GetShopDef(shopId)
    return shopRegistry[shopId]
end

-- ── Készlet inicializálás ────────────────────────────────────
local function InitStock(shop)
    if not Config.UseStock then return end
    stockCache[shop.id] = stockCache[shop.id] or {}

    for _, cat in ipairs(shop.categories) do
        for _, item in ipairs(Config.Items) do
            if item.category == cat and item.stock ~= nil then
                local row = exports['fvg-database']:QuerySingle(
                    'SELECT `stock` FROM `fvg_shop_stock` WHERE `shop_id`=? AND `item`=?',
                    { shop.id, item.item }
                )
                if row then
                    stockCache[shop.id][item.item] = row.stock
                else
                    stockCache[shop.id][item.item] = item.stock
                    exports['fvg-database']:Insert(
                        'INSERT INTO `fvg_shop_stock` (`shop_id`,`item`,`stock`) VALUES (?,?,?)',
                        { shop.id, item.item, item.stock }
                    )
                end
            end
        end
    end
end

-- ── Shop regisztráció ───────────────────────────────────────────
local function RegisterShopInternal(shop)
    shopRegistry[shop.id] = shop
    InitStock(shop)
end

CreateThread(function()
    Wait(300)
    for _, shop in ipairs(Config.Shops) do
        RegisterShopInternal(shop)
    end
    print('[fvg-shops] ' .. #Config.Shops .. ' bolt betöltve.')
end)

-- ── Készlet regenerálás ───────────────────────────────────────────
CreateThread(function()
    if not Config.UseStock then return end
    while true do
        Wait(Config.StockRegenTime * 1000)
        for shopId, items in pairs(stockCache) do
            local shop = GetShopDef(shopId)
            if shop then
                for itemName, currentStock in pairs(items) do
                    local itemDef = GetItemDef(itemName)
                    if itemDef and itemDef.stock ~= nil then
                        local newStock = math.min(currentStock + Config.StockRegenAmount, itemDef.stock)
                        if newStock ~= currentStock then
                            stockCache[shopId][itemName] = newStock
                            exports['fvg-database']:Execute(
                                'UPDATE `fvg_shop_stock` SET `stock`=? WHERE `shop_id`=? AND `item`=?',
                                { newStock, shopId, itemName }
                            )
                        end
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetShopById', function(shopId)
    return GetShopDef(shopId)
end)

exports('GetAllShops', function()
    local result = {}
    for _, shop in pairs(shopRegistry) do
        table.insert(result, shop)
    end
    return result
end)

exports('RegisterShop', function(shopDef)
    if not shopDef or not shopDef.id then return false end
    RegisterShopInternal(shopDef)
    TriggerClientEvent('fvg-shops:client:RegisterShop', -1, shopDef)
    return true
end)

exports('GetItemStock', function(shopId, itemName)
    if not Config.UseStock then return 999 end
    local s = stockCache[shopId]
    if not s then return 0 end
    if s[itemName] == nil then return 999 end
    return s[itemName]
end)

exports('SetItemStock', function(shopId, itemName, amount)
    if not stockCache[shopId] then stockCache[shopId] = {} end
    stockCache[shopId][itemName] = math.max(0, tonumber(amount) or 0)
    exports['fvg-database']:Execute(
        'INSERT INTO `fvg_shop_stock` (`shop_id`,`item`,`stock`) VALUES (?,?,?) ON DUPLICATE KEY UPDATE `stock`=VALUES(`stock`)',
        { shopId, itemName, stockCache[shopId][itemName] }
    )
    TriggerEvent('fvg-shops:server:StockUpdated', shopId, itemName, stockCache[shopId][itemName])
    return true
end)

exports('AddShopItem', function(shopId, itemDef)
    if not itemDef or not itemDef.item then return false end
    table.insert(Config.Items, itemDef)
    TriggerEvent('fvg-shops:server:ItemAdded', shopId, itemDef)
    return true
end)

exports('RemoveShopItem', function(shopId, itemName)
    for i, item in ipairs(Config.Items) do
        if item.item == itemName then
            table.remove(Config.Items, i)
            TriggerEvent('fvg-shops:server:ItemRemoved', shopId, itemName)
            return true
        end
    end
    return false
end)

exports('ProcessPurchase', function(src, shopId, itemName, quantity, paymentMethod)
    TriggerEvent('fvg-shops:server:Buy', src, shopId, itemName, quantity, paymentMethod)
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Bolt megnyitás kérés
RegisterNetEvent('fvg-shops:server:RequestShop', function(shopId)
    local src  = source
    local shop = GetShopDef(shopId)
    if not shop then return end

    -- JAVÍTÁS: player.job → player.metadata.job
    if shop.requiredJob then
        local player = exports['fvg-playercore']:GetPlayer(src)
        if not player or (player.metadata and player.metadata.job or nil) ~= shop.requiredJob then
            Notify(src, 'Ehhez a bolthoz szükséges: ' .. shop.requiredJob, 'error')
            return
        end
    end

    if shop.requiredLicense then
        local hasLicense = exports['fvg-idcard']:HasLicense(src, shop.requiredLicense)
        if not hasLicense then
            Notify(src, 'Ehhez a bolthoz szükséges: ' .. shop.requiredLicense .. ' engedély.', 'error')
            return
        end
    end

    local items = {}
    for _, item in ipairs(Config.Items) do
        for _, cat in ipairs(shop.categories) do
            if item.category == cat then
                local show = true
                if item.requiredLicense then
                    show = exports['fvg-idcard']:HasLicense(src, item.requiredLicense)
                end
                if show then
                    local stockVal = exports['fvg-shops']:GetItemStock(shopId, item.item)
                    table.insert(items, {
                        item           = item.item,
                        label          = item.label,
                        price          = item.price,
                        category       = item.category,
                        stock          = stockVal,
                        maxPerPurchase = item.maxPerPurchase,
                        icon           = item.icon,
                        description    = item.description,
                    })
                end
                break
            end
        end
    end

    local bankBal = 0
    local cashBal = 0
    if shop.paymentMethod ~= 'cash' then
        bankBal = exports['fvg-banking']:GetBalance(src, 'checking')
    end
    -- JAVÍTÁS: player.cash → player.metadata.cash
    local player = exports['fvg-playercore']:GetPlayer(src)
    if player then cashBal = (player.metadata and player.metadata.cash or 0) end

    TriggerClientEvent('fvg-shops:client:OpenShop', src, {
        shopId        = shopId,
        shopLabel     = shop.label,
        shopType      = shop.type,
        items         = items,
        categories    = Config.Categories,
        paymentMethod = shop.paymentMethod or Config.DefaultPaymentMethod,
        bankBalance   = bankBal,
        cashBalance   = cashBal,
    })
end)

-- Vásárlás (external hook - üres, csak placeholder)
AddEventHandler('fvg-shops:server:Buy', function(srcOverride, shopIdOvr, itemOvr, qtyOvr, pmOvr)
    local isExternal = srcOverride ~= nil
end)

RegisterNetEvent('fvg-shops:server:Buy', function(shopId, itemName, quantity, paymentMethod)
    local src = source
    TriggerEvent('fvg-shops:server:Buy', src, shopId, itemName, quantity, paymentMethod)
end)

AddEventHandler('fvg-shops:server:Buy', function(src, shopId, itemName, quantity, paymentMethod)
    if type(src) ~= 'number' then return end

    local shop    = GetShopDef(shopId)
    local itemDef = GetItemDef(itemName)

    if not shop or not itemDef then
        Notify(src, 'Érvénytelen termék vagy bolt.', 'error'); return
    end

    quantity = math.floor(tonumber(quantity) or 1)
    if quantity < 1 then return end
    if quantity > (itemDef.maxPerPurchase or 99) then
        Notify(src, 'Maximum ' .. itemDef.maxPerPurchase .. ' db vásárolható egyszerre.', 'warning'); return
    end

    if Config.UseStock and itemDef.stock ~= nil then
        local currentStock = exports['fvg-shops']:GetItemStock(shopId, itemName)
        if currentStock < quantity then
            Notify(src, 'Nincs elegendő készlet. Elérhető: ' .. currentStock .. ' db.', 'error'); return
        end
    end

    local totalPrice  = itemDef.price * quantity
    paymentMethod     = paymentMethod or shop.paymentMethod or Config.DefaultPaymentMethod

    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player then return end

    -- JAVÍTÁS: player.cash → player.metadata.cash
    local playerCash = player.metadata and player.metadata.cash or 0

    if paymentMethod == 'both' and playerCash < totalPrice then
        paymentMethod = 'bank'
    end

    local paid = false
    if paymentMethod == 'cash' then
        if playerCash < totalPrice then
            Notify(src, 'Nincs elég készpénzed. Szükséges: $' .. totalPrice, 'error'); return
        end
        exports['fvg-playercore']:RemoveCash(src, totalPrice)
        exports['fvg-banking']:CreateTransaction(src, 'payment', -totalPrice,
            itemDef.label .. ' x' .. quantity .. ' – ' .. shop.label)
        paid = true
    elseif paymentMethod == 'bank' then
        local ok = exports['fvg-banking']:RemoveBalance(src, totalPrice, 'checking',
            itemDef.label .. ' x' .. quantity .. ' – ' .. shop.label, 'payment')
        if not ok then
            Notify(src, 'Nincs elég bankegyenleg. Szükséges: $' .. totalPrice, 'error'); return
        end
        paid = true
    end

    if not paid then return end

    for i = 1, quantity do
        exports['fvg-inventory']:AddItem(src, itemName, 1)
    end

    if Config.UseStock and itemDef.stock ~= nil then
        local newStock = exports['fvg-shops']:GetItemStock(shopId, itemName) - quantity
        exports['fvg-shops']:SetItemStock(shopId, itemName, newStock)
        TriggerClientEvent('fvg-shops:client:StockUpdate', src, shopId, itemName, newStock)
    end

    local playerId = player.id or 0
    exports['fvg-database']:Insert(
        [[INSERT INTO `fvg_shop_transactions`
          (`player_id`,`shop_id`,`item`,`quantity`,`price_each`,`total_price`,`payment`)
          VALUES (?,?,?,?,?,?,?)]],
        { playerId, shopId, itemName, quantity, itemDef.price, totalPrice, paymentMethod }
    )

    TriggerClientEvent('fvg-shops:client:PurchaseSuccess', src, {
        item      = itemName,
        label     = itemDef.label,
        quantity  = quantity,
        total     = totalPrice,
        payment   = paymentMethod,
    })

    TriggerEvent('fvg-shops:server:ItemPurchased', src, shopId, itemName, quantity, totalPrice, paymentMethod)
end)

-- Készlet lekérés (NUI-nak)
RegisterNetEvent('fvg-shops:server:GetStock', function(shopId)
    local src   = source
    local stock = {}
    local s     = stockCache[shopId]
    if s then
        for item, amount in pairs(s) do
            stock[item] = amount
        end
    end
    TriggerClientEvent('fvg-shops:client:StockSync', src, shopId, stock)
end)
