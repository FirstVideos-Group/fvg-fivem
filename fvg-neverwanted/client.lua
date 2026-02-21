-- ╔══════════════════════════════════════════════╗
-- ║       fvg-neverwanted :: client              ║
-- ╚══════════════════════════════════════════════╝

local enabled    = Config.Enabled
local isWhitelisted = false

-- ── Whitelist ellenőrzés ──────────────────────────────────────
-- A szerver oldali whitelist-et nem tudunk kliens oldalon
-- biztonságosan ellenőrizni, ezért a szerver visszajelez
AddEventHandler('fvg-neverwanted:client:SetEnabled', function(state)
    enabled = state
end)

-- ── Exportok ─────────────────────────────────────────────────
exports('IsEnabled', function()
    return enabled
end)

exports('SetEnabled', function(state)
    enabled = state == true
    -- Dispatch állapot szinkronizálás
    _ApplyDispatchState(enabled)
end)

exports('SetMaxWantedLevel', function(level)
    SetMaxWantedLevel(math.max(0, math.min(5, tonumber(level) or 0)))
end)

-- ── Dispatch és NPC viselkedés beállítás ─────────────────────
function _ApplyDispatchState(block)
    if block and Config.DisableDispatch then
        -- Mind a 15 dispatch típus tiltása
        -- (0=police, 1=swat, 2=army, 3=bikers, 4=ambulance,
        --  5=firetruck, 6=unk, 7=helicopter, 8=backup,
        --  9=unk, 10=unk, 11=unk, 12=boat, 13=helicopter2, 14=unk)
        for i = 0, 14 do
            EnableDispatchService(i, false)
        end
    else
        for i = 0, 14 do
            EnableDispatchService(i, true)
        end
    end

    if block and Config.DisableCopChase then
        SetPoliceIgnorePlayer(PlayerId(), true)
        SetEveryoneIgnorePlayer(PlayerId(), false)  -- járókelők IGEN reagálnak
    else
        SetPoliceIgnorePlayer(PlayerId(), false)
    end

    if Config.DisablePedReaction then
        SetEveryoneIgnorePlayer(PlayerId(), true)
    end
end

-- ── Fő blokkoló szál ─────────────────────────────────────────
CreateThread(function()
    -- Dispatch állapot kezdeti beállítás
    Wait(500)
    _ApplyDispatchState(enabled)

    while true do
        Wait(Config.TickRate)

        if not enabled then goto continue end

        local pid = PlayerId()

        -- Wanted szint törlése
        local current = GetPlayerWantedLevel(pid)
        if current > Config.MaxWantedLevel then
            SetPlayerWantedLevel(pid, Config.MaxWantedLevel, false)
            SetPlayerWantedLevelNow(pid, false)
            ClearPlayerWantedLevel(pid)
        end

        -- Max wanted limit frissítés (GTA néha visszaállítja)
        SetMaxWantedLevel(Config.MaxWantedLevel)

        -- Cop chase újra tiltás (néha visszakapcsolódik)
        if Config.DisableCopChase then
            SetPoliceIgnorePlayer(pid, true)
        end

        ::continue::
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Visszaállítjuk az alapállapotot
    SetMaxWantedLevel(5)
    SetPoliceIgnorePlayer(PlayerId(), false)
    SetEveryoneIgnorePlayer(PlayerId(), false)
    for i = 0, 14 do
        EnableDispatchService(i, true)
    end
end)
