-- ╔══════════════════════════════════════════════╗
-- ║       fvg-emergency :: client               ║
-- ╚══════════════════════════════════════════════╝

local currentCode   = nil
local isAuthorized  = false
local nuiReady      = false

-- ── Jogosultság ellenőrzés betöltéskor ──────────────────────────
AddEventHandler('fvg-playercore:client:PlayerLoaded', function(data)
    local job = data and data.metadata and data.metadata.job
    isAuthorized = false
    if job then
        for _, j in ipairs(Config.AuthorizedJobs) do
            if j == job then isAuthorized = true; break end
        end
    end
    if isAuthorized then
        Wait(300)
        SendNUIMessage({ action = 'setAuthorized', authorized = true, position = Config.HudPosition })
        nuiReady = true
    end
end)

AddEventHandler('fvg-playercore:client:DataUpdated', function(key, value)
    if key ~= 'job' then return end
    isAuthorized = false
    for _, j in ipairs(Config.AuthorizedJobs) do
        if j == value then isAuthorized = true; break end
    end
    SendNUIMessage({ action = 'setAuthorized', authorized = isAuthorized, position = Config.HudPosition })
end)

-- ── Kód beállítás (helyi parancs) ──────────────────────────────
RegisterCommand('code', function(_, args)
    if not isAuthorized then
        TriggerEvent('fvg-notify:client:Notify', { type = 'error', message = Config.Locale.not_authorized })
        return
    end
    local code = args[1] and string.lower(args[1]) or nil
    if not code or not Config.Codes[code] then
        TriggerEvent('fvg-notify:client:Notify', {
            type    = 'warning',
            message = 'Használat: /code [code1|code2|code3|code4|bolo|signal100] [megjegyzés]'
        })
        return
    end
    local note = table.concat(args, ' ', 2)
    TriggerServerEvent('fvg-emergency:server:SetCode', code, note)
end, false)

RegisterCommand('clearcode', function()
    if not isAuthorized then return end
    TriggerServerEvent('fvg-emergency:server:ClearCode')
end, false)

RegisterCommand('bolo', function(_, args)
    if not isAuthorized then return end
    local plate = args[1] or 'N/A'
    local desc  = table.concat(args, ' ', 2)
    TriggerServerEvent('fvg-emergency:server:IssueBOLO', plate, desc)
end, false)

RegisterCommand('clearbolo', function(_, args)
    if not isAuthorized then return end
    local id = tonumber(args[1])
    if not id then return end
    TriggerServerEvent('fvg-emergency:server:ClearBOLO', id)
end, false)

RegisterCommand('signal100', function(_, args)
    if not isAuthorized then return end
    local state = args[1] == 'on' or args[1] == '1'
    TriggerServerEvent('fvg-emergency:server:Signal100', state)
end, false)

-- ── Szerver események (kód frissítés) ──────────────────────────
RegisterNetEvent('fvg-emergency:client:CodeUpdated', function(data)
    currentCode = data
    SendNUIMessage({ action = 'setCode', data = data })
    TriggerEvent('fvg-emergency:client:CodeChanged', data)
end)

RegisterNetEvent('fvg-emergency:client:CodeCleared', function()
    currentCode = nil
    SendNUIMessage({ action = 'clearCode' })
    TriggerEvent('fvg-emergency:client:CodeChanged', nil)
end)

-- ── Beérkező kód (más egységtől) ───────────────────────────────
RegisterNetEvent('fvg-emergency:client:IncomingCode', function(data)
    SendNUIMessage({ action = 'incomingCode', data = data })
    -- fvg-notify integráció
    TriggerEvent('fvg-notify:client:Notify', {
        type    = 'police',
        title   = data.label,
        message = (data.issuedBy or '?') .. (data.note ~= '' and (' – ' .. data.note) or ''),
    })
end)

RegisterNetEvent('fvg-emergency:client:UnitCodeCleared', function(data)
    SendNUIMessage({ action = 'unitCleared', src = data.src })
end)

-- ── BOLO események ────────────────────────────────────────────
RegisterNetEvent('fvg-emergency:client:BOLOIssued', function(data)
    SendNUIMessage({ action = 'boloIssued', data = data })
    TriggerEvent('fvg-notify:client:Notify', {
        type    = 'police',
        title   = 'BOLO #' .. data.id,
        message = (data.plate or 'N/A') .. ' – ' .. (data.description or ''),
    })
end)

RegisterNetEvent('fvg-emergency:client:BOLOCleared', function(data)
    SendNUIMessage({ action = 'boloCleared', id = data.id })
    TriggerEvent('fvg-notify:client:Notify', {
        type    = 'info',
        message = 'BOLO #' .. data.id .. ' visszavonva.',
    })
end)

-- ── Signal 100 ────────────────────────────────────────────────
RegisterNetEvent('fvg-emergency:client:Signal100', function(data)
    SendNUIMessage({ action = 'signal100', active = data.active, issuedBy = data.issuedBy })
    local msg = data.active
        and ('⚠ SIGNAL 100 – ' .. (data.issuedBy or '?') .. ' kiadta az üzem zárat!')
        or  'Signal 100 megszüntetve.'
    TriggerEvent('fvg-notify:client:Notify', {
        type    = data.active and 'error' or 'info',
        title   = 'Signal 100',
        message = msg,
    })
end)

-- ── Exportok ──────────────────────────────────────────────────
exports('GetCurrentCode', function()
    return currentCode
end)

exports('IsAuthorized', function()
    return isAuthorized
end)

exports('SetCodeLocal', function(data)
    currentCode = data
    SendNUIMessage({ action = 'setCode', data = data })
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    currentCode  = nil
    isAuthorized = false
    nuiReady     = false
end)
