-- ╔══════════════════════════════════════════════╗
-- ║          fvg-hud :: client core              ║
-- ╚══════════════════════════════════════════════╝

local _modules       = {}
local _moduleIndex   = {}
local _hudReady      = false   -- NUI betöltött-e már
local _isRunning     = false   -- fő tick thread fut-e már

DisplayHud(false)
DisplayRadar(true)

-- ── Modul regisztrátor ─────────────────────────────────────────
function RegisterModule(id, tickFn)
    if _moduleIndex[id] then return end

    local cfg = Config.Modules[id]
    if not cfg or not cfg.enabled then return end

    local entry = {
        id      = id,
        tick    = tickFn,
        enabled = true,
        order   = cfg.order or 99,
        value   = nil,
        visible = true,
    }
    table.insert(_modules, entry)
    _moduleIndex[id] = entry
    table.sort(_modules, function(a, b) return a.order < b.order end)
end

exports('RegisterModule', RegisterModule)

-- ── Érték frissítő (csak cached értéket ment, NUI-t NEM küld) ─────
-- A tényleges NUI küldés a tick végén, batch SendNUIMessage-ként
local pendingUpdates = {}

exports('SetModuleValue', function(id, value, visible)
    local m = _moduleIndex[id]
    if not m or not m.enabled then return end
    -- csak elmentjük, a tick-ciklus végén SendHudBatch() küldi el
    m.value   = value
    m.visible = visible
    pendingUpdates[id] = true
end)

-- ── Modul be-/kikapcsolás ──────────────────────────────────────
exports('ToggleModule', function(id, state)
    local m = _moduleIndex[id]
    if not m then return end
    m.enabled = state
    if _hudReady then
        SendNUIMessage({ action = 'toggleModule', id = id, enabled = state })
    end
end)

exports('GetModuleState', function(id)
    local m = _moduleIndex[id]
    return m and m.enabled or false
end)

-- ── Batch NUI küldés (1 üzenetben minden pending érték) ─────────
local function SendHudBatch()
    if not _hudReady then return end
    local updates = {}
    for id, _ in pairs(pendingUpdates) do
        local m = _moduleIndex[id]
        if m and m.value ~= nil then
            table.insert(updates, { id = id, value = m.value, visible = m.visible })
        end
    end
    pendingUpdates = {}
    if #updates == 0 then return end
    SendNUIMessage({ action = 'batchUpdate', updates = updates })
end

-- ── NUI struktúra inicializálása (csak egyszer) ─────────────────
local function InitNUI()
    -- 1. init üzenet (pozíció)
    SendNUIMessage({ action = 'init', position = Config.Position })
    Citizen.Wait(100)
    -- 2. modulok regisztrálása – értéket NEM küldünk, csak struktúrát
    for _, m in ipairs(_modules) do
        SendNUIMessage({
            action   = 'registerModule',
            id       = m.id,
            enabled  = m.enabled,
            position = Config.Position,
        })
    end
    -- 3. NUI-t ready-nek jelölünk, tick majd küld valós értékeket
    _hudReady = true
end

-- ── Fő tick (modulok futtatása + batch flush) ───────────────────
local function StartHudTick()
    if _isRunning then return end
    _isRunning = true

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.TickRate)
            if not _hudReady then goto continue end
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                for _, m in ipairs(_modules) do
                    if m.enabled and m.tick then
                        m.tick(ped)
                    end
                end
                -- Egy tick = egy batch NUI üzenet (nem N darab)
                SendHudBatch()
            end
            ::continue::
        end
    end)
end

-- ── NUI visszajelzés: NUI újraindult (pl. F8 refresh, resource restart)
RegisterNUICallback('hudReady', function(data, cb)
    -- NUI-t nem jelöljük ready-nek amíg az InitNUI le nem futott
    -- Megjegyzés: ezt a tickből NEM hívjuk, így nincs loop
    _hudReady = false
    Citizen.CreateThread(function()
        InitNUI()
    end)
    cb('ok')
end)

-- ── Első betöltés ──────────────────────────────────────────────
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(500)
    end
    Citizen.Wait(300)
    InitNUI()
    StartHudTick()
end)

-- ── PlayerLoaded (playercore restart után is inicializál) ────────
AddEventHandler('fvg-playercore:client:PlayerLoaded', function()
    Citizen.CreateThread(function()
        _hudReady = false
        Citizen.Wait(600)
        InitNUI()
        StartHudTick()
    end)
end)

-- ── Resource restart ──────────────────────────────────────────
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    _isRunning = false
    _hudReady  = false
    pendingUpdates = {}
    Citizen.CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Citizen.Wait(300)
        end
        Citizen.Wait(400)
        InitNUI()
        StartHudTick()
    end)
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    _isRunning     = false
    _hudReady      = false
    pendingUpdates = {}
end)
