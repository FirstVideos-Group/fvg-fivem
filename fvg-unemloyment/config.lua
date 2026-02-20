Config = {}

-- ── Munkanélküli segély ───────────────────────────────────────
Config.BenefitAmount        = 500          -- $, alkalmanként
Config.BenefitCooldown      = 3600         -- másodperc (1 óra)
Config.BenefitMaxClaims     = 8            -- max igénylés összesen (reset jobbváltásnál)
Config.BenefitEligibleJob   = 'unemployed' -- ez a job jogosít segélyre

-- ── Munkaügyi hivatal helyszín ────────────────────────────────
Config.OfficeLocation = {
    coords  = vector4(-327.87, -700.35, 33.47, 114.0),
    marker  = true,
    blip    = true,
    blipSprite = 408,
    blipColor  = 3,
    blipLabel  = 'Munkaügyi Hivatal',
}

-- ── Állás hirdetések ──────────────────────────────────────────
-- Ezek a "legális belépő szintű" állások, melyekre bárki jelentkezhet
-- A tényleges job-váltást az fvg-playercore kezeli
Config.Jobs = {
    {
        id          = 'taxi',
        label       = 'Taxisofőr',
        description = 'Szállítsd a városiak utasokat biztonságosan és gyorsan.',
        salary      = { min = 800,  max = 1200 },
        icon        = 'hgi-stroke hgi-taxi',
        color       = '#f59e0b',
        requirements= { minAge = 18, license = 'driving' },
        slots       = 20,   -- max létszám (0 = korlátlan)
        open        = true,
    },
    {
        id          = 'trucker',
        label       = 'Kamionsofőr',
        description = 'Áruszállítás a város és a megye területén.',
        salary      = { min = 1000, max = 1600 },
        icon        = 'hgi-stroke hgi-truck-delivery',
        color       = '#f97316',
        requirements= { minAge = 21, license = 'driving' },
        slots       = 15,
        open        = true,
    },
    {
        id          = 'fisherman',
        label       = 'Halász',
        description = 'Friss halak fogása és értékesítése a kikötőben.',
        salary      = { min = 600,  max = 1000 },
        icon        = 'hgi-stroke hgi-fishing',
        color       = '#38bdf8',
        requirements= { minAge = 18 },
        slots       = 0,
        open        = true,
    },
    {
        id          = 'miner',
        label       = 'Bányász',
        description = 'Ásványok kitermelése a Sandy Shores bányában.',
        salary      = { min = 900,  max = 1400 },
        icon        = 'hgi-stroke hgi-mine',
        color       = '#a78bfa',
        requirements= { minAge = 18 },
        slots       = 10,
        open        = true,
    },
    {
        id          = 'farmer',
        label       = 'Farmer',
        description = 'Mezőgazdasági munka a Blaine County farmjain.',
        salary      = { min = 700,  max = 1100 },
        icon        = 'hgi-stroke hgi-farmer',
        color       = '#22c55e',
        requirements= { minAge = 18 },
        slots       = 0,
        open        = true,
    },
    {
        id          = 'garbage',
        label       = 'Szemétszállító',
        description = 'Kommunális hulladékgyűjtés a városi körzetekben.',
        salary      = { min = 750,  max = 1050 },
        icon        = 'hgi-stroke hgi-recycle-03',
        color       = '#84cc16',
        requirements= { minAge = 18, license = 'driving' },
        slots       = 12,
        open        = true,
    },
    {
        id          = 'courier',
        label       = 'Futár',
        description = 'Csomagkézbesítés a városon belül kerékpárral vagy motorral.',
        salary      = { min = 650,  max = 950 },
        icon        = 'hgi-stroke hgi-package-delivered',
        color       = '#ec4899',
        requirements= { minAge = 18 },
        slots       = 0,
        open        = true,
    },
}

-- ── Aktivitás feladatok (napi álláskeresési feladatok) ─────────
Config.DailyTasks = {
    {
        id     = 'collect_items',
        label  = 'Gyűjts 10 alapanyagot',
        reward = 200,
        type   = 'inventory',  -- fvg-inventory item count ellenőrzés
        item   = 'iron',
        amount = 10,
    },
    {
        id     = 'visit_office',
        label  = 'Látogass el a munkaügyi hivatalba',
        reward = 100,
        type   = 'location',
    },
    {
        id     = 'earn_money',
        label  = 'Keress 500$ készpénzt',
        reward = 150,
        type   = 'cash',
        amount = 500,
    },
}

-- ── Értesítések ───────────────────────────────────────────────
Config.Notifications = {
    benefit_claimed  = 'Munkanélküli segély igényelve: $',
    benefit_cooldown = 'Még nem igényelhetsz segélyt. Következő igénylés: ',
    benefit_maxed    = 'Elérted a maximális segélyigénylési limitet.',
    benefit_ineligible = 'Nem vagy jogosult munkanélküli segélyre.',
    job_applied      = 'Sikeresen jelentkeztél a következő állásra: ',
    job_no_slots     = 'Sajnos ez az állás már betelt.',
    job_requirements = 'Nem felelsz meg a követelményeknek.',
    job_already      = 'Már rendelkezel állással.',
    task_completed   = 'Napi feladat teljesítve! Jutalom: $',
}

-- ── Integráció ────────────────────────────────────────────────
Config.UseBankingForBenefit = true  -- fvg-banking-ba kerül a segély
Config.UseInventoryTasks    = true  -- fvg-inventory alapú napi feladatok
Config.UseIdCardLicenseCheck = true -- fvg-idcard jogosítvány ellenőrzés