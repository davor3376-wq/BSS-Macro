local Actuator = {}

Actuator.MovementType = "Walk" -- Options: "Walk", "Tween"
Actuator.FarmingPattern = "Circular" -- Options: "Circular", "S-Pattern"
Actuator.FarmingRadius = 15
Actuator.PatternWidth = 30
Actuator.PatternLength = 30
Actuator.CurrentField = nil
Actuator.IsFarming = false

-- Coordinate Registry
Actuator.Fields = {
    ["Sunflower Field"] = Vector3.new(-212.53, 3.97, 170.00),
    ["Dandelion Field"] = Vector3.new(-40.38, 3.97, 218.76),
    ["Mushroom Field"] = Vector3.new(-92.92, 3.97, 115.72),
    ["Blue Flower Field"] = Vector3.new(153.60, 3.97, 98.12),
    ["Clover Field"] = Vector3.new(151, 33.47, 198.69),
    ["Spider Field"] = Vector3.new(-43.76, 19.97, -4.11),
    ["Bamboo Field"] = Vector3.new(132.39, 19.97, -24.32),
    ["Strawberry Field"] = Vector3.new(-182.93, 19.97, -15.73),
    ["Pineapple Patch"] = Vector3.new(255.21, 67.97, -206.35),
    ["Stump Field"] = Vector3.new(422.69, 95.95, -174.36),
    ["Cactus Field"] = Vector3.new(-193.24, 67.97, -101.94),
    ["Pumpkin Patch"] = Vector3.new(-189.57, 67.97, -185.54),
    ["Pine Tree Forest"] = Vector3.new(-326.85, 67.97, -188.41),
    ["Rose Field"] = Vector3.new(-328.45, 19.92, 129.96),
    ["Mountain Top Field"] = Vector3.new(78.28, 175.97, -172.09),
    ["Coconut Field"] = Vector3.new(-263.03, 71.42, 466.07),
    ["Pepper Patch"] = Vector3.new(-491.53, 123.18, 530.59)
}

Actuator.NPCs = {
    ["Black Bear"] = Vector3.new(-255.01, 5, 298.17),
    ["Mother Bear"] = Vector3.new(-177.80, 5.14, 88.34),
    ["Science Bear"] = Vector3.new(268.41, 102.64, 21.14),
    ["Panda Bear"] = Vector3.new(103.24, 35.36, 47.14),
    ["Brown Bear"] = Vector3.new(280.95, 45.62, 235.66),
    ["Bee Bear"] = Vector3.new(-46.41, 4.34, 288.89),
    ["Polar Bear"] = Vector3.new(-106.95, 119.05, -77.71),
    ["Onett"] = Vector3.new(-11.03, 232.29, -520.63),
    ["Spirit Bear"] = Vector3.new(-365.66, 97.88, 478.18),
    ["Dapper Bear"] = Vector3.new(552.21, 142.06, -362.28),
    ["Riley Bee"] = Vector3.new(-360.39, 73.25, 213.91),
    ["Bucko Bee"] = Vector3.new(306.68, 61.43, 105.06),
    ["Honey Bee"] = Vector3.new(-387, 89.27, -220.53)
}

Actuator.Utilities = {
    ["Hive Hub"] = Vector3.new(-185.91, 5.91, 331.49),
    ["Blue HQ"] = Vector3.new(245.19, 4.47, 98.81),
    ["Red HQ"] = Vector3.new(-281.21, 20.24, 215.89),
    ["Honey Dispenser"] = Vector3.new(49.31, 5.57, 324.17),
    ["Coconut Dispenser"] = Vector3.new(-177.87, 73.07, 531.91),
    ["Glue Dispenser"] = Vector3.new(268, 33, 200),
    ["Wind Shrine"] = Vector3.new(-482.06, 141.48, 411.94),
    ["Wealth Clock"] = Vector3.new(330.54, 48.19, 192.04),
    ["Ant Challenge"] = Vector3.new(91.39, 32.77, 543.46),
    ["Stick Bug"] = Vector3.new(-129.07, 49.57, 149.07)
}

-- Collectibles Scanner (Weighted Loop)
function Actuator.GetBestToken()
    local bestToken = nil
    local highestScore = 0
    local character = game.Players.LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    -- Assuming Collectibles are in workspace.Collectibles (Standard BSS)
    -- Fallback to workspace if folder doesn't exist (some private servers vary)
    local container = workspace:FindFirstChild("Collectibles") or workspace

    for _, token in ipairs(container:GetChildren()) do
        -- Simple check if it's a token (usually has a decal or specific name)
        -- In a real scenario, check token.Name or attributes
        if token:IsA("BasePart") and (token.Position - rootPart.Position).Magnitude < 60 then
             local score = 1 -- Default Common

             -- Priority Scoring
             if string.find(token.Name, "Mythic") or string.find(token.Name, "Event") then
                 score = 1000
             elseif string.find(token.Name, "Legendary") or string.find(token.Name, "Precise") or string.find(token.Name, "Tadpole") then
                 score = 500
             elseif string.find(token.Name, "Epic") or string.find(token.Name, "Gumdrops") then
                 score = 100
             elseif string.find(token.Name, "Token") then -- Basic tokens
                 score = 1
             end

             if score > highestScore then
                 highestScore = score
                 bestToken = token
             end
        end
    end
    return bestToken
end

-- Movement Engine
function Actuator.MoveTo(targetPosition)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    if Actuator.MovementType == "Tween" then
        local TweenService = game:GetService("TweenService")
        local distance = (humanoidRootPart.Position - targetPosition).Magnitude
        local speed = 60 -- Studs per second
        local time = distance / speed

        local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
        tween:Play()
        tween.Completed:Wait()
    elseif Actuator.MovementType == "Walk" then
        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait()
    end
end

-- Farming Engine
function Actuator.StartFarming(fieldName)
    local center = Actuator.Fields[fieldName]
    if not center then
        print("Field not found: " .. tostring(fieldName))
        return
    end

    Actuator.CurrentField = fieldName
    Actuator.IsFarming = true

    -- Move to field center first
    Actuator.MoveTo(center)

    task.spawn(function()
        local angle = 0
        while Actuator.IsFarming do
            -- 1. Check for High-Value Tokens
            local bestToken = Actuator.GetBestToken()
            if bestToken then
                Actuator.MoveTo(bestToken.Position)
            else
                -- 2. Execute Farming Pattern
                local targetPos = center

                if Actuator.FarmingPattern == "Circular" then
                    local x = math.cos(math.rad(angle)) * Actuator.FarmingRadius
                    local z = math.sin(math.rad(angle)) * Actuator.FarmingRadius
                    targetPos = center + Vector3.new(x, 0, z)
                    angle = (angle + 15) % 360
                elseif Actuator.FarmingPattern == "S-Pattern" then
                     -- Simple zigzag implementation
                     local t = tick() % 10
                     local xOffset = (t/5 - 1) * Actuator.PatternWidth -- Oscillates -Width to +Width
                     local zOffset = math.sin(t) * Actuator.PatternLength
                     targetPos = center + Vector3.new(xOffset, 0, zOffset)
                end

                Actuator.MoveTo(targetPos)
            end
            task.wait(0.1)
        end
    end)
end

function Actuator.StopFarming()
    Actuator.IsFarming = false
end

function Actuator.Init()
    print("Actuator Module Initialized")
end

return Actuator
