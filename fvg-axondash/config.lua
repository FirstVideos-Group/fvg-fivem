Config = {}

-- ── Jogosult job-ok ─────────────────────────────────────────────
-- Csak ezek a job-ok aktiválhatják a dashcam-et
Config.AuthorizedJobs = {
    'police',
    'sheriff',
    'state_police',
}

-- ── Parancs ─────────────────────────────────────────────────────
Config.Command        = 'dashcam'          -- /dashcam
Config.CommandDesc    = 'Axon fedélzeti kamera be/ki kapcsolása'

-- ── Emergency jármű modellek ────────────────────────────────────
-- Csak akkor aktiválható, ha a játékos ilyen járműben ül
-- Ha üres táblát adsz meg → minden jármű engedélyezett (nem ajánlott)
Config.EmergencyModels = {
    -- LSPD
    'police',  'police2', 'police3', 'police4',
    'policeb',  'policeold1', 'policeold2',
    -- Sheriff
    'sheriff', 'sheriff2',
    -- State Police
    'stanier2',
    -- Motorosok
    'policet', 'sheriff3',
    -- FBI / FIB
    'fbi',  'fbi2',
    -- Egyéb rendvédelmi
    'riot',  'riot2', 'pranger',
}

-- ── Kamera viselkedés ───────────────────────────────────────────
-- Automatikusan leálljon-e ha a játékos kiszáll a járműből
Config.StopOnExit     = true

-- Folyamatos szerver szinkron (más rendőrök látják-e az állapotot)
Config.SyncState      = true

-- ── Időformátum ─────────────────────────────────────────────────
-- Használható: '24h' | '12h'
Config.TimeFormat     = '24h'

-- ── Overlay elemek engedélyezése ────────────────────────────────
Config.ShowRealTime   = true    -- Valós idő (OS)
Config.ShowGameTime   = true    -- Játékbeli idő (GetClockHours)
Config.ShowDate       = true    -- Valós dátum
Config.ShowUnit       = true    -- Egységszám / callsign
Config.ShowGPS        = true    -- Koordináták
Config.ShowSpeed      = true    -- Jármű sebesség km/h

-- ── Rögzítés villogó ─────────────────────────────────────────────
-- Villogó REC pötty intervalluma ms-ben
Config.RecBlinkMs     = 800

-- ── Locale ───────────────────────────────────────────────────────
Config.Locale = {
    not_in_vehicle     = 'Csak járműben kapcsolható be a dashcam.',
    not_emergency_veh  = 'Ez a jármű nem rendvédelmi egység.',
    not_authorized     = 'Nincs jogosultságod a dashcam használatához.',
    cam_on             = 'Axon DashCam: AKTÍV',
    cam_off            = 'Axon DashCam: KIKAPCSOLVA',
    exited_vehicle     = 'DashCam automatikusan leállt (kiszálltál).',
}
