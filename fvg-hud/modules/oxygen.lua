-- ── Oxygen modul ────────────────────────────────────────────
local function tick(ped)
    local inWater  = IsPedSwimmingUnderWater(ped)
    local oxygen   = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) / 3.0 * 100)
    oxygen = math.max(0, math.min(100, oxygen))
    local visible  = inWater or oxygen < Config.OxygenShowThreshold
    exports['fvg-hud']:SetModuleValue('oxygen', oxygen, visible)
end

RegisterModule('oxygen', tick)