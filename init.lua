local HttpService = game:GetService("HttpService")

-- Configuration
local REPO_URL = "https://raw.githubusercontent.com/USER/REPO/BRANCH/" -- Placeholder: Update with actual repo URL

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

local function LoadModule(moduleName, fileName)
    Log("Loading Module: " .. moduleName)
    local url = REPO_URL .. fileName
    local success, scriptContent = pcall(function() return game:HttpGet(url) end)

    if success then
        local loadSuccess, moduleFunc = pcall(function() return loadstring(scriptContent) end)
        if loadSuccess and moduleFunc then
            local module = moduleFunc()
            Modules[moduleName] = module

            -- Initialize module if it has an Init function
            if module.Init then
                module.Init()
            end
            Log(moduleName .. " Loaded and Initialized.")
        else
            Log("Error compiling " .. moduleName)
        end
    else
        Log("Failed to fetch " .. moduleName)
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
    Log = Log,
    ParseLatexFormula = ParseLatexFormula
}

-- UI Controls (Overlord Tab)
local FarmingToggle = OverlordTab:CreateToggle({
    Name = "Enable Farming",
    CurrentValue = false,
    Flag = "FarmingToggle",
    Callback = function(Value)
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
        if Value then
            Log("Director Activated.")
            Modules.Pathfinder.StartQuesting()
        else
            Log("Director Deactivated.")
            Modules.Actuator.StopFarming()
        end
    end,
})

Log("Aegis Initialization Complete. Handshake Successful.")
