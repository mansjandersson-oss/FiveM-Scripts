local RESOURCE = GetCurrentResourceName()
local QBCore = exports['qb-core']:GetCoreObject()

local harvestCooldowns = {}
local processCooldowns = {}
local deliveryCooldowns = {}
local alertCooldowns = {}
local pendingWitnessChecks = {}
local harvestZones = {}
local stockZones = {}
local processingStations = {}

local recipeActions = {
    Bottle = 'bottle',
    Pack = 'pack'
}

local function eventName(scope, name)
    return ('%s:%s:%s'):format(RESOURCE, scope, name)
end

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key

    if select('#', ...) > 0 then
        return text:format(...)
    end

    return text
end

local function notify(src, message, notifyType)
    TriggerClientEvent(eventName('client', 'Notify'), src, message, notifyType)
end

local function buildLookups()
    for _, zone in ipairs(Config.HarvestZones) do
        harvestZones[zone.name] = zone
    end

    for _, zone in ipairs(Config.StockZones) do
        stockZones[zone.name] = zone
    end

    for _, station in ipairs(Config.ProcessingStations) do
        processingStations[station.action] = station
    end
end

local function getPoliceCount()
    if Config.PoliceRequired < 1 then
        return 0
    end

    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()

    for _, player in pairs(players) do
        local job = player.PlayerData.job
        if job and job.name == 'police' and job.onduty then
            amount = amount + 1
        end
    end

    return amount
end

local function getCooldownRemaining(bucket, src)
    local expiresAt = bucket[src] or 0
    local remaining = expiresAt - os.time()

    if remaining > 0 then
        return remaining
    end

    bucket[src] = nil
    return 0
end

local function setCooldown(bucket, src, cooldown)
    bucket[src] = os.time() + cooldown
end

local function isNearCoords(src, coords, maxDistance)
    if not Config.Security or Config.Security.ValidateDistance == false then
        return true
    end

    local ped = GetPlayerPed(src)
    if ped == 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= maxDistance
end

local function validateZoneDistance(src, zone, maxDistance)
    if isNearCoords(src, zone.coords, maxDistance) then
        return true
    end

    notify(src, t('too_far_from_station'), 'error')
    return false
end

local function validateProcessingDistance(src, action)
    local station = processingStations[action]
    if not station then
        notify(src, t('invalid_recipe'), 'error')
        return false
    end

    return validateZoneDistance(src, station, Config.Security.MaxProcessDistance)
end

local function canSendPoliceAlert(src)
    local alertConfig = Config.PoliceAlert
    if not alertConfig or alertConfig.Enabled == false then
        return false
    end

    local remaining = getCooldownRemaining(alertCooldowns, src)
    return remaining <= 0
end

local function isAlertAction(action)
    local alertConfig = Config.PoliceAlert
    return alertConfig
        and alertConfig.Enabled ~= false
        and alertConfig.Actions
        and alertConfig.Actions[action] == true
end

local function hasDistillingPermit(src)
    local permitItem = Config.PoliceAlert and Config.PoliceAlert.PermitItem
    if not permitItem or permitItem == '' then
        return false
    end

    return (exports.ox_inventory:Search(src, 'count', permitItem) or 0) > 0
end

local function isPolice(player)
    local job = player.PlayerData.job
    local policeJobs = Config.PoliceAlert and Config.PoliceAlert.PoliceJobs
    return job and job.onduty and policeJobs and policeJobs[job.name] == true
end

local function sendPoliceAlert(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then
        return
    end

    local coords = GetEntityCoords(ped)
    local alertConfig = Config.PoliceAlert
    local dispatchConfig = alertConfig and alertConfig.Dispatch or {}
    local payload = {
        message = t('police_alert_illegal_distilling'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    }

    local dispatchResource = dispatchConfig.Resource or 'lb-tablet'
    if GetResourceState(dispatchResource) == 'started' then
        local success = pcall(function()
            local dispatch = {
                priority = dispatchConfig.Priority or 'medium',
                code = dispatchConfig.Code or '10-66',
                title = dispatchConfig.Title or t('police_alert_illegal_distilling'),
                description = t('police_alert_illegal_distilling'),
                location = {
                    label = dispatchConfig.LocationLabel or t('police_alert_illegal_distilling'),
                    coords = {
                        x = coords.x,
                        y = coords.y
                    }
                },
                time = dispatchConfig.Time or 300,
                job = 'police',
                sound = dispatchConfig.Sound,
                fields = {
                    {
                        icon = 'flask',
                        label = 'Larm',
                        value = t('police_alert_illegal_distilling')
                    }
                }
            }

            if not Config.PoliceAlert.Blip or Config.PoliceAlert.Blip.Enabled ~= false then
                dispatch.blip = {
                    sprite = (Config.PoliceAlert.Blip and Config.PoliceAlert.Blip.Sprite) or 161,
                    color = (Config.PoliceAlert.Blip and Config.PoliceAlert.Blip.Color) or 1,
                    size = (Config.PoliceAlert.Blip and Config.PoliceAlert.Blip.Scale) or 1.0,
                    shortRange = false,
                    label = dispatchConfig.Title or t('police_alert_illegal_distilling')
                }
            end

            exports[dispatchResource]:AddDispatch(dispatch)
        end)

        if success then
            return
        end
    end

    if dispatchConfig.UseFallbackNotify == false then
        return
    end

    local players = QBCore.Functions.GetQBPlayers()
    for targetSrc, player in pairs(players) do
        if isPolice(player) then
            local policeSrc = player.PlayerData.source or targetSrc
            TriggerClientEvent(eventName('client', 'PoliceAlert'), policeSrc, payload)
        end
    end
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

local function canStartAlertedAction(src, action, actionData)
    actionData = type(actionData) == 'table' and actionData or {}

    if action == 'ferment' then
        local route = tostring(actionData.route or '')
        local fermentRoute = Config.FermentationRoutes[route]
        if not fermentRoute then
            return false
        end

        return hasItems(src, fermentRoute.input)
    end

    if action == 'distill' then
        local sourceMash = tostring(actionData.source or '')
        if not Config.DistillProfiles[sourceMash] then
            return false
        end

        local mashItem = sourceMash == 'beer' and Config.Items.beerMash or Config.Items.wineMash
        return (exports.ox_inventory:Search(src, 'count', mashItem) or 0) > 0
    end

    if action == 'bottle' then
        return hasItems(src, Config.Recipes.Bottle.input)
    end

    if action == 'pack' then
        return hasItems(src, Config.Recipes.Pack.input)
    end

    return false
end

local function getDistillProfile(sourceMash, product, temp, time)
    local sourceProfiles = Config.DistillProfiles[sourceMash]
    if not sourceProfiles then return end

    local profile = sourceProfiles[product]
    if not profile then return end

    if temp >= profile.temp.min and temp <= profile.temp.max
        and time >= profile.time.min and time <= profile.time.max then
        return profile
    end
end

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

RegisterNetEvent(eventName('server', 'HarvestItem'), function(zoneName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    if getPoliceCount() < Config.PoliceRequired then
        notify(src, t('not_enough_police', Config.PoliceRequired), 'error')
        return
    end

    local zone = harvestZones[zoneName]
    if not zone then
        notify(src, t('invalid_harvest_zone'), 'error')
        return
    end

    if not validateZoneDistance(src, zone, Config.Security.MaxHarvestDistance) then
        return
    end

    local remaining = getCooldownRemaining(harvestCooldowns, src)
    if remaining > 0 then
        notify(src, t('field_exhausted', remaining), 'error')
        return
    end

    local amount = math.random(zone.count.min, zone.count.max)
    if not canCarryOutput(src, zone.item, amount) then
        notify(src, t('not_enough_inventory'), 'error')
        return
    end

    setCooldown(harvestCooldowns, src, Config.Cooldowns.Harvest)
    addOutput(src, zone.item, amount)
    notify(src, t('collected_item', amount, zone.item), 'success')
end)

RegisterNetEvent(eventName('server', 'FermentMash'), function(fermentData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(fermentData) ~= 'table' then
        notify(src, t('invalid_ferment_data'), 'error')
        return
    end

    if not validateProcessingDistance(src, 'ferment') then
        return
    end

    local route = tostring(fermentData.route or '')
    local fermentRoute = Config.FermentationRoutes[route]
    if not fermentRoute then
        notify(src, t('invalid_mash_route'), 'error')
        return
    end

    local remaining = getCooldownRemaining(processCooldowns, src)
    if remaining > 0 then
        notify(src, t('cooling_down', remaining), 'error')
        return
    end

    local enoughItems, missingItem, missingAmount = hasItems(src, fermentRoute.input)
    if not enoughItems then
        notify(src, t('missing_item', missingAmount, missingItem), 'error')
        return
    end

    local metadata = {
        mashType = route,
        label = t(fermentRoute.labelKey or fermentRoute.label)
    }

    if not canCarryOutput(src, fermentRoute.output, fermentRoute.outputCount, metadata) then
        notify(src, t('no_space_mash_output'), 'error')
        return
    end

    setCooldown(processCooldowns, src, Config.Cooldowns.Process)

    local removed, failedItem = removeInputs(src, fermentRoute.input)
    if not removed then
        notify(src, t('remove_ingredient_fail', failedItem), 'error')
        return
    end

    local added = addOutput(src, fermentRoute.output, fermentRoute.outputCount, metadata)
    if not added then
        notify(src, t('add_ferment_output_fail'), 'error')
        return
    end

    notify(src, t('fermentation_success', fermentRoute.outputCount, metadata.label), 'success')
end)

RegisterNetEvent(eventName('server', 'DistillMash'), function(distillData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(distillData) ~= 'table' then
        notify(src, t('invalid_distill_settings'), 'error')
        return
    end

    if not validateProcessingDistance(src, 'distill') then
        return
    end

    local sourceMash = tostring(distillData.source or '')
    local productKey = tostring(distillData.product or '')
    local temp = math.floor(tonumber(distillData.temp) or 0)
    local time = math.floor(tonumber(distillData.time) or 0)

    if not Config.DistillProfiles[sourceMash] then
        notify(src, t('invalid_mash_source'), 'error')
        return
    end

    if not Config.DistillProfiles[sourceMash][productKey] then
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

    local remaining = getCooldownRemaining(processCooldowns, src)
    if remaining > 0 then
        notify(src, t('cooling_down', remaining), 'error')
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

    setCooldown(processCooldowns, src, Config.Cooldowns.Process)

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

RegisterNetEvent(eventName('server', 'ProcessRecipe'), function(recipeName, craftData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local recipe = Config.Recipes[recipeName]
    if not recipe then
        notify(src, t('invalid_recipe'), 'error')
        return
    end

    if not validateProcessingDistance(src, recipeActions[recipeName]) then
        return
    end

    local remaining = getCooldownRemaining(processCooldowns, src)
    if remaining > 0 then
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
            local cleanedName = trim(craftData.bottleName):sub(1, 24)
            if cleanedName ~= '' then
                bottleName = cleanedName
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

    setCooldown(processCooldowns, src, Config.Cooldowns.Process)

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

RegisterNetEvent(eventName('server', 'TryFermentationExplosion'), function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local station = processingStations.ferment
    if not station or not validateZoneDistance(src, station, Config.Security.MaxProcessDistance) then
        return
    end

    if math.random(1, 100) > Config.Minigames.Ferment.explosionChance then
        notify(src, t('avoided_explosion'), 'inform')
        return
    end

    local playerPed = GetPlayerPed(src)
    if playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    TriggerClientEvent(eventName('client', 'FermentationExplosion'), -1, {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        radius = Config.Minigames.Ferment.explosionRadius,
        damage = Config.Minigames.Ferment.explosionDamage
    })
end)

RegisterNetEvent(eventName('server', 'BreakBottles'), function(amount)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if not validateProcessingDistance(src, 'pack') then
        return
    end

    local breakAmount = math.max(1, math.min(3, tonumber(amount) or 1))
    local bottleItem = Config.Items.bottledLiquor

    local removed = exports.ox_inventory:RemoveItem(src, bottleItem, breakAmount)
    if removed then
        notify(src, t('broke_bottles', breakAmount), 'error')
    else
        notify(src, t('no_bottles_broken'), 'error')
    end
end)

RegisterNetEvent(eventName('server', 'CheckIllegalProductionAlert'), function(action, actionData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(action) ~= 'string' or not isAlertAction(action) then
        return
    end

    if hasDistillingPermit(src) or not canSendPoliceAlert(src) then
        return
    end

    if not validateProcessingDistance(src, action) then
        return
    end

    if not canStartAlertedAction(src, action, actionData) then
        return
    end

    pendingWitnessChecks[src] = {
        action = action,
        expiresAt = os.time() + 8
    }

    TriggerClientEvent(eventName('client', 'CheckNpcWitness'), src, action)
end)

RegisterNetEvent(eventName('server', 'ConfirmIllegalProductionWitness'), function(action)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end
    if type(action) ~= 'string' or not isAlertAction(action) then
        return
    end

    if hasDistillingPermit(src) or not canSendPoliceAlert(src) then
        return
    end

    local pending = pendingWitnessChecks[src]
    pendingWitnessChecks[src] = nil

    if not pending or pending.action ~= action or pending.expiresAt < os.time() then
        return
    end

    if not validateProcessingDistance(src, action) then
        return
    end

    setCooldown(alertCooldowns, src, Config.PoliceAlert.Cooldown or 120)
    sendPoliceAlert(src)
end)

RegisterNetEvent(eventName('server', 'StockStore'), function(zoneName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then return end

    local zone = stockZones[zoneName]
    if not zone then
        notify(src, t('invalid_store_route'), 'error')
        return
    end

    if not validateZoneDistance(src, zone, Config.Security.MaxStockDistance) then
        return
    end

    local remaining = getCooldownRemaining(deliveryCooldowns, src)
    if remaining > 0 then
        notify(src, t('store_stocked_wait', remaining), 'error')
        return
    end

    local crateItem = Config.Items.liquorCrate
    local hasCrates = exports.ox_inventory:Search(src, 'count', crateItem) or 0
    if hasCrates < 1 then
        notify(src, t('need_crate'), 'error')
        return
    end

    setCooldown(deliveryCooldowns, src, Config.Cooldowns.Delivery)

    local removed = exports.ox_inventory:RemoveItem(src, crateItem, 1)
    if not removed then
        notify(src, t('remove_crate_fail'), 'error')
        return
    end

    local payout = math.random(Config.MinDeliveryPayout, Config.MaxDeliveryPayout)
    player.Functions.AddMoney('bank', payout, 'nb-destil-store-stock')

    notify(src, t('stock_success', t(zone.labelKey or zone.label), payout), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    harvestCooldowns[src] = nil
    processCooldowns[src] = nil
    deliveryCooldowns[src] = nil
    alertCooldowns[src] = nil
    pendingWitnessChecks[src] = nil
end)

buildLookups()
