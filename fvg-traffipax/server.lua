-- ╔══════════════════════════════════════════════╗
-- ║       fvg-traffipax :: server               ║
-- ╚══════════════════════════════════════════════╝

-- Büntetési rekordok: [src] = os.time() – utolsó büntetés időpontja
local lastFined  = {}
-- Zsón kikapcsolás futás közben
local zoneStates = {}   -- [zoneId] = true/false
-- Összes rögzített büntetés (session)
local fineLog    = {}

-- ── Segédfüggvények ─────────────────────────────────────────────

local function Notify(src, msg, ntype, title)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'warning',
        title   = title,
        message = msg,
    })
end

local function Log(msg)
    if Config.LogEnabled then
        print('[fvg-traffipax] ' .. msg)
    end
end

local function GetPlayerName(src)
    local ok, p = pcall(function()
        return exports['fvg-playercore']:GetPlayer(src)
    end)
    if ok and p then
        return (p.firstname or '') .. ' ' .. (p.lastname or '')
    end
    return _G.GetPlayerName(src) or 'Ismeretlen'
end

local function GetVehiclePlate(src)
    -- A kliens küldi a rendsszámot a büntetési kéréssel
    return nil   -- lásd: RegisterNetEvent-ben paraméterként jön
end

local function GetMultiplier(over)
    local mul = 1.0
    for _, row in ipairs(Config.FineMultipliers) do
        if over >= row.over then
            mul = row.mul
        end
    end
    return mul
end

local function IsZoneEnabled(zoneId)
    if zoneStates[zoneId] == false then return false end
    for _, z in ipairs(Config.Zones) do
        if z.id == zoneId then
            return z.enabled ~= false
        end
    end
    return true
end

-- ── Büntetés feldolgozás ────────────────────────────────────────
RegisterNetEvent('fvg-traffipax:server:SpeedingFine', function(data)
    local src = source

    -- Cooldown ellenőrzés
    local now = os.time()
    local cooldownSec = Config.FineCooldown / 1000
    if lastFined[src] and (now - lastFined[src]) < cooldownSec then
        return
    end

    -- Zóna aktivált?
    if not IsZoneEnabled(data.zoneId) then return end

    -- Adatok
    local zoneLabel = data.zoneLabel or 'Ismeretlen zóna'
    local speed     = math.floor(tonumber(data.speed)   or 0)
    local limit     = math.floor(tonumber(data.limit)   or 50)
    local plate     = data.plate or 'N/A'
    local over      = speed - limit
    if over <= 0 then return end

    local baseFine  = math.floor(tonumber(data.baseFine) or 500)
    local mul       = GetMultiplier(over)
    local totalFine = math.floor(baseFine * mul)

    local playerName = GetPlayerName(src)
    lastFined[src]   = now

    -- ── Pénz levonás ──────────────────────────────────────────
    local fineDesc = string.format('Traffipax bírsság – %s (%d km/h)', zoneLabel, speed)
    local paid     = false
    local method   = Config.FineMethod

    if method == 'cash' or method == 'both' then
        local cash = exports['fvg-playercore']:GetPlayerData(src, 'cash') or 0
        local toDeduct = math.min(cash, totalFine)
        if toDeduct > 0 then
            exports['fvg-playercore']:SetPlayerData(src, 'cash', cash - toDeduct)
            totalFine = totalFine - toDeduct
            if totalFine == 0 then paid = true end
        end
    end

    if not paid and (method == 'bank' or method == 'both') then
        local ok = exports['fvg-banking']:RemoveBalance(
            src, totalFine, 'checking', fineDesc, 'fine'
        )
        if ok then
            paid = true
            totalFine = 0
        end
    end

    -- ── Értesítés a játékosnak ────────────────────────────────
    local origFine = math.floor((data.baseFine or 500) * mul)
    if paid then
        Notify(src,
            Config.Locale.fine_charged .. origFine ..
            ' | Zóna: ' .. zoneLabel ..
            ' | Sebesség: ' .. speed .. ' km/h (határ: ' .. limit .. ')',
            'warning',
            Config.Locale.speeding_fine
        )
    elseif Config.DebtOnInsufficientFunds then
        Notify(src, Config.Locale.fine_no_money, 'error', Config.Locale.speeding_fine)
    end

    -- NUI visszajelzés: kamera vaku effekt
    TriggerClientEvent('fvg-traffipax:client:FlashEffect', src, {
        zoneId = data.zoneId,
        speed  = speed,
        limit  = limit,
        fine   = origFine,
    })

    -- ── Rendőrök értesítése ─────────────────────────────────
    if Config.NotifyPolice then
        local ok, officers = pcall(function()
            return exports['fvg-police']:GetOnDutyOfficers()
        end)
        if ok and officers then
            local policeMsg = string.format(
                '%s – Rend.sz: %s – %d km/h (határ: %d) – %s',
                playerName, plate, speed, limit, zoneLabel
            )
            for offSrc, _ in pairs(officers) do
                if tonumber(offSrc) ~= src then
                    Notify(offSrc, policeMsg, 'police', Config.Locale.police_alert)
                end
            end
        end
    end

    -- ── BOLO kiadás súlyos túlsebessség esetén ─────────────────
    if Config.BOLOEnabled and over >= Config.BOLOThreshold then
        local boloDesc = string.format(
            '%s – %s – %d km/h (%d km/h túlsebessség) – %s',
            Config.Locale.bolo_desc, plate, speed, over, zoneLabel
        )
        local ok2 = pcall(function()
            exports['fvg-emergency']:IssueBOLO(plate, boloDesc, 'traffipax')
        end)
        if not ok2 then
            Log('BOLO kiadás sikertelen (fvg-emergency nem elérhető)')
        end
    end

    -- ── Log ─────────────────────────────────────────────────────
    local record = {
        src       = src,
        name      = playerName,
        plate     = plate,
        zoneId    = data.zoneId,
        zoneLabel = zoneLabel,
        speed     = speed,
        limit     = limit,
        over      = over,
        fine      = origFine,
        paid      = paid,
        time      = now,
    }
    table.insert(fineLog, record)
    TriggerEvent('fvg-traffipax:server:FineIssued', src, record)

    Log(string.format('%s (src=%d) | %s | %dkm/h (határ %d) | Bírsság: $%d | Fizetve: %s',
        playerName, src, zoneLabel, speed, limit, origFine, tostring(paid)))
end)

-- ── Admin: zóna kapcsolás ──────────────────────────────────────
RegisterNetEvent('fvg-traffipax:server:ToggleZone', function(zoneId, state)
    local src = source
    if not IsPlayerAceAllowed(src, 'fvg.admin') and
       not IsPlayerAceAllowed(src, 'fvg.superadmin') then
        return
    end
    zoneStates[zoneId] = state
    TriggerClientEvent('fvg-traffipax:client:ZoneStateChanged', -1, zoneId, state)
    Log('Zóna állapot: ' .. zoneId .. ' → ' .. tostring(state))
end)

-- Kilépéskor tisztítás
AddEventHandler('playerDropped', function()
    lastFined[source] = nil
end)

-- ══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ══════════════════════════════════════════════════════════════

exports('GetFineLog', function(limit)
    local result = {}
    local n = #fineLog
    local from = math.max(1, n - (tonumber(limit) or 50) + 1)
    for i = from, n do
        table.insert(result, fineLog[i])
    end
    return result
end)

exports('GetZoneState', function(zoneId)
    return IsZoneEnabled(zoneId)
end)

exports('SetZoneState', function(zoneId, state)
    zoneStates[zoneId] = state == true
    TriggerClientEvent('fvg-traffipax:client:ZoneStateChanged', -1, zoneId, state == true)
    return true
end)

exports('GetZones', function()
    local result = {}
    for _, z in ipairs(Config.Zones) do
        result[#result+1] = {
            id      = z.id,
            label   = z.label,
            coords  = z.coords,
            range   = z.range,
            limit   = z.limit,
            fine    = z.fine,
            enabled = IsZoneEnabled(z.id),
        }
    end
    return result
end)

exports('IssueFineManual', function(src, zoneId, speedKmh)
    src = tonumber(src)
    local zone = nil
    for _, z in ipairs(Config.Zones) do
        if z.id == zoneId then zone = z; break end
    end
    if not zone then return false end
    local limit = zone.limit
    local over  = math.max(0, speedKmh - limit)
    local mul   = GetMultiplier(over)
    local fine  = math.floor(zone.fine * mul)
    local desc  = string.format('Manuális traffipax bírsság – %s', zone.label)
    local ok = exports['fvg-banking']:RemoveBalance(src, fine, 'checking', desc, 'fine')
    TriggerEvent('fvg-traffipax:server:FineIssued', src, {
        zoneId = zoneId, zoneLabel = zone.label, speed = speedKmh,
        limit = limit, over = over, fine = fine, paid = ok, time = os.time(),
    })
    return ok, fine
end)
