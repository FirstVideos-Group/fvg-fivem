-- ── Stamina modul ───────────────────────────────────────────
local function tick(ped)
    local stamina = GetPlayerStamina(PlayerId())   -- 0–100
    local visible = stamina < Config.StaminaShowThreshold
    exports['fvg-hud']:SetModuleValue('stamina', stamina, visible)
end

RegisterModule('stamina', tick)