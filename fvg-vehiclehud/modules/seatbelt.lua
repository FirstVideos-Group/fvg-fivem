-- ── Biztonsági öv modul ─────────────────────────────────────
-- Alap tick: nem kezeli az állapotot, az fvg-seatbelt küldi SetModuleValue-val.
-- Alapértelmezetten: nem csatolt (fastened = false)

local function tick(ped, veh)
    -- Passiv – az fvg-seatbelt kezeli
end

-- Kezdeti állapot küldése
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    exports['fvg-vehiclehud']:SetModuleValue('seatbelt', {
        fastened = false,
        visible  = true
    })
end)

RegisterModule('seatbelt', tick)