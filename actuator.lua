local Actuator = {}

Actuator.MovementType = "Walk" -- Options: "Walk", "Tween"

-- Placeholder Vector3 coordinates for Fields
-- These need to be updated with actual game coordinates
Actuator.Fields = {
    ["Sunflower Field"] = Vector3.new(0, 0, 0),
    ["Dandelion Field"] = Vector3.new(0, 0, 0),
    ["Mushroom Field"] = Vector3.new(0, 0, 0),
    ["Blue Flower Field"] = Vector3.new(0, 0, 0),
    ["Clover Field"] = Vector3.new(0, 0, 0),
    ["Bamboo Field"] = Vector3.new(0, 0, 0),
    ["Strawberry Field"] = Vector3.new(0, 0, 0),
    ["Spider Field"] = Vector3.new(0, 0, 0),
    ["Pineapple Patch"] = Vector3.new(0, 0, 0),
    ["Stump Field"] = Vector3.new(0, 0, 0),
    ["Rose Field"] = Vector3.new(0, 0, 0),
    ["Cactus Field"] = Vector3.new(0, 0, 0),
    ["Pumpkin Patch"] = Vector3.new(0, 0, 0),
    ["Pine Tree Forest"] = Vector3.new(0, 0, 0),
    ["Coconut Field"] = Vector3.new(0, 0, 0),
    ["Pepper Patch"] = Vector3.new(0, 0, 0),
    ["Mountain Top Field"] = Vector3.new(0, 0, 0),
}

-- Placeholder Vector3 coordinates for Dispensers
Actuator.Dispensers = {
    ["Honey Dispenser"] = Vector3.new(0, 0, 0),
    ["Treat Dispenser"] = Vector3.new(0, 0, 0),
    ["Blueberry Dispenser"] = Vector3.new(0, 0, 0),
    ["Strawberry Dispenser"] = Vector3.new(0, 0, 0),
    ["Coconut Dispenser"] = Vector3.new(0, 0, 0),
    ["Glue Dispenser"] = Vector3.new(0, 0, 0),
}

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

return Actuator
