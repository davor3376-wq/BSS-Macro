--[[
    Aegis Monolith v1.0
    Bee Swarm Simulator Macro (Delta Executor)

    Architecture: Monolithic (Single Script)
    Data Source: External JSON (BSS_DATA)
    UI Library: Rayfield

    Author: Jules
--]]

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- 1. CONFIGURATION & STATE
-- ============================================================================

local Aegis = {
    Version = "1.0.0",
    Status = "Idle", -- Options: Idle, Farming, Converting, Combat, Paused
    IsRunning = false,
    Config = {
        Field = "Sunflower Field",
        WalkSpeed = 16,
        JumpPower = 50,
        AutoFarm = false,
        AutoDig = false,
        AutoSprinkler = false,
        ConvertHoney = false,
        AutoQuest = false,
        WebhookURL = ""
    },
    Data = {}, -- Loaded BSS_DATA
    Services = {}, -- Internal services (Tween, Pathfinding, etc.)
    UI = {} -- Rayfield Window & Tabs
}

-- Default Configuration (JSON Serializable)
local DefaultConfig = HttpService:JSONEncode(Aegis.Config)

-- ============================================================================
-- 2. DATA LOADER (BSS_DATA)
-- ============================================================================

local DATA_URL = "https://raw.githubusercontent.com/jules-ai/bss-data/main/BSS_DATA.json" -- Placeholder URL

function Aegis.LoadData()
    Aegis.Status = "Loading Data..."
    local success, response = pcall(function()
        return game:HttpGet(DATA_URL)
    end)

    if success then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)

        if decodeSuccess then
            Aegis.Data = data
            print("Aegis: BSS_DATA Loaded Successfully.")
        else
            warn("Aegis: Failed to decode BSS_DATA JSON.")
            -- Fallback: Empty or minimal data to prevent crash
            Aegis.Data = { Fields = {}, Tokens = {} }
        end
    else
        warn("Aegis: Failed to fetch BSS_DATA. (HTTP Error)")
        Aegis.Data = { Fields = {}, Tokens = {} }
    end
    Aegis.Status = "Idle"
end

-- ============================================================================
-- 3. CONFIG SYSTEM
-- ============================================================================

local ConfigFileName = "Aegis_Config.json"

function Aegis.SaveConfig()
    local json = HttpService:JSONEncode(Aegis.Config)
    writefile(ConfigFileName, json)
    print("Aegis: Config Saved.")
end

function Aegis.LoadConfig()
    if isfile(ConfigFileName) then
        local json = readfile(ConfigFileName)
        local success, config = pcall(function()
            return HttpService:JSONDecode(json)
        end)

        if success then
            -- Merge with existing config to ensure new keys exist
            for k, v in pairs(config) do
                Aegis.Config[k] = v
            end
            print("Aegis: Config Loaded.")
        else
            warn("Aegis: Failed to decode config file.")
        end
    else
        print("Aegis: No config file found. Using defaults.")
    end
end

function Aegis.ExportConfig()
    local json = HttpService:JSONEncode(Aegis.Config)
    setclipboard(json)
    print("Aegis: Config exported to clipboard.")
end

function Aegis.ImportConfig(jsonStr)
    local success, config = pcall(function()
        return HttpService:JSONDecode(jsonStr)
    end)

    if success then
        for k, v in pairs(config) do
            Aegis.Config[k] = v
        end
        Aegis.SaveConfig()
        print("Aegis: Config Imported.")
    else
        warn("Aegis: Invalid Config JSON.")
    end
end

-- ============================================================================
-- 4. MOVEMENT ENGINE
-- ============================================================================

function Aegis.GetCharacter()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
        return character, character.HumanoidRootPart, character.Humanoid
    end
    return nil, nil, nil
end

function Aegis.TweenTo(targetPos, speed)
    local char, root, humanoid = Aegis.GetCharacter()
    if not char then return end

    speed = speed or Aegis.Config.WalkSpeed or 16
    local distance = (root.Position - targetPos).Magnitude
    local time = distance / speed

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})

    tween:Play()

    -- Non-blocking wait loop that checks for interruptions
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        -- Check if paused or stopped
        if Aegis.Status == "Paused" or not Aegis.IsRunning then
            tween:Cancel()
            break
        end

        -- Check character validity
        if not char or not char.Parent or humanoid.Health <= 0 then
            tween:Cancel()
            break
        end

        task.wait(0.1)
    end
end

function Aegis.MoveToField(fieldName)
    -- Check BSS_DATA for field position
    local fieldData = Aegis.Data.Fields and Aegis.Data.Fields[fieldName]

    if fieldData and fieldData.Position then
        -- Assuming Position is stored as a table {x, y, z} or string
        -- Parsing logic would go here depending on JSON format
        -- Placeholder: Assuming Vector3 or table {X=..., Y=..., Z=...}
        local pos = Vector3.new(fieldData.Position.X, fieldData.Position.Y, fieldData.Position.Z)
        Aegis.TweenTo(pos)
    else
        warn("Aegis: Field data not found for " .. tostring(fieldName))
    end
end

-- ============================================================================
-- 5. CORE LOGIC & LOOPS
-- ============================================================================

function Aegis.ValidationLoop()
    while true do
        -- Check Character Health
        local char, root, humanoid = Aegis.GetCharacter()

        if char and humanoid then
            if humanoid.Health <= 0 then
                Aegis.Status = "Dead"
                Aegis.IsRunning = false
                print("Aegis: Character Died. Pausing.")
            end
        else
            -- No character exists (respawning)
            if Aegis.IsRunning then
                Aegis.Status = "Waiting for Respawn"
            end
        end

        task.wait(1)
    end
end

function Aegis.CollectTokens()
    -- Scan workspace for tokens and move to them (Placeholder)
    local char, root = Aegis.GetCharacter()
    if not char then return end

    -- In real implementation: Iterate Workspace.Collectibles
    -- For skeleton: We just wait to simulate collection
    task.wait(0.5)
end

function Aegis.FarmingLoop()
    while true do
        if Aegis.IsRunning and Aegis.Config.AutoFarm then
            Aegis.Status = "Farming"

            -- 1. Move to Field
            if Aegis.Config.Field then
                Aegis.MoveToField(Aegis.Config.Field)
            end

            -- 2. Collection Loop
            if Aegis.IsRunning then
                Aegis.CollectTokens()
            end

        else
            if Aegis.Status == "Farming" then
                Aegis.Status = "Idle"
            end
        end
        task.wait(0.1)
    end
end

-- ============================================================================
-- 6. UI CONSTRUCTION (Rayfield)
-- ============================================================================

function Aegis.InitUI()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    local Window = Rayfield:CreateWindow({
        Name = "Aegis Monolith v" .. Aegis.Version,
        LoadingTitle = "Aegis Initialization",
        LoadingSubtitle = "by Jules",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "AegisMacro",
            FileName = "AegisConfig"
        },
        KeySystem = false,
    })

    Aegis.UI.Window = Window

    -- TAB 1: Farming & Fields
    local Tab1 = Window:CreateTab("Farming", 4483362458)
    Tab1:CreateToggle({
        Name = "Autofarm",
        CurrentValue = false,
        Flag = "AutoFarm",
        Callback = function(Value)
            Aegis.Config.AutoFarm = Value
            Aegis.IsRunning = Value
        end,
    })
    Tab1:CreateDropdown({
        Name = "Select Field",
        Options = {"Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field", "Clover Field"}, -- Populate from BSS_DATA in real version
        CurrentOption = "Sunflower Field",
        Callback = function(Option)
            Aegis.Config.Field = Option
        end,
    })

    -- TAB 2: Tokens & Collection
    local Tab2 = Window:CreateTab("Tokens", 4483362458)
    Tab2:CreateToggle({
        Name = "Farm Tokens",
        CurrentValue = false,
        Callback = function(Value) end,
    })

    -- TAB 3: Convert & Items
    local Tab3 = Window:CreateTab("Convert", 4483362458)
    Tab3:CreateToggle({
        Name = "Auto Convert Honey",
        CurrentValue = false,
        Callback = function(Value)
            Aegis.Config.ConvertHoney = Value
        end,
    })

    -- TAB 4: Combat & Bosses
    local Tab4 = Window:CreateTab("Combat", 4483362458)
    Tab4:CreateToggle({
        Name = "Auto Kill Mobs",
        CurrentValue = false,
        Callback = function(Value) end,
    })

    -- TAB 5: Quests & Progression
    local Tab5 = Window:CreateTab("Quests", 4483362458)
    Tab5:CreateToggle({
        Name = "Auto Quest",
        CurrentValue = false,
        Callback = function(Value)
            Aegis.Config.AutoQuest = Value
        end,
    })

    -- TAB 6: World Events & Misc
    local Tab6 = Window:CreateTab("Events", 4483362458)
    Tab6:CreateToggle({
        Name = "Auto Planters",
        CurrentValue = false,
        Callback = function(Value) end,
    })

    -- TAB 7: Config & Movement
    local Tab7 = Window:CreateTab("Settings", 4483362458)
    Tab7:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 100},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(Value)
            Aegis.Config.WalkSpeed = Value
        end,
    })
    Tab7:CreateButton({
        Name = "Save Config",
        Callback = function()
            Aegis.SaveConfig()
        end,
    })
    Tab7:CreateButton({
        Name = "Load Config",
        Callback = function()
            Aegis.LoadConfig()
        end,
    })
    Tab7:CreateButton({
        Name = "Export Config to Clipboard",
        Callback = function()
            Aegis.ExportConfig()
        end,
    })

    local ImportInput = ""
    Tab7:CreateInput({
        Name = "Import Config (JSON)",
        PlaceholderText = "Paste JSON here...",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            ImportInput = Text
        end,
    })
    Tab7:CreateButton({
        Name = "Import Config",
        Callback = function()
            if ImportInput ~= "" then
                Aegis.ImportConfig(ImportInput)
            end
        end,
    })

    print("Aegis: UI Initialized.")
end

-- ============================================================================
-- 7. INITIALIZATION
-- ============================================================================

function Aegis.Main()
    print("Aegis: Starting...")

    -- 1. Load Data
    Aegis.LoadData()

    -- 2. Load Config
    Aegis.LoadConfig()

    -- 3. Init UI
    Aegis.InitUI()

    -- 4. Start Loops
    task.spawn(Aegis.ValidationLoop)
    task.spawn(Aegis.FarmingLoop)

    print("Aegis: Startup Complete.")
end

-- Run
Aegis.Main()
