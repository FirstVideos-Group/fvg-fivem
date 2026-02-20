Config = {}

-- ── Igazolvány típusok ────────────────────────────────────────
-- Ezeket az inventory 'id_card' iteme nyitja meg
Config.CardTypes = {
    { id = 'id',         label = 'Személyi igazolvány', icon = 'hgi-stroke hgi-user-id-verification',    color = '#38bdf8' },
    { id = 'driving',    label = 'Jogosítvány',          icon = 'hgi-stroke hgi-steering-wheel',          color = '#22c55e' },
    { id = 'weapon',     label = 'Fegyverviselési eng.', icon = 'hgi-stroke hgi-sword-02',                color = '#f59e0b' },
    { id = 'business',   label = 'Vállalkozói igazolvány',icon = 'hgi-stroke hgi-briefcase-02',           color = '#a855f7' },
    { id = 'medical',    label = 'Orvosi igazolvány',    icon = 'hgi-stroke hgi-heart-add',               color = '#ef4444' },
    { id = 'police',     label = 'Rendőrségi igazolvány',icon = 'hgi-stroke hgi-shield-user',             color = '#3b82f6' },
}

-- ── Jogosítvány kategóriák ─────────────────────────────────────
Config.DrivingCategories = { 'AM', 'A', 'B', 'C', 'D', 'E' }

-- ── Körözési szintek ──────────────────────────────────────────
Config.WantedLevels = {
    { level = 0, label = 'Nincs',        color = '#22c55e' },
    { level = 1, label = 'Enyhe',        color = '#84cc16' },
    { level = 2, label = 'Közepes',      color = '#f59e0b' },
    { level = 3, label = 'Súlyos',       color = '#f97316' },
    { level = 4, label = 'Veszélyes',    color = '#ef4444' },
    { level = 5, label = 'Terrorista',   color = '#dc2626' },
}

-- ── Távolság – igazolvány felmutatás ──────────────────────────
Config.ShowDistance     = 4.0   -- méter, ennyire kell lenni egymástól

-- ── Felmutatás időtartam ──────────────────────────────────────
Config.ShowDuration     = 8000  -- ms – ennyi ideig látja a másik fél

-- ── Admin: igazolvány ellenőrzés ──────────────────────────────
Config.AdminCheckPerms  = { 'police', 'admin', 'superadmin' }

-- ── Kezdeti jogosítványok (karakterkészítés után) ─────────────
Config.DefaultLicenses  = {}  -- üres: semmi sem jár alapból

-- ── Igazolvány kiadói hatóság szöveg ─────────────────────────
Config.IssuedBy         = 'Los Santos Önkormányzat'
Config.CityName         = 'LOS SANTOS ÁLLAM'

-- ── Integráció ────────────────────────────────────────────────
Config.UseInventoryItem     = true  -- fvg-inventory 'id_card' item nyitja
Config.UseAdminIntegration  = true  -- fvg-admin export ellenőrzés