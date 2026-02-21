-- ╔══════════════════════════════════════════════════════════════╗
-- ║          fvg-axondash :: client                              ║
-- ╚══════════════════════════════════════════════════════════════╝

local isActive      = false
local playerJob     = nil
local playerCallsign= nil
local watchThread   = nil

-- ── Segédfüggvények ─────────────────────────────────────────────

local function Notify(msg, ntype)
    TriggerServerEvent('fvg-axondash:server:Notify', msg, ntype or 'info')
end

local function IsAuthorized()
    if not playerJob then return false end
    for _, j in ipairs(Config.AuthorizedJobs) do
        if playerJob == j then return true end
    end
    return false
end

local function IsEmergencyVehicle(veh)
    if #Config.EmergencyModels == 0 then return true end
    local model = GetEntityModel(veh)
    for _, m in ipairs(Config.EmergencyModels) do
        if model == GetHashKey(m) then return true end
    end
    return false
end

local function GetUnitLabel()
    -- fvg-police callsign lekérdezése ha elérhető
    local ok, off = pcall(function()
        return exports['fvg-police']:GetOfficer(PlayerId())
    end)
    if ok and off and off.callsign and off.callsign ~= '' then
        return off.callsign
    end
    return playerCallsign or ('P-' .. GetPlayerServerId(PlayerId()))
end

local function GetSpeedKmh(veh)
    return math.floor(GetEntitySpeed(veh) * 3.6)
end

local function GetGPSCoords()
    local c = GetEntityCoords(PlayerPedId())
    return string.format('%.0f / %.0f', c.x, c.y)
end

-- ── Kamera effekt (szín + vinyette) ─────────────────────────────
-- A NUI-n keresztül törtnik, de a Citizen oldalon
-- a SetTimecycleModifier adja az igazi kamera-hatást
local function ApplyCamEffect(enable)
    if enable then
        SetTimecycleModifier('camera_security_BORED')
        SetTimecycleModifierStrength(0.55)
    else
        ClearTimecycleModifier()
    end
end

-- ── NUI szinkron ────────────────────────────────────────────────
local function SyncNUI(data)
    SendNUIMessage(data)
end

-- ── Kamera indítás ──────────────────────────────────────────────
local function StartDashCam()
    isActive = true
    ApplyCamEffect(true)
    SyncNUI({ action = 'start', unit = GetUnitLabel() })

    -- Autó / játékidő / koordináta valós idejű frissítés
    watchThread = Citizen.CreateThread(function()
        while isActive do
            Wait(500)

            local ped = PlayerPedId()

            -- Kilép a járműből → automatikus stop
            if Config.StopOnExit and not IsPedInAnyVehicle(ped, false) then
                TriggerEvent('fvg-axondash:client:Stop')
                Notify(Config.Locale.exited_vehicle, 'warning')
                break
            end

            local veh    = GetVehiclePedIsIn(ped, false)
            local speed  = veh ~= 0 and GetSpeedKmh(veh) or 0
            local gps    = GetGPSCoords()
            local gh, gm = GetClockHours(), GetClockMinutes()

            SyncNUI({
                action   = 'update',
                speed    = speed,
                gps      = gps,
                gameHour = gh,
                gameMin  = gm,
            })
        end
    end)

    Notify(Config.Locale.cam_on, 'success')
end

-- ── Kamera leállítás ────────────────────────────────────────────
local function StopDashCam(notify)
    isActive = false
    ApplyCamEffect(false)
    SyncNUI({ action = 'stop' })
    if notify ~= false then
        Notify(Config.Locale.cam_off, 'info')
    end
end

-- ── Toggle ──────────────────────────────────────────────────────
local function ToggleDashCam()
    if not IsAuthorized() then
        Notify(Config.Locale.not_authorized, 'error')
        return
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        Notify(Config.Locale.not_in_vehicle, 'warning')
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    -- Csak sofőr
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        Notify(Config.Locale.not_in_vehicle, 'warning')
        return
    end

    if not IsEmergencyVehicle(veh) then
        Notify(Config.Locale.not_emergency_veh, 'error')
        return
    end

    if isActive then
        StopDashCam()
    else
        StartDashCam()
    end

    -- Szerveroldali szinkron
    if Config.SyncState then
        TriggerServerEvent('fvg-axondash:server:SyncState', isActive)
    end
end

-- ── Parancs regisztráció ────────────────────────────────────────
RegisterCommand(Config.Command, function()
    ToggleDashCam()
end, false)

-- ── Belső leállítás esemény ─────────────────────────────────────
AddEventHandler('fvg-axondash:client:Stop', function()
    if isActive then StopDashCam(false) end
end)

-- ── Playercore integráció ───────────────────────────────────────
AddEventHandler('fvg-playercore:client:PlayerLoaded', function(player)
    playerJob     = player and player.metadata and player.metadata.job or 'unemployed'
    playerCallsign= player and player.metadata and player.metadata.callsign or nil
end)

AddEventHandler('fvg-playercore:client:DataUpdated', function(key, value)
    if key == 'job'      then playerJob      = value end
    if key == 'callsign' then playerCallsign = value end
    -- Ha megváltoztatják a job-ot és aktív → leállítás
    if key == 'job' and isActive and not IsAuthorized() then
        TriggerEvent('fvg-axondash:client:Stop')
    end
end)

-- ── Kliens exportok ─────────────────────────────────────────────
exports('IsActive', function()
    return isActive
end)

exports('ForceStart', function()
    if not isActive then StartDashCam() end
end)

exports('ForceStop', function()
    if isActive then StopDashCam() end
end)

exports('GetUnitLabel', function()
    return GetUnitLabel()
end)

-- ── Cleanup ─────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isActive then StopDashCam(false) end
end)
