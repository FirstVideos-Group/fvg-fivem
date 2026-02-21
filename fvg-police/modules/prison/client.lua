local inPrison   = false
local prisonTimer= nil
local csActive   = false
local csLocation = nil

RegisterClientModule('prison', {
    onAction = function(action, payload, cb)
        TriggerServerEvent('fvg-police:server:ModuleAction', 'prison', action, payload)
        cb('ok')
    end
})

RegisterNetEvent('fvg-police:client:SendToPrison', function(data)
    inPrison = true
    local prison = Config.Locations.prison

    -- Teleport börtönbe
    local ped = PlayerPedId()
    SetEntityCoords(ped,
        prison.inside.x, prison.inside.y, prison.inside.z,
        false, false, false, false)

    -- Timer
    local timeLeft = data.timeMinutes * 60
    SendNUIMessage({ action = 'prisonStarted', timeLeft = timeLeft, reason = data.reason })

    -- Tick thread
    CreateThread(function()
        while inPrison and timeLeft > 0 do
            Wait(1000)
            timeLeft = timeLeft - 1
            SendNUIMessage({ action = 'prisonTick', timeLeft = timeLeft })
            if timeLeft <= 0 then
                TriggerServerEvent('fvg-police:server:ModuleAction', 'prison', 'release',
                    { identifier = 'self' })
            end
        end
    end)

    exports['fvg-notify']:Notify({
        type='error', title='⛓️ Börtönbe zárva',
        message=data.reason .. ' – ' .. data.timeMinutes .. ' perc',
        duration=8000
    })
end)

RegisterNetEvent('fvg-police:client:ReleasedFromPrison', function()
    inPrison = false
    csActive = false
    local loc = Config.Locations.prison.exit
    SetEntityCoords(PlayerPedId(), loc.x, loc.y, loc.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), loc.w)
    SendNUIMessage({ action = 'prisonEnded' })
    exports['fvg-notify']:Notify({
        type='success', title='🔓 Szabadon engedve',
        message='Letöltötted a büntetésedet. Viselkedj!',
    })
end)

RegisterNetEvent('fvg-police:client:PrisonTick', function(data)
    SendNUIMessage({ action = 'prisonTick', timeLeft = data.timeLeft * 60 })
end)

-- Közmunka területek
CreateThread(function()
    while true do
        Wait(1000)
        if not inPrison then goto continue end
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, cs in ipairs(Config.Locations.community_service) do
            local dist = #(coords - cs.coords)
            if dist < 3.0 then
                if not csActive then
                    csActive   = true
                    csLocation = cs
                    SendNUIMessage({ action = 'csStarted', task = cs.task, label = cs.label })
                    exports['fvg-notify']:Notify({
                        type='info',
                        message='Közmunka területen vagy: ' .. cs.label
                    })
                end
            else
                if csActive and csLocation and csLocation.id == cs.id then
                    csActive   = false
                    csLocation = nil
                    SendNUIMessage({ action = 'csStopped' })
                end
            end
        end
        ::continue::
    end
end)

-- Közmunka task elvégzés
CreateThread(function()
    while true do
        Wait(Config.Prison.csTaskInterval * 1000)
        if inPrison and csActive then
            local p = exports['fvg-playercore']:GetLocalPlayer()
            if p then
                TriggerServerEvent('fvg-police:server:ModuleAction', 'prison', 'csProgress',
                    { identifier = p.identifier })
                exports['fvg-notify']:Notify({
                    type='success',
                    message='Közmunka pont +1 → Idő csökkentve.'
                })
            end
        end
    end
end)