local QBCore = exports['qb-core']:GetCoreObject()
local actionBusy = false

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key

    if select('#', ...) > 0 then
        return text:format(...)
    end

    return text
end

local function notify(message, notifyType)
    lib.notify({
        title = t('script_title'),
        description = message,
        type = notifyType or 'inform'
    })
end

local function runAction(label, duration, anim)
    if actionBusy then
        notify(t('busy_action'), 'error')
        return false
    end

    actionBusy = true
    local completed = lib.progressCircle({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = anim
    })
    actionBusy = false

    return completed
end

local function runSkillMinigame(minigameConfig)
    local success = lib.skillCheck(minigameConfig.stages, minigameConfig.keys)
    if not success then
        notify(t('failed_minigame'), 'error')
    end

    return success
end

local function chooseFermentRoute()
    local input = lib.inputDialog(t('ferment_route_title'), {
        {
            type = 'select',
            label = t('mash_type_label'),
            required = true,
            options = {
                { label = t('wine_mash_option'), value = 'wine' },
                { label = t('beer_mash_option'), value = 'beer' }
            }
        }
    })

    if not input then
        notify(t('ferment_route_cancelled'), 'error')
        return
    end

    return input[1]
end

local function runFermentMinigame()
    if not runSkillMinigame(Config.Minigames.Ferment) then
        return
    end

    local targetTemp = math.random(Config.Minigames.Ferment.tempMin, Config.Minigames.Ferment.tempMax)
    local mixData = lib.inputDialog(t('fermentation_mix_title'), {
        {
            type = 'number',
            label = t('fermentation_temp_label', Config.Minigames.Ferment.tempMin, Config.Minigames.Ferment.tempMax),
            required = true,
            min = Config.Minigames.Ferment.tempMin,
            max = Config.Minigames.Ferment.tempMax + 20
        },
        {
            type = 'number',
            label = t('fermentation_stir_label', Config.Minigames.Ferment.stirMin, Config.Minigames.Ferment.stirMax),
            required = true,
            min = Config.Minigames.Ferment.stirMin,
            max = Config.Minigames.Ferment.stirMax
        }
    })

    if not mixData then
        notify(t('stopped_mixing'), 'error')
        return
    end

    local temp = math.floor(tonumber(mixData[1]) or 0)
    local stir = math.floor(tonumber(mixData[2]) or 0)
    local variance = Config.Minigames.Ferment.sweetSpotVariance

    if temp > Config.Minigames.Ferment.tempMax then
        TriggerServerEvent('qb-boozebiz:server:TryFermentationExplosion')
        notify(t('mash_overheated'), 'error')
        return
    end

    if math.abs(temp - targetTemp) > variance then
        notify(t('mash_ruined', targetTemp), 'error')
        return
    end

    local perfectStir = math.random(Config.Minigames.Ferment.stirMin, Config.Minigames.Ferment.stirMax)
    if math.abs(stir - perfectStir) > 1 then
        notify(t('mash_texture_wrong', perfectStir), 'error')
        return
    end

    return {
        temp = temp,
        stir = stir
    }
end

local function chooseDistillProduct(source)
    local options

    if source == 'beer' then
        options = {
            { label = t('product_beer'), value = 'beer' },
            { label = t('product_vodka'), value = 'vodka' },
            { label = t('product_gin'), value = 'gin' },
            { label = t('product_whiskey'), value = 'whiskey' }
        }
    else
        options = {
            { label = t('product_wine'), value = 'wine' }
        }
    end

    local input = lib.inputDialog(t('distill_product_title'), {
        {
            type = 'select',
            label = t('distill_product_label'),
            required = true,
            options = options
        }
    })

    if not input then
        notify(t('distill_setup_cancelled'), 'error')
        return
    end

    return input[1]
end

local function getDistillSettings()
    local input = lib.inputDialog(t('distill_setup_title'), {
        {
            type = 'select',
            label = t('mash_source_label'),
            required = true,
            options = {
                { label = t('beer_mash_source'), value = 'beer' },
                { label = t('wine_mash_source'), value = 'wine' }
            }
        },
        {
            type = 'number',
            label = t('still_temp_label', Config.Minigames.Distill.tempMin, Config.Minigames.Distill.tempMax),
            required = true,
            min = Config.Minigames.Distill.tempMin,
            max = Config.Minigames.Distill.tempMax
        },
        {
            type = 'number',
            label = t('distill_time_label', Config.Minigames.Distill.timeMin, Config.Minigames.Distill.timeMax),
            required = true,
            min = Config.Minigames.Distill.timeMin,
            max = Config.Minigames.Distill.timeMax
        }
    })

    if not input then
        notify(t('distill_setup_cancelled'), 'error')
        return
    end

    local product = chooseDistillProduct(input[1])
    if not product then
        return
    end

    return {
        source = input[1],
        product = product,
        temp = math.floor(tonumber(input[2]) or 0),
        time = math.floor(tonumber(input[3]) or 0)
    }
end

local function getBottleBranding()
    local input = lib.inputDialog(t('bottle_title'), {
        {
            type = 'input',
            label = t('bottle_name_label'),
            description = t('bottle_name_desc'),
            required = true,
            min = 3,
            max = 24
        },
        {
            type = 'number',
            label = t('purity_label'),
            description = t('purity_desc'),
            required = true,
            min = 70,
            max = 99
        }
    })

    if not input then
        notify(t('bottling_setup_cancelled'), 'error')
        return
    end

    local bottleName = tostring(input[1] or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local purity = math.floor(tonumber(input[2]) or 0)

    if bottleName == '' then
        notify(t('bottle_name_empty'), 'error')
        return
    end

    if purity < 70 or purity > 99 then
        notify(t('purity_range'), 'error')
        return
    end

    return {
        bottleName = bottleName,
        purity = purity
    }
end

local function createBlips()
    for _, data in ipairs(Config.Blips) do
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, data.scale)
        SetBlipColour(blip, data.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(t(data.labelKey or data.label))
        EndTextCommandSetBlipName(blip)
    end
end

local function registerHarvestTargets()
    for _, zone in ipairs(Config.HarvestZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords,
            size = zone.size,
            rotation = zone.rotation,
            debug = Config.Debug,
            options = {
                {
                    name = zone.name,
                    label = t(zone.labelKey or zone.label),
                    icon = zone.icon,
                    distance = 2.0,
                    onSelect = function()
                        if not runSkillMinigame(Config.Minigames.Harvest) then
                            return
                        end

                        local completed = runAction(t(zone.labelKey or zone.label), Config.Progress.Harvest, {
                            dict = 'amb@world_human_gardener_plant@male@base',
                            clip = 'base',
                            flag = 1
                        })

                        if not completed then
                            notify(t('action_cancelled'), 'error')
                            return
                        end

                        TriggerServerEvent('qb-boozebiz:server:HarvestItem', zone.name)
                    end
                }
            }
        })
    end
end

local function registerProcessingTargets()
    for _, station in ipairs(Config.ProcessingStations) do
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = station.size,
            rotation = station.rotation,
            debug = Config.Debug,
            options = {
                {
                    name = station.name,
                    label = t(station.labelKey or station.label),
                    icon = station.icon,
                    distance = 2.0,
                    onSelect = function()
                        TriggerEvent(station.event)
                    end
                }
            }
        })
    end
end

local function registerStockTargets()
    for _, zone in ipairs(Config.StockZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords,
            size = zone.size,
            rotation = zone.rotation,
            debug = Config.Debug,
            options = {
                {
                    name = zone.name,
                    label = t(zone.labelKey or zone.label),
                    icon = zone.icon,
                    distance = 2.0,
                    onSelect = function()
                        if not runSkillMinigame(Config.Minigames.Stock) then
                            return
                        end

                        local completed = runAction(t('stock_action'), Config.Progress.Stock, {
                            dict = 'mini@repair',
                            clip = 'fixing_a_ped'
                        })

                        if not completed then
                            notify(t('stocking_cancelled'), 'error')
                            return
                        end

                        TriggerServerEvent('qb-boozebiz:server:StockStore', zone.name)
                    end
                }
            }
        })
    end
end

RegisterNetEvent('qb-boozebiz:client:FermentMash', function()
    local route = chooseFermentRoute()
    if not route then
        return
    end

    local fermentData = runFermentMinigame()
    if not fermentData then
        return
    end

    fermentData.route = route

    local completed = runAction(t('fermenting_action'), Config.Progress.Ferment, {
        dict = 'amb@prop_human_bbq@male@base',
        clip = 'base',
        flag = 1
    })

    if not completed then
        notify(t('fermentation_cancelled'), 'error')
        return
    end

    TriggerServerEvent('qb-boozebiz:server:FermentMash', fermentData)
end)

RegisterNetEvent('qb-boozebiz:client:DistillSpirit', function()
    if not runSkillMinigame(Config.Minigames.Distill) then
        return
    end

    local distillData = getDistillSettings()
    if not distillData then
        return
    end

    local completed = runAction(t('distill_action'), Config.Progress.Distill, {
        dict = 'amb@world_human_hammering@male@base',
        clip = 'base',
        flag = 1
    })

    if not completed then
        notify(t('distillation_cancelled'), 'error')
        return
    end

    TriggerServerEvent('qb-boozebiz:server:DistillMash', distillData)
end)

RegisterNetEvent('qb-boozebiz:client:BottleLiquor', function()
    if not runSkillMinigame(Config.Minigames.Bottle) then
        return
    end

    local bottleData = getBottleBranding()
    if not bottleData then
        return
    end

    local completed = runAction(t('bottling_action'), Config.Progress.Bottle, {
        dict = 'mp_prison_break',
        clip = 'hack_loop'
    })

    if not completed then
        notify(t('bottling_cancelled'), 'error')
        return
    end

    TriggerServerEvent('qb-boozebiz:server:ProcessRecipe', 'Bottle', bottleData)
end)

RegisterNetEvent('qb-boozebiz:client:PackCrate', function()
    if not runSkillMinigame(Config.Minigames.Pack) then
        local broken = math.random(Config.Minigames.Pack.breakMin, Config.Minigames.Pack.breakMax)
        TriggerServerEvent('qb-boozebiz:server:BreakBottles', broken)
        return
    end

    local completed = runAction(t('pack_action'), Config.Progress.Pack, {
        dict = 'anim@heists@ornate_bank@grab_cash',
        clip = 'grab'
    })

    if not completed then
        notify(t('packing_cancelled'), 'error')
        return
    end

    TriggerServerEvent('qb-boozebiz:server:ProcessRecipe', 'Pack')
end)

RegisterNetEvent('qb-boozebiz:client:FermentationExplosion', function(explosionData)
    local coords = vec3(explosionData.x, explosionData.y, explosionData.z)
    AddExplosion(coords.x, coords.y, coords.z, 29, 1.0, true, false, 1.0)

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local distance = #(pedCoords - coords)

    if distance <= explosionData.radius then
        local currentHealth = GetEntityHealth(ped)
        local newHealth = math.max(0, currentHealth - explosionData.damage)
        SetEntityHealth(ped, newHealth)
        notify(t('explosion_damage'), 'error')
    end
end)

RegisterNetEvent('qb-boozebiz:client:Notify', function(message, notifyType)
    notify(message, notifyType)
end)

CreateThread(function()
    createBlips()
    registerHarvestTargets()
    registerProcessingTargets()
    registerStockTargets()
end)
