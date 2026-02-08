local World = {}

-- Botanist: Planter Automation
World.PlanterQueue = {}
World.IsPlanting = false
World.CurrentNectarGoal = "Satisfying" -- Default

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

    -- Attempt to load Nectar Mapping from Manifest
    if _G.Aegis and _G.Aegis.Manifest then
         local manifest = _G.Aegis.Manifest
         -- Assuming Manifest structure has a "Nectar" or "Fields" category
         -- Example: manifest["Satisfying"] = { "Sunflower Field", ... }
         for nectarName, _ in pairs(World.NectarMap) do
             if manifest[nectarName] and type(manifest[nectarName]) == "table" then
                  -- If Manifest directly lists fields for the nectar
                  local fields = {}
                  for _, v in pairs(manifest[nectarName]) do
                      if type(v) == "string" then table.insert(fields, v) end
                  end
                  if #fields > 0 then
                      World.NectarMap[nectarName] = fields
                      print("Botanist: Loaded Fields for " .. nectarName)
                  end
             end
         end
    end

    task.spawn(World.PlanterLoop)
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

    -- Move to Field
    if _G.Aegis.Actuator then
        _G.Aegis.Actuator.StartFarming(targetField) -- Move to field
        task.wait(2) -- Wait for arrival
        _G.Aegis.Actuator.StopFarming()
    end

    -- Place Planter (Simulated Interact)
    -- This requires firing a RemoteEvent or interacting with a ProximityPrompt
    -- game.ReplicatedStorage.Events.PlayerActivesCommand:FireServer({["Name"] = planterName})
    print("Botanist: Planter Placed.")
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

function World.Interact(interactableName)
    print("Interacting with: " .. interactableName)
    -- Add logic to interact with objects (e.g., dispensers, bees)
end

return World
