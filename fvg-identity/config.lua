Config = {}

-- ── Karakter korlátozások ─────────────────────────────────────
Config.MinAge     = 18
Config.MaxAge     = 80
Config.MinHeight  = 150   -- cm
Config.MaxHeight  = 210   -- cm
Config.MinWeight  = 45    -- kg
Config.MaxWeight  = 150   -- kg
Config.MaxNameLen = 16    -- keresztnév és vezetéknév max hossza

-- ── Nem opciók ────────────────────────────────────────────────
Config.Sexes = {
    { value = 0, label = 'Férfi',  model = 'mp_m_freemode_01' },
    { value = 1, label = 'Nő',     model = 'mp_f_freemode_01' },
}

-- ── Bőrszín ───────────────────────────────────────────────────
-- 0–5: GTA freemode bőrtónusok (SetPedHeadBlendData skinFirstID)
Config.SkinTones = {
    { id = 0, label = 'Nagyon világos' },
    { id = 1, label = 'Világos'        },
    { id = 2, label = 'Közepes'        },
    { id = 3, label = 'Olívás'         },
    { id = 4, label = 'Sötét'          },
    { id = 5, label = 'Nagyon sötét'   },
}

-- ── Hajszínek ─────────────────────────────────────────────────
Config.HairColors = {
    { id = 0,  label = 'Fekete'          },
    { id = 1,  label = 'Nagyon sötétbarna'},
    { id = 2,  label = 'Sötétbarna'      },
    { id = 3,  label = 'Középbarna'      },
    { id = 4,  label = 'Világosbarna'    },
    { id = 5,  label = 'Szőke'           },
    { id = 6,  label = 'Aranyszőke'      },
    { id = 7,  label = 'Vörös'           },
    { id = 8,  label = 'Narancsvörös'    },
    { id = 9,  label = 'Ősz'             },
    { id = 10, label = 'Fehér'           },
}

-- ── Hajstílusok ───────────────────────────────────────────────
-- SetPedComponentVariation component 2 = hajak
Config.HairStyles = {
    { id = 0, label = 'Rövid – egyenes' },
    { id = 1, label = 'Rövid – hullámos' },
    { id = 2, label = 'Közepes – laza'  },
    { id = 3, label = 'Hosszú – egyenes'},
    { id = 4, label = 'Hosszú – hullámos'},
    { id = 5, label = 'Kopasz'          },
    { id = 6, label = 'Dreadlock'       },
    { id = 7, label = 'Afro'            },
}

-- ── Szem szín ─────────────────────────────────────────────────
-- SetPedHeadOverlay index 2 = szemöldök / szem terület
Config.EyeColors = {
    { id = 0, label = 'Barna'    },
    { id = 1, label = 'Zöld'     },
    { id = 2, label = 'Kék'      },
    { id = 3, label = 'Szürke'   },
    { id = 4, label = 'Mogyoró'  },
    { id = 5, label = 'Világoskék'},
}

-- ── Foglalkozás (karakterkezdeti) ─────────────────────────────
Config.DefaultJob   = 'unemployed'
Config.DefaultGrade = 0
Config.DefaultCash  = 500
Config.DefaultBank  = 2500

-- ── Regisztrációs helyszín ────────────────────────────────────
-- Ide teleportálódik a játékos a regisztráció alatt
Config.RegistrationCoords = {
    x = -269.4, y = -955.3, z = 31.2, heading = 205.0
}

-- ── Kamera beállítás ──────────────────────────────────────────
Config.CamOffset  = { x = 0.0, y = -2.5, z = 0.3 }
Config.CamFOV     = 45.0

-- ── Integrációk ──────────────────────────────────────────────
Config.NotifyIntegration     = true
Config.PlayerCoreIntegration = true

-- ── Locale ───────────────────────────────────────────────────
Config.Locale = {
    welcome_new     = 'Üdvözlünk! Hozd létre a karaktered.',
    registered      = 'Karakter sikeresen létrehozva!',
    updated         = 'Karakter adatai frissítve.',
    invalid_name    = 'Érvénytelen név! Csak betűk használhatók.',
    invalid_age     = 'Érvénytelen kor! (' .. Config.MinAge .. '–' .. Config.MaxAge .. ')',
    invalid_height  = 'Érvénytelen magasság! (' .. Config.MinHeight .. '–' .. Config.MaxHeight .. ' cm)',
    invalid_weight  = 'Érvénytelen súly! (' .. Config.MinWeight .. '–' .. Config.MaxWeight .. ' kg)',
}