-- ── Food modul ─────────────────────────────────────────────────
-- Értéket az fvg-needs script tölti fel a SetModuleValue exporton keresztül.
-- A modul inicializáláskor 100-as alapot küld a NUI-nak.

local function tick(ped)
    -- Passiv tick – az fvg-needs kezeli az értékeket
end

RegisterModule('food', tick)

-- FIX: első érték push – hogy a HUD azonnal megjelenjen
-- (fvg-needs SetNeeds event előtt is látszik az ikon)
Citizen.CreateThread(function()
    -- Megvárjuk hogy a HUD betöltszönön, majd pusholunk egy alapértéket
    while not _G['_hudReady'] do Citizen.Wait(200) end
    exports['fvg-hud']:SetModuleValue('food', {
        value   = 100.0,
        level   = 'ok',
        visible = true,
    })
end)
