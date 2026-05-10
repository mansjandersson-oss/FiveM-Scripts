local QBCore = exports['qb-core']:GetCoreObject()
local actionBusy = false

local strippedParts = {}
local chopZoneActive = false
local chopZoneVehicle = nil
local npcEntities = {}
local activeContractData = { vehicles = nil, completed = {} }
local markedForScrap = {}
local contractUiOpen = false
local vehicleTargetsReady = false

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(message, notifyType)
    lib.notify({ title = t('script_title'), description = message, type = notifyType or 'inform' })
end

local function debugPrint(message, ...)
    if not Config.Debug or not (Config.DebugOptions and Config.DebugOptions.verbose) then return end

    if select('#', ...) > 0 then
        message = message:format(...)
    end

    print(('[nb-chopshop:debug:client] %s'):format(message))
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
        disable = { move = true, car = true, combat = true, mouse = false },
        anim = anim,
    })
    actionBusy = false
    return completed
end

local function runSkillMinigame(cfg)
    local ok = lib.skillCheck(cfg.stages, cfg.keys)
    if not ok then notify(t('failed_minigame'), 'error') end
    return ok
end

local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < Config.ModelLoadTimeout do
        Wait(10)
        timeout = timeout + 10
    end
    return HasModelLoaded(model)
end

local function resolveModelHash(model)
    if type(model) == 'number' then return model end
    if type(model) == 'string' then return GetHashKey(model) end
    return 0
end

local function getVehicleNetId(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(0)
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then return nil end

    SetNetworkIdCanMigrate(netId, true)
    return netId
end

local function isPartStripped(netId, name)
    return strippedParts[netId] and strippedParts[netId][name] == true
end

local function markPartStripped(netId, name)
    strippedParts[netId] = strippedParts[netId] or {}
    strippedParts[netId][name] = true
end

local function isVehicleMarkedForScrap(netId)
    return markedForScrap[netId] == true
end

local function lockVehicleForScrap(vehicle)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleDoorsLockedForAllPlayers(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleUndriveable(vehicle, true)
end

local function getVehicleDoorCount(vehicle)
    if not DoesEntityExist(vehicle) then return 4 end

    local doorBoneIndexes = {
        GetEntityBoneIndexByName(vehicle, 'door_dside_f'),
        GetEntityBoneIndexByName(vehicle, 'door_pside_f'),
        GetEntityBoneIndexByName(vehicle, 'door_dside_r'),
        GetEntityBoneIndexByName(vehicle, 'door_pside_r'),
    }

    local count = 0
    for _, boneIndex in ipairs(doorBoneIndexes) do
        if boneIndex and boneIndex ~= -1 then
            count = count + 1
        end
    end

    if count >= 4 then return 4 end
    if count >= 2 then return 2 end
    return 4
end

local function getDoorIndexForPart(partName)
    local map = {
        driver_door = 0,
        passenger_door = 1,
        rear_left_door = 2,
        rear_right_door = 3,
        hood = 4,
        trunk = 5,
    }
    return map[partName]
end

local function getPartBoneName(partName)
    local map = {
        driver_door = 'door_dside_f',
        passenger_door = 'door_pside_f',
        rear_left_door = 'door_dside_r',
        rear_right_door = 'door_pside_r',
        hood = 'bonnet',
        trunk = 'boot',
    }
    return map[partName]
end

local function isPlayerNearVehiclePart(vehicle, partName)
    local ped = PlayerPedId()
    if not DoesEntityExist(vehicle) then return false end

    local partBone = getPartBoneName(partName)
    if partBone then
        local boneIndex = GetEntityBoneIndexByName(vehicle, partBone)
        if boneIndex and boneIndex ~= -1 then
            return #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(vehicle, boneIndex)) <= 2.2
        end
    end

    local doorIndex = getDoorIndexForPart(partName)
    if doorIndex then
        local doorCoords = GetEntryPositionOfDoor(vehicle, doorIndex)
        if doorCoords and type(doorCoords) == 'vector3' then
            return #(GetEntityCoords(ped) - doorCoords) <= 2.2
        end
    end

    return #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) <= 3.0
end

local function hideStrippedPartOnVehicle(vehicle, partName)
    if not DoesEntityExist(vehicle) then return end
    local doorIndex = getDoorIndexForPart(partName)
    if doorIndex then SetVehicleDoorBroken(vehicle, doorIndex, true) end
end

local function shouldShowStripPartForVehicle(vehicle, part)
    if part.name == 'rear_left_door' or part.name == 'rear_right_door' then
        return getVehicleDoorCount(vehicle) >= 4
    end
    return true
end

local function allPartsStripped(vehicle, netId)
    if not strippedParts[netId] or not DoesEntityExist(vehicle) then return false end

    for _, part in ipairs(Config.StripParts) do
        if shouldShowStripPartForVehicle(vehicle, part) and not strippedParts[netId][part.name] then
            return false
        end
    end
    return true
end

local function clearVehicleTarget(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local names = { 'chop_mark_vehicle', 'chop_strip_frame' }
    for _, part in ipairs(Config.StripParts) do
        names[#names + 1] = 'chop_strip_' .. part.name
    end
    exports.ox_target:removeLocalEntity(vehicle, names)
end

local function despawnVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end

    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local timeout = 0
        while not NetworkHasControlOfEntity(vehicle) and timeout < Config.NetworkControlTimeout do
            Wait(10)
            timeout = timeout + 10
        end
    end

    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
    end
end

local function isVehicleAllowedForCurrentJob(vehicle)
    if not DoesEntityExist(vehicle) or not activeContractData.vehicles then return false end

    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    for _, vehicleData in ipairs(activeContractData.vehicles) do
        if vehicleData.model:lower() == modelName and not activeContractData.completed[vehicleData.model] then
            return true
        end
    end

    return false
end

local function applyVehicleTarget(vehicle)
    if not Config.Debug or not DoesEntityExist(vehicle) then return end

    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    if not activeContractData.vehicles then
        debugPrint('vehicle target skipped, no active contract model=%s', modelName)
    elseif not isVehicleAllowedForCurrentJob(vehicle) then
        debugPrint('vehicle target skipped, model not in active contract model=%s', modelName)
    end
end

local function selectedVehicle(data)
    if type(data) == 'table' then return data.entity end
    return data
end

local function canUseVehicleOption(vehicle)
    return chopZoneActive and DoesEntityExist(vehicle) and isVehicleAllowedForCurrentJob(vehicle)
end

local function getMarkedNetId(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 and isVehicleMarkedForScrap(netId) then
        return netId
    end

    return nil
end

local function setupVehicleTargets()
    if vehicleTargetsReady then return end
    vehicleTargetsReady = true

    local options = {
        {
            name = 'chop_mark_vehicle',
            label = t('mark_vehicle_for_scrap'),
            icon = 'fa-solid fa-clipboard-check',
            distance = 3.0,
            canInteract = function(entity)
                if not canUseVehicleOption(entity) then return false end
                local netId = NetworkGetNetworkIdFromEntity(entity)
                return not (netId and netId ~= 0 and isVehicleMarkedForScrap(netId))
            end,
            onSelect = function(data)
                local vehicle = selectedVehicle(data)
                if not DoesEntityExist(vehicle) then return end

                local netId = getVehicleNetId(vehicle)
                if not netId then
                    notify(t('vehicle_network_failed'), 'error')
                    debugPrint('failed to network vehicle for target')
                    return
                end

                local done = runAction(t('marking_vehicle'), 2200, Config.Animations.frame)
                if not done then
                    notify(t('action_cancelled'), 'error')
                    return
                end

                markedForScrap[netId] = true
                lockVehicleForScrap(vehicle)
                notify(t('vehicle_marked_for_scrap'), 'success')
            end,
        },
    }

    for _, part in ipairs(Config.StripParts) do
        local partConfig = part
        local partName = part.name
        local partItem = part.item
        local partLabel = t(part.labelKey)
        local anim = (partName == 'hood' or partName == 'trunk') and Config.Animations.hood or Config.Animations.door

        options[#options + 1] = {
            name = 'chop_strip_' .. partName,
            label = partLabel,
            icon = part.icon or 'fa-solid fa-screwdriver-wrench',
            distance = 3.0,
            canInteract = function(entity)
                if not canUseVehicleOption(entity) then return false end

                local netId = getMarkedNetId(entity)
                return netId ~= nil
                    and shouldShowStripPartForVehicle(entity, partConfig)
                    and not isPartStripped(netId, partName)
            end,
            onSelect = function(data)
                local vehicle = selectedVehicle(data)
                if not DoesEntityExist(vehicle) then return end

                local netId = getMarkedNetId(vehicle)
                if not netId then return end

                if not isPlayerNearVehiclePart(vehicle, partName) then
                    notify(t('too_far_from_part'), 'error')
                    return
                end

                if not runSkillMinigame(Config.Minigames.StripPart) then return end

                local done = runAction(partLabel, part.duration, anim)
                if not done then
                    notify(t('action_cancelled'), 'error')
                    return
                end

                TriggerServerEvent('nb-chopshop:server:StripPart', netId, partName, partItem)
                markPartStripped(netId, partName)
                hideStrippedPartOnVehicle(vehicle, partName)
            end,
        }
    end

    local frameLabel = t(Config.FrameStrip.labelKey)
    options[#options + 1] = {
        name = 'chop_strip_frame',
        label = frameLabel,
        icon = 'fa-solid fa-car-burst',
        distance = 3.0,
        canInteract = function(entity)
            if not canUseVehicleOption(entity) then return false end

            local netId = getMarkedNetId(entity)
            return netId ~= nil and allPartsStripped(entity, netId)
        end,
        onSelect = function(data)
            local vehicle = selectedVehicle(data)
            if not DoesEntityExist(vehicle) then return end

            local netId = getMarkedNetId(vehicle)
            if not netId then return end
            if not runSkillMinigame(Config.Minigames.StripFrame) then return end

            local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
            local done = runAction(frameLabel, Config.FrameStrip.duration, Config.Animations.frame)
            if not done then
                notify(t('action_cancelled'), 'error')
                return
            end

            TriggerServerEvent('nb-chopshop:server:StripFrame', netId, modelName)
            activeContractData.completed[modelName] = true
            strippedParts[netId] = nil
            markedForScrap[netId] = nil
            clearVehicleTarget(vehicle)
            despawnVehicle(vehicle)
            chopZoneVehicle = nil
        end,
    }

    exports.ox_target:addGlobalVehicle(options)
    debugPrint('registered global vehicle targets')
end

local function setupChopZone()
    lib.zones.sphere({
        coords = Config.ChopZone.coords,
        radius = Config.ChopZone.radius or 30.0,
        debug = Config.Debug,
        onEnter = function()
            chopZoneActive = true
            notify(t('entered_chop_zone'), 'inform')
        end,
        onExit = function()
            chopZoneActive = false
            if chopZoneVehicle and DoesEntityExist(chopZoneVehicle) then
                clearVehicleTarget(chopZoneVehicle)
            end
            chopZoneVehicle = nil
        end,
    })
end

CreateThread(function()
    while true do
        if not chopZoneActive then
            Wait(1500)
        else
            Wait(800)
            local ped = PlayerPedId()

            if GetVehiclePedIsIn(ped, false) == 0 then
                local pedCoords = GetEntityCoords(ped)
                local nearest = nil
                local nearestDist = Config.ChopZone.vehicleDetectionDistance

                for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                    if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
                        local dist = #(GetEntityCoords(vehicle) - pedCoords)
                        if dist < nearestDist then
                            nearest = vehicle
                            nearestDist = dist
                        end
                    end
                end

                if nearest ~= chopZoneVehicle then
                    if chopZoneVehicle and DoesEntityExist(chopZoneVehicle) then
                        clearVehicleTarget(chopZoneVehicle)
                    end

                    chopZoneVehicle = nearest
                    if chopZoneVehicle then
                        applyVehicleTarget(chopZoneVehicle)
                        if activeContractData.vehicles then
                            local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(chopZoneVehicle)):lower()
                            TriggerServerEvent('nb-chopshop:server:CheckContractVehicle', modelName)
                        end
                    end
                end
            elseif chopZoneVehicle and DoesEntityExist(chopZoneVehicle) then
                clearVehicleTarget(chopZoneVehicle)
                chopZoneVehicle = nil
            end
        end
    end
end)

local function spawnNPC(data, options)
    local model = resolveModelHash(data.model)
    if model == 0 or not IsModelValid(model) or not IsModelInCdimage(model) or not IsModelAPed(model) then
        if Config.Debug then print(('[nb-chopshop] invalid NPC model: %s'):format(tostring(data.model))) end
        return nil
    end

    if not loadModel(model) then
        if Config.Debug then print(('[nb-chopshop] failed to load NPC model: %s'):format(tostring(data.model))) end
        return nil
    end

    local ped = CreatePed(4, model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, true, true)
    if ped == 0 or not DoesEntityExist(ped) then
        if Config.Debug then print(('[nb-chopshop] failed to spawn NPC: %s'):format(tostring(data.name or data.model))) end
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetEntityHeading(ped, data.coords.w)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)

    exports.ox_target:addLocalEntity(ped, options)
    SetModelAsNoLongerNeeded(model)
    return ped
end

local function normalizeRouteResult(result)
    if type(result) == 'string' then
        result = result:lower()
        if result == 'criminal' or result == 'both' then return true end
        if result == 'civilian' then return false end
    elseif type(result) == 'boolean' then
        return result
    elseif type(result) == 'table' then
        if type(result.route) == 'string' then
            local route = result.route:lower()
            if route == 'criminal' or route == 'both' then return true end
            if route == 'civilian' then return false end
        end

        if result.isCriminal == true or result.criminal == true or result.is_criminal == true then return true end
        if result.isCivilian == true or result.civilian == true or result.is_civilian == true then return false end
    end

    return nil
end

local function hasConfiguredAccess()
    local access = Config.CriminalAccess or {}
    local jobs = access.jobs or {}
    local gangs = access.gangs or {}
    local playerData = QBCore.Functions.GetPlayerData()
    local jobName = playerData.job and playerData.job.name
    local gangName = playerData.gang and playerData.gang.name

    return (jobName and jobs[jobName] == true) or (gangName and gangs[gangName] == true)
end

local function canUseCriminalOptions()
    local debugOptions = Config.DebugOptions or {}
    if Config.Debug and debugOptions.bypassRoleCheck then
        local forcedRoute = tostring(debugOptions.forcedRoute or 'criminal'):lower()
        local allowed = forcedRoute == 'criminal' or forcedRoute == 'both'
        debugPrint('role check bypassed, forcedRoute=%s allowed=%s', forcedRoute, tostring(allowed))
        return allowed
    end

    local roleCfg = Config.RoleCheckExport
    if roleCfg and roleCfg.resource and roleCfg.func then
        local exportRes = exports[roleCfg.resource]
        if exportRes and exportRes[roleCfg.func] then
            local ok, result = pcall(function()
                if roleCfg.passServerId ~= false then
                    return exportRes[roleCfg.func](GetPlayerServerId(PlayerId()))
                end
                return exportRes[roleCfg.func]()
            end)

            if ok then
                local allowed = normalizeRouteResult(result)
                if allowed ~= nil then
                    debugPrint('RoleCheckExport result=%s allowed=%s', tostring(result), tostring(allowed))
                    return allowed
                end
                debugPrint('RoleCheckExport returned unknown value: %s', tostring(result))
            else
                debugPrint('RoleCheckExport error: %s', tostring(result))
            end
        else
            debugPrint('RoleCheckExport missing export: %s.%s', tostring(roleCfg.resource), tostring(roleCfg.func))
        end
    else
        debugPrint('RoleCheckExport not configured')
    end

    local allowed = hasConfiguredAccess()
    debugPrint('CriminalAccess fallback allowed=%s', tostring(allowed))
    return allowed
end

local function setupMainNPC()
    npcEntities.main = spawnNPC(Config.NPCs.main, {
        {
            name = 'chop_get_contract',
            label = t('get_contract'),
            icon = 'fa-solid fa-file-contract',
            distance = 2.5,
            canInteract = canUseCriminalOptions,
            onSelect = function() TriggerServerEvent('nb-chopshop:server:GetContract') end,
        },
        {
            name = 'chop_view_contract',
            label = t('view_contract'),
            icon = 'fa-solid fa-list-check',
            distance = 2.5,
            canInteract = canUseCriminalOptions,
            onSelect = function() TriggerServerEvent('nb-chopshop:server:ViewContract') end,
        },
        {
            name = 'chop_turnin_contract',
            label = t('turn_in_contract'),
            icon = 'fa-solid fa-hand-holding-dollar',
            distance = 2.5,
            canInteract = canUseCriminalOptions,
            onSelect = function() TriggerServerEvent('nb-chopshop:server:TurnInContract') end,
        },
    })
end

local function createBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function createBlips()
    local mainNpc = Config.NPCs.main
    if mainNpc.blip.enabled ~= false then
        createBlip(mainNpc.coords, mainNpc.blip.sprite, mainNpc.blip.color, mainNpc.blip.scale, t(mainNpc.blip.labelKey))
    end

    local chopZone = Config.ChopZone
    if chopZone.blip.enabled ~= false then
        createBlip(chopZone.coords, chopZone.blip.sprite, chopZone.blip.color, chopZone.blip.scale, t(chopZone.blip.labelKey))
    end
end

local function getContractPayload(contractData)
    local vehicles = contractData and contractData.vehicles or {}
    local completed = contractData and contractData.completed or {}
    local done = 0

    local uiVehicles = {}
    for index, vehicle in ipairs(vehicles) do
        local isDone = completed[vehicle.model] == true
        if isDone then done = done + 1 end
        uiVehicles[#uiVehicles + 1] = {
            index = index,
            model = vehicle.model,
            label = vehicle.label,
            completed = isDone,
        }
    end

    return {
        title = t('contract_status_title'),
        subtitle = t('contract_ui_subtitle'),
        hint = t('contract_vehicles_spawned'),
        vehicles = uiVehicles,
        completedCount = done,
        totalCount = #uiVehicles,
        complete = #uiVehicles > 0 and done == #uiVehicles,
    }
end

local function sendContractToUi(action, contractData)
    SendNUIMessage({
        action = action,
        payload = getContractPayload(contractData),
    })
end

local function openContractUi(contractData)
    contractUiOpen = true
    SetNuiFocus(true, true)
    sendContractToUi('openContract', contractData)
end

local function closeContractUi()
    contractUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeContract' })
end

RegisterNetEvent('nb-chopshop:client:ShowContract', function(contractData)
    if not contractData or not contractData.vehicles then
        notify(t('no_active_contract'), 'error')
        return
    end

    activeContractData.vehicles = contractData.vehicles
    activeContractData.completed = contractData.completed or {}
    openContractUi(contractData)
end)

RegisterNetEvent('nb-chopshop:client:SetContractVehicles', function(contractData)
    if contractData and contractData.vehicles then
        activeContractData.vehicles = contractData.vehicles
        activeContractData.completed = contractData.completed or activeContractData.completed or {}
        if contractUiOpen then sendContractToUi('updateContract', contractData) end
    end
end)

RegisterNetEvent('nb-chopshop:client:ClearContract', function()
    activeContractData = { vehicles = nil, completed = {} }
    if contractUiOpen then closeContractUi() end
end)

RegisterNetEvent('nb-chopshop:client:ContractVehicleDetected', function(vehicleLabel)
    notify(t('contract_vehicle_detected', vehicleLabel), 'success')
end)

RegisterNetEvent('nb-chopshop:client:Notify', function(message, notifyType)
    notify(message, notifyType)
end)

RegisterNUICallback('close', function(_, cb)
    closeContractUi()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('nb-chopshop:server:ViewContract')
    cb({ ok = true })
end)

RegisterNUICallback('turnIn', function(_, cb)
    TriggerServerEvent('nb-chopshop:server:TurnInContract')
    cb({ ok = true })
end)

CreateThread(function()
    setupVehicleTargets()
    createBlips()
    setupChopZone()
    setupMainNPC()
end)
