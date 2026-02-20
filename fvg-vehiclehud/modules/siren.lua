-- ── Sziréna modul ───────────────────────────────────────────
-- Passiv alap tick, az fvg-emergency pontosabb állapotot küldhet.
local function tick(ped, veh)
    local active = IsVehicleSirenOn(veh)

    exports['fvg-vehiclehud']:SetModuleValue('siren', {
        active  = active,
        visible = active   -- csak akkor látható ha be van kapcsolva
    })
end

RegisterModule('siren', tick)