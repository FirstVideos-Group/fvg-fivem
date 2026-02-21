Config = {}

-- ── Billentyűzet ─────────────────────────────────────────────────
Config.Key      = 'Y'
Config.KeyLabel = 'Motor kapcsolása'

-- ── Motor indítás / leállítás logika ──────────────────────────────
Config.SlowStart = true

-- Motor automatikusan indul-e ha valaki beül?
Config.AutoStartOnEnter = false

-- Motor automatikusan leáll-e ha a játékos kiszáll?
-- FONTOS: ha false, a motor futva marad kiszallás után is!
Config.AutoStopOnExit = false

-- Ha AutoStopOnExit = false: a járó motor a jármű közelében marad-e aktivan?
-- A játékos visszatérésekor a motor állapotát helyreallítjuk.
Config.KeepEngineOnExit = true

-- Mennyi ideig tartja életben a motor állapotát kiszallás után (ms)
-- 0 = végtelen (amíg a jármű létezik)
Config.KeepEngineTimeout = 0

-- Hany ms-ként erősítsük meg a motor állapotát a játmő nelküli járműven
Config.EngineKeepTickRate = 500

-- Mennyi ideig tart a motor leállítása (ms)
Config.ShutdownDelay = 1500

-- ── Hangok ────────────────────────────────────────────────────────────
Config.SoundDict  = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
Config.SoundStart = 'WAYPOINT_SET'
Config.SoundStop  = 'CANCEL'

-- ── Tiltott osztályok ───────────────────────────────────────────────
Config.DisabledClasses = { 13 }

-- ── Integrációk ─────────────────────────────────────────────────────
Config.VehicleHudIntegration = true
Config.NotifyIntegration     = true

-- ── Locale ──────────────────────────────────────────────────────────────
Config.Locale = {
    engine_on      = 'Motor beíndítva.',
    engine_off     = 'Motor leállítva.',
    not_in_veh     = 'Nem vagy járműben.',
    not_driver     = 'Csak a vezető kapcsolhatja a motort.',
    cant_use       = 'Ebben a járműben nem használható.',
    already_on     = 'A motor már jár.',
    already_off    = 'A motor már le van állítva.',
}
