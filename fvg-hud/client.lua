-- ╔══════════════════════════════════════════════╗
-- ║          fvg-hud :: client core              ║
-- ╚══════════════════════════════════════════════╝

local _modules       = {}
local _moduleIndex   = {}
local _playerToggles = {}
local _hudInitDone   = false   -- NUI init elküldve-e már
local _isRunning     = false   -- fő tick thread fut-e már

DisplayHud(false)
DisplayRadar(true)

-- ── Modul regisztrátor ───────────────────────────────────────────
function RegisterModule(id, tickFn)
    if _moduleIndex[id] then return end

    local cfg = Config.Modules[id]
    if not cfg or not cfg.enabled then return end

    local entry = {
        id      = id,
        tick    = tickFn,
        enabled = true,
        order   = cfg.order or 99,
        value   = nil,   -- utolsó ismert érték, hudReady-nél visszaküldjük
    }
    table.insert(_modules, entry)
    _moduleIndex[id] = entry

    table.sort(_modules, function(a, b) return a.order < b.order end)
end

exports('RegisterModule', RegisterModule)

-- ── Érték frissítő ────────────────────────────────────────────────
local function SendModuleUpdate(id, value, visible)
    SendNUIMessage({
        action  = 'updateModule',
        id      = id,
        value   = value,
        visible = visible
    })
end

exports('SetModuleValue', function(id, value, visible)
    local m = _moduleIndex[id]
    if not m or not m.enabled then return end
    m.value = value   -- elmentjük, hogy hudReady után is vissza tudjuk küldeni
    SendModuleUpdate(id, value, visible)
end)

-- ── Modul be-/kikapcsolás ─────────────────────────────────────────
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

-- ── Összes modul szinkronizálása az NUI-val ─────────────────────────
local function SyncModulesToNUI()
    _hudInitDone = true
    SendNUIMessage({ action = 'init', position = Config.Position })
    Citizen.Wait(80)  -- NUI-nak idő az init feldolgozására
    for _, m in ipairs(_modules) do
        SendNUIMessage({
            action   = 'registerModule',
            id       = m.id,
            enabled  = m.enabled,
            position = Config.Position
        })
        -- Ha van már ismert érték (pl. restart után), azonnal elküldjük
        if m.value ~= nil then
            Citizen.Wait(10)
            SendModuleUpdate(m.id, m.value, true)
        end
    end
end

-- ── NUI visszajelzések ───────────────────────────────────────────
-- A NUI jelzi hogy betöltött / újraindulás után újra kész
RegisterNUICallback('hudReady', function(data, cb)
    -- Teljes újraszinkronizálás: modul struktúра és értékek is
    Citizen.CreateThread(function()
        SendNUIMessage({ action = 'init', position = Config.Position })
        Citizen.Wait(80)
        for _, m in ipairs(_modules) do
            SendNUIMessage({
                action   = 'registerModule',
                id       = m.id,
                enabled  = m.enabled,
                position = Config.Position
            })
            if m.value ~= nil then
                Citizen.Wait(10)
                SendModuleUpdate(m.id, m.value, true)
            end
        end
    end)
    cb('ok')
end)

-- ── Fő tick indítása (csak egyszer) ────────────────────────────────
local function StartHudTick()
    if _isRunning then return end
    _isRunning = true

    Citizen.CreateThread(function()
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
end

-- ── Init: első betöltés ─────────────────────────────────────────────
Citizen.CreateThread(function()
    -- Várunk amig a hálózat aktiv és a playercore betöltötte a játékost
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(500)
    end

    -- Extra várakozás hogy a modules/*.lua mind regisztrálva legyen
    -- (a fxmanifest client.lua előtt tölt, de biztonság kedvéért)
    Citizen.Wait(300)

    SyncModulesToNUI()
    StartHudTick()
end)

-- ── PlayerLoaded event: playercore restart után is szinkronizál ────────
-- Ez a legfontosabb: ha a playercore restart-ol, a HUD-ot újra be kell
-- sync-elni mert az NUI nem kapott adatot a betöltés során
AddEventHandler('fvg-playercore:client:PlayerLoaded', function(playerData)
    -- Várunk egy kicsit hogy a NUI biztosan betöltött
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        SyncModulesToNUI()
        StartHudTick()   -- ha még nem futna
    end)
end)

-- ── Resource restart: HUD újrainicializálása ────────────────────────
-- Ha maga a fvg-hud restart-ol, az NUI újraindul és hudReady-t küld
-- → a hudReady callback gondoskodik a szinkronizálásról
-- Ha a fvg-hud indul el második ként (pl. ensure), a fő thread indul
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    _isRunning   = false
    _hudInitDone = false
    Citizen.CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Citizen.Wait(300)
        end
        Citizen.Wait(400)
        SyncModulesToNUI()
        StartHudTick()
    end)
end)

-- ── Cleanup ──────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    _isRunning   = false
    _hudInitDone = false
end)
