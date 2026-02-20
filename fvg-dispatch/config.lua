Config = {}

-- ── Riasztás típusok ──────────────────────────────────────────
Config.AlertTypes = {
    -- Rendőrség
    police = {
        label    = 'Rendőrség',
        icon     = 'hgi-stroke hgi-shield-user',
        color    = '#3b82f6',
        blip     = 161,
        blipColor= 3,
        sound    = 'GTAO_FM_Events_Soundset',
        jobs     = { 'police', 'sheriff', 'admin', 'superadmin' },
    },
    -- Mentők
    ems = {
        label    = 'Mentők',
        icon     = 'hgi-stroke hgi-heart-add',
        color    = '#ef4444',
        blip     = 153,
        blipColor= 1,
        sound    = 'GTAO_FM_Events_Soundset',
        jobs     = { 'ems', 'doctor', 'admin', 'superadmin' },
    },
    -- Tűzoltók
    fire = {
        label    = 'Tűzoltók',
        icon     = 'hgi-stroke hgi-fire-02',
        color    = '#f97316',
        blip     = 436,
        blipColor= 1,
        sound    = 'GTAO_FM_Events_Soundset',
        jobs     = { 'fire', 'admin', 'superadmin' },
    },
    -- Közlekedési rendőrség
    traffic = {
        label    = 'Közlekedési',
        icon     = 'hgi-stroke hgi-steering-wheel',
        color    = '#f59e0b',
        blip     = 164,
        blipColor= 5,
        sound    = 'GTAO_FM_Events_Soundset',
        jobs     = { 'police', 'traffic', 'admin' },
    },
    -- Bármely egység
    all = {
        label    = 'Általános',
        icon     = 'hgi-stroke hgi-radio-02',
        color    = '#38bdf8',
        blip     = 1,
        blipColor= 3,
        sound    = 'GTAO_FM_Events_Soundset',
        jobs     = { 'police', 'ems', 'fire', 'traffic', 'admin', 'superadmin' },
    },
}

-- ── Prioritási szintek ────────────────────────────────────────
Config.Priorities = {
    { level = 1, label = 'Alacsony',  color = '#22c55e', pulse = false },
    { level = 2, label = 'Közepes',   color = '#f59e0b', pulse = false },
    { level = 3, label = 'Magas',     color = '#f97316', pulse = true  },
    { level = 4, label = 'Kritikus',  color = '#ef4444', pulse = true  },
}

-- ── Előre definiált riasztás sablonok ─────────────────────────
-- Más scriptek ezeket triggerlik (pl. fvg-idcard körözésnél)
Config.Templates = {
    wanted = {
        type     = 'police',
        priority = 3,
        title    = 'Körözött személy',
        icon     = 'hgi-stroke hgi-alert-02',
    },
    shooting = {
        type     = 'police',
        priority = 4,
        title    = 'Lövöldözés',
        icon     = 'hgi-stroke hgi-sword-02',
    },
    robbery = {
        type     = 'police',
        priority = 4,
        title    = 'Rablás',
        icon     = 'hgi-stroke hgi-money-bag-02',
    },
    vehicle_crash = {
        type     = 'ems',
        priority = 2,
        title    = 'Balesetkárjelzés',
        icon     = 'hgi-stroke hgi-car-03',
    },
    medical = {
        type     = 'ems',
        priority = 3,
        title    = 'Orvosi segítség',
        icon     = 'hgi-stroke hgi-heart-add',
    },
    fire = {
        type     = 'fire',
        priority = 3,
        title    = 'Tűzjelzés',
        icon     = 'hgi-stroke hgi-fire-02',
    },
    panic_button = {
        type     = 'police',
        priority = 4,
        title    = 'Pánikgomb aktiválva',
        icon     = 'hgi-stroke hgi-alert-circle',
    },
}

-- ── Dispatch panel hozzáférés ─────────────────────────────────
Config.DispatchJobs = { 'police', 'ems', 'fire', 'traffic', 'admin', 'superadmin' }

-- ── Riasztás lejárat ──────────────────────────────────────────
Config.AlertExpiry      = 600       -- másodperc (0 = nem jár le)
Config.MaxActiveAlerts  = 50        -- max egyidejű aktív riasztás

-- ── Blip beállítások ─────────────────────────────────────────
Config.BlipScale        = 0.8
Config.BlipTimeout      = 60        -- másodperc, utána eltűnik a blip

-- ── Hang ─────────────────────────────────────────────────────
Config.EnableSound      = true
Config.SoundName        = 'Menu_Accept'
Config.SoundRef         = 'HUD_FRONTEND_DEFAULT_SOUNDSET'

-- ── Pánikgomb ────────────────────────────────────────────────
Config.PanicButtonKey   = 'F9'
Config.PanicButtonCmd   = 'panic'

-- ── Chat log ─────────────────────────────────────────────────
Config.LogToChat        = false     -- dispatch üzenetek chatbe is?