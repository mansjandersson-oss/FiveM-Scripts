local Inventory = require 'modules.inventory.server'

local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Server:PlayerDropped', server.playerDropped)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
	local inventory = Inventory(source)
	if not inventory then return end

	for name in pairs(inventory.player.groups) do
		inventory.player.groups[name] = nil
	end

	inventory.player.groups[job.name] = job.grade.level
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(source, player, isNew)
	server.setPlayerInventory({
		source = source,
		identifier = player.PlayerData.citizenid,
		name = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
		groups = { [player.PlayerData.job.name] = player.PlayerData.job.grade.level },
		-- QBCore gender: 0 = male, 1 = female.  ox_inventory sex: 1 = male, 0 = female.
		sex = player.PlayerData.charinfo.gender == 0 and 1 or 0,
		dateofbirth = player.PlayerData.charinfo.birthdate,
	})
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
	local groups = {}

	if player.job then
		groups[player.job.name] = player.job.grade and player.job.grade.level or 0
	elseif player.groups then
		groups = player.groups
	end

	return {
		source = player.source,
		name = player.name,
		groups = groups,
		sex = player.sex,
		dateofbirth = player.dateofbirth,
	}
end

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
	-- QBCore does not use a shared account/weight system natively;
	-- trigger a client event so QB-side scripts can react if needed.
	TriggerClientEvent('ox_inventory:qb:syncInventory', inv.id, inv.weight, inv.maxWeight)
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId)
	local player = QBCore.Functions.GetPlayer(playerId)
	return player and player.PlayerData.job.isboss or false
end

-- Load inventories for any players already connected when the resource starts.
for _, playerId in ipairs(GetPlayers()) do
	local player = QBCore.Functions.GetPlayer(tonumber(playerId))

	if player then
		server.setPlayerInventory({
			source = tonumber(playerId),
			identifier = player.PlayerData.citizenid,
			name = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
			groups = { [player.PlayerData.job.name] = player.PlayerData.job.grade.level },
			-- QBCore gender: 0 = male, 1 = female.  ox_inventory sex: 1 = male, 0 = female.
			sex = player.PlayerData.charinfo.gender == 0 and 1 or 0,
			dateofbirth = player.PlayerData.charinfo.birthdate,
		})
	end
end
