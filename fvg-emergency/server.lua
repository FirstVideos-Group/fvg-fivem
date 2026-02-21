-- ╔══════════════════════════════════════════════╗
-- ║       fvg-emergency :: server               ║
-- ╚══════════════════════════════════════════════╝

-- Aktív hívókódok: [src] = { code, issuedBy, issuedAt, note }
local activeCodes   = {}
-- Aktív BOLO-k: [id] = { plate, description, issuedBy, issuedAt }
local activeBOLOs   = {}
local boloCounter   = 0
-- Signal 100 állapot
local signal100     = false
local signal100By   = nil

-- ── Segédfüggvények ───────────────────────────────────────────

local function Notify(src, msg, ntype)
    TriggerClientEvent('fvg-notify:client:Notify', src, {
        type    = ntype or 'info',
        message = msg,
    })
end

local function GetJob(src)
    local ok, job = pcall(function()
        return exports['fvg-playercore']:GetPlayerData(src, 'job')
    end)
    return ok and job or nil
end

local function IsAuthorized(src)
    local job = GetJob(src)
    if not job then return false end
    for _, j in ipairs(Config.AuthorizedJobs) do
        if j == job then return true end
    end
    return false
end

local function IsDispatcher(src)
    local job = GetJob(src)
    if not job then return false end
    for _, j in ipairs(Config.DispatchJobs) do
        if j == job then return true end
    end
    return false
end

local function GetName(src)
    local ok, p = pcall(function()
        return exports['fvg-playercore']:GetPlayer(src)
    end)
    if ok and p then
        return (p.firstname or '') .. ' ' .. (p.lastname or '')
    end
    return GetPlayerName(src) or 'Ismeretlen'
end

local function BroadcastToUnits(event, data, excludeSrc)
    local allPlayers = exports['fvg-playercore']:GetAllPlayers()
    for _, p in ipairs(allPlayers) do
        if p.source ~= excludeSrc then
            local job = GetJob(p.source)
            local authorized = false
            for _, j in ipairs(Config.AuthorizedJobs) do
                if j == job then authorized = true; break end
            end
            if authorized then
                TriggerClientEvent(event, p.source, data)
            end
        end
    end
end

local function Log(msg)
    if Config.LogEnabled then
        print('[fvg-emergency] ' .. msg)
    end
end

-- ══════════════════════════════════════════════════════════════
--  HÍVÓKÓD KEZELÉS
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-emergency:server:SetCode', function(code, note)
    local src = source
    if not IsAuthorized(src) then
        Notify(src, Config.Locale.not_authorized, 'error')
        return
    end

    -- Signal 100 alatt kód nem adható ki
    if signal100 and Config.LockdownOnSignal100 and code ~= 'signal100' then
        Notify(src, 'Signal 100 érvényes – kód nem adható ki!', 'error')
        return
    end

    local codeData = Config.Codes[code]
    if not codeData then return end

    local name = GetName(src)
    activeCodes[src] = {
        code      = code,
        issuedBy  = name,
        issuedAt  = os.time(),
        note      = note or '',
        job       = GetJob(src),
    }

    local broadcastData = {
        src      = src,
        code     = code,
        label    = codeData.label,
        color    = codeData.color,
        icon     = codeData.icon,
        issuedBy = name,
        note     = note or '',
    }

    -- NeverWanted integráció: Code 3 → wanted kikapcsolás
    if code == 'code3' and Config.NeverWantedOnCode3 then
        TriggerClientEvent('fvg-neverwanted:client:SetEnabled', src, true)
    end

    -- Saját HUD frissítés
    TriggerClientEvent('fvg-emergency:client:CodeUpdated', src, broadcastData)

    -- Szétsugárzás minden jogosult egységnek
    BroadcastToUnits('fvg-emergency:client:IncomingCode', broadcastData, src)

    -- Szerver-oldali esemény más resourceoknak
    TriggerEvent('fvg-emergency:server:CodeSet', src, code, note)

    Notify(src, Config.Locale.code_set .. ': ' .. codeData.label, 'police')
    Log(string.format('Kód beállítva: %s → %s (note: %s)', name, code, note or '-'))
end)

RegisterNetEvent('fvg-emergency:server:ClearCode', function()
    local src = source
    if not IsAuthorized(src) then return end

    activeCodes[src] = nil

    -- NeverWanted visszakapcsolás ha Code 3 volt
    if Config.NeverWantedOnCode3 then
        TriggerClientEvent('fvg-neverwanted:client:SetEnabled', src, true)
    end

    TriggerClientEvent('fvg-emergency:client:CodeCleared', src)
    BroadcastToUnits('fvg-emergency:client:UnitCodeCleared', { src = src }, src)
    TriggerEvent('fvg-emergency:server:CodeCleared', src)
    Notify(src, Config.Locale.code_cleared, 'info')
end)

-- ══════════════════════════════════════════════════════════════
--  BOLO KEZELÉS
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-emergency:server:IssueBOLO', function(plate, description)
    local src = source
    if not IsDispatcher(src) then
        Notify(src, Config.Locale.not_authorized, 'error')
        return
    end

    boloCounter = boloCounter + 1
    local id = boloCounter
    local name = GetName(src)

    activeBOLOs[id] = {
        id          = id,
        plate       = plate or 'N/A',
        description = description or '',
        issuedBy    = name,
        issuedAt    = os.time(),
    }

    local broadcastData = {
        id          = id,
        plate       = plate or 'N/A',
        description = description or '',
        issuedBy    = name,
    }

    BroadcastToUnits('fvg-emergency:client:BOLOIssued', broadcastData, nil)
    TriggerClientEvent('fvg-emergency:client:BOLOIssued', src, broadcastData)
    TriggerEvent('fvg-emergency:server:BOLOIssued', id, broadcastData)
    Notify(src, Config.Locale.bolo_issued .. ': ' .. (plate or 'N/A'), 'police')
    Log(string.format('BOLO kiadva #%d: %s – %s (%s)', id, plate or 'N/A', description or '-', name))
end)

RegisterNetEvent('fvg-emergency:server:ClearBOLO', function(id)
    local src = source
    if not IsDispatcher(src) then
        Notify(src, Config.Locale.not_authorized, 'error')
        return
    end

    id = tonumber(id)
    if not activeBOLOs[id] then return end
    activeBOLOs[id] = nil

    BroadcastToUnits('fvg-emergency:client:BOLOCleared', { id = id }, nil)
    TriggerClientEvent('fvg-emergency:client:BOLOCleared', src, { id = id })
    TriggerEvent('fvg-emergency:server:BOLOCleared', id)
    Notify(src, Config.Locale.bolo_cleared, 'info')
end)

-- ══════════════════════════════════════════════════════════════
--  SIGNAL 100
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-emergency:server:Signal100', function(state)
    local src = source
    if not IsDispatcher(src) then
        Notify(src, Config.Locale.not_authorized, 'error')
        return
    end

    signal100   = state == true
    signal100By = signal100 and GetName(src) or nil

    local broadcastData = {
        active    = signal100,
        issuedBy  = signal100By,
    }

    -- Minden online jogosult egységet értesítünk
    local allPlayers = exports['fvg-playercore']:GetAllPlayers()
    for _, p in ipairs(allPlayers) do
        local job = GetJob(p.source)
        local auth = false
        for _, j in ipairs(Config.AuthorizedJobs) do
            if j == job then auth = true; break end
        end
        if auth then
            TriggerClientEvent('fvg-emergency:client:Signal100', p.source, broadcastData)
        end
    end

    TriggerEvent('fvg-emergency:server:Signal100Changed', signal100, src)

    local msg = signal100 and Config.Locale.signal_100_on or Config.Locale.signal_100_off
    Notify(src, msg, signal100 and 'error' or 'info')
    Log(string.format('Signal 100: %s (%s)', tostring(signal100), GetName(src)))
end)

-- ══════════════════════════════════════════════════════════════
--  EXPORTOK
-- ══════════════════════════════════════════════════════════════

exports('GetActiveCode', function(src)
    return activeCodes[tonumber(src)]
end)

exports('GetAllActiveCodes', function()
    local result = {}
    for s, data in pairs(activeCodes) do
        result[s] = data
    end
    return result
end)

exports('SetCode', function(src, code, note)
    src = tonumber(src)
    if not Config.Codes[code] then return false end
    activeCodes[src] = {
        code     = code,
        issuedBy = 'system',
        issuedAt = os.time(),
        note     = note or '',
    }
    TriggerClientEvent('fvg-emergency:client:CodeUpdated', src, {
        src      = src,
        code     = code,
        label    = Config.Codes[code].label,
        color    = Config.Codes[code].color,
        icon     = Config.Codes[code].icon,
        issuedBy = 'system',
        note     = note or '',
    })
    return true
end)

exports('ClearCode', function(src)
    src = tonumber(src)
    activeCodes[src] = nil
    TriggerClientEvent('fvg-emergency:client:CodeCleared', src)
    return true
end)

exports('IsSignal100', function()
    return signal100
end)

exports('GetActiveBOLOs', function()
    local result = {}
    for _, b in pairs(activeBOLOs) do
        table.insert(result, b)
    end
    return result
end)

exports('IssueBOLO', function(plate, description, issuedBy)
    boloCounter = boloCounter + 1
    local id = boloCounter
    activeBOLOs[id] = {
        id          = id,
        plate       = plate or 'N/A',
        description = description or '',
        issuedBy    = issuedBy or 'system',
        issuedAt    = os.time(),
    }
    BroadcastToUnits('fvg-emergency:client:BOLOIssued', activeBOLOs[id], nil)
    TriggerEvent('fvg-emergency:server:BOLOIssued', id, activeBOLOs[id])
    return id
end)

exports('ClearBOLO', function(id)
    id = tonumber(id)
    if not activeBOLOs[id] then return false end
    activeBOLOs[id] = nil
    BroadcastToUnits('fvg-emergency:client:BOLOCleared', { id = id }, nil)
    return true
end)

-- Kilépéskor kód törlés
AddEventHandler('playerDropped', function()
    local src = source
    if activeCodes[src] then
        activeCodes[src] = nil
        BroadcastToUnits('fvg-emergency:client:UnitCodeCleared', { src = src }, src)
    end
end)
