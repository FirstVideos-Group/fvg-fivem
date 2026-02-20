Config = {}

-- HUD frissítési intervallum milliszekundumban
Config.TickRate = 100

-- Alapértelmezett pozíció: 'bottom-left', 'bottom-right', 'top-left', 'top-right'
Config.Position = 'bottom-right'

-- Natív GTA V életerő max értéke (200 = teljes)
Config.MaxHealth  = 200
Config.MinHealth  = 100  -- 100 alatt hal meg a karakter

-- Stamina küszöb - ez alatt jelenjen meg (0-100 skálán)
Config.StaminaShowThreshold = 99.0

-- Oxigén küszöb – ez alatt jelenjen meg (0-100 skálán)
Config.OxygenShowThreshold = 99.0

-- Modulok engedélyezése/tiltása
-- Ha false, a modul teljesen inaktív (nem tölt be, nem jelenít meg adatot)
Config.Modules = {
    health  = { enabled = true,  order = 1 },
    shield  = { enabled = true,  order = 2 },
    stamina = { enabled = true,  order = 3 },
    food    = { enabled = true,  order = 4 },
    water   = { enabled = true,  order = 5 },
    oxygen  = { enabled = true,  order = 6 },
    stress  = { enabled = true,  order = 7 },
}