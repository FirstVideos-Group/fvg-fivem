-- ── Lámpák modul ────────────────────────────────────────────
-- GetVehicleLightsState visszaadja a tompított és teli fényszóró állapotát.
local function tick(ped, veh)
    local lightsOn, highbeamsOn = GetVehicleLightsState(veh)
    local indicators = GetVehicleIndicatorLights(veh)
    -- indicators: 0=ki, 1=bal, 2=jobb, 3=mindkettő (vészvillogó)

    exports['fvg-vehiclehud']:SetModuleValue('lights', {
        lights    = lightsOn,
        highbeam  = highbeamsOn,
        indicator = indicators,  -- 0, 1, 2, 3
        visible   = true
    })
end

RegisterModule('lights', tick)