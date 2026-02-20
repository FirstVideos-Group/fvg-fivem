-- ╔══════════════════════════════════════════════╗
-- ║         fvg-courier :: client                ║
-- ╚══════════════════════════════════════════════╝

local onDuty        = false
local activeRun     = nil   -- { runId, spots, currentIdx, timeLimit, totalReward }
local runTimer      = nil
local timeLeft      = 0
local courierVeh    = nil
local depotBlip     = nil
local deliveryBlip  = nil
local menuOpen      = false

-- ── Kliens exportok ───────────────────────────────────────────
exports('IsOnDuty', function() return onDuty end)
exports('GetLocalDelivery', function() return activeRun end)

-- ── Depot blip ────────────────────────────────────────────────
CreateThread(function()
    depotBlip = AddBlipForCoord(
        Config.DepotLocation.coords.x,
        Config.DepotLocation.coords.y,
        Config.DepotLocation.coords.z
    )
    SetBlipSprite(depotBlip, Config.DepotLocation.blipSprite)
    SetBlipColour(depotBlip, Config.DepotLocation.blipColor)
    SetBlipScale(depotBlip, 0.85)
    SetBlipAsShortRange(depotBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.DepotLocation.blipLabel)
    EndTextCommandSetBlipName(depotBlip)
end)

-- ── Depot marker és interakció ────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local depot  = Config.DepotLocation.coords
        local dist   = #(coords - vector3(depot.x, depot.y, depot.z))

        if dist < 30.0 then
            sleep = 0
            DrawMarker(Config.DepotLocation.markerType,
                depot.x, depot.y, depot.z - 0.9,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.5, 1.5, 0.6,
                245, 158, 11, 130,
                false, true, 2, nil, nil, false
            )

            if dist < 2.0 then
                local hint = onDuty
                    and (activeRun and '[E] Futár panel  [G] Kör lemondása' or '[E] Futár panel  [F] Kör indítása')
                    or '[E] Munkába lépés'
                exports['fvg-notify']:Notify({ type='info', message=hint, duration=600, static=true })

                if IsControlJustPressed(0, 38) then -- E
                    if not onDuty then
                        TriggerServerEvent('fvg-courier:server:ToggleDuty')
                    else
                        if not menuOpen then
                            TriggerServerEvent('fvg-courier:server:RequestPanel')
                        end
                    end
                end

                if onDuty and not activeRun and IsControlJustPressed(0, 23) then -- F
                    TriggerServerEvent('fvg-courier:server:StartRun')
                end

                if onDuty and activeRun and IsControlJustPressed(0, 47) then -- G
                    TriggerServerEvent('fvg-courier:server:CancelRun')
                    CleanupRun()
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Kézbesítési pont marker ───────────────────────────────────
CreateThread(function()
    while true do
        local sleep = 500
        if activeRun then
            sleep = 0
            local spot   = activeRun.spots[activeRun.currentIdx]
            if spot and not spot.done then
                local ped    = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local dist   = #(coords - vector3(spot.coords.x, spot.coords.y, spot.coords.z))

                DrawMarker(1,
                    spot.coords.x, spot.coords.y, spot.coords.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.2, 1.2, 0.6,
                    56, 189, 248, 150,
                    false, true, 2, nil, nil, false
                )

                if dist < Config.DeliveryRadius then
                    exports['fvg-notify']:Notify({
                        type='info', message='[E] Csomag kézbesítése – ' .. spot.label,
                        duration=600, static=true
                    })

                    if IsControlJustPressed(0, 38) then
                        DeliverPackage()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Időmérő ──────────────────────────────────────────────────
function StartRunTimer(limit)
    timeLeft = limit
    if runTimer then return end
    runTimer = CreateThread(function()
        while activeRun and timeLeft > 0 do
            Wait(1000)
            timeLeft = timeLeft - 1
            SendNUIMessage({ action = 'timerTick', timeLeft = timeLeft })
            if timeLeft <= 0 then
                TriggerServerEvent('fvg-courier:server:RunTimeout')
                CleanupRun()
            end
        end
        runTimer = nil
    end)
end

-- ── Kézbesítési animáció ──────────────────────────────────────
function DeliverPackage()
    if not activeRun then return end
    local spotIdx      = activeRun.currentIdx
    local spot         = activeRun.spots[spotIdx]
    local deliveryStart= GetGameTimer()

    -- Animáció
    local ped = PlayerPedId()
    RequestAnimDict(Config.DeliveryAnim.dict)
    while not HasAnimDictLoaded(Config.DeliveryAnim.dict) do Wait(10) end
    TaskPlayAnim(ped, Config.DeliveryAnim.dict, Config.DeliveryAnim.anim,
        3.0, -3.0, Config.DeliveryAnim.duration, 1, 0, false, false, false)
    Wait(Config.DeliveryAnim.duration)
    ClearPedTasks(ped)

    local deliveryTime = math.floor((GetGameTimer() - deliveryStart) / 1000)
    -- Tényleges idő = timeLimit - timeLeft
    local totalDeliveryTime = Config.DeliveryTimeLimit - timeLeft

    TriggerServerEvent('fvg-courier:server:DeliverPackage', spotIdx, totalDeliveryTime)
end

-- ── Cleanup ───────────────────────────────────────────────────
function CleanupRun()
    activeRun = nil
    if runTimer then runTimer = nil end
    RemoveDeliveryBlip()
    SendNUIMessage({ action = 'runEnded' })
end

function SetDeliveryBlip(spot)
    RemoveDeliveryBlip()
    deliveryBlip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
    SetBlipSprite(deliveryBlip, 478)
    SetBlipColour(deliveryBlip, 5)
    SetBlipScale(deliveryBlip, 0.9)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('📦 ' .. spot.label)
    EndTextCommandSetBlipName(deliveryBlip)
end

function RemoveDeliveryBlip()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

-- ── Jármű spawn ───────────────────────────────────────────────
function SpawnCourierVehicle(cb)
    local depot  = Config.DepotLocation.coords
    local offset = Config.CourierVehicle.spawnOffset
    local spawnX = depot.x + offset.x
    local spawnY = depot.y + offset.y
    local spawnZ = depot.z + offset.z

    local model  = GetHashKey(Config.CourierVehicle.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local veh = CreateVehicle(model, spawnX, spawnY, spawnZ,
        Config.CourierVehicle.heading, true, false)
    SetVehicleNumberPlateText(veh, Config.CourierVehicle.plate)
    SetEntityAsMissionEntity(veh, true, true)
    courierVeh = veh

    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) end
end

function DeleteCourierVehicle()
    if courierVeh and DoesEntityExist(courierVeh) then
        SetEntityAsMissionEntity(courierVeh, false, true)
        DeleteVehicle(courierVeh)
        courierVeh = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--  SZERVER EVENTEK FOGADÁSA
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('fvg-courier:client:ToggleDuty', function(stats)
    onDuty = not onDuty

    if onDuty then
        -- Jármű spawn
        SpawnCourierVehicle(function(veh)
            local ped = PlayerPedId()
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end)
        exports['fvg-notify']:Notify({ type='success', message='Munkába léptél! Menj a depot-hoz egy kör indításához.', title='🚴 Futár' })
        SendNUIMessage({ action = 'setDuty', onDuty=true, stats=stats })
    else
        if Config.DeleteVehicleOnDutyEnd then DeleteCourierVehicle() end
        SendNUIMessage({ action = 'setDuty', onDuty=false })
        exports['fvg-notify']:Notify({ type='info', message='Munkából kilépve.' })
    end
end)

RegisterNetEvent('fvg-courier:client:RunStarted', function(data)
    activeRun = data
    local firstSpot = data.spots[1]
    SetDeliveryBlip(firstSpot)
    StartRunTimer(data.timeLimit)

    SendNUIMessage({ action = 'runStarted', data = data })
    exports['fvg-notify']:Notify({
        type='warning', title='📦 Kör indult',
        message='Első helyszín: ' .. firstSpot.label
    })
end)

RegisterNetEvent('fvg-courier:client:PackageDelivered', function(data)
    -- Lokális frissítés
    if activeRun then
        activeRun.spots[data.spotIdx].done = true
        activeRun.currentIdx               = data.nextIdx
        activeRun.totalReward              = data.totalReward
    end

    -- Blip frissítés
    SetDeliveryBlip(data.nextSpot)

    -- UI frissítés
    SendNUIMessage({ action = 'packageDelivered', data = data })

    -- Értesítés
    local bonusText = ''
    for _, b in ipairs(data.bonuses or {}) do
        bonusText = bonusText .. ' ' .. b.label .. ' +$' .. b.amount
    end
    exports['fvg-notify']:Notify({
        type='success', title='✅ Kézbesítve',
        message='$' .. data.reward .. bonusText .. ' | Következő: ' .. data.nextSpot.label
    })
end)

RegisterNetEvent('fvg-courier:client:RunCompleted', function(data)
    CleanupRun()
    SendNUIMessage({ action = 'runCompleted', data = data })
    -- Részletes összefoglaló panel
    Wait(500)
    TriggerServerEvent('fvg-courier:server:RequestPanel')
end)

RegisterNetEvent('fvg-courier:client:RunCancelled', function(data)
    CleanupRun()
    SendNUIMessage({ action = 'runCancelled' })
end)

RegisterNetEvent('fvg-courier:client:LevelUp', function(levelData)
    exports['fvg-notify']:Notify({
        type='success', title='🏆 Szint emelkedés!',
        message='Elérted: ' .. levelData.label .. ' | Jutalom szorzó: x' .. levelData.rewardMult
    })
    SendNUIMessage({ action = 'levelUp', levelData = levelData })
end)

RegisterNetEvent('fvg-courier:client:OpenPanel', function(data)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openPanel', data = data })
end)

-- ── NUI Callbacks ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startRun', function(_, cb)
    TriggerServerEvent('fvg-courier:server:StartRun')
    cb('ok')
end)

RegisterNUICallback('cancelRun', function(_, cb)
    TriggerServerEvent('fvg-courier:server:CancelRun')
    CleanupRun()
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('fvg-courier:server:ToggleDuty')
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if data.x and data.y then SetNewWaypoint(data.x, data.y) end
    cb('ok')
end)

-- ── Parancs ───────────────────────────────────────────────────
RegisterCommand('courier', function()
    if not onDuty then return end
    TriggerServerEvent('fvg-courier:server:RequestPanel')
end, false)

RegisterKeyMapping('courier', 'Futár panel megnyitása', 'keyboard', 'F5')

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    RemoveDeliveryBlip()
    if depotBlip then RemoveBlip(depotBlip) end
    DeleteCourierVehicle()
    onDuty   = false
    activeRun= nil
    menuOpen = false
end)