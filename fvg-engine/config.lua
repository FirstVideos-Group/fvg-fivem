Config = {}

-- ── Billentyűzet ────────────────────────────────────────────
Config.Key      = 'Y'
Config.KeyLabel = 'Motor kapcsolása'

-- ── Motor indítás / leállítás logika ───────────────────────
-- Ha true: a jármű natív motorindítás animációval indul (fokozatos)
Config.SlowStart = true

-- Motor automatikusan indul-e újra ha valaki beül?
-- false = mindig manuálisan kell indítani
Config.AutoStartOnEnter = false

-- Motor automatikusan leáll-e ha a játékos kiszáll?
Config.AutoStopOnExit = true

-- Mennyi ideig tart a motor leállítása (ms) - animált fokozatos leállás
Config.ShutdownDelay = 1500

-- ── Hangok ──────────────────────────────────────────────────
Config.SoundDict  = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
Config.SoundStart = 'WAYPOINT_SET'
Config.SoundStop  = 'CANCEL'

-- ── Tiltott osztályok (kerékpár, csónak stb.) ───────────────
-- 13 = kerékpár, 14 = hajó (ezeknél nincs értelme a motor togglenak)
Config.DisabledClasses = { 13 }

-- ── Integrációk ─────────────────────────────────────────────
Config.VehicleHudIntegration = true   -- fvg-vehiclehud engine modul
Config.NotifyIntegration     = true   -- fvg-notify értesítések

-- ── Locale ──────────────────────────────────────────────────
Config.Locale = {
    engine_on      = 'Motor beindítva.',
    engine_off     = 'Motor leállítva.',
    not_in_veh     = 'Nem vagy járműben.',
    not_driver     = 'Csak a vezető kapcsolhatja a motort.',
    cant_use       = 'Ebben a járműben nem használható.',
    already_on     = 'A motor már jár.',
    already_off    = 'A motor már le van állítva.',
}