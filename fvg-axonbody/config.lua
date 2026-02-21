Config = {}

-- ── Jogosult job-ok ─────────────────────────────────────────────
Config.AuthorizedJobs = {
    'police',
    'sheriff',
    'state_police',
}

-- ── Parancs ─────────────────────────────────────────────────────
Config.Command     = 'bodycam'
Config.CommandDesc = 'Axon testikamera be/ki kapcsolása'

-- ── Kamera viselkedés ───────────────────────────────────────────
-- Folyamatos szerver szinkron (más rendőrök látják-e az állapotot)
Config.SyncState   = true

-- Automatikusan leálljon-e ha a játékos meghal
Config.StopOnDeath = true

-- ── Időformátum ─────────────────────────────────────────────────
-- '24h' | '12h'
Config.TimeFormat  = '24h'

-- ── Overlay elemek engedélyezése ────────────────────────────────
Config.ShowRealTime  = true   -- Valós idő
Config.ShowDate      = true   -- Valós dátum
Config.ShowOfficer   = true   -- Járőr neve
Config.ShowUnit      = true   -- Egységszám / callsign
Config.ShowBattery   = true   -- Akkumulátor (szimulált)
Config.ShowGPS       = true   -- GPS koordináta

-- ── Akkumulátor szimuláció ───────────────────────────────────────
-- Kamera bekapcsolásakor ennyi % töltöttséggel indul
-- (tisztán vizuális, nem funkcionális)
Config.BatteryStart  = 87
-- Ennyi mp-enként csökken 1%-ot
Config.BatteryDrainSec = 120

-- ── REC villogó ─────────────────────────────────────────────────
Config.RecBlinkMs    = 800

-- ── Timecycle effekt ────────────────────────────────────────────
-- Bodycam esetén enyhébb effekt mint a dashcam-nél
Config.TimecycleModifier  = 'camera_security_BORED'
Config.TimecycleStrength  = 0.35

-- ── Locale ──────────────────────────────────────────────────────
Config.Locale = {
    not_authorized = 'Nincs jogosultságod a bodycam használatához.',
    cam_on         = 'Axon BodyCam: AKTÍV',
    cam_off        = 'Axon BodyCam: KIKAPCSOLVA',
    died           = 'BodyCam automatikusan leállt.',
}
