-- ── Üzemanyag modul ─────────────────────────────────────────
-- Passiv alap tick (natív GTA érték), az fvg-fuel pontosabb értéket küldhet.
local function tick(ped, veh)
    local fuel = math.floor(GetVehicleFuelLevel(veh))   -- 0–100
    local low  = fuel <= Config.FuelLowThreshold

    exports['fvg-vehiclehud']:SetModuleValue('fuel', {
        value   = fuel,
        low     = low,
        visible = true
    })
end

RegisterModule('fuel', tick)