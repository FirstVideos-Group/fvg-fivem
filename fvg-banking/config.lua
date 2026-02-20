Config = {}

-- ── Számlák típusai ───────────────────────────────────────────
Config.AccountTypes = {
    checking = { label = 'Folyószámla',   icon = 'hgi-stroke hgi-bank',          color = '#38bdf8' },
    savings  = { label = 'Megtakarítás',  icon = 'hgi-stroke hgi-piggy-bank',     color = '#22c55e' },
}

-- ── Alapértelmezett egyenleg ──────────────────────────────────
Config.DefaultBalance    = 5000    -- $ kezdő egyenleg
Config.DefaultSavings    = 0

-- ── Készpénz limit ───────────────────────────────────────────
Config.MaxCashOnHand     = 50000   -- max kézpénz nálad
Config.MaxBankBalance    = 9999999 -- max bankegyenleg

-- ── Tranzakció limit ─────────────────────────────────────────
Config.MaxTransactionLog = 50      -- ennyi tranzakciót tárolunk

-- ── ATM helyszínek ────────────────────────────────────────────
Config.ATMLocations = {
    { coords = vector3(149.19,  -1042.79, 29.37),  heading = 340.0, model = 'prop_atm_01' },
    { coords = vector3(-1393.73, -583.53, 30.33),  heading = 117.0, model = 'prop_atm_02' },
    { coords = vector3(247.69,  -338.74,  44.92),  heading = 160.0, model = 'prop_atm_03' },
    { coords = vector3(-2963.03, 483.12,  15.70),  heading = 85.0,  model = 'prop_atm_01' },
    { coords = vector3(1175.19, 2706.69,  38.09),  heading = 180.0, model = 'prop_atm_02' },
    { coords = vector3(318.01,  -279.26,  54.17),  heading = 340.0, model = 'prop_atm_01' },
    { coords = vector3(-351.43, -49.74,   49.04),  heading = 70.0,  model = 'prop_atm_02' },
    { coords = vector3(1207.35, -331.28,  69.21),  heading = 230.0, model = 'prop_atm_03' },
}

-- ── Bank fiókok (full panel) ──────────────────────────────────
Config.BankLocations = {
    {
        label  = 'Maze Bank – Downtown',
        coords = vector4(150.29, -1042.00, 29.37, 340.0),
        blip   = { sprite = 108, color = 2, label = 'Maze Bank' },
    },
    {
        label  = 'Pacific Standard Bank',
        coords = vector4(232.70, 214.66, 106.31, 340.0),
        blip   = { sprite = 108, color = 2, label = 'Pacific Standard' },
    },
    {
        label  = 'Fleeca Bank – Rockford Hills',
        coords = vector4(-1212.87, -330.34, 37.79, 286.0),
        blip   = { sprite = 108, color = 2, label = 'Fleeca Bank' },
    },
    {
        label  = 'Blaine County Savings',
        coords = vector4(1175.19, 2706.69, 38.09, 180.0),
        blip   = { sprite = 108, color = 2, label = 'Blaine County Bank' },
    },
}

-- ── Interakció sugár ─────────────────────────────────────────
Config.ATMRadius        = 1.5
Config.BankRadius       = 2.0

-- ── Tranzakció típusok ────────────────────────────────────────
Config.TxTypes = {
    deposit    = { label = 'Befizetés',    icon = 'hgi-stroke hgi-money-receive-02', color = '#22c55e' },
    withdraw   = { label = 'Kifizetés',    icon = 'hgi-stroke hgi-money-send-02',    color = '#f59e0b' },
    transfer   = { label = 'Átutalás',     icon = 'hgi-stroke hgi-transfer-horizontal-02', color = '#38bdf8' },
    received   = { label = 'Beérkezett',   icon = 'hgi-stroke hgi-money-receive-02', color = '#22c55e' },
    salary     = { label = 'Fizetés',      icon = 'hgi-stroke hgi-briefcase-02',     color = '#a855f7' },
    payment    = { label = 'Kifizetés',    icon = 'hgi-stroke hgi-credit-card',      color = '#ef4444' },
    fine       = { label = 'Bírság',       icon = 'hgi-stroke hgi-alert-02',         color = '#ef4444' },
    benefit    = { label = 'Segély',       icon = 'hgi-stroke hgi-heart-add',        color = '#22c55e' },
    reward     = { label = 'Jutalom',      icon = 'hgi-stroke hgi-star-02',          color = '#f59e0b' },
    other      = { label = 'Egyéb',        icon = 'hgi-stroke hgi-bank',             color = '#8899b4' },
}

-- ── Átutalás limitek ─────────────────────────────────────────
Config.TransferMinAmount = 1
Config.TransferMaxAmount = 500000
Config.TransferFee       = 0       -- % tranzakciós díj (0 = ingyenes)

-- ── ATM limit (kiszedés) ─────────────────────────────────────
Config.ATMWithdrawLimit  = 10000   -- $ / alkalom ATM-nél

-- ── Integráció ────────────────────────────────────────────────
Config.SyncCashWithPlayercore = true   -- fvg-playercore cash szinkron