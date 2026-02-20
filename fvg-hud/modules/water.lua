-- ── Water modul ─────────────────────────────────────────────
-- Értéket az fvg-needs script tölti fel a SetModuleValue exporton keresztül.

local function tick(ped)
    -- Passiv tick – az fvg-needs kezeli az értékeket
end

RegisterModule('water', tick)