-- ╔══════════════════════════════════════════════╗
-- ║        fvg-inventory :: client               ║
-- ╚══════════════════════════════════════════════╝

local localInventory = {}
local menuOpen       = false
local nearbyDrops    = {}

-- ── Kliens exportok ───────────────────────────────────────────────
exports('GetLocalInventory', function()
    return localInventory
end)

exports('GetLocalItemCount', function(itemName)
    local count = 0
    for _, data in pairs(localInventory) do
        if data.item == itemName then count = count + data.amount end
    end
    return count
end)

exports('HasLocalItem', function(itemName, amount)
    return exports['fvg-inventory']:GetLocalItemCount(itemName) >= (tonumber(amount) or 1)
end)

-- ── Inventory szinkron fogadása ────────────────────────────────────
RegisterNetEvent('fvg-inventory:client:SyncInventory', function(data)
    localInventory = {}
    for _, slot in ipairs(data.slots or {}) do
        localInventory[slot.slot] = slot
    end
    if menuOpen then
        SendNUIMessage({
            action    = 'syncSlots',
            slots     = data.slots,
            weight    = data.weight,
            maxWeight = data.maxWeight,
        })
    end
end)

-- ── Inventory megnyitás ─────────────────────────────────────────────
RegisterNetEvent('fvg-inventory:client:OpenInventory', function(data)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'open',
        slots      = data.slots,
        weight     = data.weight,
        maxWeight  = data.maxWeight,
        maxSlots   = data.maxSlots,
        categories = data.categories,
    })
end)

-- ── Billentyű: inventory megnyitás ──────────────────────────────────
RegisterCommand('inventory', function()
    if menuOpen then return end
    TriggerServerEvent('fvg-inventory:server:RequestOpen')
end, false)

RegisterKeyMapping('inventory', 'Inventory megnyitása', 'keyboard', 'TAB')

-- ── NUI Callbacks ────────────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('fvg-inventory:server:UseItem', tonumber(data.slot))
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('fvg-inventory:server:DropItem', tonumber(data.slot), tonumber(data.amount) or 1)
    cb('ok')
end)

RegisterNUICallback('moveSlot', function(data, cb)
    TriggerServerEvent('fvg-inventory:server:MoveSlot', tonumber(data.from), tonumber(data.to))
    cb('ok')
end)

RegisterNUICallback('pickupDrop', function(data, cb)
    TriggerServerEvent('fvg-inventory:server:PickupDrop', data.dropId)
    cb('ok')
end)

-- ── Drop koordináta küldés ──────────────────────────────────────────
RegisterNetEvent('fvg-inventory:client:GetDropCoords', function(slot, amount)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('fvg-inventory:server:ConfirmDrop', slot, amount, {
        x = coords.x + math.random(-1, 1) * 0.5,
        y = coords.y + math.random(-1, 1) * 0.5,
        z = coords.z,
    })
end)

-- ── Drop megjelenítés ──────────────────────────────────────────────
RegisterNetEvent('fvg-inventory:client:AddDrop', function(dropId, dropData)
    nearbyDrops[dropId] = dropData
end)

RegisterNetEvent('fvg-inventory:client:RemoveDrop', function(dropId)
    nearbyDrops[dropId] = nil
end)

-- ── Felvétel (E gomb) ────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(500)
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, closestDist = nil, Config.DropDistance + 1
        for dropId, drop in pairs(nearbyDrops) do
            local dist = #(coords - vector3(drop.x, drop.y, drop.z))
            if dist < closestDist then
                closestDist = dist
                closest     = dropId
            end
        end
        if closest and closestDist <= Config.DropDistance then
            local drop  = nearbyDrops[closest]
            local label = (Config.Items[drop.item] or {}).label or drop.item
            exports['fvg-notify']:Notify({
                type     = 'info',
                message  = '[E] ' .. label .. ' felvétele (x' .. drop.amount .. ')',
                duration = 600,
            })
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent('fvg-inventory:server:PickupDrop', closest)
            end
        end
    end
end)

-- ── Drop marker rajzolás ────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if not Config.DropMarker then goto continue end
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, drop in pairs(nearbyDrops) do
            local dist = #(coords - vector3(drop.x, drop.y, drop.z))
            if dist < 30.0 then
                DrawMarker(1,
                    drop.x, drop.y, drop.z + 0.1,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.3, 0.3, 0.3,
                    56, 189, 248, 180,
                    false, true, 2, nil, nil, false
                )
            end
        end
        ::continue::
    end
end)

-- ── Gyógyítás fogadása ──────────────────────────────────────────────
RegisterNetEvent('fvg-inventory:client:UseHeal', function(amount)
    local ped    = PlayerPedId()
    local health = GetEntityHealth(ped)
    SetEntityHealth(ped, math.min(health + amount, 200))
end)

-- ── Fegyver equipálás (FIX: weaponHash paraméter a serverről jön) ──────────
RegisterNetEvent('fvg-inventory:client:EquipWeapon', function(itemName, metadata, weaponHash)
    local ped  = PlayerPedId()
    -- FIX: weaponHash közvetlenül jön, nem szükséges helyi térkép
    local hash = GetHashKey(weaponHash or itemName)
    GiveWeaponToPed(ped, hash, metadata.ammo or 30, false, true)
end)

-- ── Cleanup ──────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    localInventory = {}
    nearbyDrops    = {}
end)
