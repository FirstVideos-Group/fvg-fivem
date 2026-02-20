Config = {}

-- ── Inventory méret ───────────────────────────────────────────
Config.MaxSlots       = 40        -- játékos inventory slot száma
Config.MaxWeight      = 30.0      -- kg – max súly
Config.HotbarSlots    = 5         -- gyorssáv slotok száma (1–5)

-- ── Stash típusok ─────────────────────────────────────────────
Config.StashTypes = {
    personal   = { slots = 50, weight = 100.0 },  -- személyes stash
    vehicle    = { slots = 20, weight = 60.0  },  -- jármű csomagtartó
    shared     = { slots = 100, weight = 200.0 }, -- közös (bolt, helyszín)
}

-- ── Drop beállítások ──────────────────────────────────────────
Config.DropDistance   = 2.0        -- méter, meddig lehet szedni
Config.DropTimeout    = 300        -- másodperc, utána eltűnik a drop
Config.DropMarker     = true       -- mutasson-e markert a dropoknál

-- ── Billentyűk ────────────────────────────────────────────────
Config.KeyInventory   = 'TAB'
Config.KeyPickup      = 'E'

-- ── Item lista ────────────────────────────────────────────────
-- name: egyedi azonosító (DB-ben is ez tárolódik)
-- label: megjelenített név
-- weight: kg
-- stackable: összerakható-e
-- usable: használható-e /use paranccsal
-- category: csoportosítás az UI-ban
-- image: html/images/ mappában lévő kép neve
Config.Items = {
    -- Élelmiszer
    bread       = { label='Kenyér',        weight=0.2, stackable=true,  usable=true,  category='food',     image='bread.png'       },
    water       = { label='Víz',           weight=0.3, stackable=true,  usable=true,  category='food',     image='water.png'       },
    sandwich    = { label='Szendvics',     weight=0.3, stackable=true,  usable=true,  category='food',     image='sandwich.png'    },
    coffee      = { label='Kávé',          weight=0.2, stackable=true,  usable=true,  category='food',     image='coffee.png'      },
    -- Orvosi
    bandage     = { label='Kötszer',       weight=0.1, stackable=true,  usable=true,  category='medical',  image='bandage.png'     },
    medkit      = { label='Elsősegély',    weight=0.5, stackable=true,  usable=true,  category='medical',  image='medkit.png'      },
    painkillers = { label='Fájdalomcsill.',weight=0.1, stackable=true,  usable=true,  category='medical',  image='pills.png'       },
    -- Fegyverek
    weapon_pistol = { label='Pisztoly',    weight=2.0, stackable=false, usable=true,  category='weapon',   image='pistol.png'      },
    ammo_pistol   = { label='Pisztolytár', weight=0.3, stackable=true,  usable=false, category='weapon',   image='ammo.png'        },
    weapon_knife  = { label='Kés',         weight=0.5, stackable=false, usable=true,  category='weapon',   image='knife.png'       },
    -- Szerszámok
    lockpick    = { label='Zárfeszítő',    weight=0.2, stackable=true,  usable=true,  category='tool',     image='lockpick.png'    },
    repair_kit  = { label='Javítócsomag',  weight=1.5, stackable=true,  usable=true,  category='tool',     image='repairkit.png'   },
    phone       = { label='Telefon',       weight=0.2, stackable=false, usable=true,  category='tool',     image='phone.png'       },
    -- Anyagok
    iron        = { label='Vasérc',        weight=2.0, stackable=true,  usable=false, category='material', image='iron.png'        },
    gold        = { label='Arany',         weight=3.0, stackable=true,  usable=false, category='material', image='gold.png'        },
    cloth       = { label='Anyag',         weight=0.5, stackable=true,  usable=false, category='material', image='cloth.png'       },
    -- Egyéb
    id_card     = { label='Személyi',      weight=0.0, stackable=false, usable=true,  category='misc',     image='id_card.png'     },
    money       = { label='Készpénz',      weight=0.0, stackable=true,  usable=false, category='misc',     image='money.png'       },
    drugs_weed  = { label='Fű',            weight=0.1, stackable=true,  usable=true,  category='drug',     image='weed.png'        },
}

-- ── Kategória sorrend és megjelenítés ─────────────────────────
Config.Categories = {
    { id='all',      label='Összes',     icon='hgi-stroke hgi-grid-view'      },
    { id='food',     label='Élelmiszer', icon='hgi-stroke hgi-hamburger-01'   },
    { id='medical',  label='Orvosi',     icon='hgi-stroke hgi-heart-add'      },
    { id='weapon',   label='Fegyver',    icon='hgi-stroke hgi-sword-02'       },
    { id='tool',     label='Szerszám',   icon='hgi-stroke hgi-wrench-01'      },
    { id='material', label='Anyag',      icon='hgi-stroke hgi-cube-01'        },
    { id='drug',     label='Kábítószer', icon='hgi-stroke hgi-pill'           },
    { id='misc',     label='Egyéb',      icon='hgi-stroke hgi-package'        },
}

-- ── Use callbackek ────────────────────────────────────────────
-- Ide kerülnek a szerver oldali use logikák (más script is hozzáadhat)
Config.UseCallbacks = {}

-- ── Integráció ────────────────────────────────────────────────
Config.NotifyOnPickup   = true
Config.NotifyOnUse      = true
Config.NotifyOnDrop     = true
Config.UseNeeds         = true   -- fvg-needs integráció étel/ital használatkor
Config.UseStress        = false  -- fvg-stress integráció bizonyos itemekre