Config = {}

-- ── Tick intervallum ─────────────────────────────────────────
-- Ennyit vár a kliens a következő csökkenési lépés előtt (ms)
Config.TickRate = 5000   -- 5 másodperc

-- ── Szükségletek definíciója ─────────────────────────────────
-- Minden szükséglet testreszabható itt.
-- decreaseRate: ennyit csökken tickenként (0.0–100.0 skálán)
-- warnThreshold: ez alá esve figyelmeztetés jelenik meg
-- critThreshold: ez alá esve kritikus hatás lép életbe
-- effects: milyen hatások lépnek életbe az adott szinten
Config.Needs = {
    food = {
        label          = 'Éhség',
        icon           = 'hgi-stroke hgi-bread-01',
        decreaseRate   = 0.3,     -- %/tick járás közben
        idleRate       = 0.15,    -- %/tick állás közben
        warnThreshold  = 30,
        critThreshold  = 10,
        deadThreshold  = 0,
        effects = {
            warn = {
                screen   = true,       -- képernyő torzítás
                sweat    = false,
                movement = false,
            },
            crit = {
                screen   = true,
                sweat    = true,       -- izzadás effekt
                movement = true,       -- mozgás lassulás
                damage   = false,      -- HP csökkenés
            },
            dead = {
                damage = true,         -- folyamatos HP csökkenés
            }
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
            warn = {
                screen   = true,
                sweat    = false,
                movement = false,
            },
            crit = {
                screen   = true,
                sweat    = true,
                movement = false,
                damage   = false,
            },
            dead = {
                damage = true,
            }
        }
    },
}

-- ── Hatás beállítások ────────────────────────────────────────

-- Izzadás erőssége (0.0–100.0)
Config.SweatIntensity = 100.0

-- Mozgás lassulás klipset kritikus éhségnél
Config.HungryMoveClip = 'move_m@injured'

-- HP csökkenés mértéke tickenként ha 0-ra esett az érték
Config.StarveDamage = 1

-- Képernyő torzítás erőssége (0.0–1.0)
Config.ScreenEffectIntensity = 0.3

-- ── Értesítési küszöbök ──────────────────────────────────────
-- Ezekre az értékekre való első átlépéskor értesít (percenként max 1x)
Config.NotifyIntervalMs = 120000   -- 2 perc minimum értesítési szünet

-- ── HUD integráció ───────────────────────────────────────────
-- A fvg-hud "needs" modulját frissíti SetModuleValue-val
Config.HudIntegration    = true
Config.HudResource       = 'fvg-hud'
Config.HudModuleName     = 'needs'

-- ── Integrációk ──────────────────────────────────────────────
Config.NotifyIntegration  = true
Config.PlayerCoreIntegration = true

-- ── Locale ───────────────────────────────────────────────────
Config.Locale = {
    food_warn   = 'Éhes vagy! Egyél valamit!',
    food_crit   = 'Nagyon éhes vagy, gyengülsz!',
    food_dead   = 'Éhen halsz!',
    water_warn  = 'Szomjas vagy! Igyál valamit!',
    water_crit  = 'Nagyon szomjas vagy, gyengülsz!',
    water_dead  = 'Kiszáradtál!',
}