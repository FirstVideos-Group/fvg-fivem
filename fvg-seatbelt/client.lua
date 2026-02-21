-- ╔══════════════════════════════════════════════╗
-- ║        fvg-seatbelt :: client                ║
-- ╚══════════════════════════════════════════════╝

local isBelted         = false
local inVehicle        = false
local lastVehicle      = 0
local lastSpeed        = 0.0
local lastBodyHealth   = 1000.0
local crashCooldown    = false
local vehicleVelocity  = vector3(0, 0, 0)
local exitNotifyCooldown = false   -- értesítés spam védelme

-- ── Segédfüggvény: tiltott-e a jármű osztálya ────────────────────
local function IsClassDisabled(vehicle)
    local class = GetVehicleClass(vehicle)
    for _, v in ipairs(Config.DisabledClasses) do
        if v == class then return true end
    end
    return false
end

-- ── Hang lejátszása ─────────────────────────────────────────────────
local function PlayBeltSound(on)
    PlaySoundFrontend(-1,
        on and Config.SoundBuckle or Config.SoundUnbuckle,
        Config.SoundDict,
        true
    )
end

-- ── Notify küldése ────────────────────────────────────────────────────
local function Notify(msgKey, ntype)
    local msg = Config.Locale[msgKey] or msgKey
    if Config.NotifyIntegration then
        exports['fvg-notify']:Notify({
            type    = ntype or 'info',
            message = msg
        })
    end
end

-- ── VehicleHUD frissítése ───────────────────────────────────────────
local function UpdateHUD(state)
    if Config.VehicleHudIntegration then
        exports['fvg-vehiclehud']:SetModuleValue('seatbelt', {
            fastened = state,
            visible  = true
        })
    end
end

-- ── Kiesés végrehajtása ─────────────────────────────────────────────
local function EjectPlayer(vehicle)
    local ped    = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.2, 0.5)

    SetPedToRagdoll(ped, 8000, 8000, 0, false, false, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    Citizen.Wait(50)

    local vel = vehicleVelocity
    SetEntityVelocity(ped,
        vel.x * (3.5 * Config.EjectDamageScale),
        vel.y * (3.5 * Config.EjectDamageScale),
        math.abs(vel.z) + 2.5
    )

    local ejectSpeed = math.floor(lastSpeed * Config.EjectDamageScale)
    local currentHp  = GetEntityHealth(ped)
    local newHp      = currentHp - ejectSpeed

    if newHp > 100 then
        SetEntityHealth(ped, newHp)
    elseif currentHp > 100 then
        SetEntityHealth(ped, 100)
    end

    TriggerServerEvent('fvg-seatbelt:server:LogEject', GetPlayerServerId(PlayerId()), math.floor(lastSpeed))
end

-- ── Kiesés esély számítása ──────────────────────────────────────────
local function ShouldEject(speed, bodyDrop)
    if speed < Config.EjectMinSpeed then return false end
    local chance = math.min(100, (speed * Config.EjectChanceScale) + (bodyDrop * 0.5))
    return math.random(100) <= chance
end

-- ── Öv kapcsolása ─────────────────────────────────────────────────────────
local function ToggleBelt()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        Notify('not_in_veh', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if IsClassDisabled(vehicle) then
        Notify('cant_use', 'warning')
        return
    end

    isBelted = not isBelted
    PlayBeltSound(isBelted)
    UpdateHUD(isBelted)
    Notify(isBelted and 'belted' or 'unbelted', isBelted and 'success' or 'info')
    TriggerServerEvent('fvg-seatbelt:server:SyncBelt', isBelted)
end

-- ── Exportok ───────────────────────────────────────────────────────────
exports('IsBelted', function()
    return isBelted
end)

exports('SetBelted', function(state)
    if type(state) ~= 'boolean' then return end
    if isBelted == state then return end
    isBelted = state
    PlayBeltSound(isBelted)
    UpdateHUD(isBelted)
    TriggerServerEvent('fvg-seatbelt:server:SyncBelt', isBelted)
end)

exports('GetBeltState', function()
    return {
        belted    = isBelted,
        inVehicle = inVehicle,
        speed     = lastSpeed
    }
end)

-- ── Billentyű regisztráció ──────────────────────────────────────────────
RegisterCommand('fvg_togglebelt', function()
    ToggleBelt()
end, false)

RegisterKeyMapping('fvg_togglebelt', Config.KeyLabel, 'keyboard', Config.Key)

-- ── Mások öv változásának kezelése (szinkron) ──────────────────────────
RegisterNetEvent('fvg-seatbelt:client:SyncBelt', function(serverId, state)
    -- Más játékos öv szinkronizálása (pl. animáció, jövőbeli kiterjeszteshez)
end)

-- ── Kiszallás blokk thread ──────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        -- Ha öv be van csatolva és a játékos járműben van
        if isBelted and inVehicle and Config.PreventExitWhenBelted then
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Kiszallási task detektálása: 2 = GET_OUT_OF_VEHICLE task id
            if GetIsTaskActive(ped, 2) then
                -- Task megszakítása + visszahelyezés ülőhelyre
                ClearPedTasks(ped)
                TaskEnterVehicle(ped, vehicle, 2000, GetPedInVehicleSeat(vehicle, -1) ~= ped
                    and GetPedInVehicleSeat(vehicle, 0) == ped and 0 or -1, 2.0, 1, 0)
                -- Seat meghatározás: megkeressük melyik ülőhelyen van
                local seat = -1
                for s = -1, 5 do
                    if GetPedInVehicleSeat(vehicle, s) == ped then
                        seat = s
                        break
                    end
end
                SetPedIntoVehicle(ped, vehicle, seat)

                -- Értesítés spam-védö cooldown-nal
                if not exitNotifyCooldown then
                    exitNotifyCooldown = true
                    Notify('cant_exit', 'warning')
                    Citizen.SetTimeout(3000, function()
                        exitNotifyCooldown = false
                    end)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(300)
        end
    end
end)

-- ── Főtick: kiesés detektálása ─────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

        -- ── Jármű be/ki esemény ───────────────────────────────────
        if inVeh and not inVehicle then
            inVehicle      = true
            lastVehicle    = vehicle
            lastBodyHealth = GetVehicleBodyHealth(vehicle)
            lastSpeed      = 0.0
            UpdateHUD(isBelted)

        elseif not inVeh and inVehicle then
            inVehicle = false
            isBelted  = false
            UpdateHUD(false)
            lastSpeed      = 0.0
            lastBodyHealth = 1000.0
            crashCooldown  = false
        end

        -- ── Ütközés + kiesés logika ─────────────────────────────────
        if inVeh and not crashCooldown then
            local currentSpeed      = GetEntitySpeed(vehicle) * 3.6
            local currentBodyHealth = GetVehicleBodyHealth(vehicle)
            local bodyDrop          = lastBodyHealth - currentBodyHealth

            vehicleVelocity = GetEntityVelocity(vehicle)

            local speedCrash = lastSpeed > Config.EjectMinSpeed
                            and currentSpeed < lastSpeed * Config.CrashSpeedDropRatio
            local bodyCrash  = bodyDrop > Config.MinBodyHealthDrop
                            and lastSpeed > Config.EjectMinSpeed

            if (speedCrash or bodyCrash) and not IsClassDisabled(vehicle) then
                if not isBelted then
                    if ShouldEject(lastSpeed, bodyDrop) then
                        crashCooldown = true
                        EjectPlayer(vehicle)
                        Citizen.SetTimeout(3000, function()
                            crashCooldown  = false
                            lastBodyHealth = 1000.0
                            lastSpeed      = 0.0
                        end)
                    end
                else
                    if lastSpeed > 120 and math.random(100) <= 15 then
                        local curHp  = GetEntityHealth(ped)
                        local damage = math.floor(lastSpeed * 0.1)
                        if curHp - damage > 100 then
                            SetEntityHealth(ped, curHp - damage)
                        end
                    end
                end
            end

            lastBodyHealth = currentBodyHealth
            lastSpeed      = currentSpeed
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        isBelted = false
        UpdateHUD(false)
    end
end)
