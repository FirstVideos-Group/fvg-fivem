Config = {}

-- ── Fizetési módok ────────────────────────────────────────────
-- 'cash'    → fvg-playercore cash
-- 'bank'    → fvg-banking checking számla
-- 'both'    → játékos választ
Config.DefaultPaymentMethod = 'both'

-- ── Animáció ─────────────────────────────────────────────────
Config.UseAnimation    = true
Config.BuyAnim = {
    dict     = 'mp_common',
    anim     = 'givetake1_a',
    duration = 1500,
}

-- ── Készletkezelés ────────────────────────────────────────────
Config.UseStock        = true     -- Ha false: végtelen készlet
Config.StockRegenTime  = 600      -- másodperc, ennyi időnként töltődik újra
Config.StockRegenAmount= 10       -- ennyivel töltődik minden alkalommal

-- ── Interakció ────────────────────────────────────────────────
Config.ShopRadius      = 2.0
Config.BlipShortRange  = true

-- ── Bolt definíciók ───────────────────────────────────────────
Config.Shops = {

    -- ════════════════════════════════════════════════
    --  24/7 ÁLTALÁNOS ÉLELMISZER BOLTOK
    -- ════════════════════════════════════════════════
    {
        id     = 'convenience_1',
        label  = '24/7 – Downtown',
        type   = 'convenience',
        coords = vector3(25.24, -1347.06, 29.50),
        heading= 271.0,
        blip   = { sprite = 52, color = 2,  scale = 0.75 },
        npc    = { model = 's_m_m_shopkeep_01', coords = vector4(25.07, -1341.42, 29.50, 93.0) },
        paymentMethod = 'both',
        categories = { 'food', 'drink', 'medical', 'misc' },
    },
    {
        id     = 'convenience_2',
        label  = '24/7 – Strawberry',
        type   = 'convenience',
        coords = vector3(-704.79, -913.52, 19.22),
        heading= 180.0,
        blip   = { sprite = 52, color = 2,  scale = 0.75 },
        npc    = { model = 's_m_m_shopkeep_01', coords = vector4(-708.58, -908.11, 19.22, 184.0) },
        paymentMethod = 'both',
        categories = { 'food', 'drink', 'medical', 'misc' },
    },
    {
        id     = 'convenience_3',
        label  = '24/7 – Sandy Shores',
        type   = 'convenience',
        coords = vector3(1732.72, 6416.50, 35.04),
        heading= 91.0,
        blip   = { sprite = 52, color = 2,  scale = 0.75 },
        npc    = { model = 's_m_m_shopkeep_01', coords = vector4(1736.62, 6416.68, 35.04, 269.0) },
        paymentMethod = 'both',
        categories = { 'food', 'drink', 'medical', 'misc' },
    },

    -- ════════════════════════════════════════════════
    --  GYÓGYSZERTÁR
    -- ════════════════════════════════════════════════
    {
        id     = 'pharmacy_1',
        label  = 'Pillbox Gyógyszertár',
        type   = 'pharmacy',
        coords = vector3(302.49, -592.43, 43.28),
        heading= 70.0,
        blip   = { sprite = 58, color = 3,  scale = 0.75 },
        npc    = { model = 's_f_y_shop_med', coords = vector4(307.73, -596.25, 43.28, 250.0) },
        paymentMethod = 'both',
        categories = { 'medical', 'medical_adv' },
    },

    -- ════════════════════════════════════════════════
    --  FEGYVERBOLT
    -- ════════════════════════════════════════════════
    {
        id          = 'gunshop_1',
        label       = 'Ammu-Nation – Downtown',
        type        = 'gunshop',
        coords      = vector3(23.01, -1106.93, 29.80),
        heading     = 340.0,
        blip        = { sprite = 110, color = 1, scale = 0.75 },
        npc         = { model = 's_m_y_ammucity_01', coords = vector4(21.12, -1098.62, 29.80, 162.0) },
        paymentMethod = 'both',
        requiredJob = nil,   -- nil = mindenki, vagy pl. 'police'
        requiredLicense = 'weapon',  -- fvg-idcard licensz ellenőrzés
        categories  = { 'weapon', 'ammo', 'weapon_acc' },
    },

    -- ════════════════════════════════════════════════
    --  RUHABOLT
    -- ════════════════════════════════════════════════
    {
        id     = 'clothing_1',
        label  = 'Suburban – Vinewood',
        type   = 'clothing',
        coords = vector3(127.26, -222.59, 54.56),
        heading= 160.0,
        blip   = { sprite = 73, color = 4,  scale = 0.75 },
        npc    = { model = 's_f_y_shop_cloth', coords = vector4(129.30, -216.57, 54.56, 340.0) },
        paymentMethod = 'both',
        categories = { 'clothing' },
    },

    -- ════════════════════════════════════════════════
    --  ÉLELMISZER PIAC
    -- ════════════════════════════════════════════════
    {
        id     = 'market_1',
        label  = 'Vespucci Piac',
        type   = 'market',
        coords = vector3(-1226.55, -898.45, 12.99),
        heading= 71.0,
        blip   = { sprite = 52, color = 69, scale = 0.75 },
        npc    = { model = 'a_m_m_indian_01', coords = vector4(-1222.33, -897.44, 12.99, 249.0) },
        paymentMethod = 'cash',
        categories = { 'food', 'drink' },
    },
}

-- ── Kategóriák ────────────────────────────────────────────────
Config.Categories = {
    food       = { label = 'Étel',          icon = 'hgi-stroke hgi-burger-01' },
    drink      = { label = 'Ital',          icon = 'hgi-stroke hgi-tea-02' },
    medical    = { label = 'Gyógyszer',     icon = 'hgi-stroke hgi-medicine-02' },
    medical_adv= { label = 'Haladó orvosi', icon = 'hgi-stroke hgi-medical-mask' },
    misc       = { label = 'Egyéb',         icon = 'hgi-stroke hgi-package-01' },
    weapon     = { label = 'Fegyver',       icon = 'hgi-stroke hgi-sword-02' },
    ammo       = { label = 'Lőszer',        icon = 'hgi-stroke hgi-target-02' },
    weapon_acc = { label = 'Kiegészítők',   icon = 'hgi-stroke hgi-settings-02' },
    clothing   = { label = 'Ruha',          icon = 'hgi-stroke hgi-t-shirt' },
}

-- ── Termékek ──────────────────────────────────────────────────
-- Minden termékhez: item (fvg-inventory item neve), label, price, category,
--                   stock (nil = végtelen), maxPerPurchase, icon, description
Config.Items = {

    -- ── Étel ─────────────────────────────────────────────────
    { item='burger',         label='Hamburger',        price=8,    category='food',     stock=50,  maxPerPurchase=5,  icon='hgi-stroke hgi-burger-01',       description='Visszatölti az éhség csíkot.' },
    { item='hotdog',         label='Hot Dog',          price=5,    category='food',     stock=50,  maxPerPurchase=5,  icon='hgi-stroke hgi-hot-dog',         description='Gyors snack.' },
    { item='sandwich',       label='Szendvics',        price=6,    category='food',     stock=50,  maxPerPurchase=5,  icon='hgi-stroke hgi-bread-01',        description='Házi szendvics.' },
    { item='apple',          label='Alma',             price=2,    category='food',     stock=100, maxPerPurchase=10, icon='hgi-stroke hgi-apple-02',        description='Friss gyümölcs.' },
    { item='chips',          label='Chips',            price=3,    category='food',     stock=80,  maxPerPurchase=10, icon='hgi-stroke hgi-cookie',          description='Sós snack.' },
    { item='donut',          label='Fánk',             price=4,    category='food',     stock=60,  maxPerPurchase=5,  icon='hgi-stroke hgi-donut',           description='Édes fánk.' },

    -- ── Ital ─────────────────────────────────────────────────
    { item='water',          label='Víz',              price=2,    category='drink',    stock=100, maxPerPurchase=10, icon='hgi-stroke hgi-water-polo',      description='Szomjúságot csökkenti.' },
    { item='cola',           label='Cola',             price=3,    category='drink',    stock=80,  maxPerPurchase=10, icon='hgi-stroke hgi-coffee-02',       description='Üdítő ital.' },
    { item='coffee',         label='Kávé',             price=4,    category='drink',    stock=60,  maxPerPurchase=5,  icon='hgi-stroke hgi-coffee-02',       description='Ébresztő hatású.' },
    { item='energydrink',    label='Energiaital',      price=6,    category='drink',    stock=40,  maxPerPurchase=3,  icon='hgi-stroke hgi-tea-02',          description='+energia bónusz.' },
    { item='beer',           label='Sör',              price=5,    category='drink',    stock=60,  maxPerPurchase=6,  icon='hgi-stroke hgi-beer',            description='Alkoholos ital.' },

    -- ── Gyógyszer (alap) ──────────────────────────────────────
    { item='bandage',        label='Kötszer',          price=15,   category='medical',  stock=30,  maxPerPurchase=5,  icon='hgi-stroke hgi-bandage',         description='Kis sebek kezelésére.' },
    { item='painkillers',    label='Fájdalomcsillapító',price=25,  category='medical',  stock=30,  maxPerPurchase=5,  icon='hgi-stroke hgi-medicine-02',     description='HP visszatöltés.' },
    { item='firstaidkit',    label='Elsősegély csomag', price=80,  category='medical',  stock=15,  maxPerPurchase=2,  icon='hgi-stroke hgi-first-aid-kit',   description='Közepes sebesülés ellátása.' },

    -- ── Gyógyszer (haladó) ────────────────────────────────────
    { item='medkit',         label='Orvosi táska',     price=250,  category='medical_adv', stock=5, maxPerPurchase=1, icon='hgi-stroke hgi-medical-mask',   description='Súlyos sérülések kezelése.' },
    { item='adrenaline',     label='Adrenalin',        price=400,  category='medical_adv', stock=3, maxPerPurchase=1, icon='hgi-stroke hgi-injection',      description='Azonnali HP visszatöltés.' },

    -- ── Fegyver ───────────────────────────────────────────────
    { item='weapon_pistol',  label='Pisztoly',         price=2500, category='weapon',   stock=10,  maxPerPurchase=1,  icon='hgi-stroke hgi-sword-02',        description='Alapvető kézifegyver.', requiredLicense='weapon' },
    { item='weapon_smg',     label='SMG',              price=5500, category='weapon',   stock=5,   maxPerPurchase=1,  icon='hgi-stroke hgi-sword-02',        description='Géppisztoly.', requiredLicense='weapon' },
    { item='weapon_shotgun', label='Sörétes',          price=4000, category='weapon',   stock=5,   maxPerPurchase=1,  icon='hgi-stroke hgi-sword-02',        description='Nagy hatótávolságú.', requiredLicense='weapon' },

    -- ── Lőszer ───────────────────────────────────────────────
    { item='ammo_pistol',    label='Pisztoly lőszer',  price=50,   category='ammo',     stock=200, maxPerPurchase=100,icon='hgi-stroke hgi-target-02',      description='9mm tölténytár.' },
    { item='ammo_smg',       label='SMG lőszer',       price=75,   category='ammo',     stock=150, maxPerPurchase=100,icon='hgi-stroke hgi-target-02',      description='SMG töltény.' },
    { item='ammo_shotgun',   label='Sörétes patron',   price=60,   category='ammo',     stock=150, maxPerPurchase=50, icon='hgi-stroke hgi-target-02',      description='Sörétes patron.' },

    -- ── Fegyver kiegészítő ───────────────────────────────────
    { item='weapon_silencer',label='Hangtompító',      price=1200, category='weapon_acc', stock=8, maxPerPurchase=1,  icon='hgi-stroke hgi-settings-02',    description='Csökkenti a zajszintet.', requiredLicense='weapon' },
    { item='weapon_flashlight',label='Taktikai lámpa', price=350,  category='weapon_acc', stock=15,maxPerPurchase=1,  icon='hgi-stroke hgi-flashlight',     description='Sötétben is célozható.', requiredLicense='weapon' },

    -- ── Ruha ─────────────────────────────────────────────────
    { item='tshirt_white',   label='Fehér póló',       price=30,   category='clothing', stock=nil, maxPerPurchase=3,  icon='hgi-stroke hgi-t-shirt',        description='Alap fehér póló.' },
    { item='jeans_blue',     label='Kék farmer',       price=55,   category='clothing', stock=nil, maxPerPurchase=2,  icon='hgi-stroke hgi-jeans',          description='Klasszikus farmer.' },
    { item='cap_black',      label='Fekete baseball sapka',price=25,category='clothing', stock=nil, maxPerPurchase=2,  icon='hgi-stroke hgi-hat',           description='Utcai sapka.' },

    -- ── Egyéb ─────────────────────────────────────────────────
    { item='map',            label='Térkép',           price=10,   category='misc',     stock=nil, maxPerPurchase=1,  icon='hgi-stroke hgi-map-01',         description='LS térkép.' },
    { item='lighter',        label='Öngyújtó',         price=5,    category='misc',     stock=nil, maxPerPurchase=5,  icon='hgi-stroke hgi-fire-02',        description='Tűzgyújtáshoz.' },
    { item='phone_charger',  label='Töltő',            price=20,   category='misc',     stock=nil, maxPerPurchase=1,  icon='hgi-stroke hgi-charging',       description='Telefon töltő.' },
}