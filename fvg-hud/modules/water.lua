-- ── Water modul ─────────────────────────────────────────────────
-- Értéket az fvg-needs script tölti fel a SetModuleValue exporton keresztül.
-- A modul inicializáláskor 100-as alapot küld a NUI-nak.

local function tick(ped)
    -- Passiv tick – az fvg-needs kezeli az értékeket
end

RegisterModule('water', tick)

-- FIX: első érték push – hogy a HUD azonnal megjelenjen
Citizen.CreateThread(function()
    while not _G['_hudReady'] do Citizen.Wait(200) end
    exports['fvg-hud']:SetModuleValue('water', {
        value   = 100.0,
        level   = 'ok',
        visible = true,
    })
end)
