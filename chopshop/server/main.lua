local QBCore = exports['qb-core']:GetCoreObject()

-- ─── Server-side state ────────────────────────────────────────────────────────
-- contracts[src]    = { vehicles = [{model, label}], completed = {model = true} }
-- civilianJobs[src] = { active = bool, vehicleNetId = int }
local contracts    = {}
local civilianJobs = {}

-- Separate cooldown buckets (seconds timestamps)
local contractCooldowns = {}
local civilCooldowns    = {}

-- ─── Utility ──────────────────────────────────────────────────────────────────

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(src, message, notifyType)
    TriggerClientEvent('chopshop:client:Notify', src, message, notifyType)
end

local function getPoliceCount()
    local count = 0
    for _, p in pairs(QBCore.Functions.GetQBPlayers()) do
        if p.PlayerData.job
           and p.PlayerData.job.name == 'police'
           and p.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

-- Returns (true, secondsRemaining) if player is on cooldown, otherwise sets the
-- cooldown and returns (false, 0).
local function hasCooldown(bucket, src, seconds)
    local now    = os.time()
    local expiry = bucket[src] or 0
    if expiry > now then return true, expiry - now end
    bucket[src] = now + seconds
    return false, 0
end

-- OX inventory helpers
local function addItem(src, item, count, metadata)
    return exports.ox_inventory:AddItem(src, item, count, metadata)
end

local function removeItem(src, item, count)
    return exports.ox_inventory:RemoveItem(src, item, count)
end

local function countItem(src, item)
    return exports.ox_inventory:Search(src, 'count', item) or 0
end

local function canCarry(src, item, count, metadata)
    return exports.ox_inventory:CanCarryItem(src, item, count, metadata)
end

-- Roll each material independently using its own drop chance.
-- Silently skips any material the player cannot carry.
local function giveRandomMaterials(src)
    for _, m in ipairs(Config.MaterialRewards) do
        if math.random(100) <= m.chance then
            local count = math.random(m.count.min, m.count.max)
            if canCarry(src, m.item, count) then
                addItem(src, m.item, count)
            end
        end
    end
end

-- Build a randomised contract (no duplicate models)
local function buildContract()
    local pool = {}
    for _, v in ipairs(Config.ContractVehicles) do
        pool[#pool + 1] = v
    end
    -- Fisher-Yates shuffle
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local vehicles = {}
    for i = 1, Config.Criminal.vehicleCount do
        vehicles[i] = pool[i]
    end
    return vehicles
end

-- Validate that a partName/partItem pair is legitimate (server-side check)
local function isValidPart(partName, partItem)
    for _, part in ipairs(Config.StripParts) do
        if part.name == partName and part.item == partItem then
            return true
        end
    end
    return false
end

-- ─── Criminal contract ────────────────────────────────────────────────────────

RegisterNetEvent('chopshop:server:GetContract', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if getPoliceCount() < Config.Criminal.policeRequired then
        notify(src, t('not_enough_police', Config.Criminal.policeRequired), 'error')
        return
    end

    -- Reject if an unfinished contract already exists
    local existing = contracts[src]
    if existing and existing.vehicles then
        for _, v in ipairs(existing.vehicles) do
            if not existing.completed[v.model] then
                notify(src, t('contract_already_active'), 'error')
                return
            end
        end
    end

    local blocked, remaining = hasCooldown(contractCooldowns, src, Config.Criminal.cooldown)
    if blocked then
        notify(src, t('contract_cooldown', remaining), 'error')
        return
    end

    local vehicles = buildContract()
    contracts[src] = { vehicles = vehicles, completed = {} }

    TriggerClientEvent('chopshop:client:SpawnContractVehicles', src, { vehicles = vehicles })
    TriggerClientEvent('chopshop:client:ShowContract', src, {
        vehicles  = vehicles,
        completed = {}
    })
    notify(src, t('contract_received', Config.Criminal.vehicleCount), 'success')
end)

RegisterNetEvent('chopshop:server:ViewContract', function()
    local src      = source
    local contract = contracts[src]
    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end
    TriggerClientEvent('chopshop:client:ShowContract', src, {
        vehicles  = contract.vehicles,
        completed = contract.completed
    })
end)

RegisterNetEvent('chopshop:server:TurnInContract', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local contract = contracts[src]
    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end

    for _, v in ipairs(contract.vehicles) do
        if not contract.completed[v.model] then
            notify(src, t('contract_incomplete'), 'error')
            return
        end
    end

    local reward = math.random(Config.Criminal.minReward, Config.Criminal.maxReward)
    addItem(src, Config.Items.money, reward)
    giveRandomMaterials(src)
    contracts[src] = nil

    notify(src, t('contract_turned_in', reward), 'success')
end)

-- Called when the player arrives at the chop zone with a vehicle.
-- Notifies the client if the model matches a pending contract entry.
RegisterNetEvent('chopshop:server:CheckContractVehicle', function(modelName)
    local src      = source
    local contract = contracts[src]
    if not contract or not contract.vehicles then return end

    if type(modelName) ~= 'string' then return end

    for _, v in ipairs(contract.vehicles) do
        if v.model:lower() == modelName:lower() and not contract.completed[v.model] then
            TriggerClientEvent('chopshop:client:ContractVehicleDetected', src, v.label)
            return
        end
    end
end)

-- ─── Civilian job ─────────────────────────────────────────────────────────────

RegisterNetEvent('chopshop:server:RequestCivilianVehicle', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local job = civilianJobs[src]
    if job and job.active then
        notify(src, t('civil_job_already_active'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(civilCooldowns, src, Config.Civilian.cooldown)
    if blocked then
        notify(src, t('civil_job_cooldown', remaining), 'error')
        return
    end

    local vehicleData = Config.CivilianVehicles[math.random(#Config.CivilianVehicles)]
    civilianJobs[src] = { active = true, vehicleNetId = nil, vehicleModel = vehicleData.model }

    TriggerClientEvent('chopshop:client:SpawnCivilianVehicle', src, vehicleData)
    notify(src, t('civil_vehicle_incoming', vehicleData.label), 'inform')
end)

-- Client reports back the network ID after spawning the vehicle
RegisterNetEvent('chopshop:server:RegisterCivilianVehicle', function(netId)
    local src = source
    local job = civilianJobs[src]
    if job then job.vehicleNetId = netId end
end)

RegisterNetEvent('chopshop:server:TurnInAutoParts', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local partsCount = countItem(src, Config.Items.auto_parts)
    if partsCount < 1 then
        notify(src, t('no_auto_parts'), 'error')
        return
    end

    local removed = removeItem(src, Config.Items.auto_parts, partsCount)
    if not removed then
        notify(src, t('remove_parts_failed'), 'error')
        return
    end

    local reward = partsCount * math.random(
        Config.Civilian.rewardPerPart.min,
        Config.Civilian.rewardPerPart.max
    )
    addItem(src, Config.Items.money, reward)
    giveRandomMaterials(src)
    civilianJobs[src] = nil

    notify(src, t('civil_parts_turned_in', partsCount, reward), 'success')
end)

-- ─── Strip events ─────────────────────────────────────────────────────────────

RegisterNetEvent('chopshop:server:StripPart', function(netId, partName, partItem)
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    -- Server-side validation: only accept known part name + item combos
    if not isValidPart(partName, partItem) then
        notify(src, t('invalid_part'), 'error')
        return
    end

    local job        = civilianJobs[src]
    local isCivil    = job and job.active
    local itemToGive = isCivil and Config.Items.auto_parts or partItem

    if not canCarry(src, itemToGive, 1) then
        notify(src, t('no_inventory_space'), 'error')
        return
    end

    addItem(src, itemToGive, 1)
    notify(src, t('part_stripped', t('part_' .. partName)), 'success')
end)

RegisterNetEvent('chopshop:server:StripFrame', function(netId, modelName)
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(modelName) ~= 'string' then modelName = '' end

    local job     = civilianJobs[src]
    local isCivil = job and job.active

    -- Give scrap / auto_parts for the frame
    local scrapCount = math.random(Config.FrameStrip.scrapCount.min, Config.FrameStrip.scrapCount.max)
    local scrapItem  = isCivil and Config.Items.auto_parts or Config.FrameStrip.scrapItem

    if canCarry(src, scrapItem, scrapCount) then
        addItem(src, scrapItem, scrapCount)
    else
        notify(src, t('no_inventory_space'), 'error')
    end

    if isCivil then
        -- Give the frame bonus as money item + random materials
        local bonus = math.random(Config.Civilian.frameBonus.min, Config.Civilian.frameBonus.max)
        addItem(src, Config.Items.money, bonus)
        giveRandomMaterials(src)
        job.active = false
        notify(src, t('civil_frame_stripped', bonus), 'success')
    else
        -- Update criminal contract if applicable
        local contract = contracts[src]
        if contract and contract.vehicles then
            for _, v in ipairs(contract.vehicles) do
                if v.model:lower() == modelName:lower() and not contract.completed[v.model] then
                    contract.completed[v.model] = true

                    local remaining = 0
                    for _, cv in ipairs(contract.vehicles) do
                        if not contract.completed[cv.model] then
                            remaining = remaining + 1
                        end
                    end

                    if remaining == 0 then
                        notify(src, t('contract_all_done'), 'success')
                    else
                        notify(src, t('contract_vehicle_done', v.label, remaining), 'success')
                    end
                    return
                end
            end
        end
        notify(src, t('frame_stripped'), 'success')
    end
end)

-- ─── Cleanup on disconnect ────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    contracts[src]           = nil
    civilianJobs[src]        = nil
    contractCooldowns[src]   = nil
    civilCooldowns[src]      = nil
end)
