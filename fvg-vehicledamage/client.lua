-- ╔══════════════════════════════════════════════╗
-- ║      fvg-vehicledamage :: client             ║
-- ╚══════════════════════════════════════════════╝

local inVehicle      = false
local lastVehicle    = 0
local lastEngineHp   = 1000.0
local lastBodyHp     = 1000.0
local tireStates     = {}       -- [wheelIndex] = burst (bool)
local notifiedThresh = {        -- melyik küszöbön értesítettük már
    engine = {},
    body   = {}
}

-- ── Segédfüggvények ─────────────────────────────────────────

local function Notify(key, ntype)
    if not Config.NotifyIntegration then return end
    exports['fvg-notify']:Notify({
        type    = ntype or 'warning',
        message = Config.Locale[key] or key
    })
end

local function UpdateHUD(enginePct, status)
    if not Config.VehicleHudIntegration then return end
    exports['fvg-vehiclehud']:SetModuleValue('enginehealth', {
        value   = enginePct,
        status  = status,
        visible = true
    })
end

local function GetEngineStatus(hp)
    if hp >= Config.Engine.good    then return 'ok'
    elseif hp >= Config.Engine.warning then return 'ok'
    elseif hp >= Config.Engine.critical then return 'warn'
    else return 'crit' end
end

local function HpToPercent(hp, max)
    return math.max(0, math.min(100, math.floor((hp / max) * 100)))
end

-- ── Küszöb értesítő (csak egyszer szól az adott szintre) ────
local function CheckEngineThresholds(hp)
    for _, threshold in ipairs(Config.NotifyOnThreshold.engine) do
        if hp <= threshold and not notifiedThresh.engine[threshold] then
            notifiedThresh.engine[threshold] = true
            if threshold <= Config.Engine.dead then
                Notify('engine_dead', 'error')
            elseif threshold <= Config.Engine.critical then
                Notify('engine_critical', 'error')
            else
                Notify('engine_warning', 'warning')
            end
        end
        -- Reset ha újra magasabb lett (javítás után)
        if hp > threshold + 50 then
            notifiedThresh.engine[threshold] = false
        end
    end
end

local function CheckBodyThresholds(hp)
    for _, threshold in ipairs(Config.NotifyOnThreshold.body) do
        if hp <= threshold and not notifiedThresh.body[threshold] then
            notifiedThresh.body[threshold] = true
            if threshold <= Config.Body.critical then
                Notify('body_critical', 'error')
            else
                Notify('body_warning', 'warning')
            end
        end
        if hp > threshold + 50 then
            notifiedThresh.body[threshold] = false
        end
    end
end

-- ── Gumi állapot figyelés ────────────────────────────────────
local function CheckTires(vehicle)
    local numWheels = GetVehicleNumberOfWheels(vehicle)
    local count     = math.min(numWheels, Config.MaxWheels)
    local burstNow  = false

    for i = 0, count - 1 do
        local burst = IsVehicleTyreBurst(vehicle, i, false)
        if burst and not tireStates[i] then
            tireStates[i] = true
            burstNow = true
        elseif not burst then
            tireStates[i] = false
        end
    end

    if burstNow then
        Notify('tire_burst', 'error')
    end
end

-- ── Exportok ─────────────────────────────────────────────────

-- Teljes sérülési állapot lekérdezése
exports('GetDamageState', function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

    if not inVeh then
        return { inVehicle = false }
    end

    local engineHp = GetVehicleEngineHealth(vehicle)
    local bodyHp   = GetVehicleBodyHealth(vehicle)
    local numWheels= GetVehicleNumberOfWheels(vehicle)
    local tires    = {}

    for i = 0, math.min(numWheels, Config.MaxWheels) - 1 do
        tires[i] = {
            burst  = IsVehicleTyreBurst(vehicle, i, false),
            health = GetVehicleWheelHealth(vehicle, i)
        }
    end

    return {
        inVehicle    = true,
        engineHealth = engineHp,
        enginePct    = HpToPercent(engineHp, 1000),
        engineStatus = GetEngineStatus(engineHp),
        bodyHealth   = bodyHp,
        bodyPct      = HpToPercent(bodyHp, 1000),
        tires        = tires,
        numWheels    = numWheels,
        isDamaged    = IsVehicleDamaged(vehicle)
    }
end)

-- Teljes javítás
exports('RepairVehicle', function(silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)

    -- Gumijavítás
    local numWheels = GetVehicleNumberOfWheels(vehicle)
    for i = 0, math.min(numWheels, Config.MaxWheels) - 1 do
        SetVehicleTyreFixed(vehicle, i)
        tireStates[i] = false
    end

    -- Reset küszöbök
    notifiedThresh = { engine = {}, body = {} }
    lastEngineHp   = 1000.0
    lastBodyHp     = 1000.0

    -- HUD frissítés
    UpdateHUD(100, 'ok')

    -- Engine visszaindítása ha szükséges
    if Config.EngineIntegration then
        exports['fvg-engine']:SetEngineOn(true, true)
    end

    if not silent then
        Notify('repaired', 'success')
    end

    TriggerServerEvent('fvg-vehicledamage:server:LogRepair', 'full')
end)

-- Motor javítás
exports('RepairEngine', function(silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end

    SetVehicleEngineHealth(vehicle, 1000.0)
    notifiedThresh.engine = {}
    lastEngineHp          = 1000.0
    UpdateHUD(100, 'ok')

    if Config.EngineIntegration then
        exports['fvg-engine']:SetEngineOn(true, true)
    end

    if not silent then Notify('engine_repaired', 'success') end
    TriggerServerEvent('fvg-vehicledamage:server:LogRepair', 'engine')
end)

-- Karosszéria javítás
exports('RepairBody', function(silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end

    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleDeformationFixed(vehicle)
    notifiedThresh.body = {}
    lastBodyHp          = 1000.0

    if not silent then Notify('body_repaired', 'success') end
    TriggerServerEvent('fvg-vehicledamage:server:LogRepair', 'body')
end)

-- Gumijavítás
exports('RepairTires', function(silent)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end

    local numWheels = GetVehicleNumberOfWheels(vehicle)
    for i = 0, math.min(numWheels, Config.MaxWheels) - 1 do
        SetVehicleTyreFixed(vehicle, i)
        tireStates[i] = false
    end

    if not silent then Notify('tire_fixed', 'success') end
end)

-- Motor egészség közvetlen beállítása (fvg-mechanic stb.)
exports('SetEngineHealth', function(value)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end
    local hp = math.max(0, math.min(1000, value))
    SetVehicleEngineHealth(vehicle, hp)
    UpdateHUD(HpToPercent(hp, 1000), GetEngineStatus(hp))
end)

-- Karosszéria egészség közvetlen beállítása
exports('SetBodyHealth', function(value)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) or vehicle == 0 then return end
    local hp = math.max(0, math.min(1000, value))
    SetVehicleBodyHealth(vehicle, hp)
end)

-- ── Szerver esemény: kényszeres javítás (pl. szerelő script) ─
RegisterNetEvent('fvg-vehicledamage:client:RepairVehicle', function(part, silent)
    if part == 'full'   then exports['fvg-vehicledamage']:RepairVehicle(silent) end
    if part == 'engine' then exports['fvg-vehicledamage']:RepairEngine(silent) end
    if part == 'body'   then exports['fvg-vehicledamage']:RepairBody(silent) end
    if part == 'tires'  then exports['fvg-vehicledamage']:RepairTires(silent) end
end)

-- ── Fő figyelő tick ─────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

        -- ── Jármű változás ─────────────────────────────────
        if inVeh and (not inVehicle or vehicle ~= lastVehicle) then
            inVehicle    = true
            lastVehicle  = vehicle
            tireStates   = {}
            notifiedThresh = { engine = {}, body = {} }

            lastEngineHp = GetVehicleEngineHealth(vehicle)
            lastBodyHp   = GetVehicleBodyHealth(vehicle)

            -- Kezdeti HUD frissítés
            local ePct = HpToPercent(lastEngineHp, 1000)
            UpdateHUD(ePct, GetEngineStatus(lastEngineHp))

            TriggerServerEvent('fvg-vehicledamage:server:SyncState',
                lastEngineHp, lastBodyHp)

        elseif not inVeh and inVehicle then
            inVehicle   = false
            lastVehicle = 0
            tireStates  = {}
        end

        -- ── Sérülés figyelés ─────────────────────────────
        if inVeh then
            local engineHp = GetVehicleEngineHealth(vehicle)
            local bodyHp   = GetVehicleBodyHealth(vehicle)

            -- Motor változás
            if math.abs(engineHp - lastEngineHp) > 1 then
                local ePct = HpToPercent(engineHp, 1000)
                UpdateHUD(ePct, GetEngineStatus(engineHp))
                CheckEngineThresholds(engineHp)

                -- Kritikus motor leállítás
                if engineHp <= Config.Engine.dead then
                    if Config.AutoStopEngineOnDead and Config.EngineIntegration then
                        exports['fvg-engine']:SetEngineOn(false, true)
                    end
                end

                TriggerServerEvent('fvg-vehicledamage:server:SyncState',
                    engineHp, bodyHp)
                lastEngineHp = engineHp
            end

            -- Karosszéria változás
            if math.abs(bodyHp - lastBodyHp) > 1 then
                CheckBodyThresholds(bodyHp)
                lastBodyHp = bodyHp
            end

            -- Gumi ellenőrzés
            CheckTires(vehicle)
        end

        Citizen.Wait(Config.TickRate)
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    inVehicle   = false
    tireStates  = {}
end)