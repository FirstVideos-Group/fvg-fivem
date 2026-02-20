-- ── Engine státusz modul ────────────────────────────────────
-- Értéket az fvg-engine is felülírhatja SetModuleValue-val.
local function tick(ped, veh)
    local running = GetIsVehicleEngineRunning(veh)
    exports['fvg-vehiclehud']:SetModuleValue('engine', {
        running = running,
        visible = true
    })
end

RegisterModule('engine', tick)