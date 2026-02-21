Config = {}

-- Wanted blokkolás be/ki
Config.Enabled          = true

-- Milyen gyakran töröljük a wanted szintet (ms)
-- Alacsonyabb = gyorsabb reakció, de több CPU
Config.TickRate         = 0        -- 0 = minden frame (legbiztosabb)

-- Max engedélyezett wanted szint (0 = soha nem kap, 1-5 = engedélyezett szintig)
Config.MaxWantedLevel   = 0

-- Rendfenntartók NPC viselkedése
-- true  = a rendőrök nem reagálnak a játékosra (dispatch tiltás)
-- false = a rendőrök normálisan reagálnak, csak a csillag nem jelenik meg
Config.DisableDispatch  = true

-- Megakadályozza hogy a rendőrök üldözzék a játékost
Config.DisableCopChase  = true

-- Járókelők (pedestrians) panaszkodnak-e / menekülnek-e
-- Ha false: a járókelők normálisan reagálnak az erőszakra (de csillag nem lesz)
Config.DisablePedReaction = false

-- Admin bypass: ezek a Steam/license azonosítók KAPHATNAK wanted szintet
-- (pl. rendőr játékos akinek kell hogy üldözzék)
Config.Whitelist = {
    -- 'license:abc123',
    -- 'steam:110000112345678',
}
