-- ╔══════════════════════════════════════════════╗
-- ║         fvg-identity :: client               ║
-- ╚══════════════════════════════════════════════╝

local localIdentity = nil
local isRegistered  = false
local creatorCam    = nil
local menuOpen      = false

-- ── Exportok ─────────────────────────────────────────────────

exports('GetLocalIdentity', function()
    return localIdentity
end)

exports('IsRegistered', function()
    return isRegistered
end)

-- ── Kamera beállítás ──────────────────────────────────────────
local function SetupCamera(ped)
    local pos    = GetEntityCoords(ped)
    local fwd    = GetEntityForwardVector(ped)
    local camPos = vector3(
        pos.x + Config.CamOffset.x - fwd.x * math.abs(Config.CamOffset.y),
        pos.y + Config.CamOffset.y - fwd.y * math.abs(Config.CamOffset.y),
        pos.z + Config.CamOffset.z
    )
    creatorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(creatorCam, camPos.x, camPos.y, camPos.z)
    SetCamPointAtCoord(creatorCam, pos.x, pos.y, pos.z + 0.5)
    SetCamFov(creatorCam, Config.CamFOV)
    RenderScriptCams(true, true, 1000, true, false)
end

local function DestroyCamera()
    if creatorCam then
        RenderScriptCams(false, true, 800, true, false)
        DestroyCam(creatorCam, false)
        creatorCam = nil
    end
end

-- ── Megjelenés alkalmazása ────────────────────────────────────
local function ApplyAppearance(identity)
    local ped = PlayerPedId()
    local app = identity.appearance or {}

    -- Modell beállítás nem/sex alapján
    local sex      = identity.sex or 0
    local modelStr = sex == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    local model    = GetHashKey(modelStr)

    if GetEntityModel(ped) ~= model then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(50) end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        ped = PlayerPedId()
    end

    -- Fejforma és bőrszín (HeadBlendData)
    local shapeId = app.shapeId or 0
    local skinId  = app.skinId  or 0
    SetPedHeadBlendData(ped,
        shapeId, shapeId, 0,
        skinId,  skinId,  0,
        0.5, 1.0, 0.0, false
    )

    -- Haj
    local hairStyle = app.hairStyle or 0
    local hairColor = app.hairColor or 0
    SetPedComponentVariation(ped, 2, hairStyle, 0, 0)
    SetPedHairColor(ped, hairColor, hairColor)

    -- Szemszín
    local eyeColor = app.eyeColor or 0
    SetPedEyeColor(ped, eyeColor)

    -- Alap öltözék – mezítelen helyett alap polgári
    SetPedDefaultComponentVariation(ped)

    -- Felsőtest – Component 11 (felső)
    SetPedComponentVariation(ped, 11, app.top    or 15, app.topTex    or 0, 2)
    -- Láb – Component 4 (nadrág)
    SetPedComponentVariation(ped, 4,  app.pants  or 14, app.pantsTex  or 0, 2)
    -- Cipő – Component 6
    SetPedComponentVariation(ped, 6,  app.shoes  or 34, app.shoesTex  or 0, 2)
    -- Kiegészítő – Component 8 (ing alap)
    SetPedComponentVariation(ped, 8,  app.shirt  or 15, app.shirtTex  or 0, 2)
end

-- ── Karakterkészítő megnyitása (új játékos) ───────────────────
RegisterNetEvent('fvg-identity:client:OpenCreator', function()
    local ped = PlayerPedId()

    -- Teleport a regisztrációs helyszínre
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(ped,
        Config.RegistrationCoords.x,
        Config.RegistrationCoords.y,
        Config.RegistrationCoords.z,
        false, false, false, false
    )
    SetEntityHeading(ped, Config.RegistrationCoords.heading)
    Wait(400)
    DoScreenFadeIn(500)

    -- Alap modell
    local model = GetHashKey('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(50) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)

    -- Kamera
    SetupCamera(ped)

    -- NUI megnyitása
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'openCreator',
        isNew   = true,
        config  = {
            minAge     = Config.MinAge,
            maxAge     = Config.MaxAge,
            minHeight  = Config.MinHeight,
            maxHeight  = Config.MaxHeight,
            minWeight  = Config.MinWeight,
            maxWeight  = Config.MaxWeight,
            maxNameLen = Config.MaxNameLen,
            sexes      = Config.Sexes,
            skinTones  = Config.SkinTones,
            hairColors = Config.HairColors,
            hairStyles = Config.HairStyles,
            eyeColors  = Config.EyeColors,
        }
    })
end)

-- ── Karakterszerkesztő megnyitása (meglévő játékos) ──────────
RegisterNetEvent('fvg-identity:client:OpenEditor', function(identity)
    local ped = PlayerPedId()
    SetupCamera(ped)

    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'openCreator',
        isNew    = false,
        identity = identity,
        config   = {
            minAge     = Config.MinAge,
            maxAge     = Config.MaxAge,
            minHeight  = Config.MinHeight,
            maxHeight  = Config.MaxHeight,
            minWeight  = Config.MinWeight,
            maxWeight  = Config.MaxWeight,
            maxNameLen = Config.MaxNameLen,
            sexes      = Config.Sexes,
            skinTones  = Config.SkinTones,
            hairColors = Config.HairColors,
            hairStyles = Config.HairStyles,
            eyeColors  = Config.EyeColors,
        }
    })
end)

-- ── Megjelenés alkalmazása (szervertől) ──────────────────────
RegisterNetEvent('fvg-identity:client:ApplyAppearance', function(identity)
    localIdentity = identity
    isRegistered  = identity.registered == true
    ApplyAppearance(identity)
    TriggerEvent('fvg-identity:client:Ready', identity)
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

-- Valós idejű megjelenés előnézet
RegisterNUICallback('previewAppearance', function(data, cb)
    local ped = PlayerPedId()
    local app = data.appearance or {}

    -- Nem / modell csere
    local sex      = tonumber(data.sex or 0)
    local modelStr = sex == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    local model    = GetHashKey(modelStr)
    if GetEntityModel(ped) ~= model then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(50) end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        ped = PlayerPedId()
    end

    -- HeadBlend
    local shapeId = tonumber(app.shapeId or 0)
    local skinId  = tonumber(app.skinId  or 0)
    SetPedHeadBlendData(ped, shapeId, shapeId, 0, skinId, skinId, 0, 0.5, 1.0, 0.0, false)

    -- Haj
    SetPedComponentVariation(ped, 2, tonumber(app.hairStyle or 0), 0, 0)
    SetPedHairColor(ped, tonumber(app.hairColor or 0), tonumber(app.hairColor or 0))
    SetPedEyeColor(ped, tonumber(app.eyeColor or 0))

    -- Ruházat
    SetPedDefaultComponentVariation(ped)
    SetPedComponentVariation(ped, 11, tonumber(app.top   or 15), tonumber(app.topTex   or 0), 2)
    SetPedComponentVariation(ped, 4,  tonumber(app.pants or 14), tonumber(app.pantsTex or 0), 2)
    SetPedComponentVariation(ped, 6,  tonumber(app.shoes or 34), tonumber(app.shoesTex or 0), 2)
    SetPedComponentVariation(ped, 8,  tonumber(app.shirt or 15), tonumber(app.shirtTex or 0), 2)

    cb('ok')
end)

-- Mentés
RegisterNUICallback('saveIdentity', function(data, cb)
    TriggerServerEvent('fvg-identity:server:SaveIdentity', data)
    menuOpen = false
    SetNuiFocus(false, false)
    DestroyCamera()
    cb('ok')
end)

-- Bezárás (csak szerkesztőnél, regisztrációnál nem engedett)
RegisterNUICallback('closeEditor', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    DestroyCamera()
    cb('ok')
end)

-- ── Parancs: /identity (szerkesztő megnyitás) ─────────────────
RegisterCommand('identity', function()
    if not isRegistered then return end
    TriggerServerEvent('fvg-identity:server:OpenEditor')
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    DestroyCamera()
    SetNuiFocus(false, false)
    localIdentity = nil
    isRegistered  = false
end)