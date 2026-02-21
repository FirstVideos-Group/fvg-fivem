Config = Config or {}

-- ═══════════════════════════════════════════════════════════
--  ALAP BEÁLLÍTÁSOK
-- ═══════════════════════════════════════════════════════════
Config.JobName        = 'police'
Config.JobLabel       = 'Rendőrség'
Config.JobIcon        = 'hgi-stroke hgi-police-badge-01'
Config.JobColor       = '#38bdf8'   -- UI fő szín

-- ═══════════════════════════════════════════════════════════
--  MODULOK – automatikus betöltés
--  Ha egy modult ki akarod kapcsolni, állítsd false-ra
-- ═══════════════════════════════════════════════════════════
Config.Modules = {
    garage   = { enabled = true,  label = 'Garázs',        icon = 'hgi-stroke hgi-garage' },
    unit     = { enabled = true,  label = 'Egység',         icon = 'hgi-stroke hgi-user-group' },
    clothing = { enabled = true,  label = 'Ruházat',        icon = 'hgi-stroke hgi-t-shirt' },
    storage  = { enabled = true,  label = 'Tárolók',        icon = 'hgi-stroke hgi-package-01' },
    weapons  = { enabled = true,  label = 'Fegyverek',      icon = 'hgi-stroke hgi-sword-02' },
    mdt      = { enabled = true,  label = 'MDT',            icon = 'hgi-stroke hgi-computer-01' },
    fines    = { enabled = true,  label = 'Bírság',         icon = 'hgi-stroke hgi-file-02' },
    prison   = { enabled = true,  label = 'Börtön',         icon = 'hgi-stroke hgi-jail' },
}

-- ═══════════════════════════════════════════════════════════
--  HELYSZÍNEK
-- ═══════════════════════════════════════════════════════════
Config.Locations = {
    -- Állomások (duty, öltöző, armoury stb.)
    stations = {
        {
            id     = 'mission_row',
            label  = 'Mission Row PD',
            coords = vector4(428.23, -984.42, 30.71, 5.0),
            blip   = { sprite=60, color=29, scale=0.7, label='MRPD' },
            -- Modulonkénti helyszínek az állomáson belül
            garage_spawn = vector4(446.82, -1017.79, 28.72, 357.0),
            locker_coords= vector3(455.06, -990.07, 30.69),
            armory_coords= vector3(479.99, -993.73, 30.69),
            storage_coords= vector3(461.85, -983.71, 30.69),
        },
        {
            id     = 'vinewood',
            label  = 'Vinewood Hills PD',
            coords = vector4(-604.40, 48.54, 101.53, 25.0),
            blip   = { sprite=60, color=29, scale=0.7, label='VHPD' },
            garage_spawn  = vector4(-612.0, 45.0, 100.0, 22.0),
            locker_coords = vector3(-601.0, 52.0, 101.5),
            armory_coords = vector3(-598.0, 44.0, 101.5),
            storage_coords= vector3(-605.0, 50.0, 101.5),
        },
    },

    -- Börtön
    prison = {
        inside  = vector3(1839.38, 2595.75, 45.67),
        outside = vector3(1848.12, 2587.85, 45.67),
        exit    = vector4(1853.53, 2586.46, 45.67, 270.0),
    },

    -- Közmunka területek
    community_service = {
        { id='ls_river',  label='LS Folyópart',     coords = vector3(-1181.28, -1568.10, 3.50),  task = 'sweep' },
        { id='maze_park', label='Maze Bank Park',   coords = vector3(235.46, 221.57, 106.31),     task = 'plant' },
        { id='del_perro', label='Del Perro Beach',  coords = vector3(-1674.64, -1066.18, 13.02),  task = 'trash' },
    },
}

-- ═══════════════════════════════════════════════════════════
--  DUTY
-- ═══════════════════════════════════════════════════════════
Config.DutyRadius     = 2.5
Config.MaxOfficers    = 32     -- max egyidejű rendőr

-- ═══════════════════════════════════════════════════════════
--  FIZETÉS
-- ═══════════════════════════════════════════════════════════
Config.SalaryInterval = 1800   -- másodpercenkénti ciklus
Config.SalaryMethod   = 'bank' -- 'cash' | 'bank'

-- ═══════════════════════════════════════════════════════════
--  PÁNIK GOMB
-- ═══════════════════════════════════════════════════════════
Config.PanicButton    = { key = 'F8', description = 'Pánik gomb' }

-- ═══════════════════════════════════════════════════════════
--  INTERAKCIÓ SUGÁR
-- ═══════════════════════════════════════════════════════════
Config.InteractRadius = 2.0