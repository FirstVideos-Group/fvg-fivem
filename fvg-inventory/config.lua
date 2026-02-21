Config = {}

-- ── Inventory méret ─────────────────────────────────────────────
Config.MaxSlots    = 40
Config.MaxWeight   = 30.0
Config.HotbarSlots = 5

-- ── Stash típusok ─────────────────────────────────────────────
Config.StashTypes = {
    personal = { slots = 50,  maxWeight = 100.0 },
    vehicle  = { slots = 20,  maxWeight = 60.0  },
    shared   = { slots = 100, maxWeight = 200.0 },
}

-- ── Drop beállítások ───────────────────────────────────────────
Config.DropDistance  = 2.0
Config.DropTimeout   = 300
Config.DropMarker    = true

-- ── Billentyűk ──────────────────────────────────────────────────
Config.KeyInventory  = 'TAB'
Config.KeyPickup     = 'E'

-- ── Item lista ──────────────────────────────────────────────────
-- FIX: szinkronban az fvg-shops/config.lua item névhasznalataval
Config.Items = {

    -- ── Étel ───────────────────────────────────────────────────────────
    bread        = { label='Kenyér',          weight=0.2, stackable=true,  usable=true,  category='food',      image='bread.png',      foodValue=20, waterValue=0  },
    sandwich     = { label='Szendvics',        weight=0.3, stackable=true,  usable=true,  category='food',      image='sandwich.png',   foodValue=25, waterValue=0  },
    burger       = { label='Hamburger',        weight=0.4, stackable=true,  usable=true,  category='food',      image='burger.png',     foodValue=35, waterValue=5  },
    hotdog       = { label='Hot Dog',          weight=0.2, stackable=true,  usable=true,  category='food',      image='hotdog.png',     foodValue=20, waterValue=0  },
    apple        = { label='Alma',             weight=0.1, stackable=true,  usable=true,  category='food',      image='apple.png',      foodValue=10, waterValue=5  },
    chips        = { label='Chips',            weight=0.1, stackable=true,  usable=true,  category='food',      image='chips.png',      foodValue=8,  waterValue=0  },
    donut        = { label='Fánk',             weight=0.1, stackable=true,  usable=true,  category='food',      image='donut.png',      foodValue=12, waterValue=0  },

    -- ── Ital ───────────────────────────────────────────────────────────
    water        = { label='Víz',             weight=0.3, stackable=true,  usable=true,  category='food',      image='water.png',      foodValue=0,  waterValue=30 },
    cola         = { label='Cola',             weight=0.3, stackable=true,  usable=true,  category='food',      image='cola.png',       foodValue=5,  waterValue=20 },
    coffee       = { label='Kávé',            weight=0.2, stackable=true,  usable=true,  category='food',      image='coffee.png',     foodValue=5,  waterValue=15 },
    energydrink  = { label='Energiaital',      weight=0.3, stackable=true,  usable=true,  category='food',      image='energydrink.png',foodValue=5,  waterValue=15, stressValue=-10 },
    beer         = { label='Sör',              weight=0.4, stackable=true,  usable=true,  category='food',      image='beer.png',       foodValue=3,  waterValue=10, stressValue=-15 },

    -- ── Orvosi ──────────────────────────────────────────────────────────
    bandage      = { label='Kötszer',          weight=0.1, stackable=true,  usable=true,  category='medical',   image='bandage.png',    healValue=25  },
    firstaidkit  = { label='Elsősegély csomag',weight=0.5, stackable=true,  usable=true,  category='medical',   image='firstaidkit.png',healValue=50  },
    medkit       = { label='Orvosi táska',     weight=1.0, stackable=false, usable=true,  category='medical',   image='medkit.png',     healValue=100 },
    painkillers  = { label='Fájdalomcsill.',   weight=0.1, stackable=true,  usable=true,  category='medical',   image='pills.png',      healValue=10, stressValue=-20 },
    adrenaline   = { label='Adrenalin',        weight=0.2, stackable=false, usable=true,  category='medical',   image='adrenaline.png', healValue=100, stressValue=30 },

    -- ── Fegyverek ────────────────────────────────────────────────────────
    weapon_pistol   = { label='Pisztoly',      weight=2.0, stackable=false, usable=true,  category='weapon',    image='pistol.png',     weaponHash='WEAPON_PISTOL'  },
    weapon_smg      = { label='SMG',           weight=3.0, stackable=false, usable=true,  category='weapon',    image='smg.png',        weaponHash='WEAPON_SMG'     },
    weapon_shotgun  = { label='Sörétes',      weight=4.0, stackable=false, usable=true,  category='weapon',    image='shotgun.png',    weaponHash='WEAPON_PUMPSHOTGUN' },
    weapon_knife    = { label='Kés',          weight=0.5, stackable=false, usable=true,  category='weapon',    image='knife.png',      weaponHash='WEAPON_KNIFE'   },

    -- ── Lőszer ───────────────────────────────────────────────────────────
    ammo_pistol  = { label='Pisztoly lőszer',  weight=0.3, stackable=true,  usable=false, category='weapon',    image='ammo.png'        },
    ammo_smg     = { label='SMG lőszer',       weight=0.3, stackable=true,  usable=false, category='weapon',    image='ammo.png'        },
    ammo_shotgun = { label='Sörétes patron',   weight=0.5, stackable=true,  usable=false, category='weapon',    image='ammo.png'        },

    -- ── Fegyver kiegészítők ──────────────────────────────────────────────
    weapon_silencer    = { label='Hangtompitó',   weight=0.3, stackable=false, usable=false, category='weapon',    image='silencer.png'    },
    weapon_flashlight  = { label='Taktikai lámpa',weight=0.2, stackable=false, usable=false, category='weapon',    image='flashlight.png'  },

    -- ── Ruha ────────────────────────────────────────────────────────────
    tshirt_white = { label='Fehér póló',        weight=0.3, stackable=true,  usable=true,  category='clothing',  image='tshirt.png'      },
    jeans_blue   = { label='Kék farmer',         weight=0.5, stackable=true,  usable=true,  category='clothing',  image='jeans.png'       },
    cap_black    = { label='Fekete sapka',       weight=0.2, stackable=true,  usable=true,  category='clothing',  image='cap.png'         },

    -- ── Szerszamok ─────────────────────────────────────────────────────────
    lockpick     = { label='Zárfeszítő',        weight=0.2, stackable=true,  usable=true,  category='tool',      image='lockpick.png'    },
    repair_kit   = { label='Javítócsomag',      weight=1.5, stackable=true,  usable=true,  category='tool',      image='repairkit.png'   },
    phone        = { label='Telefon',            weight=0.2, stackable=false, usable=true,  category='tool',      image='phone.png'       },

    -- ── Anyagok ────────────────────────────────────────────────────────────
    iron         = { label='Vasérc',             weight=2.0, stackable=true,  usable=false, category='material',  image='iron.png'        },
    gold         = { label='Arany',              weight=3.0, stackable=true,  usable=false, category='material',  image='gold.png'        },
    cloth        = { label='Anyag',              weight=0.5, stackable=true,  usable=false, category='material',  image='cloth.png'       },

    -- ── Egyéb ────────────────────────────────────────────────────────────
    id_card      = { label='Személyi',           weight=0.0, stackable=false, usable=true,  category='misc',      image='id_card.png'     },
    money        = { label='Készpénz',           weight=0.0, stackable=true,  usable=false, category='misc',      image='money.png'       },
    map          = { label='Térkép',             weight=0.1, stackable=false, usable=true,  category='misc',      image='map.png'         },
    lighter      = { label='Öngyújtó',           weight=0.1, stackable=true,  usable=true,  category='misc',      image='lighter.png'     },
    phone_charger= { label='Töltő',              weight=0.2, stackable=false, usable=false, category='misc',      image='charger.png'     },
    drugs_weed   = { label='Fű',                weight=0.1, stackable=true,  usable=true,  category='drug',      image='weed.png'        },
}

-- ── Kategória sorrend ─────────────────────────────────────────────────
Config.Categories = {
    { id='all',      label='Összes',     icon='hgi-stroke hgi-grid-view'      },
    { id='food',     label='Élelmiszer', icon='hgi-stroke hgi-hamburger-01'   },
    { id='medical',  label='Orvosi',     icon='hgi-stroke hgi-heart-add'      },
    { id='weapon',   label='Fegyver',    icon='hgi-stroke hgi-sword-02'       },
    { id='tool',     label='Szerszám',   icon='hgi-stroke hgi-wrench-01'      },
    { id='material', label='Anyag',      icon='hgi-stroke hgi-cube-01'        },
    { id='clothing', label='Ruha',       icon='hgi-stroke hgi-t-shirt'        },
    { id='drug',     label='Kábítószer', icon='hgi-stroke hgi-pill'           },
    { id='misc',     label='Egyéb',      icon='hgi-stroke hgi-package'        },
}

-- ── Use callbackek ───────────────────────────────────────────────
Config.UseCallbacks = {}

-- ── Integráció ────────────────────────────────────────────────────────
Config.NotifyOnPickup = true
Config.NotifyOnUse    = true
Config.NotifyOnDrop   = true
Config.UseNeeds       = true   -- fvg-needs integráció
Config.UseStress      = true   -- fvg-stress integráció (FIX: volt false)
