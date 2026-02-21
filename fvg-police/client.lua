-- ╔══════════════════════════════════════════════╗
-- ║       fvg-police :: client (core)            ║
-- ╚══════════════════════════════════════════════╝

local menuOpen    = false
local onDuty      = false
local localOfficer= nil
local stationBlips= {}
local stationNPCs = {}
local moduleHandlers = {}   -- { id → { onOpen = fn } }

-- ── Kliens exportok ───────────────────────────────────────────
exports('IsPlayerOnDuty', function() return onDuty end)
exports('GetLocalOfficer', function() return localOfficer end)
exports('OpenPoliceMenu', function(stationId)
    if menuOpen then return end
    TriggerServerEvent('fvg-police:server:RequestMenu', stationId or 'mission_row')
end)

-- ── Modul regisztráció (client oldalon) ───────────────────────
function RegisterClientModule(id, def)
    if not Config.Modules[id] or not Config.Modules[id].enabled then return end
    moduleHandlers[id] = def
    print(('[fvg-police] Kliens modul betöltve: %s'):format(id))
end

-- ── Blipek és NPC-k ───────────────────────────────────────────
CreateThread(function()
    for _, station in ipairs(Config.Locations.stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip,  station.blip.sprite)
        SetBlipColour(blip,  station.blip.color)
        SetBlipScale(blip,   station.blip.scale or 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.blip.label)
        EndTextCommandSetBlipName(blip)
        stationBlips[station.id] = blip

        -- Duty NPC
        local model = GetHashKey('s_m_y_cop_01')
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        local npc = CreatePed(4, model,
            station.coords.x, station.coords.y, station.coords.z - 1.0,
            station.coords.w, false, true)
        SetEntityHeading(npc, station.coords.w)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedDiesWhenInjured(npc, false)
        SetEntityInvincible(npc, true)
        FreezeEntityPosition(npc, true)
        SetModelAsNoLongerNeeded(model)
        stationNPCs[station.id] = npc
    end
end)

-- ── Interakció thread ─────────────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, station in ipairs(Config.Locations.stations) do
            local dist = #(coords - vector3(station.coords.x, station.coords.y, station.coords.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1,
                    station.coords.x, station.coords.y, station.coords.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 0.6,
                    56, 189, 248, 120,
                    false, true, 2, nil, nil, false
                )
                if dist < Config.DutyRadius then
                    exports['fvg-notify']:Notify({
                        type='info',
                        message='[E] ' .. station.label,
                        duration=600, static=true
                    })
                    if IsControlJustPressed(0, 38) and not menuOpen then
                        TriggerServerEvent('fvg-police:server:RequestMenu', station.id)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Pánik gomb ────────────────────────────────────────────────
RegisterKeyMapping(Config.PanicButton.key, Config.PanicButton.description, 'keyboard', Config.PanicButton.key)
RegisterCommand(Config.PanicButton.key, function()
    if not onDuty then return end
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('fvg-police:server:Panic', coords)
end, false)

-- ── Menü megnyitás ────────────────────────────────────────────
RegisterNetEvent('fvg-police:client:OpenMenu', function(data)
    menuOpen     = true
    localOfficer = data.officer
    onDuty       = data.officer.duty
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = data })
end)

-- ── Duty változás ─────────────────────────────────────────────
RegisterNetEvent('fvg-police:client:DutyChanged', function(state)
    onDuty = state
    SendNUIMessage({ action = 'dutyChanged', duty = state })
    -- HUD frissítés
    TriggerEvent('fvg-police:client:HudUpdate', state)
end)

-- ── Rang frissítés ────────────────────────────────────────────
RegisterNetEvent('fvg-police:client:RankUpdate', function(data)
    if localOfficer then
        localOfficer.grade     = data.grade
        localOfficer.rankLabel = data.rankLabel
    end
    SendNUIMessage({ action = 'rankUpdate', data = data })
end)

-- ── NUI Callbacks ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('fvg-police:server:ToggleDuty')
    cb('ok')
end)

RegisterNUICallback('moduleAction', function(data, cb)
    -- Modul-specifikus akció dispatch
    local handler = moduleHandlers[data.module]
    if handler and handler.onAction then
        handler.onAction(data.action, data.payload, cb)
    else
        -- Szerver felé továbbít
        TriggerServerEvent('fvg-police:server:ModuleAction',
            data.module, data.action, data.payload)
        cb('ok')
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, blip in pairs(stationBlips) do RemoveBlip(blip) end
    for _, npc  in pairs(stationNPCs) do
        if DoesEntityExist(npc) then DeletePed(npc) end
    end
    menuOpen = false
end)