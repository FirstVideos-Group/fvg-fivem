-- ╔══════════════════════════════════════════════╗
-- ║       fvg-traffipax :: client               ║
-- ╚══════════════════════════════════════════════╝

local isLoaded       = false
local zoneStates     = {}   -- [zoneId] = bool (override)
local lastWarned     = {}   -- [zoneId] = GetGameTimer()
local lastFineLocal  = 0    -- GetGameTimer() alapon loklális cooldown

-- ── Betltöés ──────────────────────────────────────────────────
AddEventHandler('fvg-playercore:client:PlayerLoaded', function()
    isLoaded = true
    -- Zónák NUI-ba küldése (térkép jelzők, ha lesz)
    SendNUIMessage({ action = 'setZones', zones = Config.Zones })
end)

-- ── Segédfüggvény: jármű sebessége km/h ────────────────────────
-- GetEntitySpeed() m/s-ben ad vissza → *3.6 = km/h
local function GetSpeedKmh(entity)
    return GetEntitySpeed(entity) * 3.6
end

local function GetVehiclePlate(veh)
    return GetVehicleNumberPlateText(veh) or 'N/A'
end

local function IsZoneEnabled(zone)
    if zoneStates[zone.id] == false then return false end
    return zone.enabled ~= false
end

local function Dist(c1, c2)
    local dx = c1.x - c2.x
    local dy = c1.y - c2.y
    local dz = (c1.z or 0) - (c2.z or 0)
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- ── Fő sebesség-ellenőrző szál ─────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        if not isLoaded then goto continue end

        local ped = PlayerPedId()
        -- Csak járműben ellenőrzünk
        if not IsPedInAnyVehicle(ped, false) then goto continue end
        -- Csak ha a játékos vezérlő
        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) ~= ped then goto continue end

        local coords = GetEntityCoords(ped)
        local speed  = GetSpeedKmh(veh)

        for _, zone in ipairs(Config.Zones) do
            if not IsZoneEnabled(zone) then goto nextZone end

            local zc   = zone.coords
            local dist = Dist(coords, zc)

            -- Közeledik a zónához – figyelmeztetes (warn range-en belül)
            if dist <= Config.WarnRange and dist > zone.range then
                local now = GetGameTimer()
                if not lastWarned[zone.id] or (now - lastWarned[zone.id]) > 15000 then
                    lastWarned[zone.id] = now
                    SendNUIMessage({
                        action = 'showWarn',
                        label  = zone.label,
                        limit  = zone.limit,
                    })
                end
            end

            -- Zónán belül + túlsebessség
            if dist <= zone.range and speed > zone.limit then
                local now = GetGameTimer()
                if (now - lastFineLocal) >= Config.FineCooldown then
                    lastFineLocal = now

                    TriggerServerEvent('fvg-traffipax:server:SpeedingFine', {
                        zoneId    = zone.id,
                        zoneLabel = zone.label,
                        speed     = math.floor(speed),
                        limit     = zone.limit,
                        baseFine  = zone.fine,
                        plate     = GetVehiclePlate(veh),
                    })
                end
            end

            ::nextZone::
        end

        ::continue::
    end
end)

-- ── Flash (vaku) effekt szervertől ───────────────────────────────
RegisterNetEvent('fvg-traffipax:client:FlashEffect', function(data)
    SendNUIMessage({
        action = 'flash',
        speed  = data.speed,
        limit  = data.limit,
        fine   = data.fine,
    })
end)

-- ── Zóna állapot változás ──────────────────────────────────────
RegisterNetEvent('fvg-traffipax:client:ZoneStateChanged', function(zoneId, state)
    zoneStates[zoneId] = state
end)

-- ── Exportok ──────────────────────────────────────────────────
exports('GetNearbyZone', function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, zone in ipairs(Config.Zones) do
        if Dist(coords, zone.coords) <= zone.range then
            return zone
        end
    end
    return nil
end)

exports('IsInZone', function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, zone in ipairs(Config.Zones) do
        if Dist(coords, zone.coords) <= zone.range then
            return true, zone
        end
    end
    return false, nil
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    isLoaded = false
end)
