Config = Config or {}

-- ═══════════════════════════════════════════════════════════
--  RANG RENDSZER
--  grade: numerikus szint (magasabb = több jog)
--  Más emergency scriptek FELÜLÍRHATJÁK ezt a táblát
-- ═══════════════════════════════════════════════════════════
Config.Ranks = {
    {
        grade       = 0,
        name        = 'recruit',
        label       = 'Újonc',
        salary      = 800,
        permissions = {
            can_garage       = true,    -- járművek kivétele
            can_weapons      = false,   -- fegyver kivétel
            can_arrest       = false,   -- letartóztatás
            can_fine         = false,   -- bírságolás
            can_storage      = true,    -- személyes tároló
            can_shared_storage=false,   -- közös tároló
            can_manage_units = false,   -- egység kezelés
            can_mdt          = false,   -- MDT hozzáférés
            can_prison        = false,  -- börtönbe küldés
            can_manage_staff  = false,  -- beosztottak kezelése
        },
        vehicle_classes = { 'patrol' },
        weapon_loadout  = {},
    },
    {
        grade       = 1,
        name        = 'officer',
        label       = 'Rendőr',
        salary      = 1200,
        permissions = {
            can_garage        = true,
            can_weapons       = true,
            can_arrest        = true,
            can_fine          = true,
            can_storage       = true,
            can_shared_storage= true,
            can_manage_units  = false,
            can_mdt           = true,
            can_prison        = true,
            can_manage_staff  = false,
        },
        vehicle_classes = { 'patrol', 'suv' },
        weapon_loadout  = { 'weapon_pistol', 'weapon_stungun', 'weapon_nightstick' },
    },
    {
        grade       = 2,
        name        = 'senior_officer',
        label       = 'Vezető Rendőr',
        salary      = 1600,
        permissions = {
            can_garage        = true,
            can_weapons       = true,
            can_arrest        = true,
            can_fine          = true,
            can_storage       = true,
            can_shared_storage= true,
            can_manage_units  = true,
            can_mdt           = true,
            can_prison        = true,
            can_manage_staff  = false,
        },
        vehicle_classes = { 'patrol', 'suv', 'unmarked' },
        weapon_loadout  = { 'weapon_pistol', 'weapon_stungun', 'weapon_nightstick', 'weapon_pumpshotgun' },
    },
    {
        grade       = 3,
        name        = 'sergeant',
        label       = 'Őrmester',
        salary      = 2200,
        permissions = {
            can_garage        = true,
            can_weapons       = true,
            can_arrest        = true,
            can_fine          = true,
            can_storage       = true,
            can_shared_storage= true,
            can_manage_units  = true,
            can_mdt           = true,
            can_prison        = true,
            can_manage_staff  = true,
        },
        vehicle_classes = { 'patrol', 'suv', 'unmarked', 'tactical' },
        weapon_loadout  = { 'weapon_pistol', 'weapon_stungun', 'weapon_nightstick', 'weapon_pumpshotgun', 'weapon_carbinerifle' },
    },
    {
        grade       = 4,
        name        = 'lieutenant',
        label       = 'Főhadnagy',
        salary      = 3000,
        permissions = {
            can_garage        = true,
            can_weapons       = true,
            can_arrest        = true,
            can_fine          = true,
            can_storage       = true,
            can_shared_storage= true,
            can_manage_units  = true,
            can_mdt           = true,
            can_prison        = true,
            can_manage_staff  = true,
        },
        vehicle_classes = { 'patrol', 'suv', 'unmarked', 'tactical', 'command' },
        weapon_loadout  = { 'weapon_pistol', 'weapon_stungun', 'weapon_nightstick', 'weapon_pumpshotgun', 'weapon_carbinerifle', 'weapon_sniperrifle' },
    },
    {
        grade       = 5,
        name        = 'chief',
        label       = 'Rendőrkapitány',
        salary      = 5000,
        permissions = {
            can_garage        = true,
            can_weapons       = true,
            can_arrest        = true,
            can_fine          = true,
            can_storage       = true,
            can_shared_storage= true,
            can_manage_units  = true,
            can_mdt           = true,
            can_prison        = true,
            can_manage_staff  = true,
        },
        vehicle_classes = { 'patrol', 'suv', 'unmarked', 'tactical', 'command', 'special' },
        weapon_loadout  = { 'weapon_pistol', 'weapon_stungun', 'weapon_nightstick', 'weapon_pumpshotgun', 'weapon_carbinerifle', 'weapon_sniperrifle', 'weapon_heavysniper' },
    },
}

-- Rang lekérés grade alapján
function Config.GetRank(grade)
    for _, r in ipairs(Config.Ranks) do
        if r.grade == grade then return r end
    end
    return Config.Ranks[1]
end

-- Rang lekérés name alapján
function Config.GetRankByName(name)
    for _, r in ipairs(Config.Ranks) do
        if r.name == name then return r end
    end
    return nil
end

-- Jogosultság ellenőrzés
function Config.HasPermission(grade, perm)
    local rank = Config.GetRank(grade)
    if not rank then return false end
    return rank.permissions[perm] == true
end