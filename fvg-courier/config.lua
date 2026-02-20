Config = {}

-- ── Jogosult job ──────────────────────────────────────────────
Config.RequiredJob = 'courier'

-- ── Szolgálati pont (munkafelvétel) ──────────────────────────
Config.DepotLocation = {
    coords     = vector4(117.36, -1080.54, 29.19, 188.0),
    blipSprite = 478,
    blipColor  = 5,
    blipLabel  = 'Futár Depot',
    markerType = 1,
}

-- ── Jármű ────────────────────────────────────────────────────
Config.CourierVehicle = {
    model     = 'faggio2',       -- motor/kerékpár/kis teherautó
    spawnOffset = vector3(0, -3, 0),
    heading   = 188.0,
    plate     = 'FUTÁR',
    extras    = {},
}
Config.DeleteVehicleOnDutyEnd = true

-- ── Csomag item (fvg-inventory) ───────────────────────────────
Config.PackageItem  = 'courier_package'
Config.PackageLabel = 'Csomag'
Config.PackagesPerRun = 5          -- ennyi csomagot kell kézbesíteni egyetlen kör alatt

-- ── Kézbesítési helyszínek ────────────────────────────────────
-- Ezekből random választ a rendszer
Config.DeliverySpots = {
    { label = 'Alta Street apartmanok',       coords = vector3(133.45,  -833.17,  31.09) },
    { label = 'Pillbox Hill posta',           coords = vector3(203.74,  -942.33,  30.69) },
    { label = 'Vinewood Blvd.',               coords = vector3(82.65,   -1401.21, 29.38) },
    { label = 'Del Perro strand',             coords = vector3(-1672.88, -1012.73, 13.14) },
    { label = 'Hawick Ave. fodrász',          coords = vector3(-56.59,  -97.97,   56.99) },
    { label = 'Mirror Park utca',             coords = vector3(1159.37, -314.27,  69.21) },
    { label = 'Strawberry Ave.',              coords = vector3(-286.77, -1457.12, 31.13) },
    { label = 'Vespucci piac',               coords = vector3(-1226.55, -898.45,  12.99) },
    { label = 'Rockford Hills rezidencia',    coords = vector3(-818.32, -5.23,    39.15) },
    { label = 'LS Olimpiai gimnázium',        coords = vector3(-545.95, -710.40,  31.34) },
    { label = 'Elysian Island kikötő',        coords = vector3(284.47,  -2512.51,  5.90) },
    { label = 'Sandy Shores ABC',             coords = vector3(1693.30, 3767.38,  34.29) },
    { label = 'Paleto Bay posta',             coords = vector3(-278.02, 6229.43,  31.46) },
    { label = 'Grapeseed farm',               coords = vector3(1700.78, 4927.03,  42.06) },
    { label = 'Chumash strand',               coords = vector3(-3193.82, 1049.96,  20.09) },
}

-- ── Időlimit ─────────────────────────────────────────────────
Config.DeliveryTimeLimit   = 600    -- másodperc (10 perc / csomag sor)
Config.DeliveryRadius      = 5.0    -- méter, ennyire kell közelíteni

-- ── Jutalom ──────────────────────────────────────────────────
Config.BaseReward          = 300    -- $, csomagонként
Config.TimeBonusThreshold  = 180    -- mp alatt kézbesítve = bónusz
Config.TimeBonus           = 150    -- $ bónusz
Config.StreakBonus          = 50    -- $ sorozat bónusz (minden 5. kör)
Config.PerfectRunBonus     = 500    -- $ ha minden csomag időn belül kézbesítve
Config.UseBanking          = true   -- fvg-banking vagy cash

-- ── XP rendszer ──────────────────────────────────────────────
Config.XPPerDelivery       = 10
Config.XPStreak            = 5      -- sorozat bónusz XP / csomag
Config.Levels = {
    { level = 1, label = 'Kezdő futár',       xpRequired = 0,    rewardMult = 1.0 },
    { level = 2, label = 'Tapasztalt futár',  xpRequired = 200,  rewardMult = 1.1 },
    { level = 3, label = 'Senior futár',      xpRequired = 500,  rewardMult = 1.2 },
    { level = 4, label = 'Profi futár',       xpRequired = 1000, rewardMult = 1.35 },
    { level = 5, label = 'Elit futár',        xpRequired = 2000, rewardMult = 1.5 },
}

-- ── Integráció ────────────────────────────────────────────────
Config.UseInventoryPackages = true   -- fvg-inventory csomag item kezelés
Config.UseDispatch          = true   -- fvg-dispatch értesítés (elveszett csomagnál)
Config.UseIdCard            = true   -- fvg-idcard jogosítvány ellenőrzés
Config.NotifyOnPickup       = true

-- ── NPC kézbesítési animáció ─────────────────────────────────
Config.DeliveryAnim = {
    dict   = 'anim@heists@box_carry@',
    anim   = 'idle',
    duration = 3000,
}