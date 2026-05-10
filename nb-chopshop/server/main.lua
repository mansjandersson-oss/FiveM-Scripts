local QBCore = exports['qb-core']:GetCoreObject()

local contracts = {}
local contractCooldowns = {}

local addItem, removeItem, countItem, canCarry, getContractItemMetadata

local function t(key, ...)
    local lang = Locales[Config.Locale] or Locales.en
    local text = (lang and lang[key]) or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(src, message, notifyType)
    TriggerClientEvent('nb-chopshop:client:Notify', src, message, notifyType)
end

local function debugPrint(message, ...)
    if not Config.Debug or not (Config.DebugOptions and Config.DebugOptions.verbose) then return end

    if select('#', ...) > 0 then
        message = message:format(...)
    end

    print(('[nb-chopshop:debug:server] %s'):format(message))
end

local function debugOptionEnabled(name)
    return Config.Debug and Config.DebugOptions and Config.DebugOptions[name] == true
end

local function normalizeRoleResult(result)
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

        if result.isCriminal == true or result.criminal == true or result.is_criminal == true then
            return true
        end
        if result.isCivilian == true or result.civilian == true or result.is_civilian == true then
            return false
        end
    end

    return nil
end

local function hasConfiguredAccess(player)
    local access = Config.CriminalAccess or {}
    local jobs = access.jobs or {}
    local gangs = access.gangs or {}
    local playerData = player.PlayerData or {}
    local jobName = playerData.job and playerData.job.name
    local gangName = playerData.gang and playerData.gang.name

    return (jobName and jobs[jobName] == true) or (gangName and gangs[gangName] == true)
end

local function isCriminal(src, player)
    local debugOptions = Config.DebugOptions or {}
    if Config.Debug and debugOptions.bypassRoleCheck then
        local forcedRoute = tostring(debugOptions.forcedRoute or 'criminal'):lower()
        local allowed = forcedRoute == 'criminal' or forcedRoute == 'both'
        debugPrint('role check bypassed source=%s forcedRoute=%s allowed=%s', src, forcedRoute, tostring(allowed))
        return allowed
    end

    local roleCfg = Config.RoleCheckExport
    if roleCfg and roleCfg.resource and roleCfg.func then
        local exportRes = exports[roleCfg.resource]
        if exportRes and exportRes[roleCfg.func] then
            local ok, result = pcall(function()
                if roleCfg.passServerId ~= false then
                    return exportRes[roleCfg.func](src)
                end
                return exportRes[roleCfg.func]()
            end)

            if ok then
                local allowed = normalizeRoleResult(result)
                if allowed ~= nil then
                    debugPrint('RoleCheckExport source=%s result=%s allowed=%s', src, tostring(result), tostring(allowed))
                    return allowed
                end
                debugPrint('RoleCheckExport source=%s returned unknown value=%s', src, tostring(result))
            else
                debugPrint('RoleCheckExport source=%s error=%s', src, tostring(result))
            end
        else
            debugPrint('RoleCheckExport missing export: %s.%s', tostring(roleCfg.resource), tostring(roleCfg.func))
        end
    else
        debugPrint('RoleCheckExport not configured')
    end

    local allowed = hasConfiguredAccess(player)
    debugPrint('CriminalAccess fallback source=%s allowed=%s', src, tostring(allowed))
    return allowed
end

local function requireCriminal(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil end
    if not isCriminal(src, player) then
        notify(src, t('not_criminal'), 'error')
        return nil
    end
    return player
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

local function hasCooldown(bucket, src, seconds)
    local now = os.time()
    local expiry = bucket[src] or 0
    if expiry > now then return true, expiry - now end
    bucket[src] = now + seconds
    return false, 0
end

if Config.Inventory == 'qb-inventory' then
    addItem = function(src, item, count, metadata)
        return exports['qb-inventory']:AddItem(src, item, count, nil, metadata)
    end

    removeItem = function(src, item, count)
        return exports['qb-inventory']:RemoveItem(src, item, count)
    end

    countItem = function(src, item)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData or not Player.PlayerData.items then return 0 end

        local total = 0
        for _, slotItem in pairs(Player.PlayerData.items) do
            if slotItem and slotItem.name == item then
                total = total + (slotItem.amount or 0)
            end
        end
        return total
    end

    canCarry = function(src, item, count)
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end

        local itemData = QBCore.Shared.Items[item]
        if not itemData then return true end

        local addWeight = (itemData.weight or 0) * count
        local currentWeight = Player.PlayerData.metadata['currentweight'] or 0
        local maxWeight = Player.PlayerData.metadata['maxweight'] or 120000
        return (currentWeight + addWeight) <= maxWeight
    end

    getContractItemMetadata = function(src)
        local item = exports['qb-inventory']:GetItemByName(src, Config.Items.chop_contract)
        if item and item.info and item.info.vehicles then
            return item.info, item.slot
        end
        return nil
    end
else
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

local function buildContractDescription(vehicles, completed)
    local lines, idx = {}, 1

    for _, v in ipairs(vehicles) do
        if not completed[v.model] then
            lines[#lines + 1] = ('[ ] %d. %s'):format(idx, v.label)
            idx = idx + 1
        end
    end

    if #lines == 0 then
        return t('contract_item_complete')
    end

    return table.concat(lines, '\n')
end

local function updateContractItemMetadata(src, metadata)
    local _, slot = getContractItemMetadata(src)
    if not slot then
        if Config.Debug then
            print(('[nb-chopshop] %s not found for source %s'):format(Config.Items.chop_contract, src))
        end
        return
    end

    metadata.description = buildContractDescription(metadata.vehicles, metadata.completed)
    if Config.Inventory == 'qb-inventory' then
        exports['qb-inventory']:SetMetadata(src, slot, metadata)
    else
        exports.ox_inventory:SetMetadata(src, slot, metadata)
    end
end

local function giveRandomMaterials(src)
    for _, reward in ipairs(Config.MaterialRewards) do
        if math.random(100) <= reward.chance then
            local count = math.random(reward.count.min, reward.count.max)
            if canCarry(src, reward.item, count) then
                addItem(src, reward.item, count)
            end
        end
    end
end

local function buildContract()
    local pool = {}
    for _, vehicle in ipairs(Config.ContractVehicles) do
        pool[#pool + 1] = vehicle
    end

    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local vehicles = {}
    local wantedCount = math.min(Config.Criminal.vehicleCount, #pool)
    for i = 1, wantedCount do
        vehicles[i] = pool[i]
    end
    return vehicles
end

local function isValidPart(partName, partItem)
    for _, part in ipairs(Config.StripParts) do
        if part.name == partName and part.item == partItem then
            return true
        end
    end
    return false
end

local function getContractPayload(contract)
    return {
        vehicles = contract.vehicles,
        completed = contract.completed or {},
    }
end

local function getRemainingContractVehicles(contract)
    local remaining = 0
    for _, vehicle in ipairs(contract.vehicles) do
        if not contract.completed[vehicle.model] then
            remaining = remaining + 1
        end
    end
    return remaining
end

RegisterNetEvent('nb-chopshop:server:GetContract', function()
    local src = source
    if not requireCriminal(src) then return end

    debugPrint('GetContract source=%s', src)

    if not debugOptionEnabled('ignorePolice') and getPoliceCount() < Config.Criminal.policeRequired then
        notify(src, t('not_enough_police', Config.Criminal.policeRequired), 'error')
        return
    elseif debugOptionEnabled('ignorePolice') then
        debugPrint('police requirement ignored source=%s required=%s', src, tostring(Config.Criminal.policeRequired))
    end

    local existing = contracts[src]
    if existing and existing.vehicles and getRemainingContractVehicles(existing) > 0 then
        notify(src, t('contract_already_active'), 'error')
        TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(existing))
        return
    end

    if not existing and countItem(src, Config.Items.chop_contract) > 0 then
        notify(src, t('contract_use_item_to_restore'), 'error')
        return
    end

    if not debugOptionEnabled('ignoreCooldown') then
        local blocked, remaining = hasCooldown(contractCooldowns, src, Config.Criminal.cooldown)
        if blocked then
            notify(src, t('contract_cooldown', remaining), 'error')
            return
        end
    else
        debugPrint('contract cooldown ignored source=%s', src)
    end

    local vehicles = buildContract()
    contracts[src] = { vehicles = vehicles, completed = {} }

    addItem(src, Config.Items.chop_contract, 1, {
        vehicles = vehicles,
        completed = {},
        description = buildContractDescription(vehicles, {}),
    })

    TriggerClientEvent('nb-chopshop:client:SetContractVehicles', src, getContractPayload(contracts[src]))
    TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(contracts[src]))
    notify(src, t('contract_received', #vehicles), 'success')
end)

RegisterNetEvent('nb-chopshop:server:ViewContract', function()
    local src = source
    if not requireCriminal(src) then return end

    local contract = contracts[src]
    debugPrint('ViewContract source=%s hasContract=%s', src, tostring(contract ~= nil))
    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end

    TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(contract))
end)

RegisterNetEvent('nb-chopshop:server:TurnInContract', function()
    local src = source
    if not requireCriminal(src) then return end

    debugPrint('TurnInContract source=%s', src)

    local contract = contracts[src]
    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end

    if getRemainingContractVehicles(contract) > 0 then
        notify(src, t('contract_incomplete'), 'error')
        TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(contract))
        return
    end

    local reward = math.random(Config.Criminal.minReward, Config.Criminal.maxReward)
    addItem(src, Config.Items.money, reward)
    giveRandomMaterials(src)
    removeItem(src, Config.Items.chop_contract, 1)
    contracts[src] = nil

    TriggerClientEvent('nb-chopshop:client:ClearContract', src)
    notify(src, t('contract_turned_in', reward), 'success')
end)

RegisterNetEvent('nb-chopshop:server:CheckContractVehicle', function(modelName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not isCriminal(src, player) then return end

    local contract = contracts[src]
    if not contract or not contract.vehicles or type(modelName) ~= 'string' then return end

    debugPrint('CheckContractVehicle source=%s model=%s', src, modelName)

    for _, vehicle in ipairs(contract.vehicles) do
        if vehicle.model:lower() == modelName:lower() and not contract.completed[vehicle.model] then
            TriggerClientEvent('nb-chopshop:client:ContractVehicleDetected', src, vehicle.label)
            return
        end
    end
end)

local function isVehicleValidForStrip(src, netId)
    if type(netId) ~= 'number' then return false end

    local contract = contracts[src]
    if not contract or not contract.vehicles then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not (entity and entity > 0 and DoesEntityExist(entity)) then return false end

    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(entity) or 0)
    if type(modelName) ~= 'string' then return false end
    modelName = modelName:lower()

    for _, vehicle in ipairs(contract.vehicles) do
        if vehicle.model:lower() == modelName and not contract.completed[vehicle.model] then
            return true
        end
    end

    return false
end

RegisterNetEvent('nb-chopshop:server:StripPart', function(netId, partName, partItem)
    local src = source
    if not requireCriminal(src) then return end

    debugPrint('StripPart source=%s netId=%s part=%s item=%s', src, tostring(netId), tostring(partName), tostring(partItem))

    if not isVehicleValidForStrip(src, netId) then
        notify(src, t('invalid_target_vehicle'), 'error')
        return
    end

    if not isValidPart(partName, partItem) then
        notify(src, t('invalid_part'), 'error')
        return
    end

    notify(src, t('part_stripped', t('part_' .. partName)), 'success')
end)

RegisterNetEvent('nb-chopshop:server:StripFrame', function(netId, modelName)
    local src = source
    if not requireCriminal(src) then return end

    debugPrint('StripFrame source=%s netId=%s model=%s', src, tostring(netId), tostring(modelName))

    if not isVehicleValidForStrip(src, netId) then
        notify(src, t('invalid_target_vehicle'), 'error')
        return
    end

    if type(modelName) ~= 'string' then modelName = '' end

    local scrapCount = math.random(Config.FrameStrip.scrapCount.min, Config.FrameStrip.scrapCount.max)
    if canCarry(src, Config.FrameStrip.scrapItem, scrapCount) then
        addItem(src, Config.FrameStrip.scrapItem, scrapCount)
    else
        notify(src, t('no_inventory_space'), 'error')
    end

    local contract = contracts[src]
    for _, vehicle in ipairs(contract.vehicles) do
        if vehicle.model:lower() == modelName:lower() and not contract.completed[vehicle.model] then
            contract.completed[vehicle.model] = true
            updateContractItemMetadata(src, getContractPayload(contract))

            local remaining = getRemainingContractVehicles(contract)
            TriggerClientEvent('nb-chopshop:client:SetContractVehicles', src, getContractPayload(contract))

            if remaining == 0 then
                notify(src, t('contract_all_done'), 'success')
            else
                notify(src, t('contract_vehicle_done', vehicle.label, remaining), 'success')
            end
            return
        end
    end

    notify(src, t('frame_stripped'), 'success')
end)

local function handleContractItemUse(src)
    if not requireCriminal(src) then return end

    debugPrint('ContractItemUse source=%s', src)

    local contract = contracts[src]
    if contract and contract.vehicles then
        TriggerClientEvent('nb-chopshop:client:SetContractVehicles', src, getContractPayload(contract))
        TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(contract))
        notify(src, t('contract_restored'), 'success')
        return
    end

    local metadata = getContractItemMetadata(src)
    if metadata then
        contracts[src] = {
            vehicles = metadata.vehicles,
            completed = metadata.completed or {},
        }
        contract = contracts[src]
    end

    if not contract or not contract.vehicles then
        notify(src, t('no_active_contract'), 'error')
        return
    end

    TriggerClientEvent('nb-chopshop:client:SetContractVehicles', src, getContractPayload(contract))
    TriggerClientEvent('nb-chopshop:client:ShowContract', src, getContractPayload(contract))
    notify(src, t('contract_restored'), 'success')
end

QBCore.Functions.CreateUseableItem(Config.Items.chop_contract, handleContractItemUse)

AddEventHandler('playerDropped', function()
    local src = source
    contracts[src] = nil
    contractCooldowns[src] = nil
end)
