-- ╔══════════════════════════════════════════════╗
-- ║         fvg-shops :: client                  ║
-- ╚══════════════════════════════════════════════╝

local menuOpen     = false
local currentShop  = nil
local shopBlips    = {}
local shopNPCs     = {}
local dynamicShops = {}   -- runtime regisztrált boltok

-- ── Kliens exportok ───────────────────────────────────────────
exports('IsShopOpen', function() return menuOpen end)

exports('OpenShop', function(shopId)
    if menuOpen then return end
    TriggerServerEvent('fvg-shops:server:RequestShop', shopId)
end)

exports('GetNearestShop', function(maxDist)
    maxDist        = maxDist or 10.0
    local ped      = PlayerPedId()
    local coords   = GetEntityCoords(ped)
    local nearest  = nil
    local nearDist = maxDist

    local allShops = {}
    for _, s in ipairs(Config.Shops) do table.insert(allShops, s) end
    for _, s in pairs(dynamicShops)  do table.insert(allShops, s) end

    for _, shop in ipairs(allShops) do
        local dist = #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
        if dist < nearDist then
            nearDist = dist
            nearest  = shop
        end
    end
    return nearest
end)

-- ── Blipek ────────────────────────────────────────────────────
local function CreateBlip(shop)
    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip,  shop.blip.sprite)
    SetBlipColour(blip,  shop.blip.color)
    SetBlipScale(blip,   shop.blip.scale or 0.75)
    SetBlipAsShortRange(blip, Config.BlipShortRange)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(shop.label)
    EndTextCommandSetBlipName(blip)
    shopBlips[shop.id] = blip
end

-- ── NPC spawn ─────────────────────────────────────────────────
local function SpawnNPC(shop)
    if not shop.npc then return end
    local model = GetHashKey(shop.npc.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local ped = CreatePed(4, model,
        shop.npc.coords.x, shop.npc.coords.y, shop.npc.coords.z - 1.0,
        shop.npc.coords.w, false, true)
    SetEntityHeading(ped, shop.npc.coords.w)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)
    shopNPCs[shop.id] = ped
end

-- ── Inicializálás ────────────────────────────────────────────
CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        CreateBlip(shop)
        SpawnNPC(shop)
    end
end)

-- ── Dinamikus bolt fogadás ────────────────────────────────────
RegisterNetEvent('fvg-shops:client:RegisterShop', function(shop)
    dynamicShops[shop.id] = shop
    CreateBlip(shop)
    SpawnNPC(shop)
end)

-- ── Interakció thread ─────────────────────────────────────────
CreateThread(function()
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local allShops = {}
        for _, s in ipairs(Config.Shops) do table.insert(allShops, s) end
        for _, s in pairs(dynamicShops)  do table.insert(allShops, s) end

        for _, shop in ipairs(allShops) do
            local dist = #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
            if dist < 25.0 then
                sleep = 0
                -- Marker
                DrawMarker(1,
                    shop.coords.x, shop.coords.y, shop.coords.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.2, 1.2, 0.5,
                    56, 189, 248, 100,
                    false, true, 2, nil, nil, false
                )
                if dist < Config.ShopRadius then
                    exports['fvg-notify']:Notify({
                        type='info',
                        message='[E] ' .. shop.label .. ' megnyitása',
                        duration=600, static=true
                    })
                    if IsControlJustPressed(0, 38) and not menuOpen then
                        currentShop = shop.id
                        TriggerServerEvent('fvg-shops:server:RequestShop', shop.id)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Panel megnyitás ──────────────────────────────────────────
RegisterNetEvent('fvg-shops:client:OpenShop', function(data)
    menuOpen = true
    currentShop = data.shopId
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', payload = data })
end)

-- ── Készlet frissítés ─────────────────────────────────────────
RegisterNetEvent('fvg-shops:client:StockUpdate', function(shopId, itemName, newStock)
    if shopId == currentShop then
        SendNUIMessage({ action = 'stockUpdate', item = itemName, stock = newStock })
    end
end)

RegisterNetEvent('fvg-shops:client:StockSync', function(shopId, stockMap)
    if shopId == currentShop then
        SendNUIMessage({ action = 'stockSync', stock = stockMap })
    end
end)

-- ── Vásárlás visszajelzés ─────────────────────────────────────
RegisterNetEvent('fvg-shops:client:PurchaseSuccess', function(data)
    -- Animáció
    if Config.UseAnimation then
        local p = PlayerPedId()
        RequestAnimDict(Config.BuyAnim.dict)
        while not HasAnimDictLoaded(Config.BuyAnim.dict) do Wait(10) end
        TaskPlayAnim(p, Config.BuyAnim.dict, Config.BuyAnim.anim,
            3.0, -3.0, Config.BuyAnim.duration, 49, 0, false, false, false)
    end
    SendNUIMessage({ action = 'purchaseSuccess', data = data })
end)

-- ── NUI Callbacks ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen    = false
    currentShop = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    TriggerServerEvent('fvg-shops:server:Buy',
        data.shopId, data.item, tonumber(data.quantity), data.paymentMethod)
    cb('ok')
end)

RegisterNUICallback('requestStock', function(data, cb)
    TriggerServerEvent('fvg-shops:server:GetStock', data.shopId)
    cb('ok')
end)

-- ── Parancs ───────────────────────────────────────────────────
RegisterCommand('shop', function()
    local nearest = exports['fvg-shops']:GetNearestShop(10.0)
    if nearest and not menuOpen then
        TriggerServerEvent('fvg-shops:server:RequestShop', nearest.id)
    end
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, blip in pairs(shopBlips) do RemoveBlip(blip) end
    for _, npc  in pairs(shopNPCs)  do
        if DoesEntityExist(npc) then DeletePed(npc) end
    end
    menuOpen    = false
    currentShop = nil
end)