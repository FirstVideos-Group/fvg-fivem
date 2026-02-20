-- ── Fokozat modul ───────────────────────────────────────────
local function tick(ped, veh)
    local gear    = GetVehicleCurrentGear(veh)
    local maxGear = GetVehicleHighGear(veh)
    -- 0 = hátramenet, 1 = 1. fokozat stb.
    local label
    if gear == 0 then
        label = 'R'
    elseif gear == 1 and maxGear == 1 then
        label = 'A'   -- automata / egyfokozatú (pl. elektromos)
    else
        label = tostring(gear)
    end

    exports['fvg-vehiclehud']:SetModuleValue('gear', {
        gear    = gear,
        label   = label,
        maxGear = maxGear,
        visible = true
    })
end

RegisterModule('gear', tick)