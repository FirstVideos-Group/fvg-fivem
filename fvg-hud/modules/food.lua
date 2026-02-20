-- ── Food modul ──────────────────────────────────────────────
-- Értéket az fvg-needs script tölti fel a SetModuleValue exporton keresztül.
-- Alapértelmezetten rejtve van, amíg az fvg-needs el nem küldi az első értéket.

local function tick(ped)
    -- Passiv tick – az fvg-needs kezeli az értékeket
    -- Ha az fvg-needs nincs betöltve, a modul látható de üres
end

RegisterModule('food', tick)