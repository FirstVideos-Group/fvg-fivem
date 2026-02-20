Config = {}

-- ── Tick sebesség ────────────────────────────────────────────
Config.TickRate = 500   -- ms – elegendő ritkán vizsgálni

-- ── Motor sérülési küszöbök (0–1000) ────────────────────────
Config.Engine = {
    perfect  = 1000,   -- tökéletes
    good     =  800,   -- jó állapot
    warning  =  600,   -- figyelmeztetés (füst kezdődik)
    critical =  300,   -- kritikus (fekete füst, lassuló motor)
    dead     =  100,   -- leáll a motor
}

-- ── Karosszéria küszöbök (0–1000) ───────────────────────────
Config.Body = {
    perfect  = 1000,
    good     =  800,
    warning  =  500,
    critical =  200,
}

-- ── Motor leállítás kritikus sérülésnél ──────────────────────
-- Ha true és fvg-engine telepítve van, automatikusan leállítja a motort
Config.AutoStopEngineOnDead = true

-- ── Gumi defekt küszöb ───────────────────────────────────────
-- Ha a gumi egészség ez alá esik, "sérült" gumi értesítés
Config.TireWarningHealth = 200.0

-- ── Értesítési küszöbök ──────────────────────────────────────
-- Ezekre az értékekre való első átlépéskor értesít a rendszer
Config.NotifyOnThreshold = {
    engine = { 600, 300, 100 },   -- motor értékek
    body   = { 500, 200 },        -- karosszéria értékek
}

-- ── Vizsgált kerekek száma (általában 4, buszok 6, teherautók 8) ─
Config.MaxWheels = 8

-- ── Integrációk ─────────────────────────────────────────────
Config.VehicleHudIntegration  = true  -- fvg-vehiclehud enginehealth modul
Config.EngineIntegration       = true  -- fvg-engine leállítás
Config.NotifyIntegration       = true  -- fvg-notify értesítések

-- ── Locale ──────────────────────────────────────────────────
Config.Locale = {
    engine_warning  = 'A motor megsérült! Keress egy szerelőt.',
    engine_critical = 'A motor kritikusan sérült! Azonnal állj meg!',
    engine_dead     = 'A motor leállt a sérülések miatt.',
    body_warning    = 'A karosszéria megsérült.',
    body_critical   = 'A karosszéria kritikusan sérült!',
    tire_burst      = 'Defektet kaptál!',
    tire_fixed      = 'A gumikat megjavítottad.',
    repaired        = 'A jármű megjavítva.',
    engine_repaired = 'A motor megjavítva.',
    body_repaired   = 'A karosszéria megjavítva.',
}