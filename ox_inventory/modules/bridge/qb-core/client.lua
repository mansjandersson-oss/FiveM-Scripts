local QBCore = exports['qb-core']:GetCoreObject()

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerData(key, value)
	PlayerData[key] = value
	QBCore.Functions.SetPlayerData(key, value)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	local playerData = QBCore.Functions.GetPlayerData()

	PlayerData.groups = { [playerData.job.name] = playerData.job.grade.level }
	-- QBCore gender: 0 = male, 1 = female.  ox_inventory sex: 1 = male, 0 = female.
	PlayerData.sex = playerData.charinfo.gender == 0 and 1 or 0
	PlayerData.dateofbirth = playerData.charinfo.birthdate
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', client.onLogout)

AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
	if not PlayerData.loaded then return end

	PlayerData.groups = { [job.name] = job.grade.level }
	OnPlayerData('groups', PlayerData.groups)
end)
