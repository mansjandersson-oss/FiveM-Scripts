local QBCore = exports['qb-core']:GetCoreObject()

local harvestCooldowns = {}
local processCooldowns = {}
local deliveryCooldowns = {}

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key

    if select('#', ...) > 0 then
        return text:format(...)
    end

    return text
end

local function notify(src, message, notifyType)
    TriggerClientEvent('qb-boozebiz:client:Notify', src, message, notifyType)
end

local function getPoliceCount()
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()

    for _, player in pairs(players) do
        if player.PlayerData.job and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            amount += 1
        end
    end

    return amount
end

local function hasCooldown(bucket, src, cooldown)
    local now = os.time()
    local expiresAt = bucket[src] or 0

    if expiresAt > now then
        return true, expiresAt - now
    end

    bucket[src] = now + cooldown
    return false, 0
end

local function hasItems(src, required)
    for item, amount in pairs(required) do
        local count = exports.ox_inventory:Search(src, 'count', item) or 0
        if count < amount then
            return false, item, amount - count
        end
    end

    return true
end

local function canCarryOutput(src, outputItem, count, metadata)
    return exports.ox_inventory:CanCarryItem(src, outputItem, count, metadata)
end

local function removeInputs(src, required)
    for item, amount in pairs(required) do
        local removed = exports.ox_inventory:RemoveItem(src, item, amount)
        if not removed then
            return false, item
        end
    end

    return true
end

local function addOutput(src, outputItem, count, metadata)
    return exports.ox_inventory:AddItem(src, outputItem, count, metadata)
end

local function getHarvestZone(zoneName)
    for _, zone in ipairs(Config.HarvestZones) do
        if zone.name == zoneName then
            return zone
        end
    end
end

local function getStockZone(zoneName)
    for _, zone in ipairs(Config.StockZones) do
        if zone.name == zoneName then
            return zone
        end
    end
end

local function getFermentRoute(route)
    return Config.FermentationRoutes[route]
end

local function getDistillProfile(source, product, temp, time)
    local sourceProfiles = Config.DistillProfiles[source]
    if not sourceProfiles then return end

    local profile = sourceProfiles[product]
    if not profile then return end

    if temp >= profile.temp.min and temp <= profile.temp.max
        and time >= profile.time.min and time <= profile.time.max then
        return profile
    end
end

RegisterNetEvent('qb-boozebiz:server:HarvestItem', function(zoneName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    if getPoliceCount() < Config.PoliceRequired then
        notify(src, t('not_enough_police', Config.PoliceRequired), 'error')
        return
    end

    local zone = getHarvestZone(zoneName)
    if not zone then
        notify(src, t('invalid_harvest_zone'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(harvestCooldowns, src, Config.Cooldowns.Harvest)
    if blocked then
        notify(src, t('field_exhausted', remaining), 'error')
        return
    end

    local amount = math.random(zone.count.min, zone.count.max)
    if not canCarryOutput(src, zone.item, amount) then
        notify(src, t('not_enough_inventory'), 'error')
        return
    end

    addOutput(src, zone.item, amount)
    notify(src, t('collected_item', amount, zone.item), 'success')
end)

RegisterNetEvent('qb-boozebiz:server:FermentMash', function(fermentData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(fermentData) ~= 'table' then
        notify(src, t('invalid_ferment_data'), 'error')
        return
    end

    local route = fermentData.route
    local fermentRoute = getFermentRoute(route)
    if not fermentRoute then
        notify(src, t('invalid_mash_route'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(processCooldowns, src, Config.Cooldowns.Process)
    if blocked then
        notify(src, t('cooling_down', remaining), 'error')
        return
    end

    local enoughItems, missingItem, missingAmount = hasItems(src, fermentRoute.input)
    if not enoughItems then
        notify(src, t('missing_item', missingAmount, missingItem), 'error')
        return
    end

    if not canCarryOutput(src, fermentRoute.output, fermentRoute.outputCount, {
        mashType = route,
        label = t(fermentRoute.labelKey or fermentRoute.label)
    }) then
        notify(src, t('no_space_mash_output'), 'error')
        return
    end

    local removed, failedItem = removeInputs(src, fermentRoute.input)
    if not removed then
        notify(src, t('remove_ingredient_fail', failedItem), 'error')
        return
    end

    local metadata = {
        mashType = route,
        label = t(fermentRoute.labelKey or fermentRoute.label)
    }

    local added = addOutput(src, fermentRoute.output, fermentRoute.outputCount, metadata)
    if not added then
        notify(src, t('add_ferment_output_fail'), 'error')
        return
    end

    notify(src, t('fermentation_success', fermentRoute.outputCount, t(fermentRoute.labelKey or fermentRoute.label)), 'success')
end)

RegisterNetEvent('qb-boozebiz:server:DistillMash', function(distillData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(distillData) ~= 'table' then
        notify(src, t('invalid_distill_settings'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(processCooldowns, src, Config.Cooldowns.Process)
    if blocked then
        notify(src, t('cooling_down', remaining), 'error')
        return
    end

    local sourceMash = distillData.source
    local productKey = distillData.product
    local temp = math.floor(tonumber(distillData.temp) or 0)
    local time = math.floor(tonumber(distillData.time) or 0)

    if sourceMash ~= 'beer' and sourceMash ~= 'wine' then
        notify(src, t('invalid_mash_source'), 'error')
        return
    end

    if sourceMash == 'beer' and productKey ~= 'beer' and productKey ~= 'vodka' and productKey ~= 'gin' and productKey ~= 'whiskey' then
        notify(src, t('invalid_distill_product'), 'error')
        return
    end

    if sourceMash == 'wine' and productKey ~= 'wine' then
        notify(src, t('invalid_distill_product'), 'error')
        return
    end

    if temp < Config.Minigames.Distill.tempMin or temp > Config.Minigames.Distill.tempMax then
        notify(src, t('invalid_distill_temp'), 'error')
        return
    end

    if time < Config.Minigames.Distill.timeMin or time > Config.Minigames.Distill.timeMax then
        notify(src, t('invalid_distill_time'), 'error')
        return
    end

    local mashItem = sourceMash == 'beer' and Config.Items.beerMash or Config.Items.wineMash
    local haveMash = exports.ox_inventory:Search(src, 'count', mashItem) or 0
    if haveMash < 1 then
        notify(src, t('need_mash', mashItem), 'error')
        return
    end

    local profile = getDistillProfile(sourceMash, productKey, temp, time)
    if not profile then
        notify(src, t('distill_profile_fail'), 'error')
        return
    end

    local alcoholType = t(profile.labelKey or profile.label)
    local purity = math.random(profile.purity.min, profile.purity.max)

    local outputMetadata = {
        alcoholType = alcoholType,
        purity = purity,
        distillTemp = temp,
        distillTime = time,
        label = ('%s (%s%%)'):format(alcoholType, purity)
    }

    if not canCarryOutput(src, Config.Items.distilledSpirit, 1, outputMetadata) then
        notify(src, t('no_space_distill_output'), 'error')
        return
    end

    local removedMash = exports.ox_inventory:RemoveItem(src, mashItem, 1)
    if not removedMash then
        notify(src, t('remove_mash_fail'), 'error')
        return
    end

    local added = addOutput(src, Config.Items.distilledSpirit, 1, outputMetadata)
    if not added then
        notify(src, t('add_distill_output_fail'), 'error')
        return
    end

    notify(src, t('distill_success', alcoholType, temp, time), 'success')
end)

RegisterNetEvent('qb-boozebiz:server:ProcessRecipe', function(recipeName, craftData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local recipe = Config.Recipes[recipeName]
    if not recipe then
        notify(src, t('invalid_recipe'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(processCooldowns, src, Config.Cooldowns.Process)
    if blocked then
        notify(src, t('cooling_down', remaining), 'error')
        return
    end

    local enoughItems, missingItem, missingAmount = hasItems(src, recipe.input)
    if not enoughItems then
        notify(src, t('missing_item', missingAmount, missingItem), 'error')
        return
    end

    local metadata
    if recipeName == 'Bottle' then
        local bottleName = 'House Blend'
        local purity = math.random(72, 99)

        if type(craftData) == 'table' then
            if type(craftData.bottleName) == 'string' then
                local cleanedName = craftData.bottleName:gsub('^%s+', ''):gsub('%s+$', '')
                cleanedName = cleanedName:sub(1, 24)
                if cleanedName ~= '' then
                    bottleName = cleanedName
                end
            end

            local clientPurity = math.floor(tonumber(craftData.purity) or 0)
            if clientPurity >= 70 and clientPurity <= 99 then
                purity = clientPurity
            end
        end

        metadata = {
            bottleName = bottleName,
            purity = purity,
            label = ('%s (%s%%)'):format(bottleName, purity)
        }
    end

    if not canCarryOutput(src, recipe.output.item, recipe.output.count, metadata) then
        notify(src, t('no_space_output'), 'error')
        return
    end

    local removed, failedItem = removeInputs(src, recipe.input)
    if not removed then
        notify(src, t('remove_ingredient_fail', failedItem), 'error')
        return
    end

    local added = addOutput(src, recipe.output.item, recipe.output.count, metadata)
    if not added then
        notify(src, t('add_crafted_fail'), 'error')
        return
    end

    notify(src, t('production_success', recipe.output.count, recipe.output.item), 'success')
end)

RegisterNetEvent('qb-boozebiz:server:TryFermentationExplosion', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local playerPed = GetPlayerPed(src)
    if playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    local stationCoords
    for _, station in ipairs(Config.ProcessingStations) do
        if station.name == 'fermentation_vat' then
            stationCoords = station.coords
            break
        end
    end

    if not stationCoords then return end

    if #(playerCoords - stationCoords) > 12.0 then
        return
    end

    if math.random(1, 100) > Config.Minigames.Ferment.explosionChance then
        notify(src, t('avoided_explosion'), 'inform')
        return
    end

    TriggerClientEvent('qb-boozebiz:client:FermentationExplosion', -1, {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        radius = Config.Minigames.Ferment.explosionRadius,
        damage = Config.Minigames.Ferment.explosionDamage
    })
end)

RegisterNetEvent('qb-boozebiz:server:BreakBottles', function(amount)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local breakAmount = math.max(1, math.min(3, tonumber(amount) or 1))
    local bottleItem = Config.Items.bottledLiquor

    local removed = exports.ox_inventory:RemoveItem(src, bottleItem, breakAmount)
    if removed then
        notify(src, t('broke_bottles', breakAmount), 'error')
    else
        notify(src, t('no_bottles_broken'), 'error')
    end
end)

RegisterNetEvent('qb-boozebiz:server:StockStore', function(zoneName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local zone = getStockZone(zoneName)
    if not zone then
        notify(src, t('invalid_store_route'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(deliveryCooldowns, src, Config.Cooldowns.Delivery)
    if blocked then
        notify(src, t('store_stocked_wait', remaining), 'error')
        return
    end

    local crateItem = Config.Items.liquorCrate
    local hasCrates = exports.ox_inventory:Search(src, 'count', crateItem) or 0
    if hasCrates < 1 then
        notify(src, t('need_crate'), 'error')
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, crateItem, 1)
    if not removed then
        notify(src, t('remove_crate_fail'), 'error')
        return
    end

    local payout = math.random(Config.MinDeliveryPayout, Config.MaxDeliveryPayout)
    player.Functions.AddMoney('bank', payout, 'booze-store-stock')

    notify(src, t('stock_success', t(zone.labelKey or zone.label), payout), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    harvestCooldowns[src] = nil
    processCooldowns[src] = nil
    deliveryCooldowns[src] = nil
end)
