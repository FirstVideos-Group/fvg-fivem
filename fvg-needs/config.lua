Config = {}

-- ── Tick intervallum ───────────────────────────────────────────────────
Config.TickRate = 5000   -- 5 másodperc

-- ── Szükségletek definíciója ────────────────────────────────────────
Config.Needs = {
    food = {
        label          = 'Éhség',
        icon           = 'hgi-stroke hgi-bread-01',
        decreaseRate   = 0.3,
        idleRate       = 0.15,
        warnThreshold  = 30,
        critThreshold  = 10,
        deadThreshold  = 0,
        effects = {
            warn = { screen = true,  sweat = false, movement = false },
            crit = { screen = true,  sweat = true,  movement = true,  damage = false },
            dead = { damage = true }
        }
    },
    water = {
        label          = 'Szomjúság',
        icon           = 'hgi-stroke hgi-water',
        decreaseRate   = 0.5,
        idleRate       = 0.2,
        warnThreshold  = 30,
        critThreshold  = 10,
        deadThreshold  = 0,
        effects = {
            warn = { screen = true,  sweat = false, movement = false },
            crit = { screen = true,  sweat = true,  movement = false, damage = false },
            dead = { damage = true }
        }
    },
}

-- ── Hatás beállítások ───────────────────────────────────────────────
Config.SweatIntensity        = 100.0
Config.HungryMoveClip        = 'move_m@injured'
Config.StarveDamage          = 1
Config.ScreenEffectIntensity = 0.3

-- ── Értesítési küszöbök ───────────────────────────────────────────
Config.NotifyIntervalMs = 120000

-- ── HUD integráció ─────────────────────────────────────────────────
-- FIX: külön modult használunk food és water-re (nem egyetlen 'needs' nevet)
Config.HudIntegration         = true
Config.HudResource            = 'fvg-hud'
Config.HudFoodModuleName      = 'food'
Config.HudWaterModuleName     = 'water'

-- ── Integrációk ─────────────────────────────────────────────────────
Config.NotifyIntegration      = true
Config.PlayerCoreIntegration  = true

-- ── Locale ──────────────────────────────────────────────────────────────
Config.Locale = {
    food_warn   = 'Éhes vagy! Egyél valamit!',
    food_crit   = 'Nagyon éhes vagy, gyengülsz!',
    food_dead   = 'Éhen halsz!',
    water_warn  = 'Szomjas vagy! Igyál valamit!',
    water_crit  = 'Nagyon szomjas vagy, gyengülsz!',
    water_dead  = 'Kiszár adtál!',
}
