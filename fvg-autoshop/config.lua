Config = {}

-- ── Interakció ────────────────────────────────────────────────
Config.ShopRadius        = 2.5
Config.TestDriveRadius   = 5.0   -- visszatérési pont sugara
Config.BlipShortRange    = true

-- ── Részletfizetés ────────────────────────────────────────────
Config.EnableInstalments = true
Config.InstalmentOptions = {
    { months = 3,  interestRate = 0.0  },  -- 3 hónap, kamatmentes
    { months = 6,  interestRate = 0.05 },  -- 6 hónap, 5% kamat
    { months = 12, interestRate = 0.10 },  -- 12 hónap, 10% kamat
}
Config.InstalmentDownPayment = 0.20   -- 20% foglalón

-- ── Tesztvezetés ─────────────────────────────────────────────
Config.EnableTestDrive   = true
Config.TestDriveTime     = 180        -- másodperc
Config.TestDrivePlate    = 'TESZT'

-- ── Értékesítési visszaváltás ─────────────────────────────────
Config.SellBackPercent   = 0.65       -- vételár 65%-a visszajár eladásnál

-- ── Licensz ellenőrzés ────────────────────────────────────────
Config.RequireDriverLicense = true    -- fvg-idcard: driving licensz
Config.LicenseTypes = {
    car        = 'driving',
    motorcycle = 'motorcycle',
    boat       = 'boat',
}

-- ── Fizetési mód ──────────────────────────────────────────────
Config.AllowBankPayment  = true
Config.AllowCashPayment  = true

-- ── Kereskedések ─────────────────────────────────────────────
Config.Dealerships = {

    -- ═══════════════════════════════════════════════
    --  PREMIUM DELUXE MOTORSPORT
    -- ═══════════════════════════════════════════════
    {
        id     = 'pdm',
        label  = 'Premium Deluxe Motorsport',
        type   = 'car',
        coords = vector4(-47.01, -1098.75, 26.42, 335.0),
        spawnPoint = vector4(-55.0, -1098.0, 26.0, 340.0),
        blip   = { sprite = 326, color = 3, scale = 0.8, label = 'PDM Autókereskedés' },
        categories = { 'sedan', 'suv', 'sport', 'super', 'muscle', 'compact' },
    },

    -- ═══════════════════════════════════════════════
    --  SIMEON YETARIAN – LUXUSAUTÓK
    -- ═══════════════════════════════════════════════
    {
        id     = 'luxury',
        label  = 'Luxury Autos',
        type   = 'car',
        coords = vector4(-1394.19, -475.19, 30.01, 205.0),
        spawnPoint = vector4(-1395.0, -482.0, 30.0, 205.0),
        blip   = { sprite = 326, color = 69, scale = 0.8, label = 'Luxury Autos' },
        categories = { 'luxury', 'sport', 'super' },
    },

    -- ═══════════════════════════════════════════════
    --  MOTORCYCLES
    -- ═══════════════════════════════════════════════
    {
        id       = 'bikes',
        label    = 'Southern S.A. Super Autos – Motorok',
        type     = 'motorcycle',
        coords   = vector4(138.90, -1085.28, 29.17, 90.0),
        spawnPoint = vector4(148.0, -1090.0, 29.0, 90.0),
        blip     = { sprite = 326, color = 4, scale = 0.8, label = 'Motorkereskedés' },
        categories = { 'motorcycle' },
        requiredLicense = 'motorcycle',
    },

    -- ═══════════════════════════════════════════════
    --  USED CARS
    -- ═══════════════════════════════════════════════
    {
        id     = 'used',
        label  = 'Használtautó Piac',
        type   = 'car',
        coords = vector4(489.67, -1307.82, 29.42, 271.0),
        spawnPoint = vector4(497.0, -1313.0, 29.0, 271.0),
        blip   = { sprite = 326, color = 2, scale = 0.8, label = 'Használtautó' },
        categories = { 'sedan', 'suv', 'compact', 'van', 'offroad' },
        discount   = 0.85,   -- 15% kedvezmény
    },
}

-- ── Járművek ─────────────────────────────────────────────────
Config.Vehicles = {

    -- ─── Sedan ───────────────────────────────────────────────
    { model='asea',       label='Asea',              price=12000,  category='sedan',     dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=55, handling=55, braking=60, acceleration=55 }, description='Megbízható, gazdaságos városi autó.' },
    { model='premier',    label='Premier',            price=14500,  category='sedan',     dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=58, handling=57, braking=62, acceleration=57 }, description='Kényelmes szedán.' },
    { model='tailgater',  label='Tailgater',          price=55000,  category='sedan',     dealerships={'pdm'}, licenseType='car',
      stats={ speed=72, handling=70, braking=72, acceleration=70 }, description='Prémium szedán.' },

    -- ─── SUV ─────────────────────────────────────────────────
    { model='granger',    label='Granger',            price=35000,  category='suv',       dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=65, handling=60, braking=65, acceleration=60 }, description='Nagy méretű SUV.' },
    { model='huntley',    label='Huntley S',          price=75000,  category='suv',       dealerships={'pdm','luxury'}, licenseType='car',
      stats={ speed=70, handling=68, braking=70, acceleration=68 }, description='Luxus terepjáró.' },
    { model='cavalcade',  label='Cavalcade',          price=42000,  category='suv',       dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=67, handling=62, braking=67, acceleration=62 }, description='Családi SUV.' },

    -- ─── Sport ───────────────────────────────────────────────
    { model='jester',     label='Jester Classic',     price=125000, category='sport',     dealerships={'pdm','luxury'}, licenseType='car',
      stats={ speed=82, handling=80, braking=82, acceleration=80 }, description='Sportos kupé.' },
    { model='fcr',        label='FCR',                price=60000,  category='sport',     dealerships={'pdm'}, licenseType='car',
      stats={ speed=78, handling=75, braking=78, acceleration=75 }, description='Sportos roadster.' },
    { model='schafter3',  label='Schafter V12',       price=116000, category='sport',     dealerships={'pdm','luxury'}, licenseType='car',
      stats={ speed=80, handling=78, braking=80, acceleration=78 }, description='Luxus sportszedán.' },

    -- ─── Super ───────────────────────────────────────────────
    { model='adder',      label='Adder',              price=1000000,category='super',     dealerships={'luxury'}, licenseType='car',
      stats={ speed=99, handling=80, braking=85, acceleration=95 }, description='A legjobb szuperautó.' },
    { model='entityxf',   label='Entity XF',          price=795000, category='super',     dealerships={'luxury'}, licenseType='car',
      stats={ speed=97, handling=82, braking=86, acceleration=92 }, description='Brutális szuperkocsi.' },
    { model='zentorno',   label='Zentorno',            price=725000, category='super',     dealerships={'pdm','luxury'}, licenseType='car',
      stats={ speed=96, handling=83, braking=87, acceleration=91 }, description='Mid-engine monster.' },

    -- ─── Muscle ──────────────────────────────────────────────
    { model='dominator',  label='Dominator',          price=35000,  category='muscle',    dealerships={'pdm'}, licenseType='car',
      stats={ speed=75, handling=65, braking=70, acceleration=80 }, description='Klasszikus muscle car.' },
    { model='gauntlet',   label='Gauntlet',           price=32000,  category='muscle',    dealerships={'pdm'}, licenseType='car',
      stats={ speed=74, handling=64, braking=69, acceleration=78 }, description='V8 izomautó.' },
    { model='vigero',     label='Vigero',             price=27000,  category='muscle',    dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=72, handling=62, braking=68, acceleration=76 }, description='Retró izomautó.' },

    -- ─── Compact ─────────────────────────────────────────────
    { model='blista',     label='Blista',             price=16000,  category='compact',   dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=60, handling=65, braking=65, acceleration=60 }, description='Kis városautó.' },
    { model='issi2',      label='Issi Classic',       price=18000,  category='compact',   dealerships={'pdm','used'}, licenseType='car',
      stats={ speed=62, handling=68, braking=66, acceleration=62 }, description='Aranyos kis kocsikó.' },

    -- ─── Luxury ──────────────────────────────────────────────
    { model='cognoscenti', label='Cognoscenti',       price=250000, category='luxury',    dealerships={'luxury'}, licenseType='car',
      stats={ speed=78, handling=74, braking=78, acceleration=74 }, description='Legprémiumabb limuzin.' },
    { model='stretch',    label='Stretch',            price=180000, category='luxury',    dealerships={'luxury'}, licenseType='car',
      stats={ speed=70, handling=60, braking=68, acceleration=65 }, description='Limuzin extra hosszal.' },

    -- ─── Motorcycle ──────────────────────────────────────────
    { model='faggio2',    label='Faggio',             price=8000,   category='motorcycle',dealerships={'bikes'}, licenseType='motorcycle',
      stats={ speed=58, handling=70, braking=65, acceleration=62 }, description='Olasz robogó.' },
    { model='bati801',    label='Bati 801',           price=15000,  category='motorcycle',dealerships={'bikes'}, licenseType='motorcycle',
      stats={ speed=85, handling=75, braking=80, acceleration=88 }, description='Sport naked motor.' },
    { model='akuma',      label='Akuma',              price=12000,  category='motorcycle',dealerships={'bikes'}, licenseType='motorcycle',
      stats={ speed=82, handling=78, braking=78, acceleration=85 }, description='Szupersport.' },
    { model='daemon',     label='Daemon',             price=18000,  category='motorcycle',dealerships={'bikes'}, licenseType='motorcycle',
      stats={ speed=80, handling=72, braking=76, acceleration=82 }, description='Chopperr stílusú.' },

    -- ─── Van ─────────────────────────────────────────────────
    { model='speedo',     label='Speedo',             price=22000,  category='van',       dealerships={'used'}, licenseType='car',
      stats={ speed=55, handling=45, braking=55, acceleration=50 }, description='Kis furgon.' },
    { model='bison',      label='Bison',              price=28000,  category='van',       dealerships={'used'}, licenseType='car',
      stats={ speed=58, handling=48, braking=58, acceleration=52 }, description='Pickup teherautó.' },

    -- ─── Offroad ─────────────────────────────────────────────
    { model='mesa',       label='Mesa',               price=45000,  category='offroad',   dealerships={'used'}, licenseType='car',
      stats={ speed=65, handling=68, braking=65, acceleration=62 }, description='Terepjáró.' },
    { model='rebel2',     label='Rebel',              price=38000,  category='offroad',   dealerships={'used'}, licenseType='car',
      stats={ speed=68, handling=70, braking=67, acceleration=65 }, description='Klasszikus pickup offroad.' },
}

-- ── Kategória definíciók ──────────────────────────────────────
Config.Categories = {
    sedan      = { label = 'Szedán',      icon = 'hgi-stroke hgi-car-01' },
    suv        = { label = 'SUV',         icon = 'hgi-stroke hgi-car-03' },
    sport      = { label = 'Sport',       icon = 'hgi-stroke hgi-car-02' },
    super      = { label = 'Szuper',      icon = 'hgi-stroke hgi-car-04' },
    muscle     = { label = 'Muscle',      icon = 'hgi-stroke hgi-car-01' },
    compact    = { label = 'Kompakt',     icon = 'hgi-stroke hgi-car-02' },
    luxury     = { label = 'Luxus',       icon = 'hgi-stroke hgi-diamond-02' },
    motorcycle = { label = 'Motor',       icon = 'hgi-stroke hgi-motorbike-01' },
    van        = { label = 'Furgon',      icon = 'hgi-stroke hgi-truck-02' },
    offroad    = { label = 'Offroad',     icon = 'hgi-stroke hgi-car-03' },
}

-- ── Rendszám generálás ────────────────────────────────────────
Config.PlateFormat = 'AA-###-BB'  -- A=betű, #=szám, B=betű