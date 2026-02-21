Config = Config or {}

-- ═══════════════════════════════════════════════════════════
--  BÍRSÁG TÍPUSOK
--  Bővíthető – csak új sort kell hozzáadni
-- ═══════════════════════════════════════════════════════════
Config.FineCategories = {
    traffic  = { label = 'Közlekedési',   icon = 'hgi-stroke hgi-car-01' },
    criminal = { label = 'Bűnügyi',       icon = 'hgi-stroke hgi-police-badge-01' },
    public   = { label = 'Közrendi',      icon = 'hgi-stroke hgi-alert-02' },
    weapon   = { label = 'Fegyveres',     icon = 'hgi-stroke hgi-sword-02' },
    drug     = { label = 'Kábítószer',    icon = 'hgi-stroke hgi-medicine-02' },
    other    = { label = 'Egyéb',         icon = 'hgi-stroke hgi-file-02' },
}

Config.FineTypes = {
    -- ── Közlekedési ──────────────────────────────────────────
    { id='speeding_minor',    category='traffic',  label='Gyorshajtás (enyhe)',       min=200,  max=500,   jail=0,   points=1 },
    { id='speeding_major',    category='traffic',  label='Gyorshajtás (súlyos)',      min=500,  max=2000,  jail=0,   points=3 },
    { id='red_light',         category='traffic',  label='Piroson áthajtás',          min=300,  max=800,   jail=0,   points=2 },
    { id='dui',               category='traffic',  label='Ittas vezetés',             min=1500, max=5000,  jail=15,  points=5 },
    { id='reckless_driving',  category='traffic',  label='Veszélyes vezetés',         min=800,  max=3000,  jail=10,  points=4 },
    { id='no_license',        category='traffic',  label='Jogosulatlan vezetés',      min=1000, max=4000,  jail=20,  points=5 },
    { id='hit_and_run',       category='traffic',  label='Cserbenhagyás',             min=2000, max=8000,  jail=30,  points=5 },
    { id='illegal_parking',   category='traffic',  label='Szabálytalan parkolás',     min=100,  max=300,   jail=0,   points=0 },

    -- ── Bűnügyi ──────────────────────────────────────────────
    { id='assault',           category='criminal', label='Testi sértés',              min=2000, max=8000,  jail=30,  points=0 },
    { id='assault_officer',   category='criminal', label='Hivatalos személy bántalmazása', min=5000, max=15000, jail=60, points=0 },
    { id='theft',             category='criminal', label='Lopás',                     min=1000, max=5000,  jail=20,  points=0 },
    { id='robbery',           category='criminal', label='Rablás',                    min=5000, max=20000, jail=90,  points=0 },
    { id='murder',            category='criminal', label='Emberölés',                 min=0,    max=0,     jail=180, points=0 },
    { id='burglary',          category='criminal', label='Betörés',                   min=2000, max=10000, jail=45,  points=0 },
    { id='vandalism',         category='criminal', label='Rongálás',                  min=500,  max=3000,  jail=10,  points=0 },
    { id='resisting_arrest',  category='criminal', label='Elfogás akadályozása',      min=1000, max=4000,  jail=15,  points=0 },

    -- ── Közrendi ─────────────────────────────────────────────
    { id='public_intoxication',category='public', label='Közterületi itasság',        min=200,  max=800,   jail=5,   points=0 },
    { id='disorderly_conduct', category='public', label='Közösség megzavarása',       min=300,  max=1000,  jail=5,   points=0 },
    { id='trespassing',        category='public', label='Magánterületre behatolás',   min=500,  max=2000,  jail=10,  points=0 },

    -- ── Fegyveres ────────────────────────────────────────────
    { id='illegal_weapon',    category='weapon',   label='Illegális fegyver',         min=3000, max=12000, jail=60,  points=0 },
    { id='weapon_discharge',  category='weapon',   label='Fegyver elsütése tiltott helyen', min=2000, max=8000, jail=30, points=0 },
    { id='armed_robbery',     category='weapon',   label='Fegyveres rablás',          min=8000, max=25000, jail=120, points=0 },

    -- ── Kábítószer ───────────────────────────────────────────
    { id='drug_possession',   category='drug',     label='Kábítószer birtoklás',      min=2000, max=8000,  jail=30,  points=0 },
    { id='drug_trafficking',  category='drug',     label='Kábítószer terjesztés',     min=5000, max=20000, jail=90,  points=0 },

    -- ── Egyéb ─────────────────────────────────────────────────
    { id='false_report',      category='other',    label='Hamis feljelentés',         min=500,  max=2000,  jail=10,  points=0 },
    { id='custom',            category='other',    label='Egyedi bírság',             min=0,    max=99999, jail=0,   points=0 },
}

-- Börtön közmunka beállítások
Config.Prison = {
    maxTime          = 60,          -- perc
    communityService = true,        -- közmunka program aktív
    csTimeReduction  = 0.5,         -- közmunka: idő csökkentés szorzója (1 perc munka = 0.5 perc levonás)
    csTaskInterval   = 30,          -- másodperc, ennyi időnként adható pont
    releaseLocation  = vector4(1853.53, 2586.46, 45.67, 270.0),
}