local QBCore = exports['qb-core']:GetCoreObject()

local HunterData = {}
local ActiveMissions = {}
local IssuedLoadout = {}

local function debugPrint(msg)
    if Config.Debug then
        print(('[nb-hunting] %s'):format(msg))
    end
end

local function sendDiscordLog(title, message, color)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
        username = 'nb-hunting',
        embeds = {
            {
                title = title,
                description = message,
                color = color or 3145658,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end


local function getDefaultSkills()
    local skills = {}
    if Config.SkillTree and Config.SkillTree.skills then
        for skillId in pairs(Config.SkillTree.skills) do
            skills[skillId] = 0
        end
    end
    return skills
end

local function getSkillBonus(data, skillId)
    local skillCfg = Config.SkillTree and Config.SkillTree.skills and Config.SkillTree.skills[skillId]
    if not skillCfg or not data or not data.skills then return 0.0 end
    local level = data.skills[skillId] or 0
    return (skillCfg.effectPerLevel or 0.0) * level
end

local function normalizeSkills(skillData)
    local normalized = getDefaultSkills()
    if type(skillData) ~= 'table' then return normalized end
    for skillId in pairs(normalized) do
        normalized[skillId] = tonumber(skillData[skillId]) or 0
    end
    return normalized
end

local function getLevelFromXP(xp)
    local level = 1
    for lvl, data in pairs(Config.Levels) do
        if xp >= data.xp and lvl > level then
            level = lvl
        end
    end
    return level
end

local function ensureHunter(source)
    if HunterData[source] then return HunterData[source] end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    HunterData[source] = {
        cid = Player.PlayerData.citizenid,
        xp = 0,
        level = 1,
        license = not Config.UseLicense,
        kills = 0,
        cuts = 0,
        sold = 0,
        skillPoints = 0,
        skills = getDefaultSkills()
    }

    return HunterData[source]
end

local function addXP(source, amount)
    local data = ensureHunter(source)
    if not data then return end

    data.xp = data.xp + amount
    local oldLevel = data.level
    data.level = getLevelFromXP(data.xp)

    TriggerClientEvent('nb-hunting:client:updateStats', source, data)

    if data.level > oldLevel then
        local gainedLevels = data.level - oldLevel
        local pointsPerLevel = (Config.SkillTree and Config.SkillTree.pointsPerLevel) or 1
        data.skillPoints = (data.skillPoints or 0) + (gainedLevels * pointsPerLevel)
        TriggerClientEvent('QBCore:Notify', source, L('level_up', data.level), 'success')
        sendDiscordLog('Hunter Level Up', ('%s reached level %s'):format(data.cid, data.level), 5763719)
    end
end

local function saveHunterBySource(source)
    local data = HunterData[source]
    if not data then return end

    MySQL.insert.await('INSERT INTO hunter_progress (citizenid, xp, level, has_license, kills, cuts, sold, skill_points, skill_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp), level = VALUES(level), has_license = VALUES(has_license), kills = VALUES(kills), cuts = VALUES(cuts), sold = VALUES(sold), skill_points = VALUES(skill_points), skill_data = VALUES(skill_data)', {
        data.cid, data.xp, data.level, data.license and 1 or 0, data.kills, data.cuts, data.sold, data.skillPoints or 0, json.encode(data.skills or getDefaultSkills())
    })
end

local function loadHunter(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local row = MySQL.single.await('SELECT * FROM hunter_progress WHERE citizenid = ?', { Player.PlayerData.citizenid })
    if row then
        HunterData[source] = {
            cid = Player.PlayerData.citizenid,
            xp = row.xp,
            level = row.level,
            license = row.has_license == 1,
            kills = row.kills,
            cuts = row.cuts,
            sold = row.sold,
            skillPoints = row.skill_points or 0,
            skills = normalizeSkills(row.skill_data and json.decode(row.skill_data) or {})
        }
    else
        HunterData[source] = nil
        ensureHunter(source)
    end

    TriggerClientEvent('nb-hunting:client:updateStats', source, HunterData[source])
end

CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 60000)
        for source in pairs(HunterData) do
            saveHunterBySource(source)
        end
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    loadHunter(source)
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
    saveHunterBySource(source)
    HunterData[source] = nil
    ActiveMissions[source] = nil
    IssuedLoadout[source] = nil
end)

AddEventHandler('playerDropped', function()
    saveHunterBySource(source)
    HunterData[source] = nil
    ActiveMissions[source] = nil
    IssuedLoadout[source] = nil
end)

QBCore.Functions.CreateCallback('nb-hunting:server:getData', function(source, cb)
    cb(ensureHunter(source), Config.Missions, Config.SkillTree)
end)

QBCore.Functions.CreateCallback('nb-hunting:server:getLeaderboard', function(_, cb)
    local rows = MySQL.query.await('SELECT citizenid, xp, level, kills FROM hunter_progress ORDER BY xp DESC LIMIT 10')
    cb(rows or {})
end)

RegisterNetEvent('nb-hunting:server:buyLicense', function(price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensureHunter(src)
    if not Player or not data then return end
    if data.license then return end

    if Player.Functions.RemoveMoney('bank', price, 'hunting-license') then
        data.license = true
        TriggerClientEvent('QBCore:Notify', src, L('license_success'), 'success')
        sendDiscordLog('License Purchased', ('%s bought a hunting license'):format(data.cid), 3447003)
    else
        TriggerClientEvent('QBCore:Notify', src, L('no_money'), 'error')
    end
end)

RegisterNetEvent('nb-hunting:server:registerKill', function(model)
    local src = source
    local data = ensureHunter(src)
    if not data then return end

    local xpReward = 25
    for _, zone in ipairs(Config.HuntingZones) do
        for _, animal in ipairs(zone.animals) do
            if animal.model == model then
                xpReward = animal.xp
                break
            end
        end
    end

    data.kills = data.kills + 1
    addXP(src, xpReward)

    local mission = ActiveMissions[src]
    if mission and mission.objective.model == model then
        mission.progress = mission.progress + 1
        if mission.progress >= mission.objective.amount then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                local missionMoneyBonus = getSkillBonus(data, 'contractor') + getSkillBonus(data, 'prime_selection')
                local finalMoney = math.floor(mission.reward.money * (1.0 + missionMoneyBonus))
                Player.Functions.AddMoney('cash', finalMoney, 'hunt-mission')
            end
            local missionXpBonus = getSkillBonus(data, 'contractor')
            addXP(src, math.floor(mission.reward.xp * (1.0 + missionXpBonus)))
            TriggerClientEvent('nb-hunting:client:missionComplete', src, mission)
            sendDiscordLog('Mission Completed', ('%s completed mission %s'):format(data.cid, mission.id), 15844367)
            ActiveMissions[src] = nil
        else
            TriggerClientEvent('nb-hunting:client:missionProgress', src, mission)
        end
    end
end)

RegisterNetEvent('nb-hunting:server:startMission', function(missionId)
    local src = source
    local data = ensureHunter(src)
    if not data then return end

    for _, mission in ipairs(Config.Missions) do
        if mission.id == missionId then
            ActiveMissions[src] = {
                id = mission.id,
                label = mission.label,
                objective = mission.objective,
                reward = mission.reward,
                progress = 0,
                startedAt = os.time()
            }
            TriggerClientEvent('nb-hunting:client:missionStarted', src, ActiveMissions[src])
            return
        end
    end
end)

RegisterNetEvent('nb-hunting:server:cutAnimal', function(model, weapon)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensureHunter(src)
    if not Player or not data then return end

    local cutCfg = Config.CuttingWeapons[weapon]
    if not cutCfg or data.level < cutCfg.level then
        TriggerClientEvent('QBCore:Notify', src, L('no_cut_weapon'), 'error')
        return
    end

    for _, zone in ipairs(Config.HuntingZones) do
        for _, animal in ipairs(zone.animals) do
            if animal.model == model then
                for _, reward in ipairs(animal.rewards) do
                    local amount = math.random(reward.min, reward.max)
                    amount = math.floor(amount * cutCfg.rewardMultiplier)
                    local bonus = getSkillBonus(data, 'reward_bonus') + getSkillBonus(data, 'clean_cut') + getSkillBonus(data, 'meat_handler') + getSkillBonus(data, 'master_skinner') + getSkillBonus(data, 'precision_butcher')
                    if reward.item == Config.Items.Trophy then
                        bonus = bonus + getSkillBonus(data, 'trophy_eye') + getSkillBonus(data, 'rare_harvest')
                    end
                    amount = math.floor(amount * (1.0 + bonus))
                    if amount > 0 then
                        exports.ox_inventory:AddItem(src, reward.item, amount)
                    end
                end
                data.cuts = data.cuts + 1
                addXP(src, 20)
                sendDiscordLog('Animal Cut', ('%s cut %s'):format(data.cid, model), 10181046)
                return
            end
        end
    end
end)


RegisterNetEvent('nb-hunting:server:upgradeSkill', function(skillId)
    local src = source
    local data = ensureHunter(src)
    if not data or not Config.SkillTree or not Config.SkillTree.enabled then return end

    local skillCfg = Config.SkillTree.skills and Config.SkillTree.skills[skillId]
    if not skillCfg then return end

    local current = (data.skills and data.skills[skillId]) or 0
    if data.skillPoints <= 0 then
        TriggerClientEvent('QBCore:Notify', src, L('skill_no_points'), 'error')
        return
    end
    if current >= (skillCfg.maxLevel or 1) then
        TriggerClientEvent('QBCore:Notify', src, L('skill_maxed'), 'error')
        return
    end
    if data.level < (skillCfg.unlockLevel or 1) then
        TriggerClientEvent('QBCore:Notify', src, L('skill_locked_level', skillCfg.unlockLevel or 1), 'error')
        return
    end

    data.skills[skillId] = current + 1
    data.skillPoints = data.skillPoints - 1
    TriggerClientEvent('nb-hunting:client:updateStats', src, data)
    TriggerClientEvent('QBCore:Notify', src, L('skill_upgraded', skillCfg.label, data.skills[skillId]), 'success')
end)

RegisterNetEvent('nb-hunting:server:sellItem', function(item, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensureHunter(src)
    if not Player or not data then return end

    local removed = exports.ox_inventory:RemoveItem(src, item, amount)
    if not removed then return end

    local saleBonus = getSkillBonus(data, 'prime_selection') + getSkillBonus(data, 'zone_specialist')
    local total = math.floor(amount * price * (1.0 + saleBonus))
    Player.Functions.AddMoney('cash', total, 'hunt-sale')
    data.sold = data.sold + total
    addXP(src, math.floor(total / 20))

    TriggerClientEvent('QBCore:Notify', src, L('sold_items', total), 'success')
    sendDiscordLog('Hunt Sale', ('%s sold %sx %s for %s'):format(data.cid, amount, item, total), 3066993)
end)



local function removeTemporaryLoadout(src)
    local issued = IssuedLoadout[src]
    if not issued then return end

    for itemName in pairs(issued) do
        local count = exports.ox_inventory:Search(src, 'count', itemName)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(src, itemName, count)
        end
    end

    IssuedLoadout[src] = nil
end

RegisterNetEvent('nb-hunting:server:requestLoadout', function()
    local src = source
    local data = ensureHunter(src)
    if not data then return end

    if Config.UseLicense and not data.license then
        TriggerClientEvent('QBCore:Notify', src, L('license_required'), 'error')
        return
    end

    if not Config.FreeLoadout or not Config.FreeLoadout.enabled then return end

    IssuedLoadout[src] = IssuedLoadout[src] or {}

    for _, entry in ipairs(Config.FreeLoadout.items or {}) do
        if data.level >= (entry.level or 1) then
            local currentCount = exports.ox_inventory:Search(src, 'count', entry.item)
            if not currentCount or currentCount < (entry.count or 1) then
                local addCount = (entry.count or 1) - (currentCount or 0)
                if addCount > 0 then
                    exports.ox_inventory:AddItem(src, entry.item, addCount)
                end
            end
            IssuedLoadout[src][entry.item] = true
        end
    end

    if next(IssuedLoadout[src]) then
        TriggerClientEvent('QBCore:Notify', src, L('loadout_received'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, L('loadout_denied_level'), 'error')
    end
end)

RegisterNetEvent('nb-hunting:server:removeLoadout', function()
    local src = source
    if not Config.FreeLoadout or not Config.FreeLoadout.enabled or not Config.FreeLoadout.removeOnLeaveZone then return end
    removeTemporaryLoadout(src)
    TriggerClientEvent('QBCore:Notify', src, L('loadout_removed'), 'primary')
end)

exports(Config.Exports.GetHunterLevel, function(source)
    return (ensureHunter(source) or {}).level or 1
end)

exports(Config.Exports.GetHunterXP, function(source)
    return (ensureHunter(source) or {}).xp or 0
end)
