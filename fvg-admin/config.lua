Config = {}

-- ── ACE jogosultság szintek ───────────────────────────────────
-- A FiveM ACE rendszerrel integrált szerepkörök
-- server.cfg-ben: add_ace identifier.license:xxx fvg.admin allow
Config.Permissions = {
    superadmin = 'fvg.superadmin',   -- teljes hozzáférés
    admin      = 'fvg.admin',        -- teljes hozzáférés (ban kivételével)
    moderator  = 'fvg.moderator',    -- kick, teleport, freeze
}

-- ── Funkció jogosultságok ─────────────────────────────────────
-- Melyik szerepkör milyen funkciókat érhet el
Config.FunctionPerms = {
    kick        = { 'moderator', 'admin', 'superadmin' },
    ban         = { 'admin', 'superadmin' },
    freeze      = { 'moderator', 'admin', 'superadmin' },
    teleport    = { 'moderator', 'admin', 'superadmin' },
    spectate    = { 'moderator', 'admin', 'superadmin' },
    godmode     = { 'admin', 'superadmin' },
    setneeds    = { 'admin', 'superadmin' },
    setstress   = { 'admin', 'superadmin' },
    revive      = { 'moderator', 'admin', 'superadmin' },
    setweather  = { 'admin', 'superadmin' },
    settime     = { 'admin', 'superadmin' },
    spawnveh    = { 'admin', 'superadmin' },
    deleteveh   = { 'admin', 'superadmin' },
    noclip      = { 'admin', 'superadmin' },
    announce    = { 'admin', 'superadmin' },
}

-- ── Ban rendszer ──────────────────────────────────────────────
Config.BanPermanentLabel = 'Örökre'
Config.BanDurations = {
    { label = '1 óra',     minutes = 60       },
    { label = '6 óra',     minutes = 360      },
    { label = '1 nap',     minutes = 1440     },
    { label = '3 nap',     minutes = 4320     },
    { label = '1 hét',     minutes = 10080    },
    { label = '1 hónap',   minutes = 43200    },
    { label = 'Örökre',    minutes = -1       },
}

-- ── Jármű spawn lista ─────────────────────────────────────────
Config.VehicleCategories = {
    { label = 'Autók',      vehicles = { 'adder', 'zentorno', 'nero', 'reaper', 't20', 'osiris', 'fmj', 'le7b', 'prototipo', 'xa21' } },
    { label = 'SUV-ok',     vehicles = { 'baller', 'baller2', 'cavalcade', 'dubsta', 'granger', 'radi', 'rebla', 'seminole', 'xls', 'xls2' } },
    { label = 'Rendőrség',  vehicles = { 'police', 'police2', 'police3', 'police4', 'policet', 'sheriff', 'sheriff2' } },
    { label = 'Motorok',    vehicles = { 'akuma', 'bati', 'bati2', 'carbonrs', 'daemon', 'defiler', 'gargoyle', 'hakuchou' } },
    { label = 'Repülők',    vehicles = { 'besra', 'hydra', 'lazer', 'luxor', 'luxor2', 'miljet', 'nimbus', 'shamal' } },
    { label = 'Helikopter', vehicles = { 'akula', 'annihilator', 'buzzard', 'buzzard2', 'frogger', 'maverick', 'savage' } },
    { label = 'Csónakok',   vehicles = { 'dinghy', 'dinghy2', 'jetmax', 'marquis', 'seashark', 'speeder', 'squalo', 'suntrap' } },
}

-- ── Időjárás opciók ───────────────────────────────────────────
Config.Weathers = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG', 'FOGGY',
    'OVERCAST', 'RAIN', 'THUNDER', 'CLEARING', 'NEUTRAL',
    'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN'
}

-- ── Noclip sebesség ───────────────────────────────────────────
Config.NoclipSpeed      = 1.5
Config.NoclipSpeedFast  = 6.0

-- ── Announce stílus ──────────────────────────────────────────
Config.AnnouncePrefix = '[ADMIN] '

-- ── Integrációk ──────────────────────────────────────────────
Config.NotifyIntegration = true