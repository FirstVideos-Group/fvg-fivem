Config = {}

-- ── Traffipax zónák ───────────────────────────────────────────────
-- id       : egyedi azonosító (string)
-- label    : megjelenített név
-- coords   : az érzékelő középpontja
-- range    : érzékelési sugara méterben
-- limit    : sebességhatár km/h-ban
-- fine     : bírság alapösszeg ($)
-- enabled  : be/ki kapcsolható egyenként
Config.Zones = {
    {
        id      = 'downtown_1',
        label   = 'Downtown – Alta St.',
        coords  = { x = 219.0,  y = -810.0, z = 30.0 },
        range   = 40.0,
        limit   = 50,
        fine    = 800,
        enabled = true,
    },
    {
        id      = 'freeway_1',
        label   = 'Del Perro Freeway',
        coords  = { x = -639.0, y = -944.0, z = 22.0 },
        range   = 60.0,
        limit   = 100,
        fine    = 1200,
        enabled = true,
    },
    {
        id      = 'sandy_1',
        label   = 'Sandy Shores – Main St.',
        coords  = { x = 1870.0, y = 3692.0, z = 33.0 },
        range   = 45.0,
        limit   = 60,
        fine    = 600,
        enabled = true,
    },
    {
        id      = 'airport_1',
        label   = 'LSIA Környék',
        coords  = { x = -1057.0, y = -2822.0, z = 13.0 },
        range   = 80.0,
        limit   = 80,
        fine    = 1000,
        enabled = true,
    },
}

-- ── Büntetés beállítások ─────────────────────────────────────────
-- Túlsebessség alapján skálázó bírsság szorzó
-- például ha 30 km/h-val túl megy → 1.5x alap bírsság
Config.FineMultipliers = {
    { over = 0,  mul = 1.0  },   -- 1–10 km/h túlsebessség
    { over = 10, mul = 1.5  },   -- 11–20 km/h
    { over = 20, mul = 2.0  },   -- 21–30 km/h
    { over = 30, mul = 3.0  },   -- 31–40 km/h
    { over = 40, mul = 4.5  },   -- 41+  km/h → BOLO küldés
}

-- Ha a játékos ennyivel többet megy → automatikus BOLO (fvg-emergency)
Config.BOLOThreshold    = 40    -- km/h túlsebessség felett
Config.BOLOEnabled      = true

-- Bírsság fizetés módja
-- 'bank'  = fvg-banking checking számláról vonja le
-- 'cash'  = készpénzből vonja le
-- 'both'  = először készpénzből, ha nincs elég → bankból
Config.FineMethod       = 'both'

-- Ha nincs elég pénze: adosságba kerülön vagy előép a rendőrség (BOLO)
Config.DebtOnInsufficientFunds = true

-- Cooldown két büntetés között (ms) – ne kapjon minden frame-ben büntetést
Config.FineCooldown     = 60000  -- 60 másodperc

-- Sebesség ellenőrzés gyakorisága (ms)
Config.CheckInterval    = 500

-- NUI értesítés mikor közelg egy traffipaxhoz (méter)
Config.WarnRange        = 80.0

-- Mentett büntetések logolása
Config.LogEnabled       = true

-- fvg-police integráció: szolgálatban lévő rendőröknek jelzés küldése
Config.NotifyPolice     = true

-- Locale
Config.Locale = {
    speeding_fine    = 'Gyorshajtlási bírsság',
    fine_charged     = 'Traffipax bírsság: $',
    fine_no_money    = 'Nem volt elég pénzed – tartozásod keletkezett.',
    bolo_desc        = 'Súlyélyos gyorshajtlás – traffipax',
    warn_approaching = 'Traffipax közel! Sebességhatár: ',
    police_alert     = 'Traffipax: gyorshajtlás',
}
