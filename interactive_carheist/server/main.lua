local QBCore = exports['qb-core']:GetCoreObject()

local activeMissions = {}
local missionCooldown = {}

local function t(key, ...)
    local lang = Config.Text[Config.Locale] or Config.Text.sv
    local text = (lang and lang[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(src, msg, nType)
    TriggerClientEvent('interactive_carheist:client:notify', src, msg, nType or 'inform')
end

local function getPoliceCount()
    local amount = 0
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        if player.PlayerData.job and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            amount += 1
        end
    end
    return amount
end

RegisterNetEvent('interactive_carheist:server:requestMission', function()
    local src = source
    if activeMissions[src] then
        notify(src, t('mission_already'), 'error')
        return
    end

    local now = os.time()
    if getPoliceCount() < Config.MinPolice then
        notify(src, ('Det krävs minst %s polis i tjänst.'):format(Config.MinPolice), 'error')
        return
    end

    if missionCooldown[src] and missionCooldown[src] > now then
        local left = missionCooldown[src] - now
        notify(src, ('Vänta %s sekunder innan nytt uppdrag.'):format(left), 'error')
        return
    end

    local spawn = Config.VehicleSpawns[math.random(1, #Config.VehicleSpawns)]
    local model = Config.VehicleModels[math.random(1, #Config.VehicleModels)]
    local plate = ('X%d'):format(math.random(10000, 99999))

    activeMissions[src] = {
        plate = plate,
        startedAt = now,
        decryptDoneAt = now + Config.DecryptSeconds
    }

    TriggerClientEvent('interactive_carheist:client:startMission', src, {
        model = model,
        spawn = spawn,
        plate = plate
    })
end)

RegisterNetEvent('interactive_carheist:server:sendPolicePing', function(coords)
    local src = source
    if not activeMissions[src] then return end

    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        if player.PlayerData.job and player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
            TriggerClientEvent('interactive_carheist:client:policePing', player.PlayerData.source, coords)
        end
    end
end)

RegisterNetEvent('interactive_carheist:server:completeMission', function(plate)
    local src = source
    local mission = activeMissions[src]
    if not mission then
        notify(src, t('mission_cancelled'), 'error')
        return
    end

    if mission.plate ~= plate then
        notify(src, t('too_far'), 'error')
        return
    end

    if os.time() < mission.decryptDoneAt then
        notify(src, 'Dekryptering är inte färdig än.', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    Player.Functions.AddMoney(Config.Reward.type, Config.Reward.amount, 'interactive-car-heist')

    activeMissions[src] = nil
    missionCooldown[src] = os.time() + 300

    TriggerClientEvent('interactive_carheist:client:missionCompleted', src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeMissions[src] = nil
    missionCooldown[src] = nil
end)

