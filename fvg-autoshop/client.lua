-- ╔══════════════════════════════════════════════╗
-- ║       fvg-autoshop :: client                 ║
-- ╚══════════════════════════════════════════════╝

local menuOpen       = false
local isTestDriving  = false
local testDriveVeh   = nil
local testDriveTimer = nil
local testDriveReturn= nil   -- visszatérési koordináta
local localVehicles  = {}
local dealerBlips    = {}
local dealerNPCs     = {}

-- ── Kliens exportok ───────────────────────────────────────────
exports('OpenDealership', function(dealershipId)
    if menuOpen then return end
    TriggerServerEvent('fvg-autoshop:server:RequestDealership', dealershipId)
end)

exports('GetLocalOwnedVehicles', function()
    return localVehicles
end)

exports('IsTestDriving', function()
    return isTestDriving
end)

-- ── Blipek és NPC-k ───────────────────────────────────────────
CreateThread(function()
    for _, dealer in ipairs(Config.Dealerships) do
        -- Blip
        local blip = AddBlipForCoord(dealer.coords.x, dealer.coords.y, dealer.coords.z)
        SetBlipSprite(blip,  dealer.blip.sprite)
        SetBlipColour(blip,  dealer.blip.color)
        SetBlipScale(blip,   dealer.blip.scale or 0.8)
        SetBlipAsShortRange(blip, Config.BlipShortRange)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(dealer.blip.label or dealer.label)
        EndTextCommandSetBlipName(blip)
        dealerBlips[dealer.id] = blip

        -- Eladó NPC
        local npcModel = 's_m_m_cardealer_01'
        local model    = GetHashKey(npcModel)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        local ped = CreatePed(4, model,
            dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0,
            dealer.coords.w, false, true)
        SetEntityHeading(ped, dealer.coords.w)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedDiesWhenInjured(ped, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetModelAsNoLongerNeeded(model)
        dealerNPCs[dealer.id] = ped
    end
end)

-- ── Interakció thread ─────────────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, dealer in ipairs(Config.Dealerships) do
            local dist = #(coords - vector3(dealer.coords.x, dealer.coords.y, dealer.coords.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1,
                    dealer.coords.x, dealer.coords.y, dealer.coords.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 0.6,
                    56, 189, 248, 100,
                    false, true, 2, nil, nil, false
                )
                if dist < Config.ShopRadius then
                    exports['fvg-notify']:Notify({
                        type='info',
                        message='[E] ' .. dealer.label,
                        duration=600, static=true
                    })
                    if IsControlJustPressed(0, 38) and not menuOpen and not isTestDriving then
                        TriggerServerEvent('fvg-autoshop:server:RequestDealership', dealer.id)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Panel megnyitás ──────────────────────────────────────────
RegisterNetEvent('fvg-autoshop:client:OpenDealership', function(data)
    menuOpen    = true
    localVehicles = data.ownedVehicles or {}
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = data })
end)

-- ── Vásárlás visszajelzés ─────────────────────────────────────
RegisterNetEvent('fvg-autoshop:client:PurchaseSuccess', function(data)
    SendNUIMessage({ action = 'purchaseSuccess', data = data })
    -- Jármű spawn a spawn pontnál
    Wait(500)
    SpawnPurchasedVehicle(data)
end)

-- ── Eladás visszajelzés ───────────────────────────────────────
RegisterNetEvent('fvg-autoshop:client:SellSuccess', function(data)
    SendNUIMessage({ action = 'sellSuccess', data = data })
end)

-- ── Részlet visszajelzés ──────────────────────────────────────
RegisterNetEvent('fvg-autoshop:client:InstalmentPaid', function(data)
    SendNUIMessage({ action = 'instalmentPaid', data = data })
end)

-- ── Jármű spawn ───────────────────────────────────────────────
function SpawnPurchasedVehicle(data)
    -- NUI-ban a spawnPoint átjön a payload-ban
    -- Itt spawn nélkül értesítünk, hogy a garage-ban van
    exports['fvg-notify']:Notify({
        type    = 'success',
        title   = '🚗 Garázsban',
        message = 'A járműved a garázs-rendszerben érhető el. Rendszám: ' .. (data.plate or ''),
    })
end

-- ═══════════════════════════════════════════════════════════════
--  TESZTVEZETÉS
-- ═══════════════════════════════════════════════════════════════
function StartTestDrive(model, spawnPoint, timeLimit)
    if isTestDriving then return end

    local vModel = GetHashKey(model)
    RequestModel(vModel)
    while not HasModelLoaded(vModel) do Wait(10) end

    local veh = CreateVehicle(vModel,
        spawnPoint.x, spawnPoint.y, spawnPoint.z,
        spawnPoint.w, true, false)
    SetVehicleNumberPlateText(veh, Config.TestDrivePlate)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(vModel)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)

    isTestDriving  = true
    testDriveVeh   = veh
    testDriveReturn= spawnPoint
    local timeLeft = timeLimit or Config.TestDriveTime

    -- HUD frissítés
    SendNUIMessage({ action = 'testDriveStarted', timeLeft = timeLeft, model = model })

    -- Timer thread
    testDriveTimer = CreateThread(function()
        while isTestDriving and timeLeft > 0 do
            Wait(1000)
            timeLeft = timeLeft - 1
            SendNUIMessage({ action = 'testDriveTick', timeLeft = timeLeft })
            if timeLeft <= 0 then
                EndTestDrive(false)
            end
        end
    end)
end

function EndTestDrive(returned)
    if not isTestDriving then return end
    isTestDriving = false

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
        Wait(1500)
    end

    if testDriveVeh and DoesEntityExist(testDriveVeh) then
        SetEntityAsMissionEntity(testDriveVeh, false, true)
        DeleteVehicle(testDriveVeh)
        testDriveVeh = nil
    end

    if not returned then
        -- Teleport vissza
        local sp = testDriveReturn
        if sp then
            SetEntityCoords(ped, sp.x, sp.y, sp.z + 0.5, false, false, false, false)
        end
        exports['fvg-notify']:Notify({ type='warning', message='Tesztvezetés lejárt.', title='⏱️' })
    end

    TriggerServerEvent('fvg-autoshop:server:TestDriveEnded', 'unknown', returned)
    SendNUIMessage({ action = 'testDriveEnded' })
end

-- ── NUI Callbacks ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyVehicle', function(data, cb)
    TriggerServerEvent('fvg-autoshop:server:BuyVehicle',
        data.model, data.dealershipId, data.paymentMethod,
        data.instalmentOption and tonumber(data.instalmentOption) or nil)
    cb('ok')
end)

RegisterNUICallback('sellVehicle', function(data, cb)
    TriggerServerEvent('fvg-autoshop:server:SellVehicle', data.plate)
    cb('ok')
end)

RegisterNUICallback('payInstalment', function(data, cb)
    TriggerServerEvent('fvg-autoshop:server:PayInstalment',
        tonumber(data.vehicleId), data.paymentMethod)
    cb('ok')
end)

RegisterNUICallback('testDrive', function(data, cb)
    if isTestDriving then cb('already'); return end
    menuOpen = false
    SetNuiFocus(false, false)
    local sp = data.spawnPoint or {}
    StartTestDrive(data.model, vector4(sp.x or 0, sp.y or 0, sp.z or 0, sp.w or 0), data.timeLimit)
    cb('ok')
end)

RegisterNUICallback('endTestDrive', function(_, cb)
    EndTestDrive(true)
    cb('ok')
end)

RegisterNUICallback('previewVehicle', function(data, cb)
    -- Spawn egy preview járművet a spawn pontnál
    local model = GetHashKey(data.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local sp  = data.spawnPoint or {}
    local veh = CreateVehicle(model,
        sp.x or 0, sp.y or 0, sp.z or 0,
        sp.w or 0, false, false)
    SetVehicleNumberPlateText(veh, 'PREVIEW')
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(model)

    -- 10 sec után töröljük
    CreateThread(function()
        Wait(10000)
        if DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, false, true)
            DeleteVehicle(veh)
        end
    end)
    cb('ok')
end)

-- ── Parancs ───────────────────────────────────────────────────
RegisterCommand('autoshop', function()
    if isTestDriving then
        EndTestDrive(true)
    end
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, blip in pairs(dealerBlips) do RemoveBlip(blip) end
    for _, npc  in pairs(dealerNPCs)  do
        if DoesEntityExist(npc) then DeletePed(npc) end
    end
    if testDriveVeh and DoesEntityExist(testDriveVeh) then
        DeleteVehicle(testDriveVeh)
    end
    menuOpen      = false
    isTestDriving = false
end)