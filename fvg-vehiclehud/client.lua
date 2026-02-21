-- ╔══════════════════════════════════════════════╗
-- ║       fvg-vehiclehud :: client core          ║
-- ╚══════════════════════════════════════════════╝

local _modules       = {}
local _moduleIndex   = {}
local _playerToggles = {}
local _inVehicle     = false
local _lastVehicle   = 0

-- ── Modul regisztrátor ──────────────────────────────────────
function RegisterModule(id, tickFn)
    if _moduleIndex[id] then return end

    local cfg = Config.Modules[id]
    if not cfg or not cfg.enabled then return end

    local entry = {
        id      = id,
        tick    = tickFn,
        enabled = true,
        order   = cfg.order or 99
    }
    table.insert(_modules, entry)
    _moduleIndex[id] = entry

    table.sort(_modules, function(a, b) return a.order < b.order end)

    SendNUIMessage({
        action   = 'registerModule',
        id       = id,
        enabled  = true,
        position = Config.Position
    })
end

exports('RegisterModule', RegisterModule)

-- ── Érték küldő ─────────────────────────────────────────────
local function SendModuleUpdate(id, data)
    SendNUIMessage({
        action = 'updateModule',
        id     = id,
        data   = data
    })
end

-- Export: külső scriptek (fvg-fuel, fvg-seatbelt stb.) adatot küldhetnek
exports('SetModuleValue', function(id, data)
    if not _moduleIndex[id] then return end
    if not _moduleIndex[id].enabled then return end
    SendModuleUpdate(id, data)
end)

-- ── Modul toggle ────────────────────────────────────────────
exports('ToggleModule', function(id, state)
    local m = _moduleIndex[id]
    if not m then return end
    m.enabled = state
    _playerToggles[id] = state
    SendNUIMessage({
        action  = 'toggleModule',
        id      = id,
        enabled = state
    })
end)

exports('GetModuleState', function(id)
    local m = _moduleIndex[id]
    if not m then return false end
    return m.enabled
end)

-- ── Jármű detektálás + HUD megjelenítés/elrejtés ───────────
local function ShowHud(visible)
    _inVehicle = visible
    SendNUIMessage({ action = 'setHudVisible', visible = visible })
end

-- ── Fő tick ─────────────────────────────────────────────────
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(500)
    end

    SendNUIMessage({ action = 'init', position = Config.Position })

    while true do
        Citizen.Wait(Config.TickRate)

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = DoesEntityExist(vehicle) and vehicle ~= 0

        -- Járműbe/ki szállás detektálás
        if inVeh and not _inVehicle then
            ShowHud(true)
            _lastVehicle = vehicle
        elseif not inVeh and _inVehicle then
            ShowHud(false)
            _lastVehicle = 0
        end

        -- Tick futtatása csak járműben
        if inVeh then
            for _, m in ipairs(_modules) do
                if m.enabled and m.tick then
                    m.tick(ped, vehicle)
                end
            end
        end
    end
end)

-- ── NUI visszajelzés ────────────────────────────────────────
RegisterNUICallback('vHudReady', function(data, cb)
    for _, m in ipairs(_modules) do
        SendNUIMessage({
            action   = 'registerModule',
            id       = m.id,
            enabled  = m.enabled,
            position = Config.Position
        })
    end
    cb('ok')
end)