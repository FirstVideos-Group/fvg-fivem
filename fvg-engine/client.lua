-- ╔══════════════════════════════════════════════╗
-- ║         fvg-engine :: client                 ║
-- ╚══════════════════════════════════════════════╝

local engineOn      = false
local inVehicle     = false
local lastVehicle   = 0
local isShuttingDown = false

-- ── Segédfüggvények ─────────────────────────────────────────

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

-- ── Motor beállítása ─────────────────────────────────────────
local function SetEngine(vehicle, state, silent)
    if isShuttingDown and state then
        -- Ha leállítás közben próbál indítani, megszakítjuk a leállítást
        isShuttingDown = false
    end

    if state then
        -- Motor indítás
        SetVehicleEngineOn(vehicle, true, false, true)
        engineOn = true
        UpdateHUD(true)
        TriggerServerEvent('fvg-engine:server:Sync', true)

        if not silent then
            PlaySoundFrontend(-1, Config.SoundStart, Config.SoundDict, true)
            Notify('engine_on', 'success')
        end

        -- Speed/RPM modulok visszakapcsolása a vehiclehud-ban
        if Config.VehicleHudIntegration then
            exports['fvg-vehiclehud']:SetModuleValue('speed', {
                value   = 0,
                unit    = 'kmh',
                visible = true
            })
            exports['fvg-vehiclehud']:SetModuleValue('rpm', {
                value   = 0.0,
                redline = false,
                visible = true
            })
        end
    else
        -- Motor leállítás (fokozatos)
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
        UpdateHUD(false)
        TriggerServerEvent('fvg-engine:server:Sync', false)

        if not silent then
            PlaySoundFrontend(-1, Config.SoundStop, Config.SoundDict, true)
            Notify('engine_off', 'info')
        end

        -- Speed/RPM modulok elrejtése
        if Config.VehicleHudIntegration then
            exports['fvg-vehiclehud']:SetModuleValue('speed', {
                value   = 0,
                unit    = 'kmh',
                visible = false
            })
            exports['fvg-vehiclehud']:SetModuleValue('rpm', {
                value   = 0.0,
                redline = false,
                visible = false
            })
        end
    end
end

-- ── Motor toggle ─────────────────────────────────────────────
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

-- ── Exportok ─────────────────────────────────────────────────

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
        engineOn    = engineOn,
        inVehicle   = inVeh,
        isShutting  = isShuttingDown,
        vehicleClass= inVeh and GetVehicleClass(vehicle) or -1
    }
end)

-- ── Billentyűzetkötés ────────────────────────────────────────
RegisterCommand('fvg_toggleengine', function()
    ToggleEngine()
end, false)

RegisterKeyMapping('fvg_toggleengine', Config.KeyLabel, 'keyboard', Config.Key)

-- ── Szerver esemény: más script kér motor műveletet ──────────
RegisterNetEvent('fvg-engine:client:SetEngine', function(state, silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end
    SetEngine(vehicle, state, silent)
end)

-- ── Szinkronizálás fogadása más játékosoktól ─────────────────
RegisterNetEvent('fvg-engine:client:Sync', function(serverId, state)
    -- Jövőbeli kiterjesztéshez (pl. látható animáció más játékosoknál)
end)

-- ── Fő figyelő tick ──────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

        -- ── Járműbe szállás ───────────────────────────────────
        if inVeh and not inVehicle then
            inVehicle   = true
            lastVehicle = vehicle

            local nativeRunning = GetIsVehicleEngineRunning(vehicle)

            if Config.AutoStartOnEnter then
                -- Auto indítás: natív állapot alapján
                if not nativeRunning then
                    SetEngine(vehicle, true, true)
                else
                    engineOn = true
                    UpdateHUD(true)
                end
            else
                -- Kézi mód: szinkronizáljuk a natív állapottal
                engineOn = nativeRunning
                UpdateHUD(nativeRunning)

                -- Ha az auto-start ki van kapcsolva, leállítjuk a natív motort
                if nativeRunning and not Config.AutoStartOnEnter then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    engineOn = false
                    UpdateHUD(false)

                    -- Speed/RPM elrejtése
                    if Config.VehicleHudIntegration then
                        exports['fvg-vehiclehud']:SetModuleValue('speed', { value = 0, unit = 'kmh', visible = false })
                        exports['fvg-vehiclehud']:SetModuleValue('rpm',   { value = 0.0, redline = false, visible = false })
                    end
                end
            end

        -- ── Kiszállás ─────────────────────────────────────────
        elseif not inVeh and inVehicle then
            inVehicle    = false
            isShuttingDown = false

            if Config.AutoStopOnExit and engineOn then
                -- Leállítjuk az előző járművet
                if DoesEntityExist(lastVehicle) then
                    SetVehicleEngineOn(lastVehicle, false, true, true)
                end
                engineOn = false
            end

            lastVehicle = 0
            UpdateHUD(false)
        end

        -- ── Aktív motor védelme: natív ne tudja felülírni ─────
        if inVeh and engineOn then
            -- GTA natív megpróbálja bekapcsolni a motort gáz nyomásra
            -- ezt hagyjuk, mivel mi is bekapcsoltuk
        elseif inVeh and not engineOn and not isShuttingDown then
            -- Ha a natív auto-start megpróbálja bekapcsolni, letiltjuk
            SetVehicleEngineOn(vehicle, false, false, true)
        end

        Citizen.Wait(250)
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    engineOn = false
    isShuttingDown = false
end)