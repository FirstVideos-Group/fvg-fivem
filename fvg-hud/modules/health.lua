-- ── Health modul ────────────────────────────────────────────
local function tick(ped)
    local hp    = GetEntityHealth(ped)         -- 100–200
    local maxHp = GetEntityMaxHealth(ped)      -- általában 200
    local pct   = math.max(0, math.min(100,
        ((hp - Config.MinHealth) / (maxHp - Config.MinHealth)) * 100
    ))
    exports['fvg-hud']:SetModuleValue('health', pct, true)
end

RegisterModule('health', tick)