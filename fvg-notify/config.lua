Config = {}

-- Alapértelmezett időtartam milliszekundumban
Config.DefaultDuration = 4000

-- Maximum egyszerre megjelenő értesítések száma
Config.MaxNotifications = 5

-- Értesítések megjelenési pozíciója: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
Config.Position = 'top-right'

-- Animáció sebessége milliszekundumban
Config.AnimationSpeed = 300

-- Hang lejátszása értesítéskor (true/false)
Config.PlaySound = true

-- Elérhető típusok és ikonjaik (HugeIcons class nevek)
Config.Types = {
    success = {
        icon    = 'hgi-stroke hgi-checkmark-circle-02',
        label   = 'Sikeres'
    },
    error = {
        icon    = 'hgi-stroke hgi-cancel-circle',
        label   = 'Hiba'
    },
    info = {
        icon    = 'hgi-stroke hgi-information-circle',
        label   = 'Információ'
    },
    warning = {
        icon    = 'hgi-stroke hgi-alert-02',
        label   = 'Figyelmeztetés'
    },
    police = {
        icon    = 'hgi-stroke hgi-police-badge',
        label   = 'Rendőrség'
    },
    money = {
        icon    = 'hgi-stroke hgi-money-bag-02',
        label   = 'Pénz'
    }
}