Config = {}

-- ── Spawn pont (ahol az első belépés / respawn történik) ─────
-- Ezeket a koordinátákat az fvg-character script felülírhatja
-- ha karakterválasztó / last position mentés van
Config.DefaultSpawn = {
    x       = -269.4,
    y       = -955.3,
    z       =   31.2,
    heading =    0.0,
}

-- ── Alapértelmezett ped modell ────────────────────────────────
Config.DefaultModel = 'mp_m_freemode_01'

-- ── Automatikus mentés intervallum (ms) ──────────────────────
Config.AutoSaveInterval = 300000   -- 5 perc

-- ── Csatlakozáskor megjelenített üzenetek (deferrals) ────────
Config.ConnectMessages = {
    checking  = 'Adatok ellenőrzése...',
    loading   = 'Karakter betöltése...',
    done      = 'Üdvözlünk a szerveren!',
}

-- ── Kick üzenetek ─────────────────────────────────────────────
Config.KickReasons = {
    no_identifier = 'Nem sikerült azonosítani a játékost. Indítsd el a Steamet!',
    db_error      = 'Adatbázis hiba a csatlakozás során. Próbálj újra!',
    banned        = 'Ki vagy tiltva a szerverről.',
}

-- ── Integrációk ──────────────────────────────────────────────
Config.NotifyIntegration = true   -- fvg-notify üdvözlő üzenet

-- ── Alapértelmezett játékos metaadatok ───────────────────────
-- Minden új játékosnál ezek az értékek kerülnek be
Config.DefaultMetadata = {
    cash      = 500,
    bank      = 2500,
    job       = 'unemployed',
    grade     = 0,
    stress    = 0,
    isDead    = false,
    lastPos   = nil,
}

-- ── Locale ───────────────────────────────────────────────────
Config.Locale = {
    welcome_new     = 'Üdvözlünk a szerveren! Ez az első belépésed.',
    welcome_back    = 'Üdvözlünk újra!',
}