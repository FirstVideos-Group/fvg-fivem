-- ── Stress modul ────────────────────────────────────────────────
-- Értéket az fvg-stress script tölti fel a SetModuleValue exporton keresztül.
-- A modul csak akkor látszódik ha a stress értéke nagyobb mint 0.

local function tick(ped)
    -- Passiv tick – az fvg-stress kezeli az értékeket
end

RegisterModule('stress', tick)

-- FIX: első érték push – alapértelmezetten 0 stress, rejtve
Citizen.CreateThread(function()
    while not _G['_hudReady'] do Citizen.Wait(200) end
    exports['fvg-hud']:SetModuleValue('stress', {
        value   = 0.0,
        level   = 'calm',
        visible = false,   -- 0 stressnél nem jelenjünk meg
    })
end)
