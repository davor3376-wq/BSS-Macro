local World = {}

-- Botanist: Planter Automation
World.PlanterQueue = {}
World.IsPlanting = false
World.CurrentNectarGoal = "Satisfying" -- Default

-- Toys & Beesmas Automation
World.IsToyAuto = false
World.IsBeesmasAuto = false

-- Base Cooldowns (Seconds) + 30s Buffer
World.ToyCooldowns = {
    ["Wealth Clock"] = { Base = 3600, NextUse = 0 },
    ["Glue Dispenser"] = { Base = 79200, NextUse = 0 }, -- 22 hours
    ["Blue HQ"] = { Base = 14400, NextUse = 0 }, -- 4 hours
    ["Red HQ"] = { Base = 14400, NextUse = 0 }, -- 4 hours
    ["Samovar"] = { Base = 28800, NextUse = 0 }, -- 8 hours
    ["Feast"] = { Base = 3600, NextUse = 0 } -- 1 hour
}

-- Planter Priorities (Ordered by Growth Speed / Nectar Yield)
World.PlanterPriority = {
    "Petal Planter",
    "Tacky Planter",
    "Pesticide Planter",
    "Heat-Treated Planter",
    "Blue Clay Planter",
    "Red Clay Planter",
    "Candy Planter",
    "Paper Planter"
}

-- Nectar Field Mapping (from Manifest/Wiki)
-- This maps Nectar Type -> Best Fields
World.NectarMap = {
    ["Satisfying"] = {"Sunflower Field", "Pineapple Patch", "Pumpkin Patch"},
    ["Comforting"] = {"Bamboo Field", "Pine Tree Forest", "Dandelion Field"},
    ["Motivating"] = {"Blue Flower Field", "Mushroom Field", "Spider Field", "Rose Field"},
    ["Invigorating"] = {"Clover Field", "Cactus Field", "Mountain Top Field", "Pepper Patch"},
    ["Refreshing"] = {"Strawberry Field", "Coconut Field", "Blue Flower Field"}
}

function World.Init()
    print("World Module Initialized")

    -- Attempt to load Nectar Mapping and Toy Cooldowns from Manifest
    if _G.Aegis and _G.Aegis.Manifest then
         local manifest = _G.Aegis.Manifest

         -- Load Nectar Fields
         for nectarName, _ in pairs(World.NectarMap) do
             if manifest[nectarName] and type(manifest[nectarName]) == "table" then
                  local fields = {}
                  for _, v in pairs(manifest[nectarName]) do
                      if type(v) == "string" then table.insert(fields, v) end
                  end
                  if #fields > 0 then
                      World.NectarMap[nectarName] = fields
                  end
             end
         end

         -- Load Toy Cooldowns
         -- Assuming structure has a category for toys/utilities or iterating recursively
         for category, data in pairs(manifest) do
             if type(data) == "table" then
                 for toyName, timerInfo in pairs(World.ToyCooldowns) do
                      -- Check for Toy Data in this category
                      if data[toyName] and data[toyName].Cooldown then
                           local timeStr = data[toyName].Cooldown
                           -- Parse "X Hours" or "X Minutes"
                           local valStr = string.match(timeStr, "(%d+)")
                           if valStr then
                               local val = tonumber(valStr)
                               local multiplier = 1
                               local lowerStr = string.lower(timeStr)

                               if string.find(lowerStr, "hour") then multiplier = 3600
                               elseif string.find(lowerStr, "minute") then multiplier = 60 end

                               World.ToyCooldowns[toyName].Base = val * multiplier
                               print("World: Loaded Cooldown for " .. toyName .. " -> " .. (val * multiplier) .. "s")
                           end
                      end
                 end
             end
         end
    end

    task.spawn(World.PlanterLoop)
    task.spawn(World.ToyLoop)
end

function World.GetBestPlanterForNectar(nectarType)
    -- Check Inventory (Simulated)
    -- In a real script, iterate through game.Players.LocalPlayer.PlayerGui.ScreenGui.PlanterBuilder...
    -- For now, we assume the user has access to basic planters
    return "Paper Planter" -- Fallback
end

function World.PlacePlanter(nectarType)
    if not World.IsPlanting then return end

    local fields = World.NectarMap[nectarType]
    if not fields then return end

    -- Select random or first field for variety/simplicity
    local targetField = fields[math.random(1, #fields)]
    local planterName = World.GetBestPlanterForNectar(nectarType)

    print("Botanist: Placing " .. planterName .. " in " .. targetField .. " for " .. nectarType .. " Nectar.")

    -- Handle Farming Conflict
    local Actuator = _G.Aegis.Actuator
    local wasFarming = false
    local currentField = nil

    if Actuator and Actuator.IsFarming then
        wasFarming = true
        currentField = Actuator.CurrentField
        Actuator.StopFarming()
        task.wait(0.5) -- Allow loop to stop
    end

    -- Move to Field
    if Actuator then
        Actuator.MoveTo(Actuator.Fields[targetField]) -- Direct move, not farming
        task.wait(1)
    end

    -- Place Planter (Simulated Interact)
    -- This requires firing a RemoteEvent or interacting with a ProximityPrompt
    -- game.ReplicatedStorage.Events.PlayerActivesCommand:FireServer({["Name"] = planterName})
    print("Botanist: Planter Placed.")

    -- Resume Farming
    if wasFarming and currentField then
        print("Botanist: Resuming Farming in " .. currentField)
        Actuator.StartFarming(currentField)
    end
end

function World.PlanterLoop()
    while true do
        if World.IsPlanting then
            World.PlacePlanter(World.CurrentNectarGoal)
            -- Wait for growth cycle (e.g., 1 hour, or check game state)
            task.wait(3600)
        end
        task.wait(10)
    end
end

-- Toy Interaction Logic
function World.VisitToy(toyName)
    local Actuator = _G.Aegis.Actuator
    local targetPos = Actuator.Utilities[toyName]

    if not targetPos then
        print("World: Toy location not found for " .. toyName)
        return
    end

    print("World: Visiting " .. toyName)

    -- Handle Farming Conflict
    local wasFarming = false
    local currentField = nil

    if Actuator and Actuator.IsFarming then
        wasFarming = true
        currentField = Actuator.CurrentField
        Actuator.StopFarming()
        task.wait(0.5) -- Allow loop to stop
    end

    -- Move to Toy
    Actuator.MoveTo(targetPos)
    task.wait(1)

    -- Interaction: Fire ProximityPrompt or TouchInterest
    local interacted = false
    local radius = 15
    local character = game.Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if rootPart then
        -- Check for ProximityPrompts
        for _, obj in ipairs(workspace:GetDescendants()) do
             if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") then
                 if (obj.Parent.Position - rootPart.Position).Magnitude < radius then
                     fireproximityprompt(obj)
                     interacted = true
                     print("World: Fired ProximityPrompt for " .. toyName)
                     break
                 end
             end
        end
    end

    -- Fallback: Wait to simulate interaction (TouchInterest usually triggers on collision)
    if not interacted then
        task.wait(2)
    end

    -- Update Cooldown
    if World.ToyCooldowns[toyName] then
        World.ToyCooldowns[toyName].NextUse = tick() + World.ToyCooldowns[toyName].Base + 30
    end

    -- Report via Webhook
    if _G.Aegis.SendWebhook then
        local leaderstats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
        local honey = leaderstats and leaderstats:FindFirstChild("Honey")
        local honeyVal = honey and honey.Value or "Unknown"

        -- Get Quest Progress
        local quests = _G.Aegis.Pathfinder.GetActiveQuests()
        local questInfo = ""
        if #quests > 0 then
            questInfo = "\nActive Quest: " .. quests[1].Name .. " (" .. quests[1].Progress .. ")"
        end

        _G.Aegis.SendWebhook("Visited Toy: " .. toyName .. "\nHoney: " .. tostring(honeyVal) .. questInfo)
    end

    -- Resume Farming
    if wasFarming and currentField then
        print("World: Resuming Farming in " .. currentField)
        Actuator.StartFarming(currentField)
    end
end

function World.ToyLoop()
    while true do
        local now = tick()

        -- Standard Toys
        if World.IsToyAuto then
            for _, toyName in ipairs({"Wealth Clock", "Glue Dispenser", "Blue HQ", "Red HQ"}) do
                 if World.ToyCooldowns[toyName] and now >= World.ToyCooldowns[toyName].NextUse then
                      World.VisitToy(toyName)
                 end
            end
        end

        -- Beesmas Toys
        if World.IsBeesmasAuto then
             for _, toyName in ipairs({"Samovar", "Feast"}) do
                 if World.ToyCooldowns[toyName] and now >= World.ToyCooldowns[toyName].NextUse then
                      World.VisitToy(toyName)
                 end
             end
        end

        task.wait(5)
    end
end

function World.Interact(interactableName)
    print("Interacting with: " .. interactableName)
    -- Add logic to interact with objects (e.g., dispensers, bees)
end

return World
