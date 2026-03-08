local QBCore = exports['qb-core']:GetCoreObject()
local actionBusy = false

-- ─── Körtidsstatus ───────────────────────────────────────────────────────────
local strippedParts    = {}   -- [vehicleNetId] = { partName = true, ... }
local chopZoneActive   = false
local chopZoneVehicle  = nil  -- fordon som just nu står parkerat och demonteras
local npcEntities      = {}   -- spawnade NPC-ped handles
local contractVehicles = {}   -- { entity, blip, model } för kriminella kontraktsspawns
local civilianVehicleBlip = nil

-- ─── Hjälpfunktioner ─────────────────────────────────────────────────────────

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(message, notifyType)
    lib.notify({ title = t('script_title'), description = message, type = notifyType or 'inform' })
end

local function runAction(label, duration, anim)
    if actionBusy then
        notify(t('busy_action'), 'error')
        return false
    end
    actionBusy = true
    local completed = lib.progressCircle({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true, mouse = false },
        anim         = anim
    })
    actionBusy = false
    return completed
end

local function runSkillMinigame(cfg)
    local ok = lib.skillCheck(cfg.stages, cfg.keys)
    if not ok then notify(t('failed_minigame'), 'error') end
    return ok
end

-- Väntar synkront på att en modell ska laddas, upp till Config.ModelLoadTimeout ms.
-- Returnerar true om modellen laddades, annars false.
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
    if type(model) == 'string' then
        return GetHashKey(model)
    end
    return 0
end

-- ─── Hjälpare för delspårning ────────────────────────────────────────────────

local function isPartStripped(netId, name)
    return strippedParts[netId] and strippedParts[netId][name] == true
end

local function markPartStripped(netId, name)
    if not strippedParts[netId] then strippedParts[netId] = {} end
    strippedParts[netId][name] = true
end

local function getVehicleDoorCount(vehicle)
    if not DoesEntityExist(vehicle) then return 4 end

    local doorBoneIndexes = {
        GetEntityBoneIndexByName(vehicle, 'door_dside_f'),
        GetEntityBoneIndexByName(vehicle, 'door_pside_f'),
        GetEntityBoneIndexByName(vehicle, 'door_dside_r'),
        GetEntityBoneIndexByName(vehicle, 'door_pside_r')
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
        driver_door    = 0,
        passenger_door = 1,
        rear_left_door = 2,
        rear_right_door = 3,
        hood           = 4,
        trunk          = 5,
    }
    return map[partName]
end

local function hideStrippedPartOnVehicle(vehicle, partName)
    if not DoesEntityExist(vehicle) then return end
    local doorIndex = getDoorIndexForPart(partName)
    if not doorIndex then return end

    SetVehicleDoorBroken(vehicle, doorIndex, true)
end

local function shouldShowStripPartForVehicle(vehicle, part)
    if part.name == 'rear_left_door' or part.name == 'rear_right_door' then
        return getVehicleDoorCount(vehicle) >= 4
    end
    return true
end

local function allPartsStripped(vehicle, netId)
    if not strippedParts[netId] then return false end
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    for _, part in ipairs(Config.StripParts) do
        if shouldShowStripPartForVehicle(vehicle, part) and not strippedParts[netId][part.name] then
            return false
        end
    end
    return true
end

-- ─── Hantering av fordons-target ─────────────────────────────────────────────

local function clearVehicleTarget(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local names = { 'chop_strip_frame' }
    for _, p in ipairs(Config.StripParts) do
        names[#names + 1] = 'chop_strip_' .. p.name
    end
    exports.ox_target:removeLocalEntity(vehicle, names)
end

local function removeContractVehicleEntry(vehicle)
    for i, cv in ipairs(contractVehicles) do
        if cv.entity == vehicle then
            if DoesBlipExist(cv.blip) then RemoveBlip(cv.blip) end
            table.remove(contractVehicles, i)
            return
        end
    end
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

-- Bygg och applicera ox_target-interaktioner på ett fordon i zonen.
-- Beräknas om varje gång en del demonteras så listan hålls korrekt.
local function applyVehicleTarget(vehicle)
    if not DoesEntityExist(vehicle) then return end
    clearVehicleTarget(vehicle)

    local netId   = NetworkGetNetworkIdFromEntity(vehicle)
    local options = {}

    -- Val för demontering av delar
    for _, part in ipairs(Config.StripParts) do
        if shouldShowStripPartForVehicle(vehicle, part) and not isPartStripped(netId, part.name) then
            local pName     = part.name
            local pItem     = part.item
            local pLabel    = t(part.labelKey)
            local pDuration = part.duration
            local pAnim     = (pName == 'hood' or pName == 'trunk')
                              and Config.Animations.hood
                              or  Config.Animations.door

            options[#options + 1] = {
                name     = 'chop_strip_' .. pName,
                label    = pLabel,
                icon     = part.icon or 'fa-solid fa-screwdriver-wrench',
                distance = 3.0,
                onSelect = function()
                    if not runSkillMinigame(Config.Minigames.StripPart) then return end
                    local done = runAction(pLabel, pDuration, pAnim)
                    if not done then notify(t('action_cancelled'), 'error'); return end

                    TriggerServerEvent('chopshop:server:StripPart', netId, pName, pItem)
                    markPartStripped(netId, pName)
                    hideStrippedPartOnVehicle(vehicle, pName)
                    -- Uppdatera val (lägger till ramval när alla delar är klara)
                    applyVehicleTarget(vehicle)
                end
            }
        end
    end

    -- Ramdemontering (endast när alla andra delar är demonterade)
    if allPartsStripped(vehicle, netId) then
        local frameLabel = t(Config.FrameStrip.labelKey)
        options[#options + 1] = {
            name     = 'chop_strip_frame',
            label    = frameLabel,
            icon     = 'fa-solid fa-car-burst',
            distance = 3.0,
            onSelect = function()
                if not runSkillMinigame(Config.Minigames.StripFrame) then return end

                local modelHash = GetEntityModel(vehicle)
                local modelName = GetDisplayNameFromVehicleModel(modelHash):lower()
                local done      = runAction(frameLabel, Config.FrameStrip.duration, Config.Animations.frame)
                if not done then notify(t('action_cancelled'), 'error'); return end

                TriggerServerEvent('chopshop:server:StripFrame', netId, modelName)

                strippedParts[netId] = nil
                clearVehicleTarget(vehicle)
                removeContractVehicleEntry(vehicle)

                if civilianVehicleBlip and DoesBlipExist(civilianVehicleBlip) then
                    RemoveBlip(civilianVehicleBlip)
                    civilianVehicleBlip = nil
                end

                despawnVehicle(vehicle)
                chopZoneVehicle = nil
            end
        }
    end

    if #options > 0 then
        exports.ox_target:addLocalEntity(vehicle, options)
    end
end

-- ─── Chop-zon ────────────────────────────────────────────────────────────────

local function setupChopZone()
    lib.zones.box({
        coords   = Config.ChopZone.coords,
        size     = Config.ChopZone.size,
        rotation = Config.ChopZone.rotation,
        debug    = Config.Debug,
        onEnter  = function()
            chopZoneActive = true
            notify(t('entered_chop_zone'), 'inform')
        end,
        onExit   = function()
            chopZoneActive = false
            if chopZoneVehicle and DoesEntityExist(chopZoneVehicle) then
                clearVehicleTarget(chopZoneVehicle)
            end
            chopZoneVehicle = nil
        end
    })
end

-- Söker efter fordon medan spelaren är till fots inne i chop-zonen.
-- När ett nytt fordon hittas i närheten får det demonterings-targets.
CreateThread(function()
    while true do
        if not chopZoneActive then
            Wait(1500)
        else
            Wait(800)
            local ped = PlayerPedId()

            if GetVehiclePedIsIn(ped, false) == 0 then
                -- Spelaren är till fots – hitta närmaste fordon
                local pedCoords  = GetEntityCoords(ped)
                local nearest    = nil
                local nearestDist = Config.ChopZone.vehicleDetectionDistance

                for _, veh in ipairs(GetGamePool('CVehicle')) do
                    if DoesEntityExist(veh) and not IsEntityDead(veh) then
                        local dist = #(GetEntityCoords(veh) - pedCoords)
                        if dist < nearestDist then
                            nearest     = veh
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
                        -- Be servern kontrollera om modellen matchar ett kriminellt kontrakt
                        local modelHash = GetEntityModel(chopZoneVehicle)
                        local modelName = GetDisplayNameFromVehicleModel(modelHash):lower()
                        TriggerServerEvent('chopshop:server:CheckContractVehicle', modelName)
                    end
                end
            else
                -- Spelaren gick in i ett fordon – dölj demonteringsval
                if chopZoneVehicle and DoesEntityExist(chopZoneVehicle) then
                    clearVehicleTarget(chopZoneVehicle)
                    chopZoneVehicle = nil
                end
            end
        end
    end
end)

-- ─── Hjälpare för NPC-spawn ──────────────────────────────────────────────────


local function spawnNPC(data, options)
    local model = resolveModelHash(data.model)
    if model == 0 or not IsModelValid(model) or not IsModelInCdimage(model) or not IsModelAPed(model) then
        if Config.Debug then
            print(('[chopshop] invalid NPC model: %s'):format(tostring(data.model)))
        end
        return nil
    end

    if not loadModel(model) then
        if Config.Debug then
            print(('[chopshop] failed to load NPC model: %s'):format(tostring(data.model)))
        end
        return nil
    end

    local ped = CreatePed(4, model,
        data.coords.x, data.coords.y, data.coords.z - 1.0,
        data.coords.w, true, true)

    if ped == 0 or not DoesEntityExist(ped) then
        if Config.Debug then
            print(('[chopshop] failed to spawn NPC: %s'):format(tostring(data.name or data.model)))
        end
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

-- ─── Kriminell NPC ───────────────────────────────────────────────────────────

local function setupCriminalNPC()
    npcEntities.criminal = spawnNPC(Config.NPCs.criminal, {
        {
            name     = 'chop_get_contract',
            label    = t('get_contract'),
            icon     = 'fa-solid fa-file-contract',
            distance = 2.5,
            onSelect = function() TriggerServerEvent('chopshop:server:GetContract') end
        },
        {
            name     = 'chop_view_contract',
            label    = t('view_contract'),
            icon     = 'fa-solid fa-list-check',
            distance = 2.5,
            onSelect = function() TriggerServerEvent('chopshop:server:ViewContract') end
        },
        {
            name     = 'chop_turnin_contract',
            label    = t('turn_in_contract'),
            icon     = 'fa-solid fa-hand-holding-dollar',
            distance = 2.5,
            onSelect = function() TriggerServerEvent('chopshop:server:TurnInContract') end
        }
    })
end

-- ─── Civil NPC ───────────────────────────────────────────────────────────────

local function setupCivilianNPC()
    npcEntities.civilian = spawnNPC(Config.NPCs.civilian, {
        {
            name     = 'chop_request_vehicle',
            label    = t('request_vehicle'),
            icon     = 'fa-solid fa-car',
            distance = 2.5,
            onSelect = function() TriggerServerEvent('chopshop:server:RequestCivilianVehicle') end
        },
        {
            name     = 'chop_turnin_parts',
            label    = t('turn_in_parts'),
            icon     = 'fa-solid fa-boxes-packing',
            distance = 2.5,
            onSelect = function() TriggerServerEvent('chopshop:server:TurnInAutoParts') end
        }
    })
end

-- ─── Blips ───────────────────────────────────────────────────────────────────

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
    local cn = Config.NPCs.criminal
    if cn.blip.enabled ~= false then
        createBlip(cn.coords, cn.blip.sprite, cn.blip.color, cn.blip.scale, t(cn.blip.labelKey))
    end

    local cv = Config.NPCs.civilian
    if cv.blip.enabled ~= false then
        createBlip(cv.coords, cv.blip.sprite, cv.blip.color, cv.blip.scale, t(cv.blip.labelKey))
    end

    local cz = Config.ChopZone
    if cz.blip.enabled ~= false then
        createBlip(cz.coords, cz.blip.sprite, cz.blip.color, cz.blip.scale, t(cz.blip.labelKey))
    end
end

-- ─── Server → klient-händelser ───────────────────────────────────────────────

-- Visa aktiv kontraktsstatus i en alert-dialog
RegisterNetEvent('chopshop:client:ShowContract', function(contractData)
    if not contractData or not contractData.vehicles then
        notify(t('no_active_contract'), 'error')
        return
    end
    local lines = {}
    for i, v in ipairs(contractData.vehicles) do
        local tick = contractData.completed[v.model] and '✓' or '○'
        lines[#lines + 1] = ('%s %d. %s'):format(tick, i, v.label)
    end
    lib.alertDialog({
        header   = t('contract_status_title'),
        content  = table.concat(lines, '\n'),
        centered = true,
        cancel   = true
    })
end)

-- Kontraktsfordon spawnas inte – de kör redan runt i staden.
-- Informera spelaren att hitta kontraktsfordonen ute på gatorna.
RegisterNetEvent('chopshop:client:SpawnContractVehicles', function(contractData)
    notify(t('contract_vehicles_spawned'), 'inform')
end)

-- Spawna civilt fordon nära NPC:n
RegisterNetEvent('chopshop:client:SpawnCivilianVehicle', function(vehicleData)
    local sp    = Config.CivilianVehicleSpawn
    local model = vehicleData.model

    if not loadModel(model) then
        notify(t('vehicle_spawn_failed'), 'error')
        return
    end

    local veh = CreateVehicle(model, sp.x, sp.y, sp.z, sp.w, true, false)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(model)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('chopshop:server:RegisterCivilianVehicle', netId)

    if civilianVehicleBlip and DoesBlipExist(civilianVehicleBlip) then
        RemoveBlip(civilianVehicleBlip)
    end
    civilianVehicleBlip = AddBlipForEntity(veh)
    SetBlipSprite(civilianVehicleBlip, 225)
    SetBlipColour(civilianVehicleBlip, 3)     -- blå
    SetBlipAsShortRange(civilianVehicleBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(t('civilian_vehicle_blip'))
    EndTextCommandSetBlipName(civilianVehicleBlip)

    notify(t('civilian_vehicle_ready', vehicleData.label), 'success')
end)

-- Servern bekräftar matchning av kontraktsfordon
RegisterNetEvent('chopshop:client:ContractVehicleDetected', function(vehicleLabel)
    notify(t('contract_vehicle_detected', vehicleLabel), 'success')
end)

-- Generisk notifieringsrelay
RegisterNetEvent('chopshop:client:Notify', function(message, notifyType)
    notify(message, notifyType)
end)

-- ─── Initialisering ──────────────────────────────────────────────────────────

CreateThread(function()
    createBlips()
    setupChopZone()
    setupCriminalNPC()
    setupCivilianNPC()
end)
