-- ── Motor állapot modul ─────────────────────────────────────
-- Passiv alap tick, az fvg-vehicledamage pontosabb értéket küldhet.
local function tick(ped, veh)
    local health = GetVehicleEngineHealth(veh)   -- 0–1000
    local pct    = math.max(0, math.min(100, (health / 1000) * 100))
    local status

    if pct > (Config.EngineHealthWarnThreshold / 10) then
        status = 'ok'
    elseif pct > (Config.EngineHealthCritThreshold / 10) then
        status = 'warn'
    else
        status = 'crit'
    end

    exports['fvg-vehiclehud']:SetModuleValue('enginehealth', {
        value   = math.floor(pct),
        status  = status,
        visible = true
    })
end

RegisterModule('enginehealth', tick)