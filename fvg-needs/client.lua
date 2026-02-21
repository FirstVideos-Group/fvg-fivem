-- ╔══════════════════════════════════════════════╗
-- ║         fvg-needs :: client                  ║
-- ╚══════════════════════════════════════════════╝

local needs = {
    food  = 100.0,
    water = 100.0,
}
local isLoaded         = false
local lastNotify       = {}
local activeEffects    = {}
local originalMoveClip = nil

-- ── Segédfüggvények ────────────────────────────────────────────────

local function Clamp(v)
    return math.max(0.0, math.min(100.0, v))
end

local function GetNeedLevel(needName, value)
    local cfg = Config.Needs[needName]
    if not cfg then return 'ok' end
    if value <= cfg.deadThreshold then return 'dead' end
    if value <= cfg.critThreshold then return 'crit' end
    if value <= cfg.warnThreshold then return 'warn' end
    return 'ok'
end

local function CanNotify(key)
    local interval = Config.NotifyIntervalMs
    local last     = lastNotify[key] or 0
    return (GetGameTimer() - last) >= interval
end

local function SendNotify(needName, level)
    if not Config.NotifyIntegration then return end
    if not CanNotify(needName .. level) then return end
    lastNotify[needName .. level] = GetGameTimer()
    local key = needName .. '_' .. level
    local msg = Config.Locale[key]
    if not msg then return end
    local ntype = (level == 'dead' or level == 'crit') and 'error' or 'warning'
    exports['fvg-notify']:Notify({ type = ntype, message = msg })
end

-- ── HUD frissítés ───────────────────────────────────────────────────
-- FIX: külön SetModuleValue hívás food és water modulra
local function UpdateHUD()
    if not Config.HudIntegration then return end
    local hud = Config.HudResource

    exports[hud]:SetModuleValue(Config.HudFoodModuleName, {
        value   = needs.food,
        level   = GetNeedLevel('food', needs.food),
        visible = isLoaded,
    })

    exports[hud]:SetModuleValue(Config.HudWaterModuleName, {
        value   = needs.water,
        level   = GetNeedLevel('water', needs.water),
        visible = isLoaded,
    })
end

-- ── Vizuális hatások kezelése ─────────────────────────────────────
local function ApplyEffects()
    local ped = PlayerPedId()
    for needName, cfg in pairs(Config.Needs) do
        local value  = needs[needName]
        local level  = GetNeedLevel(needName, value)
        local prev   = activeEffects[needName] or 'ok'
        if level == prev then goto continue end
        activeEffects[needName] = level

        local eff = cfg.effects[level] or {}

        local anySweat = false
        for _, cfg2 in pairs(Config.Needs) do
            local l2 = GetNeedLevel(needName, needs[needName])
            local e2 = cfg2.effects[l2] or {}
            if e2.sweat then anySweat = true end
        end
        SetPedSweat(ped, anySweat and Config.SweatIntensity or 0.0)

        if eff.movement then
            SetPedMovementClipset(ped, Config.HungryMoveClip, 1.0)
        else
            local anyMovement = false
            for n2, cfg2 in pairs(Config.Needs) do
                local l2 = GetNeedLevel(n2, needs[n2])
                local e2 = cfg2.effects[l2] or {}
                if e2.movement then anyMovement = true end
            end
            if not anyMovement then ResetPedMovementClipset(ped, 1.0) end
        end

        if level ~= 'ok' then SendNotify(needName, level) end
        ::continue::
    end
end

local function DrawScreenEffect()
    local anyEff = false
    for needName, cfg in pairs(Config.Needs) do
        local level = GetNeedLevel(needName, needs[needName])
        local eff   = cfg.effects[level] or {}
        if eff.screen then anyEff = true end
    end
    if anyEff then
        if not IsScreenEffectActive('SwitchHUDIn') then
            StartScreenEffect('DeathFailOut', 0, true)
        end
    else
        StopScreenEffect('DeathFailOut')
    end
end

local function ApplyStarveDamage()
    local ped = PlayerPedId()
    for needName, cfg in pairs(Config.Needs) do
        local level = GetNeedLevel(needName, needs[needName])
        local eff   = cfg.effects[level] or {}
        if eff.damage then
            local hp = GetEntityHealth(ped)
            if hp > 100 then SetEntityHealth(ped, hp - Config.StarveDamage) end
        end
    end
end

-- ── Exportok ───────────────────────────────────────────────────────────

exports('GetNeeds', function()
    return { food = needs.food, water = needs.water }
end)

exports('GetNeed', function(name)
    return needs[name]
end)

exports('SetNeed', function(name, value)
    if needs[name] == nil then return false end
    needs[name] = Clamp(value)
    UpdateHUD()
    ApplyEffects()
    TriggerServerEvent('fvg-needs:server:Sync', needs.food, needs.water)
    return true
end)

exports('ModifyNeed', function(name, amount)
    if needs[name] == nil then return false end
    needs[name] = Clamp(needs[name] + amount)
    UpdateHUD()
    ApplyEffects()
    TriggerServerEvent('fvg-needs:server:Sync', needs.food, needs.water)
    return true
end)

exports('IsLoaded', function()
    return isLoaded
end)

-- ── Szerver szinkron fogadása ────────────────────────────────────
RegisterNetEvent('fvg-needs:client:SetNeeds', function(data)
    needs.food  = Clamp(data.food  or 100.0)
    needs.water = Clamp(data.water or 100.0)
    isLoaded    = true
    activeEffects = {}
    UpdateHUD()
    ApplyEffects()
end)

-- ── Fő csökkenési tick ──────────────────────────────────────────────────
CreateThread(function()
    while not isLoaded do Wait(500) end

    while true do
        Wait(Config.TickRate)
        if not isLoaded then goto continue end

        local ped    = PlayerPedId()
        local isIdle = IsPedStill(ped)
        local inVeh  = IsPedInAnyVehicle(ped, false)

        for needName, cfg in pairs(Config.Needs) do
            local rate
            if inVeh then
                rate = cfg.idleRate * 0.5
            elseif isIdle then
                rate = cfg.idleRate
            else
                rate = cfg.decreaseRate
            end
            needs[needName] = Clamp(needs[needName] - rate)
        end

        local syncCounter = (syncCounter or 0) + 1
        if syncCounter >= 10 then
            TriggerServerEvent('fvg-needs:server:Sync', needs.food, needs.water)
            syncCounter = 0
        end

        UpdateHUD()
        ApplyEffects()
        DrawScreenEffect()
        ApplyStarveDamage()

        ::continue::
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    SetPedSweat(ped, 0.0)
    ResetPedMovementClipset(ped, 1.0)
    StopScreenEffect('DeathFailOut')
    isLoaded = false
    needs    = { food = 100.0, water = 100.0 }
end)
