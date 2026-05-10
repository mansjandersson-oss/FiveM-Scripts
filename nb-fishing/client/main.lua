local QBCore = exports['qb-core']:GetCoreObject()

local PlayerData = nil
local TournamentData = nil
local MinigameActive = false
local CurrentZone = nil
local CurrentCatchId = nil
local SellPed = nil

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

local function getClosestZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best, bestDist

    for _, zone in ipairs(Config.Zones) do
        local dist = #(coords - zone.center)
        if dist <= zone.radius and (not bestDist or dist < bestDist) then
            best = zone
            bestDist = dist
        end
    end

    return best
end

local function openSkillMenu()
    if not PlayerData then return end

    local options = {
        {
            title = ('Nivå %s - XP %s'):format(PlayerData.level, PlayerData.xp),
            description = ('Tillgängliga skill-poäng: %s'):format(PlayerData.skillPoints),
            disabled = true
        }
    }

    for skillId, skillCfg in pairs(Config.SkillTree.skills) do
        local lvl = PlayerData.skills[skillId] or 0
        local nextLvl = math.min(lvl + 1, skillCfg.maxLevel)
        local currentEffect = (skillCfg.effectPerLevel or 0.0) * lvl * 100.0
        local nextEffect = (skillCfg.effectPerLevel or 0.0) * nextLvl * 100.0
        local description = skillCfg.description

        if skillCfg.effectLabel then
            description = ('%s\n%s'):format(description, skillCfg.effectLabel:format(currentEffect, nextEffect))
        end

        options[#options + 1] = {
            title = ('%s (%s/%s)'):format(skillCfg.label, lvl, skillCfg.maxLevel),
            description = description,
            icon = 'star',
            disabled = lvl >= skillCfg.maxLevel,
            onSelect = function()
                TriggerServerEvent('nb-fishing:server:upgradeSkill', skillId)
            end
        }
    end

    lib.registerContext({
        id = 'nb_fishing_skill_menu',
        title = 'Fiskeskills',
        options = options
    })
    lib.showContext('nb_fishing_skill_menu')
end

local function startFishing()
    local zone = getClosestZone()
    if not zone then
        QBCore.Functions.Notify('Du måste stå nära en fiskezon.', 'error')
        return
    end

    CurrentZone = zone
    TriggerServerEvent('nb-fishing:server:startCatch', zone.id)
end

RegisterCommand('fishskills', function()
    openSkillMenu()
end)

RegisterNetEvent('nb-fishing:client:useFishingRod', function()
    if MinigameActive then return end
    startFishing()
end)

RegisterNetEvent('nb-fishing:client:updateData', function(data, tournament)
    PlayerData = data
    TournamentData = tournament
end)

RegisterNetEvent('nb-fishing:client:tournamentState', function(tournament)
    TournamentData = tournament
end)

RegisterNetEvent('nb-fishing:client:openLeaderboard', function(rows)
    local options = {}
    for i, row in ipairs(rows) do
        options[#options + 1] = {
            title = ('#%s %s'):format(i, row.citizenid),
            description = ('Nivå %s | XP %s | Fångat %s | Bäst %.2fkg'):format(row.level, row.xp, row.total_caught, row.best_weight),
            icon = 'fish'
        }
    end

    lib.registerContext({
        id = 'nb_fishing_leaderboard',
        title = L('leaderboard_title'),
        options = options
    })
    lib.showContext('nb_fishing_leaderboard')
end)

RegisterNetEvent('nb-fishing:client:beginMinigame', function(payload)
    if MinigameActive then return end
    MinigameActive = true
    CurrentCatchId = payload.catchId

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'start',
        config = {
            minigame = Config.Minigame,
            fish = payload.fish,
            zoneLabel = payload.zoneLabel,
            catchId = payload.catchId,
            aggression = payload.aggression,
            barHeight = payload.barHeight,
            catchWindow = payload.catchWindow,
            skillEffects = payload.skillEffects
        }
    })
end)

RegisterNUICallback('finish', function(data, cb)
    cb('ok')

    SetNuiFocus(false, false)
    MinigameActive = false

    if not CurrentZone then return end

    TriggerServerEvent('nb-fishing:server:finishCatch', {
        success = data.success == true,
        perfect = data.perfect == true,
        catchId = CurrentCatchId,
        zoneId = CurrentZone.id
    })

    CurrentZone = nil
    CurrentCatchId = nil
end)

CreateThread(function()
    QBCore.Functions.TriggerCallback('nb-fishing:server:getBootstrap', function(data, _, tournament)
        PlayerData = data
        TournamentData = tournament
    end)
end)

CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        exports.ox_target:addSphereZone({
            coords = shop.coords,
            radius = 1.8,
            debug = Config.Debug,
            options = {
                {
                    name = ('fish_shop_%s'):format(shop.label),
                    icon = 'fa-solid fa-fish',
                    label = 'Öppna fiskehandel',
                    onSelect = function()
                        exports.ox_inventory:openInventory('shop', { type = 'Fishing', id = 1 })
                    end
                }
            }
        })
    end

    local npcCfg = Config.SellNPC
    local model = loadModel(npcCfg.model)
    SellPed = CreatePed(0, model, npcCfg.coords.x, npcCfg.coords.y, npcCfg.coords.z - 1.0, npcCfg.coords.w, false, true)
    SetEntityAsMissionEntity(SellPed, true, true)
    FreezeEntityPosition(SellPed, true)
    SetBlockingOfNonTemporaryEvents(SellPed, true)
    SetEntityInvincible(SellPed, true)

    if npcCfg.scenario and npcCfg.scenario ~= '' then
        TaskStartScenarioInPlace(SellPed, npcCfg.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(SellPed, {
        {
            name = 'fish_sell_npc',
            icon = 'fa-solid fa-sack-dollar',
            label = 'Sälj all fisk',
            distance = npcCfg.targetRadius or 2.0,
            onSelect = function()
                TriggerServerEvent('nb-fishing:server:sellInventoryFish')
            end
        },
        {
            name = 'fish_skill_npc',
            icon = 'fa-solid fa-chart-line',
            label = 'Öppna fiskeskills',
            distance = npcCfg.targetRadius or 2.0,
            onSelect = function()
                openSkillMenu()
            end
        }
    })

    if npcCfg.blip and npcCfg.blip.enabled then
        local blip = AddBlipForCoord(npcCfg.coords.x, npcCfg.coords.y, npcCfg.coords.z)
        SetBlipSprite(blip, npcCfg.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, npcCfg.blip.scale)
        SetBlipColour(blip, npcCfg.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(npcCfg.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if SellPed and DoesEntityExist(SellPed) then
        DeleteEntity(SellPed)
    end
end)
