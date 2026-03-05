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

-- ─── Inventory adapter (ox_inventory or qb-inventory) ────────────────────────
local addItem, removeItem, countItem, canCarry, getContractItemMetadata

if Config.Inventory == 'qb-inventory' then
    addItem = function(src, item, count, metadata)
        return exports['qb-inventory']:AddItem(src, item, count, nil, metadata)
    end
    removeItem = function(src, item, count)
        return exports['qb-inventory']:RemoveItem(src, item, count)
    end
    countItem = function(src, item)
        local found = exports['qb-inventory']:GetItemByName(src, item)
        return found and found.amount or 0
    end
    canCarry = function(src, item, count)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        local itemData = QBCore.Shared.Items[item]
        if not itemData then return true end
        local addWeight     = (itemData.weight or 0) * count
        local currentWeight = Player.PlayerData.metadata['currentweight'] or 0
        local maxWeight     = Player.PlayerData.metadata['maxweight'] or 120000
        return (currentWeight + addWeight) <= maxWeight
    end
    getContractItemMetadata = function(src)
        local item = exports['qb-inventory']:GetItemByName(src, Config.Items.chop_contract)
        if item and item.info and item.info.vehicles then
            return item.info, item.slot
        end
        return nil
    end
else -- ox_inventory (default)
    addItem = function(src, item, count, metadata)
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end
    removeItem = function(src, item, count)
        return exports.ox_inventory:RemoveItem(src, item, count)
    end
    countItem = function(src, item)
        return exports.ox_inventory:Search(src, 'count', item) or 0
    end
    canCarry = function(src, item, count, metadata)
        return exports.ox_inventory:CanCarryItem(src, item, count, metadata)
    end
    getContractItemMetadata = function(src)
        local slots = exports.ox_inventory:Search(src, 'slots', Config.Items.chop_contract)
        if slots and slots[1] then
            local found = exports.ox_inventory:GetSlot(src, slots[1])
            if found and found.metadata and found.metadata.vehicles then
                return found.metadata, slots[1]
            end
        end
        return nil
    end
end

-- Build a human-readable vehicle list for the contract item description.
-- Completed vehicles are removed from the list so only remaining targets are shown.
local function buildContractDescription(vehicles, completed)
    local lines, idx = {}, 1

    for _, v in ipairs(vehicles) do
        if not completed[v.model] then
            lines[#lines + 1] = ('○ %d. %s'):format(idx, v.label)
            idx = idx + 1
        end
    end

    if #lines == 0 then
        return t('contract_item_complete')
    end

    return table.concat(lines, '\n')
end

-- Update the chop_contract item's metadata to reflect the latest contract state.
-- Used to keep item metadata in sync so crash recovery restores the correct progress.
local function updateContractItemMetadata(src, metadata)
    local _, slot = getContractItemMetadata(src)
    if slot then
        metadata.description = buildContractDescription(metadata.vehicles, metadata.completed)
        if Config.Inventory == 'qb-inventory' then
            exports['qb-inventory']:SetMetadata(src, slot, metadata)
        else
            exports.ox_inventory:SetMetadata(src, slot, metadata)
        end
    elseif Config.Debug then
        print(('[chopshop] updateContractItemMetadata: %s not found for source %s'):format(Config.Items.chop_contract, src))
    end
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

    -- Reject if an unfinished contract already exists (server state or item in inventory)
    local existing = contracts[src]
    if existing and existing.vehicles then
        for _, v in ipairs(existing.vehicles) do
            if not existing.completed[v.model] then
                notify(src, t('contract_already_active'), 'error')
                return
            end
        end
    elseif countItem(src, Config.Items.chop_contract) > 0 then
        -- Player crashed mid-contract; item still in inventory — tell them to use it
        notify(src, t('contract_use_item_to_restore'), 'error')
        return
    end

    local blocked, remaining = hasCooldown(contractCooldowns, src, Config.Criminal.cooldown)
    if blocked then
        notify(src, t('contract_cooldown', remaining), 'error')
        return
    end

    local vehicles = buildContract()
    contracts[src] = { vehicles = vehicles, completed = {} }

    -- Give the player a physical contract item they can use to restore progress after a crash
    addItem(src, Config.Items.chop_contract, 1, {
        vehicles    = vehicles,
        completed   = {},
        description = buildContractDescription(vehicles, {})
    })

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
    removeItem(src, Config.Items.chop_contract, 1)
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

    local sellableParts = Config.Civilian.sellableParts or {
        Config.Items.auto_parts,
        Config.Items.car_door,
        Config.Items.car_hood,
        Config.Items.car_trunk_lid,
        Config.Items.scrap_metal
    }

    local totalParts = 0
    local removalQueue = {}

    for _, itemName in ipairs(sellableParts) do
        local count = countItem(src, itemName)
        if count and count > 0 then
            totalParts = totalParts + count
            removalQueue[#removalQueue + 1] = { name = itemName, count = count }
        end
    end

    if totalParts < 1 then
        notify(src, t('no_auto_parts'), 'error')
        return
    end

    for _, part in ipairs(removalQueue) do
        local removed = removeItem(src, part.name, part.count)
        if not removed then
            notify(src, t('remove_parts_failed'), 'error')
            return
        end
    end

    local reward = totalParts * math.random(
        Config.Civilian.rewardPerPart.min,
        Config.Civilian.rewardPerPart.max
    )
    addItem(src, Config.Items.money, reward)
    giveRandomMaterials(src)
    civilianJobs[src] = nil

    notify(src, t('civil_parts_turned_in', totalParts, reward), 'success')
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
                    -- Keep the contract item metadata in sync for crash recovery
                    updateContractItemMetadata(src, { vehicles = contract.vehicles, completed = contract.completed })

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

-- ─── Contract item: crash recovery ───────────────────────────────────────────
-- When a player uses the chop_contract item, restore their active contract from
-- the item metadata (handles the case where the server state was lost on crash).

local function handleContractItemUse(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local contract = contracts[src]

    if contract and contract.vehicles then
        -- Contract is still active in server state — just display it
        TriggerClientEvent('chopshop:client:ShowContract', src, {
            vehicles  = contract.vehicles,
            completed = contract.completed
        })
        notify(src, t('contract_restored'), 'success')
        return
    end

    -- Server state lost (e.g. after a crash) – restore from item metadata
    local meta = getContractItemMetadata(src)
    if meta then
        contracts[src] = {
            vehicles  = meta.vehicles,
            completed = meta.completed or {}
        }
        contract = contracts[src]
    end

    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end

    TriggerClientEvent('chopshop:client:SpawnContractVehicles', src, { vehicles = contract.vehicles })
    TriggerClientEvent('chopshop:client:ShowContract', src, {
        vehicles  = contract.vehicles,
        completed = contract.completed
    })
    notify(src, t('contract_restored'), 'success')
end

if Config.Inventory == 'qb-inventory' then
    QBCore.Functions.CreateUseableItem(Config.Items.chop_contract, handleContractItemUse)
else
    exports.ox_inventory:RegisterUsableItem(Config.Items.chop_contract, handleContractItemUse)
end

-- ─── Cleanup on disconnect ────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    contracts[src]           = nil
    civilianJobs[src]        = nil
    contractCooldowns[src]   = nil
    civilCooldowns[src]      = nil
end)
