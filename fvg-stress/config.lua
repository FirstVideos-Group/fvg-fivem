Config = {}

-- ── Tick intervallum ─────────────────────────────────────────
Config.TickRate = 2000   -- ms

-- ── Stressz szintek (0–100) ──────────────────────────────────
Config.Levels = {
    -- Neve, küszöb, és az alatta lévő szint hatásai
    { name = 'calm',     min =  0, max = 25  },
    { name = 'mild',     min = 26, max = 50  },
    { name = 'high',     min = 51, max = 75  },
    { name = 'critical', min = 76, max = 100 },
}

-- ── Automatikus csökkentés ────────────────────────────────────
-- Ennyit csökken a stressz tickenként ha nincs aktív stresszforrás
Config.PassiveDecreaseRate = 0.3   -- %/tick

-- ── Stresszforrások – automatikusan figyelve ──────────────────
Config.Triggers = {
    -- Lövöldözés: fegyver elsütésekor hozzáadott stressz
    shooting = {
        enabled   = true,
        addAmount = 2.5,
    },
    -- Ütés / bántalmazás elszenvedésekor
    beingShot = {
        enabled   = true,
        addAmount = 8.0,
    },
    -- Autóbaleset (sebesség zuhanás detektálás)
    carCrash = {
        enabled          = true,
        addAmount        = 6.0,
        speedDropRatio   = 0.6,
        minSpeed         = 30.0,
    },
    -- Rendőrök közelében (csillag aktív esetén)
    wanted = {
        enabled   = true,
        addAmount = 1.5,   -- %/tick amíg körözik
    },
    -- Sprint / futás
    sprinting = {
        enabled   = false,
        addAmount = 0.3,
    },
}

-- ── Hatások per szint ─────────────────────────────────────────
Config.Effects = {
    calm = {
        sweat       = 0.0,
        blur        = false,
        shake       = false,
        shakePower  = 0.0,
        screenTint  = false,
        moveRate    = 1.0,
    },
    mild = {
        sweat       = 30.0,
        blur        = false,
        shake       = false,
        shakePower  = 0.0,
        screenTint  = false,
        moveRate    = 1.0,
    },
    high = {
        sweat       = 70.0,
        blur        = true,
        shake       = true,
        shakePower  = 0.04,
        screenTint  = true,    -- enyhe vörös tint
        moveRate    = 0.95,
    },
    critical = {
        sweat       = 100.0,
        blur        = true,
        shake       = true,
        shakePower  = 0.09,
        screenTint  = true,
        moveRate    = 0.85,
        heartbeat   = true,    -- szívverés hang
    },
}

-- ── Blur beállítások ─────────────────────────────────────────
Config.BlurFadeTime    = 2.0    -- mp: TriggerScreenblurFadeIn/Out átmenet
Config.BlurInterval    = 8000   -- ms: milyen gyakran villog a blur (high szinten)
Config.BlurDuration    = 2500   -- ms: meddig tart egy blur epizód

-- ── Kamera rázás ─────────────────────────────────────────────
Config.ShakeType = 'HAND_SHAKE'   -- HAND_SHAKE | SMALL_EXPLOSION_SHAKE | stb.

-- ── Szívverés hang ───────────────────────────────────────────
Config.HeartbeatSound    = 'HEARTBEAT'
Config.HeartbeatSoundSet = 'PLAYER_HEALTH_CRITICAL_SOUNDSET'

-- ── Értesítési küszöbök ──────────────────────────────────────
Config.NotifyOnLevelChange = true
Config.NotifyIntervalMs    = 90000   -- 1.5 perc minimum szünet

-- ── Integrációk ──────────────────────────────────────────────
Config.HudIntegration        = true
Config.HudResource           = 'fvg-hud'
Config.HudModuleName         = 'stress'
Config.NotifyIntegration     = true
Config.PlayerCoreIntegration = true

-- ── Locale ───────────────────────────────────────────────────
Config.Locale = {
    level_mild     = 'Egy kicsit stresszes vagy.',
    level_high     = 'Nagyon stresszes vagy! Pihenj le!',
    level_critical = 'Kritikus stressz szint! Azonnal lazíts!',
    level_calm     = 'Megnyugodtál.',
}