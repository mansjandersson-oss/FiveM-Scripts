local QBCore = exports['qb-core']:GetCoreObject()

local FishingData = {}
local Tournament = {
    active = false,
    endsAt = 0,
    catches = {}
}

local function debugPrint(msg)
    if Config.Debug then
        print(('[nb-fishing] %s'):format(msg))
    end
end

local function sendDiscordLog(title, message, color)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
        username = 'nb-fishing',
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
    for skillId in pairs(Config.SkillTree.skills) do
        skills[skillId] = 0
    end
    return skills
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

local function getSkillBonus(data, skillId)
    if not data or not data.skills then return 0.0 end
    local skillCfg = Config.SkillTree.skills[skillId]
    if not skillCfg then return 0.0 end
    return (skillCfg.effectPerLevel or 0.0) * (data.skills[skillId] or 0)
end

local function ensurePlayerData(source)
    if FishingData[source] then return FishingData[source] end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    FishingData[source] = {
        cid = Player.PlayerData.citizenid,
        xp = 0,
        level = 1,
        skillPoints = 0,
        totalCaught = 0,
        perfectCatches = 0,
        bestWeight = 0.0,
        totalEarned = 0,
        skills = getDefaultSkills()
    }

    return FishingData[source]
end

local function syncPlayer(source)
    TriggerClientEvent('nb-fishing:client:updateData', source, FishingData[source], Tournament)
end

local function addXP(source, amount)
    local data = ensurePlayerData(source)
    if not data then return end

    data.xp = data.xp + amount
    local oldLevel = data.level
    data.level = getLevelFromXP(data.xp)

    if data.level > oldLevel then
        local gainedLevels = data.level - oldLevel
        data.skillPoints = data.skillPoints + (gainedLevels * (Config.SkillTree.pointsPerLevel or 1))
        TriggerClientEvent('QBCore:Notify', source, L('level_up', data.level), 'success')
        TriggerClientEvent('QBCore:Notify', source, L('skill_point'), 'success')
    end

    syncPlayer(source)
end

local function saveBySource(source)
    local data = FishingData[source]
    if not data then return end

    MySQL.insert.await('INSERT INTO fishing_progress (citizenid, xp, level, skill_points, total_caught, perfect_catches, best_weight, total_earned, skill_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp), level = VALUES(level), skill_points = VALUES(skill_points), total_caught = VALUES(total_caught), perfect_catches = VALUES(perfect_catches), best_weight = VALUES(best_weight), total_earned = VALUES(total_earned), skill_data = VALUES(skill_data)', {
        data.cid,
        data.xp,
        data.level,
        data.skillPoints,
        data.totalCaught,
        data.perfectCatches,
        data.bestWeight,
        data.totalEarned,
        json.encode(data.skills)
    })
end

local function loadBySource(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local row = MySQL.single.await('SELECT * FROM fishing_progress WHERE citizenid = ?', { Player.PlayerData.citizenid })
    if row then
        FishingData[source] = {
            cid = Player.PlayerData.citizenid,
            xp = row.xp,
            level = row.level,
            skillPoints = row.skill_points or 0,
            totalCaught = row.total_caught or 0,
            perfectCatches = row.perfect_catches or 0,
            bestWeight = row.best_weight or 0.0,
            totalEarned = row.total_earned or 0,
            skills = normalizeSkills(row.skill_data and json.decode(row.skill_data) or {})
        }
    else
        FishingData[source] = nil
        ensurePlayerData(source)
    end

    syncPlayer(source)
end

local function getZoneById(zoneId)
    for _, zone in ipairs(Config.Zones) do
        if zone.id == zoneId then
            return zone
        end
    end
end


local function getTierData(tierId)
    local tiers = Config.FishTiers or {}
    return tiers[tierId] or tiers.common or { label = 'Common', xpMultiplier = 1.0, payoutMultiplier = 1.0, color = '#9ca3af' }
end

local function getSizeClass(fish, weight)
    local minWeight = fish.minWeight or 0.1
    local maxWeight = fish.maxWeight or (minWeight + 1.0)
    local ratio = (weight - minWeight) / math.max(0.01, (maxWeight - minWeight))
    local selected = (Config.SizeClasses and Config.SizeClasses[1]) or { id = 'medium', label = 'Medium', payoutMultiplier = 1.0, xpMultiplier = 1.0 }

    for _, class in ipairs(Config.SizeClasses or {}) do
        if ratio >= (class.minPercent or 0) then
            selected = class
        end
    end

    return selected
end


local function applyRodDurability(source, rodSlot, didCatch)
    if not Config.UseDurability or not rodSlot then return true end

    local baseUses = (Config.RodDurability and Config.RodDurability.BaseUses) or 100
    local catchLoss = (Config.RodDurability and Config.RodDurability.CatchLoss) or 2
    local escapeLoss = (Config.RodDurability and Config.RodDurability.EscapeLoss) or 7

    local metadata = rodSlot.metadata or {}
    local usesLeft = tonumber(metadata.rod_uses)
    if not usesLeft then
        usesLeft = baseUses
    end

    local data = ensurePlayerData(source)
    local maintenanceBonus = getSkillBonus(data, 'rod_maintenance')
    local rawLoss = didCatch and catchLoss or escapeLoss
    local loss = math.max(1, math.floor(rawLoss * (1.0 - maintenanceBonus) + 0.5))
    usesLeft = usesLeft - loss

    if usesLeft <= 0 then
        exports.ox_inventory:RemoveItem(source, Config.Items.Rod, 1, nil, rodSlot.slot)
        TriggerClientEvent('QBCore:Notify', source, L('rod_broken'), 'error')
        return false
    end

    local durabilityPercent = math.floor((usesLeft / baseUses) * 100)
    metadata.rod_uses = usesLeft
    metadata.durability = durabilityPercent

    exports.ox_inventory:SetMetadata(source, rodSlot.slot, metadata)
    exports.ox_inventory:SetDurability(source, rodSlot.slot, durabilityPercent)
    TriggerClientEvent('QBCore:Notify', source, L('rod_durability', usesLeft, baseUses), 'primary')

    return true
end

local function weightedSpecies(speciesList, trophyBonus)
    local weighted = {}
    local total = 0
    for _, fish in ipairs(speciesList) do
        local adjusted = fish.rarity
        if fish.rarity <= 12 then
            adjusted = adjusted * (1.0 + trophyBonus)
        end
        total = total + adjusted
        weighted[#weighted + 1] = { fish = fish, weight = adjusted }
    end

    local pick = math.random() * total
    local cursor = 0
    for _, entry in ipairs(weighted) do
        cursor = cursor + entry.weight
        if pick <= cursor then
            return entry.fish
        end
    end

    return weighted[#weighted].fish
end


QBCore.Functions.CreateUseableItem(Config.Items.Rod, function(source)
    TriggerClientEvent('nb-fishing:client:useFishingRod', source)
end)

QBCore.Functions.CreateCallback('nb-fishing:server:getBootstrap', function(source, cb)
    cb(ensurePlayerData(source), Config, Tournament)
end)

QBCore.Functions.CreateCallback('nb-fishing:server:getLeaderboard', function(_, cb)
    local rows = MySQL.query.await('SELECT citizenid, level, xp, total_caught, best_weight, perfect_catches FROM fishing_progress ORDER BY xp DESC LIMIT 25')
    cb(rows or {})
end)

RegisterNetEvent('nb-fishing:server:startCatch', function(zoneId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensurePlayerData(src)
    local zone = getZoneById(zoneId)

    if not Player or not data or not zone then return end
    if data.level < zone.minLevel then
        TriggerClientEvent('QBCore:Notify', src, L('level_locked'), 'error')
        return
    end

    local rodSlot = exports.ox_inventory:GetSlotWithItem(src, Config.Items.Rod, nil, false)
    local baitSlot = exports.ox_inventory:GetSlotWithItem(src, Config.Items.Bait, nil, false)

    if not rodSlot then
        TriggerClientEvent('QBCore:Notify', src, L('no_rod'), 'error')
        return
    end

    if not baitSlot then
        TriggerClientEvent('QBCore:Notify', src, L('no_bait'), 'error')
        return
    end

    local baitSaveChance = getSkillBonus(data, 'efficient_baiting')
    if math.random() > baitSaveChance then
        exports.ox_inventory:RemoveItem(src, Config.Items.Bait, 1)
    end

    local fish = weightedSpecies(zone.species, getSkillBonus(data, 'trophy_hunter'))
    local fishAggression = fish.difficulty * (1.0 - getSkillBonus(data, 'fish_reader'))
    local barHeight = Config.Minigame.barHeight + getSkillBonus(data, 'steady_hands')

    TriggerClientEvent('nb-fishing:client:beginMinigame', src, {
        fish = fish,
        zoneId = zone.id,
        barHeight = barHeight,
        aggression = fishAggression,
        catchWindow = Config.DefaultCatchWindow
    })

    TriggerClientEvent('QBCore:Notify', src, L('cast_started'), 'primary')
end)

RegisterNetEvent('nb-fishing:server:finishCatch', function(payload)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensurePlayerData(src)
    if not Player or not data or type(payload) ~= 'table' then return end

    local zone = getZoneById(payload.zoneId)
    if not zone then return end

    local rodSlot = exports.ox_inventory:GetSlotWithItem(src, Config.Items.Rod, nil, false)

    if not payload.success then
        applyRodDurability(src, rodSlot, false)
        TriggerClientEvent('QBCore:Notify', src, L('catch_failed'), 'error')
        return
    end

    applyRodDurability(src, rodSlot, true)

    local fish = payload.fish
    local weight = tonumber(payload.weight) or fish.minWeight
    local tier = getTierData(fish.tier)
    local sizeClass = getSizeClass(fish, weight)
    local xp = math.floor((fish.xp * zone.xpMultiplier * (tier.xpMultiplier or 1.0) * (sizeClass.xpMultiplier or 1.0)) + (weight * 5.0))
    local isPerfect = payload.perfect == true

    data.totalCaught = data.totalCaught + 1
    if isPerfect then
        data.perfectCatches = data.perfectCatches + 1
        xp = math.floor(xp * 1.15)
    end

    if weight > data.bestWeight then
        data.bestWeight = weight
    end

    exports.ox_inventory:AddItem(src, fish.item, 1, {
        quality = isPerfect and 'perfect' or 'normal',
        weight = weight,
        size = sizeClass.id,
        sizeLabel = sizeClass.label,
        tier = fish.tier or 'common',
        tierLabel = tier.label,
        zone = zone.id,
        caughtAt = os.time()
    })

    addXP(src, xp)
    TriggerClientEvent('QBCore:Notify', src, L('catch_success', tier.label, sizeClass.label, fish.item, weight), 'success')
    TriggerClientEvent('QBCore:Notify', src, L('xp_gain', xp), 'primary')

    if Tournament.active then
        local current = Tournament.catches[src]
        if not current or weight > current.weight then
            Tournament.catches[src] = {
                source = src,
                cid = data.cid,
                weight = weight,
                fish = fish.item
            }
        end
    end

    sendDiscordLog('Fisk fångad', ('%s fångade %s %.2fkg'):format(data.cid, fish.item, weight), isPerfect and 3066993 or 3447003)
    syncPlayer(src)
end)

RegisterNetEvent('nb-fishing:server:sellInventoryFish', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local data = ensurePlayerData(src)
    if not Player or not data then return end

    local payout = 0
    for _, zone in ipairs(Config.Zones) do
        for _, fish in ipairs(zone.species) do
            local items = exports.ox_inventory:Search(src, 'slots', fish.item)
            if items and #items > 0 then
                for _, slot in ipairs(items) do
                    local weightBonus = 1.0
                    if slot.metadata and slot.metadata.weight then
                        weightBonus = 1.0 + ((slot.metadata.weight - fish.minWeight) * 0.03)
                    end
                    local perfectBonus = (slot.metadata and slot.metadata.quality == 'perfect') and 1.2 or 1.0
                    local tierMultiplier = 1.0
                    local sizeMultiplier = 1.0

                    if slot.metadata and slot.metadata.tier then
                        tierMultiplier = getTierData(slot.metadata.tier).payoutMultiplier or 1.0
                    elseif fish.tier then
                        tierMultiplier = getTierData(fish.tier).payoutMultiplier or 1.0
                    end

                    if slot.metadata and slot.metadata.size then
                        for _, class in ipairs(Config.SizeClasses or {}) do
                            if class.id == slot.metadata.size then
                                sizeMultiplier = class.payoutMultiplier or 1.0
                                break
                            end
                        end
                    end

                    payout = payout + math.floor(fish.price * slot.count * weightBonus * perfectBonus * tierMultiplier * sizeMultiplier)
                    exports.ox_inventory:RemoveItem(src, fish.item, slot.count, slot.metadata, slot.slot)
                end
            end
        end
    end

    if payout > 0 then
        local saleBonus = 1.0 + getSkillBonus(data, 'fish_monger')
        payout = math.floor(payout * saleBonus)
        Player.Functions.AddMoney('cash', payout, 'fish-sale')
        data.totalEarned = data.totalEarned + payout
        TriggerClientEvent('QBCore:Notify', src, L('sold_fish', payout), 'success')
        syncPlayer(src)
    end
end)

RegisterNetEvent('nb-fishing:server:upgradeSkill', function(skillId)
    local src = source
    local data = ensurePlayerData(src)
    if not data then return end

    local skillCfg = Config.SkillTree.skills[skillId]
    if not skillCfg then return end

    local current = data.skills[skillId] or 0
    if current >= skillCfg.maxLevel then
        TriggerClientEvent('QBCore:Notify', src, L('already_maxed'), 'error')
        return
    end

    if data.skillPoints <= 0 then
        TriggerClientEvent('QBCore:Notify', src, L('no_points'), 'error')
        return
    end

    data.skillPoints = data.skillPoints - 1
    data.skills[skillId] = current + 1

    TriggerClientEvent('QBCore:Notify', src, L('skill_upgraded', skillCfg.label, data.skills[skillId]), 'success')
    syncPlayer(src)
end)

local function finalizeTournament()
    Tournament.active = false
    Tournament.endsAt = 0

    local ranked = {}
    for _, catchData in pairs(Tournament.catches) do
        ranked[#ranked + 1] = catchData
    end

    table.sort(ranked, function(a, b)
        return a.weight > b.weight
    end)

    for place = 1, 3 do
        local winner = ranked[place]
        if winner and Config.Events.tournaments.payout[place] then
            local payout = Config.Events.tournaments.payout[place]
            local Player = QBCore.Functions.GetPlayer(winner.source)
            if Player then
                Player.Functions.AddMoney('cash', payout.cash, 'fishing-tournament')
                addXP(winner.source, payout.xp)
                TriggerClientEvent('QBCore:Notify', winner.source, ('Turneringspris #%s mottaget!'):format(place), 'success')
            end
        end
    end

    Tournament.catches = {}
    TriggerClientEvent('nb-fishing:client:tournamentState', -1, Tournament)
    TriggerClientEvent('QBCore:Notify', -1, L('tournament_ended'), 'primary')
end

local function beginTournament()
    Tournament.active = true
    Tournament.catches = {}
    Tournament.endsAt = os.time() + (Config.Events.tournaments.durationMinutes * 60)

    TriggerClientEvent('nb-fishing:client:tournamentState', -1, Tournament)
    TriggerClientEvent('QBCore:Notify', -1, L('tournament_started'), 'primary')

    CreateThread(function()
        Wait(Config.Events.tournaments.durationMinutes * 60000)
        if Tournament.active then
            finalizeTournament()
        end
    end)
end

CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 60000)
        for src in pairs(FishingData) do
            saveBySource(src)
        end
    end
end)

CreateThread(function()
    if not Config.Events.tournaments.enabled then return end
    while true do
        Wait(Config.Events.tournaments.intervalMinutes * 60000)
        if not Tournament.active then
            beginTournament()
        end
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    loadBySource(source)
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
    saveBySource(source)
    FishingData[source] = nil
    Tournament.catches[source] = nil
end)

AddEventHandler('playerDropped', function()
    saveBySource(source)
    FishingData[source] = nil
    Tournament.catches[source] = nil
end)

exports(Config.Exports.GetFishingLevel, function(source)
    local data = ensurePlayerData(source)
    return data and data.level or 1
end)

exports(Config.Exports.GetFishingXP, function(source)
    local data = ensurePlayerData(source)
    return data and data.xp or 0
end)

lib.addCommand('fishlb', {
    help = 'Visa fiske-topplista'
}, function(source)
    local rows = MySQL.query.await('SELECT citizenid, level, xp, total_caught, best_weight FROM fishing_progress ORDER BY xp DESC LIMIT 10')
    TriggerClientEvent('nb-fishing:client:openLeaderboard', source, rows)
end)

lib.addCommand('fishadmin_start_tourney', {
    help = 'Tvinga igång fisketurnering',
    restricted = 'group.admin'
}, function()
    if not Tournament.active then
        beginTournament()
    end
end)
