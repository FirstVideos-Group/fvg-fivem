Config = Config or {}

-- ═══════════════════════════════════════════════════════════
--  RENDŐRSÉGI JÁRMŰVEK
--  class: egyezik a Config.Ranks vehicle_classes listájával
-- ═══════════════════════════════════════════════════════════
Config.Vehicles = {

    -- ── Patrol ──────────────────────────────────────────────
    {
        model      = 'police',
        label      = 'Police Cruiser',
        class      = 'patrol',
        livery     = 0,
        extras     = { [1]=true, [2]=true },
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'LSPD##',
        description= 'Alapjármű',
    },
    {
        model      = 'police2',
        label      = 'Police Buffalo',
        class      = 'patrol',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'LSPD##',
        description= 'Sport cruiser',
    },
    {
        model      = 'police3',
        label      = 'Police Interceptor',
        class      = 'patrol',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'LSPD##',
        description= 'Interceptor',
    },

    -- ── SUV ─────────────────────────────────────────────────
    {
        model      = 'policet',
        label      = 'Police Transporter',
        class      = 'suv',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'LSPD##',
        description= 'Fogolyszállító',
    },

    -- ── Unmarked ────────────────────────────────────────────
    {
        model      = 'police4',
        label      = 'Unmarked Cruiser',
        class      = 'unmarked',
        livery     = 0,
        colorPrimary = 12,
        colorSecondary = 12,
        plate      = 'CIV###',
        description= 'Civil rendőr',
    },

    -- ── Tactical ────────────────────────────────────────────
    {
        model      = 'riot',
        label      = 'NOOSE Riot Van',
        class      = 'tactical',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'NOOSE#',
        description= 'Taktikai szállító',
    },

    -- ── Command ─────────────────────────────────────────────
    {
        model      = 'FBI',
        label      = 'Command SUV',
        class      = 'command',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'CMD###',
        description= 'Parancsnoki jármű',
    },

    -- ── Special ─────────────────────────────────────────────
    {
        model      = 'policeold1',
        label      = 'Vintage Cruiser',
        class      = 'special',
        livery     = 0,
        colorPrimary = 0,
        colorSecondary = 0,
        plate      = 'LSPD##',
        description= 'Vintage cruiser',
    },
}

-- Jármű osztályok megjelenítési neve
Config.VehicleClassLabels = {
    patrol   = 'Járőr',
    suv      = 'SUV',
    unmarked = 'Civil',
    tactical = 'Taktikai',
    command  = 'Parancsnoki',
    special  = 'Különleges',
}