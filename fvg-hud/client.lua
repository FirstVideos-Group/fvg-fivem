-- ╔══════════════════════════════════════════════╗
-- ║          fvg-hud :: client core              ║
-- ╚══════════════════════════════════════════════╝

local _modules       = {}
local _moduleIndex   = {}
local _playerToggles = {}

DisplayHud(false)
DisplayRadar(true)

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

    -- NUI-nak csak akkor küldjük, ha már init ment ki
    -- (hudReady után a syncModules gondoskodik róla)
end

exports('RegisterModule', RegisterModule)

-- ── Érték frissítő ──────────────────────────────────────────
local function SendModuleUpdate(id, value, visible)
    SendNUIMessage({
        action  = 'updateModule',
        id      = id,
        value   = value,
        visible = visible
    })
end

exports('SetModuleValue', function(id, value, visible)
    if not _moduleIndex[id] then return end
    if not _moduleIndex[id].enabled then return end
    SendModuleUpdate(id, value, visible)
end)

-- ── Modul be-/kikapcsolás ───────────────────────────────────
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

-- ── Összes modul szinkronizálása az NUI-val ─────────────────
local function SyncModulesToNUI()
    SendNUIMessage({ action = 'init', position = Config.Position })
    Citizen.Wait(50) -- rövid várakozás hogy az init feldolgozódjon
    for _, m in ipairs(_modules) do
        SendNUIMessage({
            action   = 'registerModule',
            id       = m.id,
            enabled  = m.enabled,
            position = Config.Position
        })
    end
end

-- ── NUI visszajelzések ──────────────────────────────────────
RegisterNUICallback('hudReady', function(data, cb)
    -- Teljes szinkronizálás: minden modult újraküldünk értékkel együtt
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

-- ── Fő tick ──────────────────────────────────────────────────
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(500)
    end

    -- Player betöltött → szinkronizálunk
    SyncModulesToNUI()

    while true do
        Citizen.Wait(Config.TickRate)

        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            for _, m in ipairs(_modules) do
                if m.enabled and m.tick then
                    m.tick(ped)
                end
            end
        end
    end
end)