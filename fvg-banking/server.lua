-- ╔══════════════════════════════════════════════╗
-- ║         fvg-banking :: server                ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)

    exports['fvg-database']:RegisterMigration('fvg_bank_accounts', [[
        CREATE TABLE IF NOT EXISTS `fvg_bank_accounts` (
            `id`           INT          NOT NULL AUTO_INCREMENT,
            `player_id`    INT          NOT NULL,
            `type`         ENUM('checking','savings') NOT NULL DEFAULT 'checking',
            `balance`      BIGINT       NOT NULL DEFAULT 0,
            `iban`         VARCHAR(24)  NOT NULL,
            `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_iban`       (`iban`),
            UNIQUE KEY `uq_player_type`(`player_id`,`type`),
            CONSTRAINT `fk_bank_player`
                FOREIGN KEY (`player_id`) REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports['fvg-database']:RegisterMigration('fvg_transactions', [[
        CREATE TABLE IF NOT EXISTS `fvg_transactions` (
            `id`           INT          NOT NULL AUTO_INCREMENT,
            `account_id`   INT          NOT NULL,
            `type`         VARCHAR(20)  NOT NULL DEFAULT 'other',
            `amount`       BIGINT       NOT NULL,
            `balance_after`BIGINT       NOT NULL,
            `description`  VARCHAR(120)          DEFAULT NULL,
            `ref_player_id`INT                   DEFAULT NULL,
            `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_account` (`account_id`),
            KEY `idx_type`    (`type`),
            CONSTRAINT `fk_tx_account`
                FOREIGN KEY (`account_id`) REFERENCES `fvg_bank_accounts`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ─────────────────────────────────────────────────────
-- [src] = { player_id, checking={id,balance,iban}, savings={id,balance,iban} }
local playerAccounts = {}

-- ── Segédfüggvények ───────────────────────────────────────────

local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type = ntype or 'info', title = title, message = msg
    })
end

local function GenIBAN()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local iban  = 'LS'
    for i = 1, 18 do
        local idx = math.random(1, #chars)
        iban = iban .. chars:sub(idx, idx)
    end
    return iban
end

local function GetAccount(src, accType)
    local p = playerAccounts[tonumber(src)]
    if not p then return nil end
    return p[accType or 'checking']
end

local function LogTransaction(accountId, txType, amount, balanceAfter, description, refPlayerId)
    exports['fvg-database']:Insert(
        [[INSERT INTO `fvg_transactions`
          (`account_id`,`type`,`amount`,`balance_after`,`description`,`ref_player_id`)
          VALUES (?,?,?,?,?,?)]],
        { accountId, txType, amount, balanceAfter, description or nil, refPlayerId or nil }
    )
end

local function SyncClient(src)
    local p = playerAccounts[src]
    if not p then return end
    TriggerClientEvent('fvg-banking:client:SyncAccounts', src, {
        checking = p.checking,
        savings  = p.savings,
    })
    -- fvg-playercore cash szinkron
    if Config.SyncCashWithPlayercore then
        local player = exports['fvg-playercore']:GetPlayer(src)
        if player then
            TriggerClientEvent('fvg-banking:client:SyncCash', src, player.cash or 0)
        end
    end
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local rows = exports['fvg-database']:Query(
        'SELECT * FROM `fvg_bank_accounts` WHERE `player_id` = ?',
        { player.id }
    )

    local accounts = { player_id = player.id, checking = nil, savings = nil }

    if rows then
        for _, row in ipairs(rows) do
            accounts[row.type] = {
                id      = row.id,
                balance = row.balance,
                iban    = row.iban,
                type    = row.type,
            }
        end
    end

    -- Checking számla létrehozás ha nincs
    if not accounts.checking then
        local iban = GenIBAN()
        local id   = exports['fvg-database']:Insert(
            'INSERT INTO `fvg_bank_accounts` (`player_id`,`type`,`balance`,`iban`) VALUES (?,?,?,?)',
            { player.id, 'checking', Config.DefaultBalance, iban }
        )
        accounts.checking = { id = id, balance = Config.DefaultBalance, iban = iban, type = 'checking' }
        LogTransaction(id, 'other', Config.DefaultBalance, Config.DefaultBalance, 'Számla nyitás', nil)
    end

    -- Savings számla létrehozás ha nincs
    if not accounts.savings then
        local iban = GenIBAN()
        local id   = exports['fvg-database']:Insert(
            'INSERT INTO `fvg_bank_accounts` (`player_id`,`type`,`balance`,`iban`) VALUES (?,?,?,?)',
            { player.id, 'savings', Config.DefaultSavings, iban }
        )
        accounts.savings = { id = id, balance = Config.DefaultSavings, iban = iban, type = 'savings' }
    end

    playerAccounts[src] = accounts
    SyncClient(src)
end)

AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    playerAccounts[src] = nil
end)

-- ═══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ═══════════════════════════════════════════════════════════════

exports('GetBalance', function(src, accType)
    local acc = GetAccount(tonumber(src), accType or 'checking')
    return acc and acc.balance or 0
end)

exports('HasSufficientFunds', function(src, amount, accType)
    local acc = GetAccount(tonumber(src), accType or 'checking')
    return acc and acc.balance >= tonumber(amount)
end)

exports('AddBalance', function(src, amount, accType, description, txType)
    local s      = tonumber(src)
    local acc    = GetAccount(s, accType or 'checking')
    if not acc then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local newBalance = math.min(acc.balance + amount, Config.MaxBankBalance)
    acc.balance      = newBalance

    exports['fvg-database']:Execute(
        'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
        { newBalance, acc.id }
    )
    LogTransaction(acc.id, txType or 'other', amount, newBalance, description or 'Befizetés', nil)
    SyncClient(s)
    TriggerEvent('fvg-banking:server:BalanceChanged', s, accType or 'checking', newBalance, amount, 'add')
    return true
end)

exports('RemoveBalance', function(src, amount, accType, description, txType)
    local s   = tonumber(src)
    local acc = GetAccount(s, accType or 'checking')
    if not acc then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    if acc.balance < amount then return false end

    local newBalance = acc.balance - amount
    acc.balance      = newBalance

    exports['fvg-database']:Execute(
        'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
        { newBalance, acc.id }
    )
    LogTransaction(acc.id, txType or 'other', -amount, newBalance, description or 'Kifizetés', nil)
    SyncClient(s)
    TriggerEvent('fvg-banking:server:BalanceChanged', s, accType or 'checking', newBalance, -amount, 'remove')
    return true
end)

exports('Transfer', function(fromSrc, toSrc, amount, description)
    local fS     = tonumber(fromSrc)
    local tS     = tonumber(toSrc)
    amount       = math.floor(tonumber(amount) or 0)

    if amount < Config.TransferMinAmount then return false, 'too_small' end
    if amount > Config.TransferMaxAmount then return false, 'too_large' end

    local fromAcc = GetAccount(fS, 'checking')
    local toAcc   = GetAccount(tS, 'checking')
    if not fromAcc or not toAcc then return false, 'account_not_found' end
    if fromAcc.balance < amount then return false, 'insufficient_funds' end
    if fS == tS then return false, 'same_account' end

    -- Tranzakciós díj
    local fee = Config.TransferFee > 0 and math.floor(amount * Config.TransferFee / 100) or 0

    -- Küldő
    local fromNew = fromAcc.balance - amount - fee
    fromAcc.balance = fromNew
    exports['fvg-database']:Execute(
        'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
        { fromNew, fromAcc.id }
    )
    LogTransaction(fromAcc.id, 'transfer', -(amount + fee), fromNew,
        description or 'Átutalás', playerAccounts[tS] and playerAccounts[tS].player_id)

    -- Fogadó
    local toNew = math.min(toAcc.balance + amount, Config.MaxBankBalance)
    toAcc.balance = toNew
    exports['fvg-database']:Execute(
        'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
        { toNew, toAcc.id }
    )
    LogTransaction(toAcc.id, 'received', amount, toNew,
        description or 'Beérkezett átutalás', playerAccounts[fS] and playerAccounts[fS].player_id)

    SyncClient(fS)
    SyncClient(tS)

    TriggerEvent('fvg-banking:server:TransferCompleted', fS, tS, amount)
    return true, 'ok'
end)

exports('GetTransactions', function(src, accType, limit)
    local s   = tonumber(src)
    local acc = GetAccount(s, accType or 'checking')
    if not acc then return {} end
    limit = math.min(tonumber(limit) or 20, Config.MaxTransactionLog)

    local rows = exports['fvg-database']:Query(
        [[SELECT t.*, p.firstname, p.lastname
          FROM `fvg_transactions` t
          LEFT JOIN `fvg_bank_accounts` ba ON ba.id = t.account_id
          LEFT JOIN `fvg_players` p ON p.id = t.ref_player_id
          WHERE t.`account_id` = ?
          ORDER BY t.`created_at` DESC
          LIMIT ?]],
        { acc.id, limit }
    )
    return rows or {}
end)

exports('GetAccountByIdentifier', function(identifier)
    local row = exports['fvg-database']:QuerySingle(
        [[SELECT ba.*, p.firstname, p.lastname
          FROM `fvg_bank_accounts` ba
          JOIN `fvg_players` p ON p.id = ba.player_id
          WHERE ba.`iban` = ? OR p.`identifier` = ?
          LIMIT 1]],
        { identifier, identifier }
    )
    return row
end)

exports('CreateTransaction', function(src, txType, amount, description, refSrc)
    local s   = tonumber(src)
    local acc = GetAccount(s, 'checking')
    if not acc then return false end

    local refId = refSrc and playerAccounts[tonumber(refSrc)] and playerAccounts[tonumber(refSrc)].player_id or nil
    LogTransaction(acc.id, txType or 'other', amount, acc.balance, description, refId)
    return true
end)

-- ═══════════════════════════════════════════════════════════════
--  NET EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Panel megnyitás kérés
RegisterNetEvent('fvg-banking:server:RequestPanel', function(mode)
    local src  = source
    local p    = playerAccounts[src]
    if not p then return end

    local txChecking = exports['fvg-banking']:GetTransactions(src, 'checking', 20)
    local txSavings  = exports['fvg-banking']:GetTransactions(src, 'savings',  20)
    local player     = exports['fvg-playercore']:GetPlayer(src)

    TriggerClientEvent('fvg-banking:client:OpenPanel', src, {
        accounts     = { checking = p.checking, savings = p.savings },
        transactions = { checking = txChecking, savings = txSavings },
        cash         = player and player.cash or 0,
        txTypes      = Config.TxTypes,
        mode         = mode or 'full',   -- 'full' | 'atm'
        limits       = {
            atmWithdraw  = Config.ATMWithdrawLimit,
            transferMax  = Config.TransferMaxAmount,
            transferMin  = Config.TransferMinAmount,
            transferFee  = Config.TransferFee,
            maxCash      = Config.MaxCashOnHand,
        },
    })
end)

-- Befizetés (bank / ATM)
RegisterNetEvent('fvg-banking:server:Deposit', function(amount, accType)
    local src    = source
    amount       = math.floor(tonumber(amount) or 0)
    accType      = accType or 'checking'

    if amount <= 0 then Notify(src, 'Érvénytelen összeg.', 'error'); return end

    -- Készpénz levonás
    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player or (player.cash or 0) < amount then
        Notify(src, 'Nincs elég készpénzed.', 'error'); return
    end

    exports['fvg-playercore']:RemoveCash(src, amount)
    exports['fvg-banking']:AddBalance(src, amount, accType, 'ATM/Bank befizetés', 'deposit')
    Notify(src, 'Befizetés sikeres: $' .. amount, 'success')
    TriggerEvent('fvg-banking:server:Deposited', src, amount, accType)
end)

-- Kifizetés (bank / ATM)
RegisterNetEvent('fvg-banking:server:Withdraw', function(amount, accType, isATM)
    local src = source
    amount    = math.floor(tonumber(amount) or 0)
    accType   = accType or 'checking'

    if amount <= 0 then Notify(src, 'Érvénytelen összeg.', 'error'); return end
    if isATM and amount > Config.ATMWithdrawLimit then
        Notify(src, 'ATM limit: $' .. Config.ATMWithdrawLimit .. ' / alkalom.', 'warning'); return
    end

    -- Készpénz limit
    local player = exports['fvg-playercore']:GetPlayer(src)
    if player then
        local currentCash = player.cash or 0
        if currentCash + amount > Config.MaxCashOnHand then
            Notify(src, 'Túl sok készpénz van nálad. Max: $' .. Config.MaxCashOnHand, 'warning')
            return
        end
    end

    local ok = exports['fvg-banking']:RemoveBalance(src, amount, accType, 'Kifizetés', 'withdraw')
    if not ok then Notify(src, 'Nincs elég egyenleg.', 'error'); return end

    exports['fvg-playercore']:AddCash(src, amount)
    Notify(src, 'Kifizetés sikeres: $' .. amount, 'success')
    TriggerEvent('fvg-banking:server:Withdrawn', src, amount, accType)
end)

-- Átutalás
RegisterNetEvent('fvg-banking:server:Transfer', function(targetIdentifier, amount, description)
    local src  = source
    amount     = math.floor(tonumber(amount) or 0)

    if amount < Config.TransferMinAmount then
        Notify(src, 'Minimum átutalás: $' .. Config.TransferMinAmount, 'error'); return
    end

    -- Célszemély keresés online játékosok között (IBAN vagy ID alapján)
    local targetSrc = nil
    for _, pid in ipairs(GetPlayers()) do
        local s = tonumber(pid)
        local p = playerAccounts[s]
        if p and (p.checking.iban == targetIdentifier) then
            targetSrc = s; break
        end
    end

    -- Ha offline: DB alapú
    if not targetSrc then
        local row = exports['fvg-banking']:GetAccountByIdentifier(targetIdentifier)
        if not row then
            Notify(src, 'Ismeretlen bankszámlaszám: ' .. targetIdentifier, 'error'); return
        end

        -- Offline átutalás
        local fromAcc = GetAccount(src, 'checking')
        if not fromAcc or fromAcc.balance < amount then
            Notify(src, 'Nincs elég egyenleg.', 'error'); return
        end

        local newBal = fromAcc.balance - amount
        fromAcc.balance = newBal
        exports['fvg-database']:Execute(
            'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
            { newBal, fromAcc.id }
        )
        LogTransaction(fromAcc.id, 'transfer', -amount, newBal,
            description or 'Átutalás (offline)', row.player_id)
        -- Fogadó egyenleg frissítés DB-ben
        local newTarget = math.min(row.balance + amount, Config.MaxBankBalance)
        exports['fvg-database']:Execute(
            'UPDATE `fvg_bank_accounts` SET `balance`=? WHERE `id`=?',
            { newTarget, row.id }
        )
        LogTransaction(row.id, 'received', amount, newTarget,
            description or 'Beérkezett (offline)', playerAccounts[src] and playerAccounts[src].player_id)

        SyncClient(src)
        Notify(src, 'Átutalás elküldve (offline): $' .. amount, 'success')
        return
    end

    local ok, err = exports['fvg-banking']:Transfer(src, targetSrc, amount, description)
    if ok then
        Notify(src,       'Átutalás sikeres: $' .. amount, 'success')
        Notify(targetSrc, 'Beérkezett: $' .. amount .. ' – ' .. GetPlayerName(src), 'success')
    else
        local msgs = {
            insufficient_funds = 'Nincs elég egyenleg.',
            too_large          = 'Túl nagy összeg. Max: $' .. Config.TransferMaxAmount,
            too_small          = 'Túl kis összeg. Min: $' .. Config.TransferMinAmount,
            same_account       = 'Saját magadnak nem utalhatsz.',
            account_not_found  = 'Számlaszám nem található.',
        }
        Notify(src, msgs[err] or 'Ismeretlen hiba.', 'error')
    end
end)

-- Számlák közötti átvezetés
RegisterNetEvent('fvg-banking:server:InternalTransfer', function(fromType, toType, amount)
    local src = source
    amount    = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local ok = exports['fvg-banking']:RemoveBalance(src, amount, fromType, 'Belső átvezetés', 'transfer')
    if not ok then Notify(src, 'Nincs elég egyenleg.', 'error'); return end
    exports['fvg-banking']:AddBalance(src, amount, toType, 'Belső átvezetés', 'received')
    Notify(src, 'Belső átvezetés sikeres: $' .. amount, 'success')
end)