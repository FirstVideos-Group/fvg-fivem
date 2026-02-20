-- ╔══════════════════════════════════════════════╗
-- ║         fvg-identity :: server               ║
-- ╚══════════════════════════════════════════════╝

-- ── Migráció ─────────────────────────────────────────────────
CreateThread(function()
    Wait(200)
    exports['fvg-database']:RegisterMigration('fvg_identity', [[
        CREATE TABLE IF NOT EXISTS `fvg_identity` (
            `player_id`  INT          NOT NULL,
            `firstname`  VARCHAR(32)  NOT NULL DEFAULT '',
            `lastname`   VARCHAR(32)  NOT NULL DEFAULT '',
            `sex`        TINYINT(1)   NOT NULL DEFAULT 0,
            `dob`        VARCHAR(20)  NOT NULL DEFAULT '',
            `age`        TINYINT      NOT NULL DEFAULT 18,
            `height`     SMALLINT     NOT NULL DEFAULT 175,
            `weight`     SMALLINT     NOT NULL DEFAULT 75,
            `nationality`VARCHAR(40)  NOT NULL DEFAULT 'Los Santos',
            `appearance` LONGTEXT              DEFAULT NULL,
            `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                               ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`player_id`),
            CONSTRAINT `fk_identity_player`
                FOREIGN KEY (`player_id`)
                REFERENCES `fvg_players`(`id`)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ── Cache ─────────────────────────────────────────────────────
local identityCache = {}
-- [src] = { firstname, lastname, sex, dob, age, height, weight, nationality, appearance={} }

-- ── Validáció ─────────────────────────────────────────────────
local function ValidateName(name)
    if type(name) ~= 'string' then return false end
    if #name < 2 or #name > Config.MaxNameLen then return false end
    return string.match(name, '^[%a%s%-]+$') ~= nil
end

local function ValidateData(data)
    if not ValidateName(data.firstname or '') then return false, 'invalid_name' end
    if not ValidateName(data.lastname  or '') then return false, 'invalid_name' end
    local age = tonumber(data.age)
    if not age or age < Config.MinAge or age > Config.MaxAge then return false, 'invalid_age' end
    local height = tonumber(data.height)
    if not height or height < Config.MinHeight or height > Config.MaxHeight then return false, 'invalid_height' end
    local weight = tonumber(data.weight)
    if not weight or weight < Config.MinWeight or weight > Config.MaxWeight then return false, 'invalid_weight' end
    return true
end

-- ── Betöltés ─────────────────────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerLoaded', function(src, player)
    local row = exports['fvg-database']:QuerySingle(
        'SELECT * FROM `fvg_identity` WHERE `player_id` = ?',
        { player.id }
    )

    if row then
        -- Appearance decode
        local appearance = {}
        if row.appearance then
            local ok, decoded = pcall(json.decode, row.appearance)
            appearance = ok and decoded or {}
        end
        identityCache[src] = {
            firstname   = row.firstname,
            lastname    = row.lastname,
            sex         = row.sex,
            dob         = row.dob,
            age         = row.age,
            height      = row.height,
            weight      = row.weight,
            nationality = row.nationality,
            appearance  = appearance,
            registered  = true,
        }
        -- fvg-playercore cache frissítés
        exports['fvg-playercore']:SetPlayerData(src, 'firstname', row.firstname)
        exports['fvg-playercore']:SetPlayerData(src, 'lastname',  row.lastname)

        -- Kliens értesítés (megjelenés alkalmazásához)
        TriggerClientEvent('fvg-identity:client:ApplyAppearance', src, identityCache[src])
    else
        -- Új játékos – karakterkészítő megnyitása
        identityCache[src] = { registered = false }
        TriggerClientEvent('fvg-identity:client:OpenCreator', src)
    end
end)

-- ── Kilépéskor cache tisztítás ────────────────────────────────
AddEventHandler('fvg-playercore:server:PlayerUnloaded', function(src, _)
    identityCache[src] = nil
end)

-- ── Karakter mentése (regisztráció / módosítás) ───────────────
RegisterNetEvent('fvg-identity:server:SaveIdentity', function(data)
    local src    = source
    local player = exports['fvg-playercore']:GetPlayer(src)
    if not player then return end

    -- Validáció
    local valid, errKey = ValidateData(data)
    if not valid then
        TriggerClientEvent('fvg-notify:client:Notify', src, {
            type    = 'error',
            message = Config.Locale[errKey] or 'Érvénytelen adat.'
        })
        return
    end

    local isNew       = not identityCache[src] or not identityCache[src].registered
    local appearance  = json.encode(data.appearance or {})
    local dob         = data.dob or ''
    local nationality = data.nationality or 'Los Santos'

    if isNew then
        -- INSERT
        exports['fvg-database']:Insert(
            [[INSERT INTO `fvg_identity`
              (`player_id`,`firstname`,`lastname`,`sex`,`dob`,`age`,`height`,`weight`,`nationality`,`appearance`)
              VALUES (?,?,?,?,?,?,?,?,?,?)]],
            { player.id, data.firstname, data.lastname, data.sex or 0,
              dob, data.age, data.height, data.weight, nationality, appearance }
        )
    else
        -- UPDATE
        exports['fvg-database']:Execute(
            [[UPDATE `fvg_identity` SET
              `firstname`=?,`lastname`=?,`sex`=?,`dob`=?,`age`=?,
              `height`=?,`weight`=?,`nationality`=?,`appearance`=?
              WHERE `player_id`=?]],
            { data.firstname, data.lastname, data.sex or 0,
              dob, data.age, data.height, data.weight, nationality, appearance, player.id }
        )
    end

    -- Cache frissítés
    identityCache[src] = {
        firstname   = data.firstname,
        lastname    = data.lastname,
        sex         = data.sex or 0,
        dob         = dob,
        age         = data.age,
        height      = data.height,
        weight      = data.weight,
        nationality = nationality,
        appearance  = data.appearance or {},
        registered  = true,
    }

    -- fvg-playercore szinkronizálás
    exports['fvg-playercore']:SetPlayerData(src, 'firstname', data.firstname)
    exports['fvg-playercore']:SetPlayerData(src, 'lastname',  data.lastname)
    exports['fvg-database']:SavePlayer(src, {
        firstname = data.firstname,
        lastname  = data.lastname,
        sex       = data.sex or 0,
        dob       = dob,
    })

    -- Megjelenés alkalmazása
    TriggerClientEvent('fvg-identity:client:ApplyAppearance', src, identityCache[src])

    -- Értesítés
    local msg = isNew and Config.Locale.registered or Config.Locale.updated
    TriggerClientEvent('fvg-notify:client:Notify', src, { type = 'success', message = msg })

    -- Más scriptek értesítése
    TriggerEvent('fvg-identity:server:IdentitySaved', src, identityCache[src], isNew)
end)

-- ── Karakter szerkesztő megnyitása ────────────────────────────
RegisterNetEvent('fvg-identity:server:OpenEditor', function()
    local src = source
    if not identityCache[src] or not identityCache[src].registered then return end
    TriggerClientEvent('fvg-identity:client:OpenEditor', src, identityCache[src])
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('GetPlayerIdentity', function(src)
    return identityCache[tonumber(src)]
end)

exports('HasIdentity', function(src)
    local id = identityCache[tonumber(src)]
    return id ~= nil and id.registered == true
end)

exports('SetPlayerIdentity', function(src, field, value)
    local s = tonumber(src)
    if not identityCache[s] then return false end
    identityCache[s][field] = value
    return true
end)