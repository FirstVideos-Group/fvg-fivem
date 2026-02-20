-- ── Shield modul ────────────────────────────────────────────
local function tick(ped)
    local armour = GetPedArmour(ped)   -- 0–100
    local visible = armour > 0
    exports['fvg-hud']:SetModuleValue('shield', armour, visible)
end

RegisterModule('shield', tick)