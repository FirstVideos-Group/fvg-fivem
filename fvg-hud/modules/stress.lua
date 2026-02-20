-- ── Stress modul ────────────────────────────────────────────
-- Értéket az fvg-stress script tölti fel a SetModuleValue exporton keresztül.

local function tick(ped)
    -- Passiv tick – az fvg-stress kezeli az értékeket
end

RegisterModule('stress', tick)