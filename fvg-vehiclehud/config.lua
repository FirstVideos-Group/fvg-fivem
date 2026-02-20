Config = {}

-- HUD frissítési intervallum milliszekundumban
Config.TickRate = 50

-- Sebesség mértékegysége: 'kmh' vagy 'mph'
Config.SpeedUnit = 'kmh'

-- Motor egészség küszöb (0–1000 skálán), ami alatt "sérült" állapot jelenik meg
Config.EngineHealthWarnThreshold  = 500
Config.EngineHealthCritThreshold  = 200

-- Üzemanyag küszöb (0–100), ami alatt "alacsony" figyelmeztetés jelenik meg
Config.FuelLowThreshold = 15

-- RPM küszöb, ami felett piros zónában van (0.0–1.0 skálán)
Config.RPMRedlineThreshold = 0.85

-- HUD pozíció: 'bottom-left', 'bottom-right', 'top-left', 'top-right'
Config.Position = 'bottom-left'

-- Modulok engedélyezése/tiltása és megjelenítési sorrendje
Config.Modules = {
    engine       = { enabled = true, order = 1 },
    speed        = { enabled = true, order = 2 },
    rpm          = { enabled = true, order = 3 },
    gear         = { enabled = true, order = 4 },
    lights       = { enabled = true, order = 5 },
    seatbelt     = { enabled = true, order = 6 },
    enginehealth = { enabled = true, order = 7 },
    fuel         = { enabled = true, order = 8 },
    siren        = { enabled = true, order = 9 },
}