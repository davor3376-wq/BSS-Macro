local HttpService = game:GetService("HttpService")

-- Configuration
local REPO_URL = "https://raw.githubusercontent.com/USER/REPO/main/" -- Placeholder: Update with actual repo URL (e.g. jules-ai/aegis-macro)

-- Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- UI Setup
local Window = Rayfield:CreateWindow({
    Name = "Aegis Macro",
    LoadingTitle = "Aegis Initialization",
    LoadingSubtitle = "by Jules",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AegisMacro",
        FileName = "AegisConfig"
    },
    KeySystem = false,
})

-- Tabs
local OverlordTab = Window:CreateTab("Overlord", 4483362458)
local SlayerTab = Window:CreateTab("Slayer", 4483362458)
local PathfinderTab = Window:CreateTab("Pathfinder", 4483362458)
local BotanistTab = Window:CreateTab("Botanist", 4483362458)
local ArtifactsTab = Window:CreateTab("Artifacts", 4483362458)
local NexusTab = Window:CreateTab("Nexus", 4483362458)

-- Live Console (Nexus Tab)
local ConsoleLogs = {}
local MAX_LOGS = 50
local ConsoleParagraph = NexusTab:CreateParagraph({Title = "Live Console", Content = "Initializing..."})

local function Log(message)
    local timestamp = os.date("%X")
    local logEntry = string.format("[%s] %s", timestamp, message)

    table.insert(ConsoleLogs, logEntry)
    if #ConsoleLogs > MAX_LOGS then
        table.remove(ConsoleLogs, 1) -- Remove oldest log
    end

    ConsoleParagraph:Set({Title = "Live Console", Content = table.concat(ConsoleLogs, "\n")})
end

Log("Aegis Macro Starting...")

-- LaTeX Parser Engine
local function ParseLatexFormula(latexStr)
    if type(latexStr) ~= "string" then return function() return 0 end end

    -- Sanitize LaTeX string
    -- Example: "{\displaystyle 500\times n}" -> "500 * n"
    local cleanStr = latexStr
    cleanStr = cleanStr:gsub("^{\\displaystyle%s*", "") -- Remove starting {\displaystyle
    cleanStr = cleanStr:gsub("}$", "")                  -- Remove ending }
    cleanStr = cleanStr:gsub("\\times", "*")            -- Replace \times with *
    cleanStr = cleanStr:gsub(",", "")                   -- Remove thousands separators

    -- Create Lua function
    return function(n)
        local funcStr = "return " .. cleanStr
        local funcChunk = loadstring(funcStr)

        if funcChunk then
            local env = {n = n} -- Inject 'n' into environment
            setfenv(funcChunk, env)
            local success, result = pcall(funcChunk)
            if success then
                return result
            else
                Log("Error calculating formula: " .. cleanStr)
                return 0
            end
        else
            Log("Failed to compile formula: " .. cleanStr)
            return 0
        end
    end
end

Log("Parser Engine Initialized.")

-- Manifest Loader
Log("Loading Aegis Ultimate Manifest...")
local Manifest = {}
local success, result = pcall(function()
    return game:HttpGet(REPO_URL .. "Aegis_Ultimate_Manifest.json")
end)

if success then
    local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(result) end)
    if decodeSuccess then
        Manifest = decoded
        Log("Manifest Loaded Successfully.")
    else
        Log("Failed to decode Manifest JSON.")
    end
else
    Log("Failed to download Manifest. (Check URL)")
end

-- Module Loader
local Modules = {}
Modules.Status = {} -- Track loading status of each module

local function LoadModule(moduleName, fileName)
    Log("Loading Module: " .. moduleName)
    local url = REPO_URL .. fileName

    -- Attempt to fetch the script
    local success, scriptContent = pcall(function() return game:HttpGet(url) end)

    if success and scriptContent then
        -- Attempt to compile the script
        local loadSuccess, moduleFunc = pcall(function() return loadstring(scriptContent) end)

        if loadSuccess and moduleFunc then
            -- Attempt to execute/init the module (returns a table)
            local execSuccess, module = pcall(moduleFunc)

            if execSuccess and type(module) == "table" then
                Modules[moduleName] = module
                Modules.Status[moduleName] = true
                Log(moduleName .. " Loaded Successfully.")
            else
                Modules.Status[moduleName] = false
                Log("Error initializing " .. moduleName .. ": " .. tostring(module)) -- module here is error msg
            end
        else
            Modules.Status[moduleName] = false
            Log("Error compiling " .. moduleName)
        end
    else
        Modules.Status[moduleName] = false
        Log("Failed to fetch " .. moduleName .. " (HTTP 404/Error)")
    end
end

-- Load Core Modules
-- In a real execution, REPO_URL needs to be valid for these to work.
LoadModule("Actuator", "actuator.lua")
LoadModule("Slayer", "slayer.lua")
LoadModule("Pathfinder", "pathfinder.lua")
LoadModule("World", "world.lua")

-- Global Registry
_G.Aegis = {
    Manifest = Manifest,
    Actuator = Modules.Actuator,
    Slayer = Modules.Slayer,
    Pathfinder = Modules.Pathfinder,
    World = Modules.World,
    Status = Modules.Status,
    Log = Log,
    ParseLatexFormula = ParseLatexFormula,
    WebhookURL = "",
    SendWebhook = nil
}

-- Initialize Modules (Order matters: Actuator first, then dependent modules)
if Modules.Actuator and Modules.Actuator.Init then Modules.Actuator.Init() end
if Modules.Slayer and Modules.Slayer.Init then Modules.Slayer.Init() end
if Modules.Pathfinder and Modules.Pathfinder.Init then Modules.Pathfinder.Init() end
if Modules.World and Modules.World.Init then Modules.World.Init() end

-- Webhook System
_G.Aegis.SendWebhook = function(message)
    if _G.Aegis.WebhookURL == "" then
        Log("Webhook URL not set.")
        return
    end

    local payload = HttpService:JSONEncode({
        content = message,
        username = "Aegis Macro",
        avatar_url = "https://i.imgur.com/your_logo.png" -- Placeholder
    })

    local success, response = pcall(function()
        return request({
            Url = _G.Aegis.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    end)

    if success then
        Log("Webhook Sent Successfully.")
    else
        Log("Failed to send Webhook: " .. tostring(response))
    end
end

-- UI Controls (Overlord Tab)
local FarmingToggle = OverlordTab:CreateToggle({
    Name = "Enable Farming",
    CurrentValue = false,
    Flag = "FarmingToggle",
    Callback = function(Value)
        if not Modules.Status["Actuator"] then Log("Error: Actuator module not loaded.") return end

        if Value then
            Log("Farming Enabled.")
            if Modules.Actuator.CurrentField then
                Modules.Actuator.StartFarming(Modules.Actuator.CurrentField)
            else
                Log("No Field Selected. Please select a field via the Director or manually.")
            end
        else
            Log("Farming Disabled.")
            Modules.Actuator.StopFarming()
        end
    end,
})

local PatternDropdown = OverlordTab:CreateDropdown({
    Name = "Farming Pattern",
    Options = {"Circular", "S-Pattern"},
    CurrentOption = "Circular",
    Flag = "PatternDropdown",
    Callback = function(Option)
        if not Modules.Status["Actuator"] then Log("Error: Actuator module not loaded.") return end
        Modules.Actuator.FarmingPattern = Option
        Log("Pattern set to: " .. Option)
    end,
})

local RadiusSlider = OverlordTab:CreateSlider({
    Name = "Pattern Radius/Width",
    Range = {5, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 15,
    Flag = "RadiusSlider",
    Callback = function(Value)
        if not Modules.Status["Actuator"] then Log("Error: Actuator module not loaded.") return end
        Modules.Actuator.FarmingRadius = Value
        Modules.Actuator.PatternWidth = Value
        Modules.Actuator.PatternLength = Value
        Log("Radius/Width set to: " .. tostring(Value))
    end,
})

local AutoQuestToggle = OverlordTab:CreateToggle({
    Name = "The Director (Auto-Quest)",
    CurrentValue = false,
    Flag = "AutoQuestToggle",
    Callback = function(Value)
        if not Modules.Status["Pathfinder"] or not Modules.Status["Actuator"] then
            Log("Error: Pathfinder/Actuator not loaded.")
            return
        end

        if Value then
            Log("Director Activated.")
            Modules.Pathfinder.StartQuesting()
        else
            Log("Director Deactivated.")
            Modules.Actuator.StopFarming()
        end
    end,
})

-- Slayer Tab UI
local SlayerToggle = SlayerTab:CreateToggle({
    Name = "Enable Boss Farming",
    CurrentValue = false,
    Flag = "SlayerToggle",
    Callback = function(Value)
        if not Modules.Status["Slayer"] then Log("Error: Slayer module not loaded.") return end
        Modules.Slayer.IsFarmingBoss = Value
        Log("Boss Farming: " .. tostring(Value))
    end,
})

-- Botanist Tab UI
local PlanterToggle = BotanistTab:CreateToggle({
    Name = "Auto-Planter",
    CurrentValue = false,
    Flag = "PlanterToggle",
    Callback = function(Value)
        if not Modules.Status["World"] then Log("Error: World module not loaded.") return end
        Modules.World.IsPlanting = Value
        Log("Auto-Planter: " .. tostring(Value))
    end,
})

local NectarDropdown = BotanistTab:CreateDropdown({
    Name = "Nectar Priority",
    Options = {"Satisfying", "Comforting", "Motivating", "Invigorating", "Refreshing"},
    CurrentOption = "Satisfying",
    Flag = "NectarDropdown",
    Callback = function(Option)
        if not Modules.Status["World"] then Log("Error: World module not loaded.") return end
        Modules.World.CurrentNectarGoal = Option
        Log("Nectar Priority: " .. Option)
    end,
})

-- Nexus Tab UI (Webhook)
local WebhookInput = NexusTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        _G.Aegis.WebhookURL = Text
        Log("Webhook URL Updated.")
    end,
})

local WebhookTestBtn = NexusTab:CreateButton({
    Name = "Send Test Webhook",
    Callback = function()
        local honey = game.Players.LocalPlayer:FindFirstChild("leaderstats") and game.Players.LocalPlayer.leaderstats:FindFirstChild("Honey")
        local honeyVal = honey and honey.Value or "Unknown"

        -- Get Quest Progress
        local quests = Modules.Pathfinder.GetActiveQuests()
        local questInfo = ""
        if #quests > 0 then
            questInfo = "\nActive Quest: " .. quests[1].Name .. " (" .. quests[1].Progress .. ")"
        end

        _G.Aegis.SendWebhook("Test Notification from Aegis Macro.\nCurrent Honey: " .. tostring(honeyVal) .. questInfo)
    end,
})

-- Nexus Optimization (3D Rendering & Particles)
local RenderingToggle = NexusTab:CreateToggle({
    Name = "Disable 3D Rendering",
    CurrentValue = false,
    Flag = "RenderingToggle",
    Callback = function(Value)
        game:GetService("RunService"):Set3dRenderingEnabled(not Value)
        Log("3D Rendering: " .. tostring(not Value))
    end,
})

local ClearParticlesBtn = NexusTab:CreateButton({
    Name = "Clear Particles (Reduce Lag)",
    Callback = function()
        local count = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj.Enabled = false
                count = count + 1
            end
        end
        Log("Disabled " .. count .. " particle effects.")
    end,
})

-- World Tab UI (Toys)
-- Assuming World Tab exists or adding to Botanist for now (or creating a new tab if I could, but stick to existing tabs)
-- Let's add Toy controls to the Botanist Tab since it's related to World interaction
local ToyToggle = BotanistTab:CreateToggle({
    Name = "Auto-Toys (Wealth, Glue, HQ)",
    CurrentValue = false,
    Flag = "ToyToggle",
    Callback = function(Value)
        if not Modules.Status["World"] then Log("Error: World module not loaded.") return end
        Modules.World.IsToyAuto = Value
        Log("Auto-Toys: " .. tostring(Value))
    end,
})

local BeesmasToggle = BotanistTab:CreateToggle({
    Name = "Beesmas Suite (Samovar, Feast)",
    CurrentValue = false,
    Flag = "BeesmasToggle",
    Callback = function(Value)
        if not Modules.Status["World"] then Log("Error: World module not loaded.") return end
        Modules.World.IsBeesmasAuto = Value
        Log("Beesmas Suite: " .. tostring(Value))
    end,
})

Log("Aegis Initialization Complete. Handshake Successful.")
