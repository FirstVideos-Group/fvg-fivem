Config = {}

-- ── Halál kezelés ─────────────────────────────────────────────
-- Mennyi ideig marad a játékos "sebesült" állapotban mielőtt
-- meghal (másodperc). 0 = azonnal meghal.
Config.InjuredTimeout    = 300       -- 5 perc

-- Játékos maga kérheti a respawnt (ha nincs aki segítsen)
Config.AllowSelfRespawn  = true

-- Mennyi várakozás után jelenjen meg az önrespawn gomb (másodperc)
Config.SelfRespawnDelay  = 60

-- ── Respawn koordináták ───────────────────────────────────────
-- Ha több spawn pont van, random választ egyet
Config.RespawnPoints = {
    { x = -269.4,  y = -955.3,  z = 31.2,  heading = 0.0,   label = 'Kórház – Downtown' },
    { x = 1839.6,  y = 3672.9,  z = 34.3,  heading = 210.0, label = 'Kórház – Sandy Shores' },
    { x = -449.7,  y = -340.4,  z = 34.5,  heading = 115.0, label = 'Kórház – Rockford Hills' },
}

-- ── Respawn HP ────────────────────────────────────────────────
Config.RespawnHealth     = 150       -- max 200 (200 = teljes HP)
Config.RespawnArmour     = 0

-- ── Animációk ─────────────────────────────────────────────────
Config.DeathAnim = {
    enabled = true,
    dict    = 'dead',
    anim    = 'dead_a',
}

-- ── Kórházi költség ──────────────────────────────────────────
Config.HospitalBill      = true
Config.HospitalBillAmount= 500       -- $500 kórházi számla

-- ── Karakter modell megőrzés ─────────────────────────────────
-- Ha true, respawn után ugyanazt a modellt alkalmazza
-- amit a playercore eltárolt
Config.PreserveModel     = true

-- ── Fade be/ki idők (ms) ──────────────────────────────────────
Config.FadeOutTime       = 500
Config.FadeInTime        = 800

-- ── Értesítések ───────────────────────────────────────────────
Config.Locale = {
    you_died         = 'Meghaltál. Kórházba szállítottak.',
    self_respawn_hint= 'Önrespawn elérhető: [E] gomb',
    respawned        = 'Kiengedtek a kórházból.',
    bill_charged     = 'Kórházi számla: $',
    bill_no_money    = 'Nem volt elég pénzed – tartozásod keletkezett.',
    revived          = 'Visszahoztak az életbe.',
}
