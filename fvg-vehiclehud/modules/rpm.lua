-- ── RPM modul ───────────────────────────────────────────────
local function tick(ped, veh)
    local running = GetIsVehicleEngineRunning(veh)
    local rpm     = GetVehicleCurrentRpm(veh)   -- 0.0–1.0
    local redline = rpm >= Config.RPMRedlineThreshold

    exports['fvg-vehiclehud']:SetModuleValue('rpm', {
        value    = rpm,
        redline  = redline,
        visible  = running
    })
end

RegisterModule('rpm', tick)