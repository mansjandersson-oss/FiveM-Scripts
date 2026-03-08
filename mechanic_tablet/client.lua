local isOpen = false

local function setTabletVisible(visible)
    isOpen = visible
    SetNuiFocus(visible, visible)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'setVisible',
        visible = visible
    })
end

exports('useMechanicTablet', function()
    if isOpen then
        return setTabletVisible(false)
    end

    setTabletVisible(true)
end)

RegisterNUICallback('closeTablet', function(_, cb)
    setTabletVisible(false)
    cb(1)
end)

RegisterCommand('stangmekplatta', function()
    if not isOpen then return end
    setTabletVisible(false)
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if isOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)
