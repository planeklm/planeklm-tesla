Config = {
    -- Compatibility Settings
    --Framework = "ox_lib", -- 'ox_lib' or 'qb' or 'esx'
    Measurment = "kph", -- 'kph' or 'mph'

    -- HUD Settings
    DetectionLength = 40.0, -- the distance to detect a car

    -- Auto Pilot Settings
    SpeedLimit = 30.0,      -- the maximum speed in mph
    StoppingDistance = 5.0, -- the distance to start slowing down
    UpdateInterval = 100,   -- how often to update pathfinding (ms)
}
