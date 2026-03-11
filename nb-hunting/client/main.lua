local QBCore = exports['qb-core']:GetCoreObject()

local hunterData = nil
local spawnedAnimals = {}
local zoneTimers = {}
local callCooldowns = {}
local baitCooldown = 0
local menuOpen = false
local zonePresenceCount = 0

local function debugPrint(msg)
    if Config.Debug then
        print(('[nb-hunting] %s'):format(msg))
    end
end

local function hasLicense()
    if not Config.UseLicense then return true end
    return hunterData and hunterData.license
end

local function canUseWeapon(weaponName)
    local required = Config.WeaponLevelRequirements[weaponName]
    if not required then return true end
    return hunterData and hunterData.level >= required
end

local function closeHunterMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openHunterMenu(data, missions, leaderboard)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = {
            locale = Config.Locale,
            hunterData = data,
            useLicense = Config.UseLicense,
            missions = missions,
            leaderboard = leaderboard,
            zones = Config.HuntingZones,
            labels = {
                title = L('hunter_title'),
                buyLicense = L('buy_license'),
                requestLoadout = L('loadout_request')
            }
        }
    })
end

local function createBlip(data)
    if not data.enabled then return end
    local blip = AddBlipForCoord(Config.HunterNPC.coords.xyz)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
end

local function spawnHunterNPC()
    local model = joaat(Config.HunterNPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(0, model, Config.HunterNPC.coords.x, Config.HunterNPC.coords.y, Config.HunterNPC.coords.z - 1.0, Config.HunterNPC.coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, Config.HunterNPC.scenario, 0, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            icon = 'fa-solid fa-paw',
            label = L('hunter_title'),
            onSelect = function()
                TriggerEvent('nb-hunting:client:openHunterMenu')
            end
        }
    })

    createBlip(Config.HunterNPC.blip)
end

local function createAnimalTarget(entity, modelName)
    exports.ox_target:addLocalEntity(entity, {
        {
            icon = 'fa-solid fa-knife',
            label = 'Stycka djur',
            canInteract = function(ent)
                return IsEntityDead(ent)
            end,
            onSelect = function(data)
                TriggerEvent('nb-hunting:client:cutAnimal', data.entity, modelName)
            end
        }
    })
end

local function animalBehaviour(entity, zone)
    CreateThread(function()
        while DoesEntityExist(entity) and not IsEntityDead(entity) do
            Wait(1000)
            local playerPed = PlayerPedId()
            local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(entity))
            if dist < 12.0 and not IsPedStealthMovement(playerPed) then
                if math.random(1, 100) > 70 then
                    TaskCombatPed(entity, playerPed, 0, 16)
                else
                    TaskSmartFleePed(entity, playerPed, 120.0, -1, false, false)
                end
            end
        end
    end)
end

local function spawnAnimalInZone(zone)
    if not hasLicense() then return end
    local aliveCount = 0
    for _, data in pairs(spawnedAnimals) do
        if data.zoneId == zone.id and DoesEntityExist(data.entity) and not IsEntityDead(data.entity) then
            aliveCount = aliveCount + 1
        end
    end
    if aliveCount >= zone.maxAlive then return end

    local animal = zone.animals[math.random(1, #zone.animals)]
    local model = joaat(animal.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local angle = math.random() * 360.0
    local distance = math.random(15, math.floor(zone.radius))
    local x = zone.center.x + math.cos(math.rad(angle)) * distance
    local y = zone.center.y + math.sin(math.rad(angle)) * distance
    local z = zone.center.z + 2.0

    local _, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    local ped = CreatePed(28, model, x, y, groundZ, math.random(0, 359) + 0.0, true, true)

    spawnedAnimals[ped] = { entity = ped, zoneId = zone.id, model = animal.model }
    createAnimalTarget(ped, animal.model)
    animalBehaviour(ped, zone)

    if Config.EnableSync then
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(ped), true)
    end
end

local function startZoneSpawner(zone)
    if zoneTimers[zone.id] then return end
    zoneTimers[zone.id] = true

    CreateThread(function()
        while zoneTimers[zone.id] do
            Wait(zone.spawnInterval * 1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - zone.center) <= zone.radius + 60.0 then
                spawnAnimalInZone(zone)
            end
        end
    end)
end

local function useAnimalCall(itemName)
    local cfg = Config.Calls[itemName]
    if not cfg then return end

    if callCooldowns[itemName] and callCooldowns[itemName] > GetGameTimer() then
        return
    end

    callCooldowns[itemName] = GetGameTimer() + (cfg.cooldown * 1000)
    local pCoords = GetEntityCoords(PlayerPedId())

    for ped, data in pairs(spawnedAnimals) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            for _, model in ipairs(cfg.targetModels) do
                if data.model == model and #(GetEntityCoords(ped) - pCoords) < 250.0 then
                    local blip = AddBlipForEntity(ped)
                    SetBlipColour(blip, 1)
                    SetBlipScale(blip, 0.7)
                    CreateThread(function()
                        Wait(cfg.pingDuration * 1000)
                        RemoveBlip(blip)
                    end)
                end
            end
        end
    end

    QBCore.Functions.Notify(L('call_used'), 'success')
end

local function deployBait()
    if baitCooldown > GetGameTimer() then return end
    local baitCfg = Config.Baits[Config.Items.Bait]
    if not baitCfg then return end

    baitCooldown = GetGameTimer() + (baitCfg.cooldown * 1000)
    local pCoords = GetEntityCoords(PlayerPedId())
    QBCore.Functions.Notify(L('bait_used'), 'success')

    CreateThread(function()
        local endTime = GetGameTimer() + (baitCfg.duration * 1000)
        while GetGameTimer() < endTime do
            Wait(1500)
            for ped, _ in pairs(spawnedAnimals) do
                if DoesEntityExist(ped) and not IsEntityDead(ped) and #(GetEntityCoords(ped) - pCoords) <= baitCfg.radius then
                    TaskGoStraightToCoord(ped, pCoords.x, pCoords.y, pCoords.z, 1.0, -1, 0.0, 0.0)
                end
            end
        end
    end)
end

RegisterNetEvent('nb-hunting:client:openHunterMenu', function()
    QBCore.Functions.TriggerCallback('nb-hunting:server:getData', function(data, missions)
        hunterData = data
        QBCore.Functions.TriggerCallback('nb-hunting:server:getLeaderboard', function(rows)
            openHunterMenu(data, missions, rows)
        end)
    end)
end)

RegisterNUICallback('close', function(_, cb)
    closeHunterMenu()
    cb('ok')
end)

RegisterNUICallback('buyLicense', function(_, cb)
    TriggerServerEvent('nb-hunting:server:buyLicense', 1500)
    cb('ok')
end)

RegisterNUICallback('requestLoadout', function(_, cb)
    TriggerServerEvent('nb-hunting:server:requestLoadout')
    cb('ok')
end)

RegisterNUICallback('startMission', function(payload, cb)
    if payload and payload.id then
        TriggerServerEvent('nb-hunting:server:startMission', payload.id)
    end
    cb('ok')
end)

RegisterNUICallback('setRoute', function(payload, cb)
    if payload and payload.zoneId then
        for _, zone in ipairs(Config.HuntingZones) do
            if zone.id == payload.zoneId then
                SetNewWaypoint(zone.center.x, zone.center.y)
                QBCore.Functions.Notify(L('route_set', zone.label), 'success')
                break
            end
        end
    end
    cb('ok')
end)

RegisterNetEvent('nb-hunting:client:updateStats', function(data)
    hunterData = data
    SendNUIMessage({ action = 'stats', payload = data })
end)

RegisterNetEvent('nb-hunting:client:missionStarted', function(mission)
    QBCore.Functions.Notify(L('mission_started', mission.label), 'success')
    closeHunterMenu()
end)

RegisterNetEvent('nb-hunting:client:missionProgress', function(mission)
    QBCore.Functions.Notify(('Progress %s/%s'):format(mission.progress, mission.objective.amount), 'primary')
end)

RegisterNetEvent('nb-hunting:client:missionComplete', function(_)
    QBCore.Functions.Notify(L('mission_completed'), 'success')
end)

RegisterNetEvent('nb-hunting:client:cutAnimal', function(entity, model)
    if not DoesEntityExist(entity) or not IsEntityDead(entity) then return end
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    local weaponName = QBCore.Shared.Weapons[weapon] and QBCore.Shared.Weapons[weapon].name
    if not weaponName or not Config.CuttingWeapons[weaponName] then
        QBCore.Functions.Notify(L('no_cut_weapon'), 'error')
        return
    end

    local success = lib.progressBar({
        duration = 5000,
        label = L('cut_started'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true }
    })

    if success then
        TriggerServerEvent('nb-hunting:server:cutAnimal', model, weaponName)
        DeleteEntity(entity)
        spawnedAnimals[entity] = nil
    end
end)

RegisterCommand('huntbait', function()
    deployBait()
end)

RegisterCommand('huntcall', function(_, args)
    useAnimalCall(args[1] or Config.Items.DeerCall)
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    local attacker = args[2]

    if attacker ~= PlayerPedId() or not IsEntityAPed(victim) or not IsPedAPlayer(victim) and not IsPedHuman(victim) then
        local modelName = spawnedAnimals[victim] and spawnedAnimals[victim].model
        if modelName and IsEntityDead(victim) then
            local weapon = GetSelectedPedWeapon(PlayerPedId())
            local weaponName = QBCore.Shared.Weapons[weapon] and QBCore.Shared.Weapons[weapon].name
            if weaponName and not canUseWeapon(weaponName) then
                QBCore.Functions.Notify(L('invalid_weapon_level'), 'error')
                return
            end
            TriggerServerEvent('nb-hunting:server:registerKill', modelName)
        end
    end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(1000) end
    spawnHunterNPC()

    for _, zone in ipairs(Config.HuntingZones) do
        startZoneSpawner(zone)

        lib.zones.sphere({
            coords = zone.center,
            radius = zone.radius,
            debug = Config.Debug,
            inside = function()
                if not hasLicense() then return end
            end,
            onEnter = function()
                zonePresenceCount = zonePresenceCount + 1
                QBCore.Functions.Notify(L('zone_entered', zone.label), 'primary')
            end,
            onExit = function()
                zonePresenceCount = math.max(0, zonePresenceCount - 1)
                if zonePresenceCount == 0 then
                    TriggerServerEvent('nb-hunting:server:removeLoadout')
                end
            end
        })
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if menuOpen and IsControlJustReleased(0, 200) then
            closeHunterMenu()
        end
    end
end)
