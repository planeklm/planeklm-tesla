local updateInterval = 250
local detectionInterval = 500
local interval = 500
local isInVehicle = false
local lastSpeed = 0
local carAhead = false

local function toggleUI(bool)
    --SetNuiFocus(bool, bool) -- for debug
    SendNUIEvent(Send.visible, bool)
    SendNUIEvent("setMenuVisible", bool)
end

RegisterNUICallback("hideUI", function()
    toggleUI(false)
end)

local function getVehicleSpeed(veh)
    local speed = GetEntitySpeed(veh)
    if Config.Measurment == "kph" then
        return math.floor(speed * 3.6)      -- kp/h
    else
        return math.floor(speed * 2.236936) -- mp/h
    end
end

Citizen.CreateThread(function()
    local playerPed = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(playerPed, false)
    local nextBlinkerUpdate = 0
    local nextGearUpdate = 0
    local nextBatteryUpdate = 0
    local blinkerState = 0
    local gearState = 0
    local batteryState = 0

    while true do
        if inVehicle then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local curTime = GetGameTimer()

            -- battery updates
            if curTime > nextBatteryUpdate then
                local newBatteryState = GetVehicleFuelLevel(vehicle)
                if newBatteryState ~= batteryState then
                    batteryState = newBatteryState
                    SendNUIEvent("updateBattery", { math.floor(GetVehicleFuelLevel(vehicle)) })
                end
                nextBatteryUpdate = curTime + interval
            end

            -- gear updates
            if curTime > nextGearUpdate then
                local newGearState = GetVehicleCurrentGear(vehicle)
                if newGearState ~= gearState then
                    gearState = newGearState
                    SendNUIEvent("updateGears", { GetVehicleCurrentGear(vehicle) })
                end
                nextGearUpdate = curTime + interval
            end

            -- blinker updates
            if curTime > nextBlinkerUpdate then
                local newBlinkerState = GetVehicleIndicatorLights(vehicle)
                if newBlinkerState ~= blinkerState then
                    blinkerState = newBlinkerState
                    print(GetVehicleIndicatorLights(vehicle))
                    SendNUIEvent("updateBlinkers", { GetVehicleIndicatorLights(vehicle) })
                end
                nextBlinkerUpdate = curTime + interval
            end
            Citizen.Wait(100)
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    local nextSpeedUpdate = 0
    local nextDetectionUpdate = 0

    while true do
        local wait = 1000
        local currentTime = GetGameTimer()
        local playerPed = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(playerPed, false)

        if inVehicle ~= isInVehicle then
            isInVehicle = inVehicle
            toggleUI(isInVehicle)
        end

        if isInVehicle then
            wait = updateInterval
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if currentTime > nextSpeedUpdate then
                local currentSpeed = getVehicleSpeed(vehicle)

                if currentSpeed ~= lastSpeed then
                    lastSpeed = currentSpeed
                    SendNUIEvent("updateSpeed", currentSpeed)
                end

                nextSpeedUpdate = currentTime + updateInterval
            end

            if currentTime > nextDetectionUpdate then
                local coords = GetEntityCoords(vehicle)
                local forwardVector = GetEntityForwardVector(vehicle)
                local distanceToCheck = Config.DetectionLength

                local startOffset = coords + (forwardVector * 2.0)
                local endOffset = coords + (forwardVector * distanceToCheck)

                local rayHandle = StartShapeTestCapsule(
                    startOffset.x, startOffset.y, startOffset.z,
                    endOffset.x, endOffset.y, endOffset.z,
                    1.0, 10, vehicle, 4
                )

                local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
                local isCarAhead = (hit == 1 and GetEntityType(entityHit) == 2)

                if isCarAhead ~= carAhead then
                    carAhead = isCarAhead
                    SendNUIEvent("setCarAheadVisible", carAhead)
                end

                nextDetectionUpdate = currentTime + detectionInterval
            end
        else
            if lastSpeed ~= 0 then lastSpeed = 0 end
            if carAhead then carAhead = false end
        end

        Citizen.Wait(wait)
    end
end)
