-- ╔══════════════════════════════════════════════╗
-- ║        fvg-autoshop :: server                ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    exports['fvg-database']:RegisterMigration('fvg_vehicles', [[
        CREATE TABLE IF NOT EXISTS `fvg_vehicles` (
            `id`           INT          NOT NULL AUTO_INCREMENT,
            `player_id`    INT          NOT NULL,
            `model`        VARCHAR(50)  NOT NULL,
            `label`        VARCHAR(80)  NOT NULL,
            `plate`        VARCHAR(12)  NOT NULL,
            `category`     VARCHAR(30)  NOT NULL DEFAULT 'sedan',
            `price`        INT          NOT NULL DEFAULT 0,
            `purchased_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `dealership_id`VARCHAR(50)            DEFAULT NULL,
            `status`       ENUM('garaged','out','impound','sold') NOT NULL DEFAULT 'garaged',
            `fuel`         TINYINT      NOT NULL DEFAULT 100,
            `mods`         JSON                   DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_plate`      (`plate`),
            KEY `idx_player`           (`player_id`),
            CONSTRAINT `fk_veh_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_vehicle_instalments', [[
        CREATE TABLE IF NOT EXISTS `fvg_vehicle_instalments` (
            `id`             INT        NOT NULL AUTO_INCREMENT,
            `vehicle_id`     INT        NOT NULL,
            `player_id`      INT        NOT NULL,
            `total_amount`   INT        NOT NULL,
            `paid_amount`    INT        NOT NULL DEFAULT 0,
            `monthly_amount` INT        NOT NULL,
            `months_total`   TINYINT    NOT NULL,
            `months_paid`    TINYINT    NOT NULL DEFAULT 0,
            `interest_rate`  FLOAT      NOT NULL DEFAULT 0.0,
            `next_due`       DATE       NOT NULL,
            `status`         ENUM('active','paid','defaulted') NOT NULL DEFAULT 'active',
            `created_at`     TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_vehicle` (`vehicle_id`),
            KEY `idx_player`  (`player_id`),
            CONSTRAINT `fk_inst_vehicle`
                FOREIGN KEY (`vehicle_id`) REFERENCES `fvg_vehicles`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ─────────────────────────────────────────────────────
-- [src] = { {id, model, label, plate, category, price, status, ...}, ... }
local playerVehicles = {}

-- ── Segédfüggvények ───────────────────────────────────────────
local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type = ntype or 'info', title = title, message = msg,
    })
end

local function GetVehicleDef(model)
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then return v end
    end
    return nil
end

local function GenPlate()
    local fmt    = Config.PlateFormat
    local chars  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result = ''
    for i = 1, #fmt do
        local c = fmt:sub(i, i)
        if c == 'A' or c == 'B' then
            result = result .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        elseif c == '#' then
            result = result .. tostring(math.random(0, 9))
        else
            result = result .. c
        end
    end
    -- Egyedi ellenőrzés
    local exists = exports['fvg-database']:QuerySingle(
        'SELECT `id` FROM `fvg_vehicles` WHERE `plate`=?', { result }
    )
    if exists then return GenPlate() end  -- rekurzív újragenerálás
    return result
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local rows = exports['fvg-database']:Query(
        [[SELECT v.*, vi.monthly_amount, vi.months_paid, vi.months_total,
                 vi.paid_amount, vi.total_amount, vi.status AS inst_status
          FROM `fvg_vehicles` v
          LEFT JOIN `fvg_vehicle_instalments` vi
              ON vi.vehicle_id = v.id AND vi.status = 'active'
          WHERE v.player_id = ? AND v.status != 'sold'
          ORDER BY v.purchased_at DESC]],
        { player.id }
    )
    playerVehicles[src] = rows or {}
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    playerVehicles[src] = nil
end)

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetOwnedVehicles', function(src)
    return playerVehicles[tonumber(src)] or {}
end)

exports('GetVehicleByPlate', function(plate)
    return exports['fvg-database']:QuerySingle(
        [[SELECT v.*, p.firstname, p.lastname
          FROM `fvg_vehicles` v
          LEFT JOIN `fvg_players` p ON p.id = v.player_id
          WHERE v.plate = ?]],
        { plate }
    )
end)

exports('IsVehicleOwned', function(plate)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT `id` FROM `fvg_vehicles` WHERE `plate`=? AND `status` != ?',
        { plate, 'sold' }
    )
    return row ~= nil
end)

exports('GetAllDealerships', function()
    return Config.Dealerships
end)

exports('BuyVehicle', function(src, model, dealershipId, paymentMethod, instalmentOption)
    src = tonumber(src)
    local vehicleDef = GetVehicleDef(model)
    if not vehicleDef then return false, 'invalid_vehicle' end

    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player then return false, 'player_not_found' end

    local dealer = nil
    for _, d in ipairs(Config.Dealerships) do
        if d.id == dealershipId then dealer = d; break end
    end
    if not dealer then return false, 'invalid_dealer' end

    -- Kereskedés hozzáférhető-e ehhez a modellhez?
    local available = false
    for _, dId in ipairs(vehicleDef.dealerships) do
        if dId == dealershipId then available = true; break end
    end
    if not available then return false, 'not_available_here' end

    -- Ár számítás (kedvezmény)
    local price = vehicleDef.price
    if dealer.discount then price = math.floor(price * dealer.discount) end

    -- Foglalási rendszám
    local plate = GenPlate()

    -- Részletfizetés
    if instalmentOption and Config.EnableInstalments then
        local opt = Config.InstalmentOptions[instalmentOption]
        if not opt then return false, 'invalid_instalment' end

        local downPayment = math.floor(price * Config.InstalmentDownPayment)
        if paymentMethod == 'bank' then
            local ok = exports['fvg-banking']:RemoveBalance(src, downPayment, 'checking',
                vehicleDef.label .. ' – foglalón (' .. opt.months .. ' hó)', 'payment')
            if not ok then return false, 'insufficient_funds' end
        else
            if (player.cash or 0) < downPayment then return false, 'insufficient_funds' end
            exports['fvg-playercore']:RemoveCash(src, downPayment)
            exports['fvg-banking']:CreateTransaction(src, 'payment', -downPayment,
                vehicleDef.label .. ' – foglalón')
        end

        local remaining     = price - downPayment
        local totalWithInt  = math.floor(remaining * (1 + opt.interestRate))
        local monthly       = math.ceil(totalWithInt / opt.months)

        local vehId = exports['fvg-database']:Insert(
            [[INSERT INTO `fvg_vehicles`
              (`player_id`,`model`,`label`,`plate`,`category`,`price`,`dealership_id`)
              VALUES (?,?,?,?,?,?,?)]],
            { player.id, model, vehicleDef.label, plate, vehicleDef.category, price, dealershipId }
        )

        exports['fvg-database']:Insert(
            [[INSERT INTO `fvg_vehicle_instalments`
              (`vehicle_id`,`player_id`,`total_amount`,`monthly_amount`,
               `months_total`,`interest_rate`,`next_due`)
              VALUES (?,?,?,?,?,?,DATE_ADD(CURDATE(), INTERVAL 30 DAY))]],
            { vehId, player.id, totalWithInt, monthly, opt.months, opt.interestRate }
        )

        -- Cache frissítés
        AddEventHandler('fvg-playercore:server:PlayerLoaded',
            function() end)  -- loader már fut, cache kézi frissítés:
        table.insert(playerVehicles[src] or {}, {
            id = vehId, model = model, label = vehicleDef.label,
            plate = plate, category = vehicleDef.category,
            price = price, status = 'garaged',
            monthly_amount = monthly, months_paid = 0,
            months_total = opt.months, inst_status = 'active',
        })

        TriggerEvent('fvg-autoshop:server:VehiclePurchased', src, model, plate, price, 'instalment')
        return true, { plate = plate, vehId = vehId, monthly = monthly, months = opt.months, downPayment = downPayment }
    end

    -- Teljes fizetés
    if paymentMethod == 'bank' then
        local ok = exports['fvg-banking']:RemoveBalance(src, price, 'checking',
            vehicleDef.label .. ' – vásárlás', 'payment')
        if not ok then return false, 'insufficient_funds' end
    else
        if (player.cash or 0) < price then return false, 'insufficient_funds' end
        exports['fvg-playercore']:RemoveCash(src, price)
        exports['fvg-banking']:CreateTransaction(src, 'payment', -price, vehicleDef.label .. ' – vásárlás')
    end

    local vehId = exports['fvg-database']:Insert(
        [[INSERT INTO `fvg_vehicles`
          (`player_id`,`model`,`label`,`plate`,`category`,`price`,`dealership_id`)
          VALUES (?,?,?,?,?,?,?)]],
        { player.id, model, vehicleDef.label, plate, vehicleDef.category, price, dealershipId }
    )

    if not playerVehicles[src] then playerVehicles[src] = {} end
    table.insert(playerVehicles[src], {
        id = vehId, model = model, label = vehicleDef.label,
        plate = plate, category = vehicleDef.category,
        price = price, status = 'garaged',
    })

    TriggerEvent('fvg-autoshop:server:VehiclePurchased', src, model, plate, price, paymentMethod)
    return true, { plate = plate, vehId = vehId }
end)

exports('SellVehicle', function(src, plate)
    src = tonumber(src)
    local vehicles = playerVehicles[src]
    if not vehicles then return false, 'not_found' end

    local veh = nil
    for _, v in ipairs(vehicles) do
        if v.plate == plate then veh = v; break end
    end
    if not veh then return false, 'not_owned' end
    if veh.status == 'out' then return false, 'vehicle_in_use' end
    if veh.inst_status == 'active' then return false, 'has_active_instalment' end

    local sellPrice = math.floor(veh.price * Config.SellBackPercent)
    exports['fvg-banking']:AddBalance(src, sellPrice, 'checking',
        veh.label .. ' – eladás', 'received')

    exports['fvg-database']:Execute(
        'UPDATE `fvg_vehicles` SET `status`=? WHERE `plate`=?',
        { 'sold', plate }
    )

    for i, v in ipairs(vehicles) do
        if v.plate == plate then
            table.remove(vehicles, i); break
        end
    end

    TriggerEvent('fvg-autoshop:server:VehicleSold', src, plate, sellPrice)
    return true, sellPrice
end)

exports('GetInstalments', function(src)
    src = tonumber(src)
    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player then return {} end
    return exports['fvg-database']:Query(
        [[SELECT vi.*, v.label, v.model, v.plate
          FROM `fvg_vehicle_instalments` vi
          JOIN `fvg_vehicles` v ON v.id = vi.vehicle_id
          WHERE vi.player_id = ? AND vi.status = 'active'
          ORDER BY vi.next_due ASC]],
        { player.id }
    ) or {}
end)

exports('PayInstalment', function(src, vehicleId, paymentMethod)
    src = tonumber(src)
    local rows = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_vehicle_instalments` WHERE `vehicle_id`=? AND `status`=?',
        { vehicleId, 'active' }
    )
    if not rows or #rows == 0 then return false, 'not_found' end
    local inst  = rows[1]
    local amount= inst.monthly_amount

    if paymentMethod == 'bank' then
        local ok = exports['fvg-banking']:RemoveBalance(src, amount, 'checking',
            'Részlet törlesztés – hó ' .. (inst.months_paid + 1) .. '/' .. inst.months_total, 'payment')
        if not ok then return false, 'insufficient_funds' end
    else
        local player = exports['fvg-playercore']:GetPlayer(src)
        if not player or (player.cash or 0) < amount then return false, 'insufficient_funds' end
        exports['fvg-playercore']:RemoveCash(src, amount)
        exports['fvg-banking']:CreateTransaction(src, 'payment', -amount, 'Részlet törlesztés')
    end

    local newPaid   = inst.months_paid + 1
    local newPaidAmt= inst.paid_amount + amount
    local done      = newPaid >= inst.months_total

    exports['fvg-database']:Execute(
        [[UPDATE `fvg_vehicle_instalments`
          SET `months_paid`=?, `paid_amount`=?, `status`=?,
              `next_due`=DATE_ADD(`next_due`, INTERVAL 30 DAY)
          WHERE `id`=?]],
        { newPaid, newPaidAmt, done and 'paid' or 'active', inst.id }
    )

    TriggerEvent('fvg-autoshop:server:InstalmentPaid', src, vehicleId, newPaid, inst.months_total, done)
    return true, { monthsPaid = newPaid, total = inst.months_total, done = done }
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Kereskedő megnyitás
RegisterNetEvent('fvg-autoshop:server:RequestDealership', function(dealershipId)
    local src    = source
    local dealer = nil
    for _, d in ipairs(Config.Dealerships) do
        if d.id == dealershipId then dealer = d; break end
    end
    if not dealer then return end

    -- Licensz ellenőrzés
    if Config.RequireDriverLicense then
        local licType = Config.LicenseTypes[dealer.type] or 'driving'
        if dealer.requiredLicense then licType = dealer.requiredLicense end
        local hasLic = exports['fvg-idcard']:HasLicense(src, licType)
        if not hasLic then
            Notify(src, 'Ehhez a kereskedőhöz szükséges: ' .. licType .. ' engedély.', 'error')
            return
        end
    end

    -- Járművek a kereskedőhöz
    local vehicles = {}
    for _, v in ipairs(Config.Vehicles) do
        for _, dId in ipairs(v.dealerships) do
            if dId == dealershipId then
                local price = v.price
                if dealer.discount then price = math.floor(price * dealer.discount) end
                table.insert(vehicles, {
                    model       = v.model,
                    label       = v.label,
                    price       = price,
                    origPrice   = v.price,
                    category    = v.category,
                    stats       = v.stats,
                    description = v.description,
                    licenseType = v.licenseType,
                })
                break
            end
        end
    end

    local player   = exports['fvg-playercore']:GetPlayer(src)
    local bankBal  = exports['fvg-banking']:GetBalance(src, 'checking')
    local cashBal  = player and player.cash or 0
    local ownedVehs= playerVehicles[src] or {}
    local instalments = exports['fvg-autoshop']:GetInstalments(src)

    TriggerClientEvent('fvg-autoshop:client:OpenDealership', src, {
        dealershipId   = dealershipId,
        dealerLabel    = dealer.label,
        dealerType     = dealer.type,
        vehicles       = vehicles,
        categories     = Config.Categories,
        bankBalance    = bankBal,
        cashBalance    = cashBal,
        ownedVehicles  = ownedVehs,
        instalments    = instalments,
        instalmentOptions= Config.InstalmentOptions,
        enableInstalments= Config.EnableInstalments,
        allowBank      = Config.AllowBankPayment,
        allowCash      = Config.AllowCashPayment,
        sellBackPct    = Config.SellBackPercent,
        downPaymentPct = Config.InstalmentDownPayment,
        discount       = dealer.discount or nil,
        spawnPoint     = dealer.spawnPoint,
        testDriveTime  = Config.TestDriveTime,
    })
end)

-- Vásárlás
RegisterNetEvent('fvg-autoshop:server:BuyVehicle', function(model, dealershipId, paymentMethod, instalmentOption)
    local src = source
    local ok, result = exports['fvg-autoshop']:BuyVehicle(src, model, dealershipId, paymentMethod, instalmentOption)
    if ok then
        local vehDef = GetVehicleDef(model)
        if instalmentOption then
            Notify(src, vehDef.label .. ' – foglalón fizetve! Havi: $' .. result.monthly .. ' × ' .. result.months, 'success', '🚗 Jármű megvéve')
        else
            Notify(src, vehDef.label .. ' – megvéve! Rendszám: ' .. result.plate, 'success', '🚗 Jármű megvéve')
        end
        TriggerClientEvent('fvg-autoshop:client:PurchaseSuccess', src, result)
    else
        local msgs = {
            insufficient_funds  = 'Nincs elég egyenleg.',
            invalid_vehicle     = 'Érvénytelen jármű.',
            invalid_dealer      = 'Érvénytelen kereskedő.',
            not_available_here  = 'Ez a jármű nem kapható ebben a szalonban.',
            invalid_instalment  = 'Érvénytelen részletfizetési opció.',
            player_not_found    = 'Játékos nem található.',
        }
        Notify(src, msgs[result] or 'Ismeretlen hiba.', 'error')
    end
end)

-- Eladás
RegisterNetEvent('fvg-autoshop:server:SellVehicle', function(plate)
    local src    = source
    local ok, result = exports['fvg-autoshop']:SellVehicle(src, plate)
    if ok then
        Notify(src, 'Jármű eladva: $' .. result .. ' jóváírva.', 'success')
        TriggerClientEvent('fvg-autoshop:client:SellSuccess', src, { plate = plate, amount = result })
    else
        local msgs = {
            not_found             = 'Jármű nem található.',
            not_owned             = 'Nem a te járműved.',
            vehicle_in_use        = 'A jármű jelenleg ki van véve.',
            has_active_instalment = 'Aktív részlet miatt nem adható el.',
        }
        Notify(src, msgs[result] or 'Hiba.', 'error')
    end
end)

-- Részlet törlesztés
RegisterNetEvent('fvg-autoshop:server:PayInstalment', function(vehicleId, paymentMethod)
    local src    = source
    local ok, result = exports['fvg-autoshop']:PayInstalment(src, vehicleId, paymentMethod)
    if ok then
        if result.done then
            Notify(src, 'Gratulálok! Az összes részlet kifizetve!', 'success', '🎉 Teljesen kifizetve')
        else
            Notify(src, result.monthsPaid .. '/' .. result.total .. ' részlet fizetve.', 'success')
        end
        TriggerClientEvent('fvg-autoshop:client:InstalmentPaid', src, result)
    else
        local msgs = {
            not_found          = 'Részletfizetés nem található.',
            insufficient_funds = 'Nincs elég egyenleg.',
        }
        Notify(src, msgs[result] or 'Hiba.', 'error')
    end
end)

-- Tesztvezetés vége (szerver oldali log)
RegisterNetEvent('fvg-autoshop:server:TestDriveEnded', function(model, returned)
    local src = source
    TriggerEvent('fvg-autoshop:server:TestDriveCompleted', src, model, returned)
end)