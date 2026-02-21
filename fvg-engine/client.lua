-- ╔══════════════════════════════════════════════╗
-- ║         fvg-engine :: client                 ║
-- ╚══════════════════════════════════════════════╝

local engineOn       = false
local inVehicle      = false
local lastVehicle    = 0
local isShuttingDown = false

-- Járműnként tárolt motorállapot (kliens-local, nincs DB)
-- [networkId] = { engineOn = bool, keepTimer = gameTimer or nil }
local vehicleEngineStates = {}

-- ── Segédfüggvények ──────────────────────────────────────────────

local function IsClassDisabled(vehicle)
    local class = GetVehicleClass(vehicle)
    for _, v in ipairs(Config.DisabledClasses) do
        if v == class then return true end
    end
    return false
end

local function IsDriver(ped, vehicle)
    return GetPedInVehicleSeat(vehicle, -1) == ped
end

local function Notify(key, ntype)
    if not Config.NotifyIntegration then return end
    exports['fvg-notify']:Notify({
        type    = ntype or 'info',
        message = Config.Locale[key] or key
    })
end

local function UpdateHUD(running)
    if not Config.VehicleHudIntegration then return end
    exports['fvg-vehiclehud']:SetModuleValue('engine', {
        running = running,
        visible = true
    })
end

-- Helyi network ID lekérése biztonságosan
local function GetNetId(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    return NetworkGetNetworkIdFromEntity(vehicle)
end

-- ── Motor beállítása ───────────────────────────────────────────────
local function SetEngine(vehicle, state, silent)
    if isShuttingDown and state then
        isShuttingDown = false
    end

    local netId = GetNetId(vehicle)

    if state then
        SetVehicleEngineOn(vehicle, true, false, true)
        engineOn = true
        -- Jármű állapot mentése
        if netId then
            vehicleEngineStates[netId] = { engineOn = true, keepTimer = nil }
        end
        UpdateHUD(true)
        TriggerServerEvent('fvg-engine:server:Sync', true)

        if not silent then
            PlaySoundFrontend(-1, Config.SoundStart, Config.SoundDict, true)
            Notify('engine_on', 'success')
        end

        if Config.VehicleHudIntegration then
            exports['fvg-vehiclehud']:SetModuleValue('speed', { value = 0, unit = 'kmh', visible = true })
            exports['fvg-vehiclehud']:SetModuleValue('rpm',   { value = 0.0, redline = false, visible = true })
        end
    else
        if Config.SlowStart then
            isShuttingDown = true
            SetVehicleEngineOn(vehicle, false, false, true)
            Citizen.SetTimeout(Config.ShutdownDelay, function()
                if isShuttingDown then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    isShuttingDown = false
                end
            end)
        else
            SetVehicleEngineOn(vehicle, false, true, true)
        end

        engineOn = false
        -- Jármű állapot mentése: kiállapítva
        if netId then
            vehicleEngineStates[netId] = { engineOn = false, keepTimer = nil }
        end
        UpdateHUD(false)
        TriggerServerEvent('fvg-engine:server:Sync', false)

        if not silent then
            PlaySoundFrontend(-1, Config.SoundStop, Config.SoundDict, true)
            Notify('engine_off', 'info')
        end

        if Config.VehicleHudIntegration then
            exports['fvg-vehiclehud']:SetModuleValue('speed', { value = 0, unit = 'kmh', visible = false })
            exports['fvg-vehiclehud']:SetModuleValue('rpm',   { value = 0.0, redline = false, visible = false })
        end
    end
end

-- ── Motor toggle ─────────────────────────────────────────────────────
local function ToggleEngine()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) or vehicle == 0 then
        Notify('not_in_veh', 'error')
        return
    end
    if IsClassDisabled(vehicle) then
        Notify('cant_use', 'warning')
        return
    end
    if not IsDriver(ped, vehicle) then
        Notify('not_driver', 'warning')
        return
    end

    if engineOn then
        SetEngine(vehicle, false)
    else
        SetEngine(vehicle, true)
    end
end

-- ── Exportok ──────────────────────────────────────────────────────────

exports('IsEngineOn', function()
    return engineOn
end)

exports('SetEngineOn', function(state, silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end
    if engineOn == state then
        Notify(state and 'already_on' or 'already_off', 'warning')
        return
    end
    SetEngine(vehicle, state, silent or false)
end)

exports('GetEngineState', function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0
    return {
        engineOn     = engineOn,
        inVehicle    = inVeh,
        isShutting   = isShuttingDown,
        vehicleClass = inVeh and GetVehicleClass(vehicle) or -1
    }
end)

-- ── Billentyűzetekötés ────────────────────────────────────────────────
RegisterCommand('fvg_toggleengine', function()
    ToggleEngine()
end, false)

RegisterKeyMapping('fvg_toggleengine', Config.KeyLabel, 'keyboard', Config.Key)

-- ── Szerver esemény ─────────────────────────────────────────────────────
RegisterNetEvent('fvg-engine:client:SetEngine', function(state, silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end
    SetEngine(vehicle, state, silent)
end)

RegisterNetEvent('fvg-engine:client:Sync', function(serverId, state)
    -- Jövőbeli kiterjesztéshez
end)

-- ──────────────────────────────────────────────────────────────
--  FŐ FIGYELŐ TICK
-- ──────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

        -- ── Járműbe szállás ─────────────────────────────────────
        if inVeh and not inVehicle then
            inVehicle   = true
            lastVehicle = vehicle
            local netId = GetNetId(vehicle)

            -- Előzőleg elmentett állapot van-e?
            local savedState = netId and vehicleEngineStates[netId]

            if savedState then
                -- Visszatérés: alkalmazzuk az elmentett állapotot
                if savedState.engineOn then
                    SetVehicleEngineOn(vehicle, true, false, true)
                    engineOn = true
                    UpdateHUD(true)
                    if Config.VehicleHudIntegration then
                        exports['fvg-vehiclehud']:SetModuleValue('speed', { value = 0, unit = 'kmh', visible = true })
                        exports['fvg-vehiclehud']:SetModuleValue('rpm',   { value = 0.0, redline = false, visible = true })
                    end
                else
                    SetVehicleEngineOn(vehicle, false, true, true)
                    engineOn = false
                    UpdateHUD(false)
                end
            elseif Config.AutoStartOnEnter then
                local nativeRunning = GetIsVehicleEngineRunning(vehicle)
                if not nativeRunning then
                    SetEngine(vehicle, true, true)
                else
                    engineOn = true
                    UpdateHUD(true)
                end
            else
                -- Isméretlen jármű, kézi mód
                local nativeRunning = GetIsVehicleEngineRunning(vehicle)
                engineOn = nativeRunning
                UpdateHUD(nativeRunning)
                if nativeRunning then
                    -- Ha natív motor fut és kezéli módban vagyunk, leállítjuk
                    SetVehicleEngineOn(vehicle, false, true, true)
                    engineOn = false
                    UpdateHUD(false)
                    if Config.VehicleHudIntegration then
                        exports['fvg-vehiclehud']:SetModuleValue('speed', { value = 0, unit = 'kmh', visible = false })
                        exports['fvg-vehiclehud']:SetModuleValue('rpm',   { value = 0.0, redline = false, visible = false })
                    end
                end
            end

        -- ── Kiszállás ─────────────────────────────────────────
        elseif not inVeh and inVehicle then
            inVehicle      = false
            isShuttingDown = false
            local netId    = GetNetId(lastVehicle)

            if Config.KeepEngineOnExit and engineOn then
                -- Motor állapotát mentjük: futva marad
                if netId then
                    vehicleEngineStates[netId] = {
                        engineOn  = true,
                        keepTimer = Config.KeepEngineTimeout > 0
                                    and (GetGameTimer() + Config.KeepEngineTimeout)
                                    or nil
                    }
                end
                -- Motor erősen futva tartva (natív GTA ne állítsa le)
                if DoesEntityExist(lastVehicle) then
                    SetVehicleEngineOn(lastVehicle, true, false, true)
                end
            elseif Config.AutoStopOnExit and engineOn then
                if DoesEntityExist(lastVehicle) then
                    SetVehicleEngineOn(lastVehicle, false, true, true)
                end
                if netId then
                    vehicleEngineStates[netId] = { engineOn = false, keepTimer = nil }
                end
                engineOn = false
            else
                -- Sem AutoStop, sem KeepEngine: állapot mentése az aktuális értékkel
                if netId then
                    vehicleEngineStates[netId] = { engineOn = engineOn, keepTimer = nil }
                end
            end

            engineOn    = false
            lastVehicle = 0
            UpdateHUD(false)
        end

        -- ── Aktív motor védelme (járműben) ─────────────────────────
        if inVeh and not engineOn and not isShuttingDown then
            SetVehicleEngineOn(vehicle, false, false, true)
        end

        Citizen.Wait(250)
    end
end)

-- ──────────────────────────────────────────────────────────────
--  KÜLSŐ MOTOR FENNTARTÓ TICK (jármű nélkül)
--  Ha a játékos kiszallt és KeepEngineOnExit = true,
--  ez a thread erősíti a motor futva maradását
--  (a GTA natív engine management megpróbálja leallitani)
-- ──────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(Config.EngineKeepTickRate)

        if not Config.KeepEngineOnExit then goto continue end

        local now = GetGameTimer()
        for netId, state in pairs(vehicleEngineStates) do
            if state.engineOn then
                -- Időzítő lejárt?
                if state.keepTimer and now > state.keepTimer then
                    -- Motor leállítása: idő lejárt
                    local veh = NetworkGetEntityFromNetworkId(netId)
                    if DoesEntityExist(veh) and veh ~= 0 then
                        SetVehicleEngineOn(veh, false, true, true)
                    end
                    vehicleEngineStates[netId] = { engineOn = false, keepTimer = nil }
                else
                    -- Motor erősítése
                    local veh = NetworkGetEntityFromNetworkId(netId)
                    if DoesEntityExist(veh) and veh ~= 0 then
                        -- Csak ha nincs benne vezétő (ne piszkaljuk más játékos motorját)
                        local driver = GetPedInVehicleSeat(veh, -1)
                        local isOccupied = DoesEntityExist(driver)
                            and driver ~= 0
                            and not IsEntityDead(driver)
                        if not isOccupied then
                            SetVehicleEngineOn(veh, true, false, true)
                        end
                    else
                        -- Jármű már nem létezik: állapot tisztitása
                        vehicleEngineStates[netId] = nil
                    end
                end
            end
        end

        ::continue::
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    engineOn       = false
    isShuttingDown = false
    vehicleEngineStates = {}
end)
