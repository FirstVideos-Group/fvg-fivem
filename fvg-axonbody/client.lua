-- ╔══════════════════════════════════════════════════════════════╗
-- ║          fvg-axonbody :: client                              ║
-- ╚══════════════════════════════════════════════════════════════╝

local isActive       = false
local playerJob      = nil
local playerCallsign = nil
local playerFirst    = nil
local playerLast     = nil
local batteryLevel   = Config.BatteryStart
local batteryThread  = nil
local deathThread    = nil

-- ── Segédfüggvények ─────────────────────────────────────────────

local function Notify(msg, ntype)
    TriggerServerEvent('fvg-axonbody:server:Notify', msg, ntype or 'info')
end

local function IsAuthorized()
    if not playerJob then return false end
    for _, j in ipairs(Config.AuthorizedJobs) do
        if playerJob == j then return true end
    end
    return false
end

local function GetOfficerName()
    local first = playerFirst or 'Ismeretlen'
    local last  = playerLast  or ''
    return first .. ' ' .. last
end

local function GetCallsign()
    -- fvg-police callsign
    local ok, off = pcall(function()
        return exports['fvg-police']:GetOfficer(PlayerId())
    end)
    if ok and off and off.callsign and off.callsign ~= '' then
        return off.callsign
    end
    return playerCallsign or ('P-' .. GetPlayerServerId(PlayerId()))
end

local function GetUnit()
    local ok, off = pcall(function()
        return exports['fvg-police']:GetOfficer(PlayerId())
    end)
    if ok and off and off.unit and off.unit ~= '' then
        return off.unit
    end
    return nil
end

local function GetGPS()
    local c = GetEntityCoords(PlayerPedId())
    return string.format('%.0f / %.0f', c.x, c.y)
end

-- ── Kamera effekt ───────────────────────────────────────────────
local function ApplyCamEffect(enable)
    if enable then
        SetTimecycleModifier(Config.TimecycleModifier)
        SetTimecycleModifierStrength(Config.TimecycleStrength)
    else
        ClearTimecycleModifier()
    end
end

-- ── Akkumulátor drain szál ───────────────────────────────────────
local function StartBatteryDrain()
    batteryLevel = Config.BatteryStart
    batteryThread = Citizen.CreateThread(function()
        while isActive do
            Wait(Config.BatteryDrainSec * 1000)
            if not isActive then break end
            batteryLevel = math.max(0, batteryLevel - 1)
            SendNUIMessage({ action = 'battery', level = batteryLevel })
        end
    end)
end

-- ── Halál figyelő ───────────────────────────────────────────────
local function StartDeathWatch()
    if not Config.StopOnDeath then return end
    deathThread = Citizen.CreateThread(function()
        while isActive do
            Wait(1000)
            if IsEntityDead(PlayerPedId()) then
                TriggerEvent('fvg-axonbody:client:Stop')
                Notify(Config.Locale.died, 'warning')
                break
            end
        end
    end)
end

-- ── GPS frissítő szál ───────────────────────────────────────────
local function StartUpdateLoop()
    Citizen.CreateThread(function()
        while isActive do
            Wait(500)
            if not isActive then break end
            SendNUIMessage({
                action = 'update',
                gps    = GetGPS(),
            })
        end
    end)
end

-- ── Kamera indítás ──────────────────────────────────────────────
local function StartBodyCam()
    isActive = true
    ApplyCamEffect(true)

    local callsign = GetCallsign()
    local unit     = GetUnit()
    local name     = GetOfficerName()

    SendNUIMessage({
        action   = 'start',
        name     = name,
        callsign = callsign,
        unit     = unit,
        battery  = batteryLevel,
        gps      = GetGPS(),
    })

    StartBatteryDrain()
    StartDeathWatch()
    StartUpdateLoop()

    if Config.SyncState then
        TriggerServerEvent('fvg-axonbody:server:SyncState', true, callsign)
    end

    Notify(Config.Locale.cam_on, 'success')
end

-- ── Kamera leállítás ────────────────────────────────────────────
local function StopBodyCam(notify)
    isActive = false
    ApplyCamEffect(false)
    SendNUIMessage({ action = 'stop' })

    if Config.SyncState then
        TriggerServerEvent('fvg-axonbody:server:SyncState', false, nil)
    end

    if notify ~= false then
        Notify(Config.Locale.cam_off, 'info')
    end
end

-- ── Toggle ──────────────────────────────────────────────────────
local function ToggleBodyCam()
    if not IsAuthorized() then
        Notify(Config.Locale.not_authorized, 'error')
        return
    end
    if isActive then
        StopBodyCam()
    else
        StartBodyCam()
    end
end

-- ── Parancs ─────────────────────────────────────────────────────
RegisterCommand(Config.Command, function()
    ToggleBodyCam()
end, false)

-- ── Belső stop esemény ──────────────────────────────────────────
AddEventHandler('fvg-axonbody:client:Stop', function()
    if isActive then StopBodyCam(false) end
end)

-- ── Playercore integráció ───────────────────────────────────────
AddEventHandler('fvg-playercore:client:PlayerLoaded', function(player)
    if not player then return end
    local meta      = player.metadata or {}
    playerJob       = meta.job      or 'unemployed'
    playerCallsign  = meta.callsign or nil
    playerFirst     = player.firstname or nil
    playerLast      = player.lastname  or nil
end)

AddEventHandler('fvg-playercore:client:DataUpdated', function(key, value)
    if key == 'job' then
        playerJob = value
        if isActive and not IsAuthorized() then
            TriggerEvent('fvg-axonbody:client:Stop')
        end
    end
    if key == 'callsign'  then playerCallsign = value end
    if key == 'firstname' then playerFirst    = value end
    if key == 'lastname'  then playerLast     = value end
end)

-- ── Kliens exportok ─────────────────────────────────────────────
exports('IsActive', function()
    return isActive
end)

exports('ForceStart', function()
    if not isActive then StartBodyCam() end
end)

exports('ForceStop', function()
    if isActive then StopBodyCam() end
end)

exports('GetOfficerName', function()
    return GetOfficerName()
end)

exports('GetCallsign', function()
    return GetCallsign()
end)

exports('GetBatteryLevel', function()
    return batteryLevel
end)

-- ── Cleanup ─────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isActive then StopBodyCam(false) end
end)
