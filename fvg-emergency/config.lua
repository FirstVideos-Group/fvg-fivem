Config = {}

-- ── Hívókód meghatározások ──────────────────────────────────────
-- Minden kódhoz: label, szta róvid leírás, szín (CSS), ikon (HugeIcons)
Config.Codes = {
    ['code1'] = {
        label       = 'Code 1',
        description = 'Normál menetsebessség, sziréna nélkül',
        color       = '#22c55e',
        icon        = 'hgi-stroke hgi-checkmark-circle-02',
        priority    = 1,
    },
    ['code2'] = {
        label       = 'Code 2',
        description = 'Sürgett menetel, fények be – sziréna opcionális',
        color       = '#f59e0b',
        icon        = 'hgi-stroke hgi-alert-02',
        priority    = 2,
    },
    ['code3'] = {
        label       = 'Code 3',
        description = 'Teljes vészhelyzet – sziréna és fények kötelező',
        color       = '#ef4444',
        icon        = 'hgi-stroke hgi-alert-circle',
        priority    = 3,
    },
    ['code4'] = {
        label       = 'Code 4',
        description = 'Helyzet biztosítva, nincs szükség segítségre',
        color       = '#3b82f6',
        icon        = 'hgi-stroke hgi-shield-check',
        priority    = 4,
    },
    ['bolo'] = {
        label       = 'BOLO',
        description = 'Be On Look Out – körözés kiadva',
        color       = '#a855f7',
        icon        = 'hgi-stroke hgi-search-02',
        priority    = 5,
    },
    ['signal100'] = {
        label       = 'Signal 100',
        description = 'Üzemzár! Minden egység azonnal vonuljon vissza',
        color       = '#ffffff',
        icon        = 'hgi-stroke hgi-radio-02',
        priority    = 6,
    },
}

-- ── Jogosult jobbágykörök ──────────────────────────────────────
-- Csak ezek a job-ok használhatják a hívókód rendszert
Config.AuthorizedJobs = {
    'police',
    'sheriff',
    'state_police',
    'fire',
    'ems',
    'dispatch',
}

-- ── Diszpécser jobbágykörök (bolo / signal 100 kiadható) ───────
Config.DispatchJobs = {
    'dispatch',
    'police',
    'state_police',
}

-- ── Értesítési hatósugara (méter) – 0 = minden online egység ──
Config.BroadcastRange   = 0

-- ── Log csatorna ─────────────────────────────────────────────
Config.LogEnabled       = true

-- ── NUI HUD pozíció ──────────────────────────────────────────
-- 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
Config.HudPosition      = 'top-left'

-- ── Signal 100 alatt minden kód tiltása ─────────────────────
Config.LockdownOnSignal100 = true

-- ── fvg-neverwanted integráció ──────────────────────────────
-- Code 3 aktív alatt a játékos nem kap wanted szintet
Config.NeverWantedOnCode3  = true

-- ── Locale ───────────────────────────────────────────────────
Config.Locale = {
    not_authorized  = 'Nincs jogosultságod hívókódot kiadni.',
    code_set        = 'Hívókód beállítva',
    code_cleared    = 'Hívókód törölve',
    signal_100_on   = '⚠ SIGNAL 100 – Üzemzár életbe lépett!',
    signal_100_off  = 'Signal 100 megszüntetve.',
    bolo_issued     = 'BOLO kiadva',
    bolo_cleared    = 'BOLO visszavonva',
}
