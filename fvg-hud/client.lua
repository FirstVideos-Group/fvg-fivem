-- ╔══════════════════════════════════════════════╗
-- ║          fvg-hud :: client core              ║
-- ╚══════════════════════════════════════════════╝

-- Regisztrált modulok táblája: { id, tick, enabled }
local _modules     = {}
local _moduleIndex = {}   -- gyors keresés id alapján
local _playerToggles = {} -- játékos egyéni beállításai (hudmenu-ból)

-- Natív HUD elrejtése
DisplayHud(false)
DisplayRadar(true)

-- ── Modul regisztrátor ──────────────────────────────────────
-- Minden modules/*.lua fájl ezt hívja meg
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

    -- Rendezés megjelenítési sorrend szerint
    table.sort(_modules, function(a, b) return a.order < b.order end)

    -- Értesítés az NUI-nak az új modulról
    SendNUIMessage({
        action   = 'registerModule',
        id       = id,
        enabled  = true,
        position = Config.Position
    })
end

-- Export: más scriptek is regisztrálhatnak modult
exports('RegisterModule', RegisterModule)

-- ── Érték frissítő ──────────────────────────────────────────
-- Modult hívja és NUI-ba küldi az adatot
local function SendModuleUpdate(id, value, visible)
    SendNUIMessage({
        action  = 'updateModule',
        id      = id,
        value   = value,
        visible = visible
    })
end

-- Export: külső scriptek (fvg-needs, fvg-stress stb.) adatot küldhetnek
exports('SetModuleValue', function(id, value, visible)
    if not _moduleIndex[id] then return end
    if not _moduleIndex[id].enabled then return end
    SendModuleUpdate(id, value, visible)
end)

-- ── Modul be-/kikapcsolás ───────────────────────────────────
-- Ezt a fvg-hudmenu fogja hívni
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

-- Export: lekérdezi egy modul állapotát
exports('GetModuleState', function(id)
    local m = _moduleIndex[id]
    if not m then return false end
    return m.enabled
end)

-- ── NUI felé jelzi az összes elérhető modult ───────────────
RegisterNetEvent('fvg-hud:client:Loaded', function()
    for _, m in ipairs(_modules) do
        SendNUIMessage({
            action   = 'registerModule',
            id       = m.id,
            enabled  = m.enabled,
            position = Config.Position
        })
    end
end)

-- ── Fő tick: minden modul tick függvényét meghívja ──────────
Citizen.CreateThread(function()
    -- Várunk amíg a játékos betölt
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(500)
    end

    -- Modulok inicializálása
    SendNUIMessage({ action = 'init', position = Config.Position })

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

-- ── NUI visszajelzések ──────────────────────────────────────
RegisterNUICallback('hudReady', function(data, cb)
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