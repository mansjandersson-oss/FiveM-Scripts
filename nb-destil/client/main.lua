local RESOURCE = GetCurrentResourceName()

local actionBusy = false
local nuiBusy = false
local nuiRequestId = 0
local nuiRequests = {}
local registeredZones = {}

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

local function notify(message, notifyType)
    lib.notify({
        title = t('script_title'),
        description = message,
        type = notifyType or 'inform'
    })
end

local function closeNui()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'closeDialog' })
    nuiBusy = false
end

local function resolveNuiRequest(requestId, value)
    local request = nuiRequests[requestId]
    if not request then
        return
    end

    nuiRequests[requestId] = nil
    request:resolve(value)
end

local function openNuiDialog(kind, payload)
    if nuiBusy then
        notify(t('busy_action'), 'error')
        return
    end

    nuiBusy = true
    nuiRequestId += 1

    local requestId = nuiRequestId
    local request = promise.new()
    nuiRequests[requestId] = request

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'openDialog',
        kind = kind,
        requestId = requestId,
        payload = payload
    })

    local result = Citizen.Await(request)
    closeNui()

    return result
end

RegisterNUICallback('submitDialog', function(data, cb)
    resolveNuiRequest(tonumber(data.requestId), data.values or {})
    cb({ ok = true })
end)

RegisterNUICallback('closeDialog', function(data, cb)
    resolveNuiRequest(tonumber(data.requestId), nil)
    cb({ ok = true })
end)

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

local function openFermentDialog()
    local ferment = Config.Minigames.Ferment
    local input = openNuiDialog('ferment', {
        title = t('fermentation_mix_title'),
        subtitle = t('ferment_route_title'),
        routeLabel = t('mash_type_label'),
        tempLabel = t('fermentation_temp_label', ferment.tempMin, ferment.tempMax),
        stirLabel = t('fermentation_stir_label', ferment.stirMin, ferment.stirMax),
        submitLabel = t('zone_start_fermentation'),
        cancelLabel = t('cancel_action'),
        routes = {
            { label = t('wine_mash_option'), value = 'wine' },
            { label = t('beer_mash_option'), value = 'beer' }
        },
        temp = { min = ferment.tempMin, max = ferment.tempMax + 20 },
        stir = { min = ferment.stirMin, max = ferment.stirMax }
    })

    if not input then
        notify(t('ferment_route_cancelled'), 'error')
        return
    end

    return {
        route = tostring(input.route or ''),
        temp = math.floor(tonumber(input.temp) or 0),
        stir = math.floor(tonumber(input.stir) or 0)
    }
end

local function runFermentMinigame()
    if not runSkillMinigame(Config.Minigames.Ferment) then
        return
    end

    local ferment = Config.Minigames.Ferment
    local targetTemp = math.random(ferment.tempMin, ferment.tempMax)
    local perfectStir = math.random(ferment.stirMin, ferment.stirMax)
    local input = openFermentDialog()

    if not input then
        return
    end

    if input.route ~= 'wine' and input.route ~= 'beer' then
        notify(t('invalid_mash_route'), 'error')
        return
    end

    if input.temp > ferment.tempMax then
        TriggerServerEvent(eventName('server', 'TryFermentationExplosion'))
        notify(t('mash_overheated'), 'error')
        return
    end

    if math.abs(input.temp - targetTemp) > ferment.sweetSpotVariance then
        notify(t('mash_ruined', targetTemp), 'error')
        return
    end

    if math.abs(input.stir - perfectStir) > 1 then
        notify(t('mash_texture_wrong', perfectStir), 'error')
        return
    end

    return input
end

local function getDistillSettings()
    local distill = Config.Minigames.Distill
    local input = openNuiDialog('distill', {
        title = t('distill_setup_title'),
        sourceLabel = t('mash_source_label'),
        productLabel = t('distill_product_label'),
        tempLabel = t('still_temp_label', distill.tempMin, distill.tempMax),
        timeLabel = t('distill_time_label', distill.timeMin, distill.timeMax),
        submitLabel = t('zone_run_distillery'),
        cancelLabel = t('cancel_action'),
        sources = {
            { label = t('beer_mash_source'), value = 'beer' },
            { label = t('wine_mash_source'), value = 'wine' }
        },
        products = {
            beer = {
                { label = t('product_beer'), value = 'beer' },
                { label = t('product_vodka'), value = 'vodka' },
                { label = t('product_gin'), value = 'gin' },
                { label = t('product_whiskey'), value = 'whiskey' }
            },
            wine = {
                { label = t('product_wine'), value = 'wine' }
            }
        },
        temp = { min = distill.tempMin, max = distill.tempMax },
        time = { min = distill.timeMin, max = distill.timeMax }
    })

    if not input then
        notify(t('distill_setup_cancelled'), 'error')
        return
    end

    return {
        source = tostring(input.source or ''),
        product = tostring(input.product or ''),
        temp = math.floor(tonumber(input.temp) or 0),
        time = math.floor(tonumber(input.time) or 0)
    }
end

local function getBottleBranding()
    local input = openNuiDialog('bottle', {
        title = t('bottle_title'),
        nameLabel = t('bottle_name_label'),
        nameDescription = t('bottle_name_desc'),
        purityLabel = t('purity_label'),
        purityDescription = t('purity_desc'),
        submitLabel = t('zone_bottle_liquor'),
        cancelLabel = t('cancel_action'),
        purity = { min = 70, max = 99 }
    })

    if not input then
        notify(t('bottling_setup_cancelled'), 'error')
        return
    end

    local bottleName = tostring(input.bottleName or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local purity = math.floor(tonumber(input.purity) or 0)

    if bottleName == '' then
        notify(t('bottle_name_empty'), 'error')
        return
    end

    if purity < 70 or purity > 99 then
        notify(t('purity_range'), 'error')
        return
    end

    return {
        bottleName = bottleName:sub(1, 24),
        purity = purity
    }
end

local function createBlips()
    for _, data in ipairs(Config.Blips) do
        if data.enabled ~= false then
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
end

local function addBoxZone(zone, option)
    local zoneId = exports.ox_target:addBoxZone({
        name = zone.name,
        coords = zone.coords,
        size = zone.size,
        rotation = zone.rotation,
        debug = Config.Debug,
        options = { option }
    })

    registeredZones[#registeredZones + 1] = zoneId or zone.name
end

local function startFermentation()
    local fermentData = runFermentMinigame()
    if not fermentData then
        return
    end

    local completed = runAction(t('fermenting_action'), Config.Progress.Ferment, {
        dict = 'amb@prop_human_bbq@male@base',
        clip = 'base',
        flag = 1
    })

    if not completed then
        notify(t('fermentation_cancelled'), 'error')
        return
    end

    TriggerServerEvent(eventName('server', 'FermentMash'), fermentData)
end

local function startDistillation()
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

    TriggerServerEvent(eventName('server', 'DistillMash'), distillData)
end

local function startBottling()
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

    TriggerServerEvent(eventName('server', 'ProcessRecipe'), 'Bottle', bottleData)
end

local function startPacking()
    if not runSkillMinigame(Config.Minigames.Pack) then
        local broken = math.random(Config.Minigames.Pack.breakMin, Config.Minigames.Pack.breakMax)
        TriggerServerEvent(eventName('server', 'BreakBottles'), broken)
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

    TriggerServerEvent(eventName('server', 'ProcessRecipe'), 'Pack')
end

local PROCESS_ACTIONS = {
    ferment = startFermentation,
    distill = startDistillation,
    bottle = startBottling,
    pack = startPacking
}

local function registerHarvestTargets()
    for _, zone in ipairs(Config.HarvestZones) do
        addBoxZone(zone, {
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

                TriggerServerEvent(eventName('server', 'HarvestItem'), zone.name)
            end
        })
    end
end

local function registerProcessingTargets()
    for _, station in ipairs(Config.ProcessingStations) do
        local handler = PROCESS_ACTIONS[station.action]
        if handler then
            addBoxZone(station, {
                name = station.name,
                label = t(station.labelKey or station.label),
                icon = station.icon,
                distance = 2.0,
                onSelect = handler
            })
        end
    end
end

local function registerStockTargets()
    for _, zone in ipairs(Config.StockZones) do
        addBoxZone(zone, {
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

                TriggerServerEvent(eventName('server', 'StockStore'), zone.name)
            end
        })
    end
end

RegisterNetEvent(eventName('client', 'FermentationExplosion'), function(explosionData)
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

RegisterNetEvent(eventName('client', 'Notify'), function(message, notifyType)
    notify(message, notifyType)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE then
        return
    end

    closeNui()

    for _, zoneId in ipairs(registeredZones) do
        pcall(function()
            exports.ox_target:removeZone(zoneId)
        end)
    end
end)

CreateThread(function()
    createBlips()
    registerHarvestTargets()
    registerProcessingTargets()
    registerStockTargets()
end)
