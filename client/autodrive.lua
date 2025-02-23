local isAutoPilotActive = false

local function GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2)
    return #(vector3(x1, y1, z1) - vector3(x2, y2, z2))
end

local function DriveTo(coords)
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if not vehicle then
        lib.notify({
            title = 'Notification title',
            description = 'Notification description',
            type = 'success'
        })
    end

    isAutoPilotActive = true
    SendNUIEvent('autopilotStatus', true)

    Citizen.CreateThread(function() -- speed calculations
        while isAutoPilotActive do
            local remainingTime = 0
            local currentSpeed = 0
            local playerCoords = GetEntityCoords(vehicle)
            local distance = GetDistanceBetweenCoords(
                playerCoords.x, playerCoords.y, playerCoords.z,
                coords.x, coords.y, coords.z
            )

            if Config.Measurment == "kph" then
                currentSpeed = GetEntitySpeed(vehicle) * 3.6      -- kp/h
            else
                currentSpeed = GetEntitySpeed(vehicle) * 2.236936 -- mp/h
            end

            if currentSpeed > 5 then
                remainingTime = (distance / 1000) / (currentSpeed) * 3600
            end

            Citizen.Wait(1000)

            SendNUIEvent('updateTripTime', remainingTime)
        end
    end)

    Citizen.CreateThread(function()
        local playerCoords = GetEntityCoords(vehicle)
        local distance = GetDistanceBetweenCoords(
            playerCoords.x, playerCoords.y, playerCoords.z,
            coords.x, coords.y, coords.z
        )
        local speed = math.min(Config.SpeedLimit, distance * 2)
        local vehicleModel = GetEntityModel(vehicle)
        TaskVehicleDriveToCoord(
            player,
            vehicle,
            coords.x, coords.y, coords.z,
            speed,
            1.0,
            vehicleModel,
            786603,
            1.0,
            0.0
        )

        while isAutoPilotActive do
            if distance < Config.StoppingDistance then
                SetVehicleForwardSpeed(vehicle, 0.0)
                isAutoPilotActive = false
                TriggerEvent('chat:addMessage', {
                    args = { 'Autopilot', 'Destination reached.' }
                })
                break
            end



            Citizen.Wait(Config.UpdateInterval)
        end
        SendNUIEvent('autopilotStatus', false)
    end)
end

RegisterCommand('autopilot', function()
    local waypointBlip = GetFirstBlipInfoId(8) -- 8 is for waypoint blips

    if not DoesBlipExist(waypointBlip) then
        TriggerEvent('chat:addMessage', {
            args = { 'Autopilot', 'Please set a waypoint first.' }
        })
        return
    end

    local coords = GetBlipCoords(waypointBlip)
    DriveTo(coords)
end, false)

RegisterCommand('stopauto', function()
    if isAutoPilotActive then
        isAutoPilotActive = false
        SendNUIEvent('autopilotStatus', false)
        local player = PlayerPedId()
        ClearPedTasks(player)
        TriggerEvent('chat:addMessage', {
            args = { 'Autopilot', 'Autopilot disabled.' }
        })
    end
end, false)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        isAutoPilotActive = false
    end
end)
