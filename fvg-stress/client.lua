-- ╔══════════════════════════════════════════════╗
-- ║         fvg-stress :: client                 ║
-- ╚══════════════════════════════════════════════╝

local stress      = 0.0
local isLoaded    = false
local currentLevel  = 'calm'
local lastNotify    = {}
local blurActive    = false
local blurTimer     = 0
local lastCrashSpeed= 0.0
local syncCounter   = 0

-- ── Segédfüggvények ───────────────────────────────────────────

local function Clamp(v)
    return math.max(0.0, math.min(100.0, v))
end

local function GetLevel(value)
    for i = #Config.Levels, 1, -1 do
        local l = Config.Levels[i]
        if value >= l.min then
            return l.name
        end
    end
    return 'calm'
end

local function CanNotify(key)
    local interval = Config.NotifyIntervalMs
    local last     = lastNotify[key] or 0
    return (GetGameTimer() - last) >= interval
end

local function SendNotify(key, ntype)
    if not Config.NotifyIntegration then return end
    if not CanNotify(key) then return end
    lastNotify[key] = GetGameTimer()
    local msg = Config.Locale[key]
    if not msg then return end
    exports['fvg-notify']:Notify({ type = ntype or 'warning', message = msg })
end

-- ── HUD frissítés ─────────────────────────────────────────────
local function UpdateHUD()
    if not Config.HudIntegration then return end
    exports[Config.HudResource]:SetModuleValue(Config.HudModuleName, {
        value   = stress,
        level   = currentLevel,
        visible = isLoaded
    })
end

-- ── Hatások alkalmazása ───────────────────────────────────────
local function ApplyEffects(level)
    local eff = Config.Effects[level]
    if not eff then return end
    local ped = PlayerPedId()

    -- Izzadás
    SetPedSweat(ped, eff.sweat or 0.0)

    -- Kamerarázás
    if eff.shake then
        ShakeGameplayCam(Config.ShakeType, eff.shakePower or 0.0)
    else
        StopGameplayCamShaking(true)
    end

    -- Mozgás sebesség
    if eff.moveRate and eff.moveRate < 1.0 then
        SetPedMoveRateOverride(ped, eff.moveRate)
    else
        SetPedMoveRateOverride(ped, 1.0)
    end

    -- Szívverés hang kritikus szinten
    if eff.heartbeat then
        PlaySoundFrontend(-1, Config.HeartbeatSound, Config.HeartbeatSoundSet, true)
    end
end

-- ── Blur epizód kezelése ──────────────────────────────────────
local function HandleBlur(level)
    local eff = Config.Effects[level]
    if not eff or not eff.blur then
        -- Blur kikapcsolása
        if blurActive then
            TriggerScreenblurFadeOut(Config.BlurFadeTime)
            blurActive = false
        end
        return
    end

    -- Időzített blur epizód
    if not blurActive and (GetGameTimer() - blurTimer) >= Config.BlurInterval then
        blurActive = true
        blurTimer  = GetGameTimer()
        TriggerScreenblurFadeIn(Config.BlurFadeTime)

        Citizen.SetTimeout(Config.BlurDuration, function()
            TriggerScreenblurFadeOut(Config.BlurFadeTime)
            blurActive = false
        end)
    end
end

-- ── Screen tint (vörös árnyalat) ──────────────────────────────
local function HandleTint(level)
    local eff = Config.Effects[level]
    if eff and eff.screenTint then
        -- Enyhe vörös overlay: GTA timecycle modifier
        SetTimecycleModifier('damage')
        local intensity = (stress - 50.0) / 50.0   -- 0–1 arány high/crit tartományban
        SetTimecycleModifierStrength(math.max(0.0, math.min(0.35, intensity * 0.35)))
    else
        ClearTimecycleModifier()
    end
end

-- ── Szint változás kezelése ───────────────────────────────────
local function OnLevelChange(newLevel, oldLevel)
    if newLevel == oldLevel then return end
    currentLevel = newLevel

    -- Értesítés
    if Config.NotifyOnLevelChange then
        local key = 'level_' .. newLevel
        local ntype = newLevel == 'calm'    and 'success'
                   or newLevel == 'mild'    and 'info'
                   or newLevel == 'high'    and 'warning'
                   or 'error'
        SendNotify(key, ntype)
    end

    -- Blur leállítás ha lecsökkent
    if newLevel == 'calm' or newLevel == 'mild' then
        if blurActive then
            TriggerScreenblurFadeOut(Config.BlurFadeTime)
            blurActive = false
        end
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
        SetPedSweat(PlayerPedId(), 0.0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
    end
end

-- ── Stressz módosítás ─────────────────────────────────────────
local function ModifyStress(amount, sync)
    local old   = stress
    stress      = Clamp(stress + amount)
    local lvOld = GetLevel(old)
    local lvNew = GetLevel(stress)

    OnLevelChange(lvNew, lvOld)
    UpdateHUD()

    -- Szerver szinkron ritkítva
    if sync then
        syncCounter = syncCounter + 1
        if syncCounter >= 5 then
            TriggerServerEvent('fvg-stress:server:Sync', stress)
            syncCounter = 0
        end
    end
end

-- ── Exportok ─────────────────────────────────────────────────

exports('GetStress', function()
    return stress
end)

exports('GetStressLevel', function()
    return currentLevel
end)

exports('SetStress', function(value)
    local old = stress
    stress = Clamp(value)
    local lvNew = GetLevel(stress)
    OnLevelChange(lvNew, GetLevel(old))
    UpdateHUD()
    TriggerServerEvent('fvg-stress:server:Sync', stress)
end)

exports('AddStress', function(amount)
    ModifyStress(math.abs(amount), true)
end)

exports('RemoveStress', function(amount)
    ModifyStress(-math.abs(amount), true)
end)

exports('IsLoaded', function()
    return isLoaded
end)

-- ── Szerver szinkron fogadása ─────────────────────────────────
RegisterNetEvent('fvg-stress:client:SetStress', function(value)
    local old  = stress
    stress     = Clamp(value)
    isLoaded   = true
    local lvNew = GetLevel(stress)
    currentLevel = lvNew
    UpdateHUD()
    ApplyEffects(lvNew)
end)

-- ── Automatikus stresszforrások figyelése ─────────────────────
CreateThread(function()
    while not isLoaded do Wait(500) end

    while true do
        Wait(0)
        if not isLoaded then goto continue end

        local ped = PlayerPedId()

        -- Lövöldözés
        if Config.Triggers.shooting.enabled then
            if IsPedShooting(ped) then
                ModifyStress(Config.Triggers.shooting.addAmount * (Config.TickRate / 1000), false)
            end
        end

        -- Körözés
        if Config.Triggers.wanted.enabled then
            local stars = GetPlayerWantedLevel(PlayerId())
            if stars > 0 then
                ModifyStress(Config.Triggers.wanted.addAmount * (Config.TickRate / 1000), false)
            end
        end

        -- Sprint
        if Config.Triggers.sprinting.enabled then
            if IsPedSprinting(ped) then
                ModifyStress(Config.Triggers.sprinting.addAmount * (Config.TickRate / 1000), false)
            end
        end

        -- Autóbaleset
        if Config.Triggers.carCrash.enabled then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) and vehicle ~= 0 then
                local currentSpeed = GetEntitySpeed(vehicle) * 3.6
                if lastCrashSpeed > Config.Triggers.carCrash.minSpeed
                and currentSpeed < lastCrashSpeed * Config.Triggers.carCrash.speedDropRatio then
                    ModifyStress(Config.Triggers.carCrash.addAmount, true)
                end
                lastCrashSpeed = currentSpeed
            else
                lastCrashSpeed = 0.0
            end
        end

        ::continue::
        Wait(Config.TickRate)
    end
end)

-- ── Lövés elszenvedése esemény ────────────────────────────────
AddEventHandler('gameEventTriggered', function(name, args)
    if not isLoaded then return end
    if name == 'CEventNetworkEntityDamage' then
        local victim   = args[1]
        local attacker = args[2]
        local isFatal  = args[6]
        if victim == PlayerPedId() and not isFatal then
            if Config.Triggers.beingShot.enabled then
                ModifyStress(Config.Triggers.beingShot.addAmount, true)
            end
        end
    end
end)

-- ── Fő hatás tick ────────────────────────────────────────────
CreateThread(function()
    while not isLoaded do Wait(500) end

    while true do
        Wait(Config.TickRate)
        if not isLoaded then goto continue end

        local level = GetLevel(stress)

        -- Passzív csökkentés – csak ha nincs aktív stresszforrás
        local ped     = PlayerPedId()
        local inCar   = IsPedInAnyVehicle(ped, false)
        local wanted  = GetPlayerWantedLevel(PlayerId()) > 0
        local shooting= IsPedShooting(ped)

        if not wanted and not shooting then
            ModifyStress(-Config.PassiveDecreaseRate, false)
        end

        -- Szinkron a szervernek 10 tickenként
        syncCounter = syncCounter + 1
        if syncCounter >= 10 then
            TriggerServerEvent('fvg-stress:server:Sync', stress)
            syncCounter = 0
        end

        -- Hatások
        ApplyEffects(level)
        HandleBlur(level)
        HandleTint(level)
        UpdateHUD()

        ::continue::
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    SetPedSweat(ped, 0.0)
    SetPedMoveRateOverride(ped, 1.0)
    StopGameplayCamShaking(true)
    TriggerScreenblurFadeOut(0.5)
    ClearTimecycleModifier()
    isLoaded = false
    stress   = 0.0
end)