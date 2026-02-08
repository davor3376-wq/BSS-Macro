local Slayer = {}

Slayer.IsFarmingBoss = false
Slayer.BossTimers = {
    ["King Beetle"] = { Cooldown = 86400, NextSpawn = 0 }, -- 24 hours
    ["Tunnel Bear"] = { Cooldown = 172800, NextSpawn = 0 }, -- 48 hours
    ["Coconut Crab"] = { Cooldown = 129600, NextSpawn = 0 } -- 36 hours
}

-- Registry of Boss Locations
Slayer.BossLocations = {
    ["King Beetle"] = Vector3.new(200, 5, 150), -- Placeholder
    ["Tunnel Bear"] = Vector3.new(300, 5, -50), -- Placeholder
    ["Coconut Crab"] = Vector3.new(-263.03, 71.42, 466.07) -- Coconut Field Center
}

-- Boss State Tracking
Slayer.BossState = {
    ["King Beetle"] = false, -- false = Dead/Missing, true = Alive
    ["Tunnel Bear"] = false,
    ["Coconut Crab"] = false
}

function Slayer.Init()
    print("Slayer Module Initialized")

    -- Attempt to load timers from Manifest
    if _G.Aegis and _G.Aegis.Manifest then
         local manifest = _G.Aegis.Manifest
         -- Example path: Check "Mobs" or "Timers" category (Assuming structure based on prompt)
         -- Since JSON structure is complex, we iterate to find matching keys
         for category, data in pairs(manifest) do
             if type(data) == "table" then
                 for bossName, timerInfo in pairs(Slayer.BossTimers) do
                      -- Look for boss data in manifest
                      if data[bossName] and data[bossName].RespawnTime then
                           -- Parse time string (e.g., "24 Hours") to seconds
                           local timeStr = data[bossName].RespawnTime
                           local hours = tonumber(string.match(timeStr, "(%d+)"))
                           if hours then
                               Slayer.BossTimers[bossName].Cooldown = hours * 3600
                               print("Slayer: Loaded Cooldown for " .. bossName .. " -> " .. (hours * 3600) .. "s")
                           end
                      end
                 end
             end
         end
    end

    task.spawn(Slayer.MonitorBosses)
end

-- Monitor Boss Spawns and Kills
function Slayer.MonitorBosses()
    while true do
        local monstersFolder = workspace:FindFirstChild("Monsters")
        if monstersFolder then
            for bossName, timerData in pairs(Slayer.BossTimers) do
                local bossModel = monstersFolder:FindFirstChild(bossName)
                local wasAlive = Slayer.BossState[bossName]

                if bossModel then
                    -- Boss Found: Update state to Alive
                    Slayer.BossState[bossName] = true

                    if Slayer.IsFarmingBoss and bossName == "Coconut Crab" then
                        Slayer.FightCrab(bossModel)
                    end
                else
                    -- Boss Missing
                    if wasAlive then
                         -- Transition: Alive -> Dead
                         -- Trigger Kill Logic
                         Slayer.OnBossKilled(bossName)
                         Slayer.BossState[bossName] = false
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- Triggered when a boss is killed
function Slayer.OnBossKilled(bossName)
    local timerData = Slayer.BossTimers[bossName]
    if timerData then
        timerData.NextSpawn = tick() + timerData.Cooldown

        -- Send Webhook Notification
        if _G.Aegis and _G.Aegis.SendWebhook then
            local leaderstats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
            local honey = leaderstats and leaderstats:FindFirstChild("Honey")
            local honeyVal = honey and honey.Value or "Unknown"

            -- Get Quest Progress
            local questInfo = ""
            if _G.Aegis.Pathfinder then
                local quests = _G.Aegis.Pathfinder.GetActiveQuests()
                if #quests > 0 then
                    questInfo = "\nActive Quest: " .. quests[1].Name .. " (" .. quests[1].Progress .. ")"
                end
            end

            _G.Aegis.SendWebhook("Boss Defeated: " .. bossName .. "\nCurrent Honey: " .. tostring(honeyVal) .. questInfo)
        end
        print("Boss Killed: " .. bossName .. ". Respawn in " .. timerData.Cooldown .. "s")
    end
end

-- Coconut Crab Logic
function Slayer.FightCrab(crabModel)
    local Actuator = _G.Aegis.Actuator
    local crabRoot = crabModel:FindFirstChild("HumanoidRootPart") or crabModel:FindFirstChild("Torso")
    if not crabRoot then return end

    local fieldCenter = Slayer.BossLocations["Coconut Crab"]
    local crabPos = crabRoot.Position
    local playerPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position

    -- Distance Check
    local dist = (playerPos - crabPos).Magnitude
    if dist < 15 then
        -- Too close! Dodge!
        Slayer.DynamicDodge(crabPos, fieldCenter)
    else
        -- Attack/Chase logic (move within range but safe)
        -- Placeholder: Face the crab
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.lookAt(playerPos, crabPos)
    end
end

-- Dynamic Dodge: Calculates a safe spot opposite to the crab relative to field center
function Slayer.DynamicDodge(crabPos, fieldCenter)
    local Actuator = _G.Aegis.Actuator

    -- Vector from Crab to Center
    local vecToCenter = (fieldCenter - crabPos).Unit
    -- Safe spot is further away from the crab, through the center
    local safeSpot = fieldCenter + (vecToCenter * 30) -- 30 studs past center

    Actuator.MoveTo(safeSpot)
end

return Slayer
