-- ╔══════════════════════════════════════════════╗
-- ║         fvg-banking :: client                ║
-- ╚══════════════════════════════════════════════╝

local localAccounts = { checking = { balance = 0 }, savings = { balance = 0 } }
local localCash     = 0
local menuOpen      = false
local bankBlips     = {}
local atmProps      = {}

-- ── Kliens exportok ───────────────────────────────────────────
exports('GetLocalBalance', function(accType)
    local acc = localAccounts[accType or 'checking']
    return acc and acc.balance or 0
end)

exports('OpenBank', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-banking:server:RequestPanel', 'full')
end)

-- ── Szinkron fogadás ─────────────────────────────────────────
RegisterNetEvent('fvg-banking:client:SyncAccounts', function(accounts)
    if accounts.checking then localAccounts.checking = accounts.checking end
    if accounts.savings  then localAccounts.savings  = accounts.savings  end
    if menuOpen then
        SendNUIMessage({ action = 'syncAccounts', accounts = localAccounts })
    end
    TriggerEvent('fvg-banking:client:AccountsUpdated', localAccounts)
end)

RegisterNetEvent('fvg-banking:client:SyncCash', function(cash)
    localCash = cash or 0
    if menuOpen then
        SendNUIMessage({ action = 'syncCash', cash = localCash })
    end
end)

-- ── Panel megnyitás ──────────────────────────────────────────
RegisterNetEvent('fvg-banking:client:OpenPanel', function(data)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = data })
end)

-- ── Bank blipek és markerek ───────────────────────────────────
CreateThread(function()
    for _, bank in ipairs(Config.BankLocations) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, bank.blip.sprite)
        SetBlipColour(blip, bank.blip.color)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(bank.blip.label)
        EndTextCommandSetBlipName(blip)
        table.insert(bankBlips, blip)
    end
end)

-- ── ATM propok ────────────────────────────────────────────────
CreateThread(function()
    for _, atm in ipairs(Config.ATMLocations) do
        local model = GetHashKey(atm.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        local obj = CreateObject(model, atm.coords.x, atm.coords.y, atm.coords.z,
            false, false, false)
        SetEntityHeading(obj, atm.heading)
        FreezeEntityPosition(obj, true)
        SetEntityAsMissionEntity(obj, false, true)
        PlaceObjectOnGroundProperly(obj)
        SetModelAsNoLongerNeeded(model)
        table.insert(atmProps, { obj = obj, coords = atm.coords })
    end
end)

-- ── Interakciós thread ────────────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        -- Bank fiókok
        for _, bank in ipairs(Config.BankLocations) do
            local dist = #(coords - vector3(bank.coords.x, bank.coords.y, bank.coords.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1,
                    bank.coords.x, bank.coords.y, bank.coords.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 0.6,
                    56, 189, 248, 120,
                    false, true, 2, nil, nil, false
                )
                if dist < Config.BankRadius then
                    exports['fvg-notify']:Notify({
                        type='info', message='[E] ' .. bank.label .. ' megnyitása',
                        duration=600, static=true
                    })
                    if IsControlJustPressed(0, 38) and not menuOpen then
                        TriggerServerEvent('fvg-banking:server:RequestPanel', 'full')
                    end
                end
            end
        end

        -- ATM-ek
        for _, atm in ipairs(atmProps) do
            local dist = #(coords - vector3(atm.coords.x, atm.coords.y, atm.coords.z))
            if dist < 3.0 then
                sleep = 0
                if dist < Config.ATMRadius then
                    exports['fvg-notify']:Notify({
                        type='info', message='[E] ATM megnyitása',
                        duration=600, static=true
                    })
                    if IsControlJustPressed(0, 38) and not menuOpen then
                        TriggerServerEvent('fvg-banking:server:RequestPanel', 'atm')
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('fvg-banking:server:Deposit',
        tonumber(data.amount), data.accType or 'checking')
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('fvg-banking:server:Withdraw',
        tonumber(data.amount), data.accType or 'checking', data.isATM == true)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('fvg-banking:server:Transfer',
        data.iban, tonumber(data.amount), data.description)
    cb('ok')
end)

RegisterNUICallback('internalTransfer', function(data, cb)
    TriggerServerEvent('fvg-banking:server:InternalTransfer',
        data.fromType, data.toType, tonumber(data.amount))
    cb('ok')
end)

-- ── Parancs ───────────────────────────────────────────────────
RegisterCommand('bank', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-banking:server:RequestPanel', 'full')
end, false)

RegisterKeyMapping('bank', 'Bank panel megnyitása', 'keyboard', 'F4')

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, blip in ipairs(bankBlips) do RemoveBlip(blip) end
    for _, atm in ipairs(atmProps) do
        if DoesEntityExist(atm.obj) then DeleteObject(atm.obj) end
    end
    menuOpen    = false
    localAccounts = { checking = { balance = 0 }, savings = { balance = 0 } }
end)