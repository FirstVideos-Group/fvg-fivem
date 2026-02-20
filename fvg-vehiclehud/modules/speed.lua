-- ── Sebesség modul ──────────────────────────────────────────
local function tick(ped, veh)
    local running = GetIsVehicleEngineRunning(veh)
    local mps     = GetEntitySpeed(veh)
    local speed

    if Config.SpeedUnit == 'mph' then
        speed = math.floor(mps * 2.23694)
    else
        speed = math.floor(mps * 3.6)
    end

    exports['fvg-vehiclehud']:SetModuleValue('speed', {
        value   = speed,
        unit    = Config.SpeedUnit,
        visible = running
    })
end

RegisterModule('speed', tick)