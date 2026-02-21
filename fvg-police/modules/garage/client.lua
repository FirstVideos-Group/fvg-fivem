RegisterClientModule('garage', {
    onAction = function(action, payload, cb)
        if action == 'spawn' then
            TriggerServerEvent('fvg-police:server:ModuleAction', 'garage', 'spawn', payload)
        end
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:SpawnVehicle', function(data)
    local vehDef  = data.vehDef
    local station = nil
    for _, s in ipairs(Config.Locations.stations) do
        if s.id == data.stationId then station = s; break end
    end
    local sp = station and station.garage_spawn or
        vector4(-47.01, -1098.75, 26.0, 335.0)

    local model = GetHashKey(vehDef.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local veh = CreateVehicle(model, sp.x, sp.y, sp.z, sp.w, true, false)
    SetVehicleNumberPlateText(veh, vehDef.plate:gsub('#', tostring(math.random(0,9))))
    SetVehicleModKit(veh, 0)

    if vehDef.colorPrimary   then SetVehicleColours(veh, vehDef.colorPrimary, vehDef.colorSecondary or 0) end
    if vehDef.livery         then SetVehicleLivery(veh, vehDef.livery) end
    if vehDef.extras then
        for extra, state in pairs(vehDef.extras) do
            SetVehicleExtra(veh, extra, state and 0 or 1)
        end
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(model)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
end)