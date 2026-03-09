local QBCore = exports['qb-core']:GetCoreObject()

local state = {
    npc = nil,
    missionActive = false,
    missionVehicle = nil,
    missionPlate = nil,
    targetBlip = nil,
    dropoffBlip = nil,
    decryptStarted = false,
    decryptDone = false,
    decryptEndTime = 0,
    lastMinuteCallout = nil,
    pingThreadRunning = false
}

local function t(key, ...)
    local lang = Config.Text[Config.Locale] or Config.Text.sv
    local text = (lang and lang[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

local function notify(msg, nType)
    lib.notify({ title = 'Car Heist', description = msg, type = nType or 'inform' })
end

local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(10)
        timeout += 10
    end
    return HasModelLoaded(model)
end

local function clearMissionBlips()
    if state.targetBlip and DoesBlipExist(state.targetBlip) then RemoveBlip(state.targetBlip) end
    if state.dropoffBlip and DoesBlipExist(state.dropoffBlip) then RemoveBlip(state.dropoffBlip) end
    state.targetBlip = nil
    state.dropoffBlip = nil
end

local function resetMission()
    state.missionActive = false
    state.decryptStarted = false
    state.decryptDone = false
    state.decryptEndTime = 0
    state.lastMinuteCallout = nil
    state.pingThreadRunning = false
    state.missionPlate = nil

    if state.missionVehicle and DoesEntityExist(state.missionVehicle) then
        exports.ox_target:removeLocalEntity(state.missionVehicle, { 'carheist_hack' })
        SetEntityAsMissionEntity(state.missionVehicle, true, true)
        DeleteEntity(state.missionVehicle)
    end

    state.missionVehicle = nil
    clearMissionBlips()
end

local function createMissionVehicle(model, spawn, plate)
    if not loadModel(model) then return nil end

    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleDirtLevel(veh, 3.0)

    SetModelAsNoLongerNeeded(model)
    return veh
end

local function startDecryptSequence()
    if state.decryptStarted or not state.missionVehicle then return end

    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= state.missionVehicle or GetPedInVehicleSeat(state.missionVehicle, -1) ~= ped then
        return
    end

    local passed = lib.skillCheck({ 'easy', 'medium', 'medium' }, { 'w', 'a', 's', 'd' })
    if not passed then
        notify(t('hack_failed'), 'error')
        return
    end

    local ok = lib.progressCircle({
        duration = 8000,
        label = t('hack_start'),
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })

    if not ok then
        notify(t('hack_failed'), 'error')
        return
    end

    SetVehicleDoorsLocked(state.missionVehicle, 1)
    SetVehicleEngineOn(state.missionVehicle, true, true, false)

    state.decryptStarted = true
    state.decryptEndTime = GetGameTimer() + (Config.DecryptSeconds * 1000)

    state.dropoffBlip = AddBlipForCoord(Config.PoliceDropoff.x, Config.PoliceDropoff.y, Config.PoliceDropoff.z)
    SetBlipSprite(state.dropoffBlip, 60)
    SetBlipScale(state.dropoffBlip, 0.9)
    SetBlipColour(state.dropoffBlip, 3)
    SetBlipRoute(state.dropoffBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Leveransplats')
    EndTextCommandSetBlipName(state.dropoffBlip)

    notify(t('decrypt_started'), 'success')
end

RegisterNetEvent('interactive_carheist:client:startMission', function(data)
    if state.missionActive then
        notify(t('mission_already'), 'error')
        return
    end

    local veh = createMissionVehicle(data.model, data.spawn, data.plate)
    if not veh then
        notify('Kunde inte skapa målbilen.', 'error')
        return
    end

    state.missionActive = true
    state.missionVehicle = veh
    state.missionPlate = data.plate

    state.targetBlip = AddBlipForCoord(data.spawn.x, data.spawn.y, data.spawn.z)
    SetBlipSprite(state.targetBlip, 225)
    SetBlipColour(state.targetBlip, 1)
    SetBlipScale(state.targetBlip, 0.9)
    SetBlipRoute(state.targetBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Målbil')
    EndTextCommandSetBlipName(state.targetBlip)

    exports.ox_target:addLocalEntity(veh, {
        {
            name = 'carheist_hack',
            label = 'Koppla in dekrypterare',
            icon = 'fa-solid fa-laptop-code',
            distance = 2.5,
            canInteract = function(entity)
                return entity == state.missionVehicle and not state.decryptStarted
            end,
            onSelect = function()
                startDecryptSequence()
            end
        }
    })

    notify(t('mission_started'), 'success')
    notify(t('vehicle_marked'), 'inform')
end)

RegisterNetEvent('interactive_carheist:client:policePing', function(coords)
    local myJob = QBCore.Functions.GetPlayerData().job
    if not myJob or myJob.name ~= 'police' then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Stulen bil - GPS')
    EndTextCommandSetBlipName(blip)
    notify(t('police_ping'), 'error')

    SetTimeout(Config.PoliceBlipDuration * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

CreateThread(function()
    local npcData = Config.MissionGiver
    if not loadModel(npcData.model) then return end

    local npc = CreatePed(0, npcData.model, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStartScenarioInPlace(npc, npcData.scenario, 0, true)
    state.npc = npc

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'carheist_talk_npc',
            label = t('npc_target'),
            icon = 'fa-solid fa-user-secret',
            distance = 2.0,
            onSelect = function()
                lib.registerContext({
                    id = 'carheist_npc_menu',
                    title = t('menu_title'),
                    options = {
                        {
                            title = t('menu_accept'),
                            description = t('menu_desc'),
                            icon = 'check',
                            onSelect = function()
                                TriggerServerEvent('interactive_carheist:server:requestMission')
                            end
                        },
                        {
                            title = t('menu_cancel'),
                            icon = 'xmark'
                        }
                    }
                })
                lib.showContext('carheist_npc_menu')
            end
        }
    })
end)

CreateThread(function()
    while true do
        Wait(1000)
        if not state.missionActive or not state.missionVehicle or not DoesEntityExist(state.missionVehicle) then
            goto continue
        end

        local ped = PlayerPedId()
        local inVeh = GetVehiclePedIsIn(ped, false) == state.missionVehicle

        if inVeh and not state.decryptStarted then
            startDecryptSequence()
        end

        if state.decryptStarted and not state.decryptDone then
            local timeLeft = math.max(0, state.decryptEndTime - GetGameTimer())
            if timeLeft <= 0 then
                state.decryptDone = true
                notify(t('decrypt_done'), 'success')
            else
                local mins = math.ceil(timeLeft / 60000)
                if mins ~= state.lastMinuteCallout then
                    state.lastMinuteCallout = mins
                    notify(t('decrypt_tick', mins), 'inform')
                end
            end
        end

        if state.decryptDone and inVeh then
            local coords = GetEntityCoords(ped)
            local dist = #(coords - Config.PoliceDropoff)
            if dist < 12.0 then
                lib.showTextUI(t('deliver_hint'))
                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI()
                    TriggerServerEvent('interactive_carheist:server:completeMission', state.missionPlate)
                end
            else
                lib.hideTextUI()
            end
        else
            lib.hideTextUI()
        end

        ::continue::
    end
end)

CreateThread(function()
    while true do
        Wait(Config.PolicePingInterval * 1000)
        if not state.missionActive or not state.decryptStarted or state.decryptDone then
            goto continue
        end

        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) ~= state.missionVehicle then
            goto continue
        end

        local speed = GetEntitySpeed(state.missionVehicle)
        if speed > 3.0 then
            local coords = GetEntityCoords(state.missionVehicle)
            TriggerServerEvent('interactive_carheist:server:sendPolicePing', { x = coords.x, y = coords.y, z = coords.z })
        end

        ::continue::
    end
end)

RegisterNetEvent('interactive_carheist:client:missionCompleted', function()
    notify(t('mission_complete'), 'success')
    resetMission()
end)

RegisterNetEvent('interactive_carheist:client:notify', function(msg, nType)
    notify(msg, nType)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lib.hideTextUI()
    clearMissionBlips()
    if state.npc and DoesEntityExist(state.npc) then
        DeleteEntity(state.npc)
    end
    if state.missionVehicle and DoesEntityExist(state.missionVehicle) then
        DeleteEntity(state.missionVehicle)
    end
end)
