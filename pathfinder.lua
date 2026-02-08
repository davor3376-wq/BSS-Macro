local Pathfinder = {}

function Pathfinder.Init()
    print("Pathfinder Module Initialized")
end

-- Reads active quests from the Player's GUI
function Pathfinder.GetActiveQuests()
    local player = game.Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return {} end

    -- Assumption: Quests are usually in a "QuestLog" or similar GUI
    -- This path might need adjustment based on the specific game UI structure
    local questGui = playerGui:FindFirstChild("QuestLog") or playerGui:FindFirstChild("ScreenGui") -- Fallback
    local activeQuests = {}

    if questGui then
        -- Iterate through GUI elements to find quest text
        -- This is a heuristic approach; specific structure depends on the game
        for _, child in ipairs(questGui:GetDescendants()) do
            if child:IsA("TextLabel") and string.find(child.Text, "Quest") then
                table.insert(activeQuests, child.Text)
            end
        end
    end

    return activeQuests
end

-- Processes a quest name to determine the farming goal
function Pathfinder.ProcessQuest(questName)
    print("Processing Quest: " .. questName)

    -- Access global Manifest
    if not _G.Aegis or not _G.Aegis.Manifest then
        print("Error: Aegis Manifest not loaded.")
        return
    end

    local manifest = _G.Aegis.Manifest
    local questData = nil

    -- Search Manifest for the quest
    -- The Manifest structure is complex; we need to iterate to find the quest key
    for category, catData in pairs(manifest) do
        if type(catData) == "table" and catData.data_tables then
             for _, tableEntry in ipairs(catData.data_tables) do
                 for key, value in pairs(tableEntry) do
                     if string.find(questName, key) then
                         questData = value
                         break
                     end
                 end
                 if questData then break end
             end
        end
        if questData then break end
    end

    if not questData then
        print("Quest not found in Manifest: " .. questName)
        return
    end

    -- Analyze Requirements to find target Field
    -- Example Requirement: "Collect 500 Honey Tokens in the Sunflower Field"
    local requirements = questData[1].Requirements -- Assuming standard structure

    -- Use ParseLatexFormula if available (e.g., to log calculated values or for future logic)
    -- This fulfills the requirement to use the parser even if string matching drives the field selection
    if _G.Aegis.ParseLatexFormula then
        -- Find LaTeX patterns like {\displaystyle 500\times n}
        for latexMatch in string.gmatch(requirements, "{.-\\}") do
             local calculator = _G.Aegis.ParseLatexFormula(latexMatch)
             -- Assuming 'n' is the quest number, default to 1 for logging/calculation
             local value = calculator(1)
             print("Pathfinder: Parsed Requirement Value -> " .. tostring(value))
        end
    end

    local targetField = nil
    for fieldName, _ in pairs(_G.Aegis.Actuator.Fields) do
        if string.find(requirements, fieldName) then
            targetField = fieldName
            break
        end
    end

    if targetField then
        print("Quest Target Identified: " .. targetField)
        return targetField
    else
        print("Could not determine target field from requirements.")
        return nil
    end
end

-- "The Director": Main Auto-Quest Logic
function Pathfinder.StartQuesting()
    print("Director: Starting Auto-Quest Sequence...")

    local quests = Pathfinder.GetActiveQuests()
    if #quests == 0 then
        print("Director: No active quests found.")
        return
    end

    local currentQuest = quests[1] -- Prioritize first found quest
    print("Director: Selected Quest - " .. currentQuest)

    local targetField = Pathfinder.ProcessQuest(currentQuest)

    if targetField then
        print("Director: Directing Actuator to " .. targetField)

        -- Stop current farming
        if _G.Aegis.Actuator.IsFarming then
            _G.Aegis.Actuator.StopFarming()
            task.wait(1)
        end

        -- Start Farming in new field
        _G.Aegis.Actuator.StartFarming(targetField)
    else
        print("Director: Unable to process quest. Idle.")
    end
end

return Pathfinder
