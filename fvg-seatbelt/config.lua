Config = {}

-- Billentyű a biztonsági öv kapcsolásához (FiveM billentyűnév)
Config.Key         = 'B'
Config.KeyLabel    = 'Biztonsági öv kapcsolása'

-- Sebesség küszöb (km/h), ami felett a kiesés aktiválódik
Config.EjectMinSpeed = 30.0

-- Esélyalapú kiesés súlyozása (0–100):
-- Minél magasabb a sebesség, annál nagyobb a kiesés esélye.
-- Ez a szorzó meghatározza, mennyire "agresszív" a kiesés.
Config.EjectChanceScale = 1.5

-- Sebesség csökkenés küszöb (%)  ami alatt ütközés detektálható
-- Pl. 0.65 = ha a sebesség 65%-ra esik egy frameen belül -> ütközés
Config.CrashSpeedDropRatio = 0.65

-- Minimális body health változás ami ütközésnek számít
Config.MinBodyHealthDrop = 15.0

-- Kiesés utáni sebzés szorzó (0.0 = nincs sebzés, 1.0 = teljes)
Config.EjectDamageScale = 0.8

-- Hang fájlok
Config.SoundBuckle   = 'seatbelt_on'
Config.SoundUnbuckle = 'seatbelt_off'
Config.SoundDict     = 'HUD_FRONTEND_DEFAULT_SOUNDSET'

-- Tiltott jármű osztályok (motor, kerékpár, csónak stb.)
-- 8 = motor, 13 = kerékpár, 14 = csónak
Config.DisabledClasses = { 8, 13, 14 }

-- fvg-vehiclehud integráció
Config.VehicleHudIntegration = true

-- fvg-notify integráció
Config.NotifyIntegration = true

-- Értesítések szövege
Config.Locale = {
    belted     = 'Biztonsági öv becsatolva.',
    unbelted   = 'Biztonsági öv kiengedve.',
    not_in_veh = 'Nem vagy járműben.',
    cant_use   = 'Ebben a járműben nem használható biztonsági öv.',
}