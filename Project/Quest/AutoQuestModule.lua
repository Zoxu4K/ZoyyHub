-- ============================================
-- AUTO QUEST MODULE - FISH IT (WITH AUTO TELEPORT)
-- ============================================

local AutoQuestModule = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ============================================
-- LOCATION DATA
-- ============================================

AutoQuestModule.Locations = {
    Ghostfinn = {
        ["Treasure Room"] = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
        ["Sysiphus Statue"] = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
    },
    Element = {
        ["Ancient Jungle"] = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
        ["Sacred Temple"] = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
    },
    
    -- ✨ NEW: Diamond Quest locations
    Diamond = {
        ["Coral Reefs"] = Vector3.new(2500, 50, -1800),  -- Placeholder - update with actual coordinates
        ["Tropical Grove"] = Vector3.new(-2200, 60, 2100),  -- Placeholder - update with actual coordinates
    }
}

-- ============================================
-- AUTO TELEPORT SETTINGS
-- ============================================

AutoQuestModule.AutoTeleportActive = false
AutoQuestModule.AutoTeleportQueue = {}
AutoQuestModule.LastTeleportTime = 0
AutoQuestModule.TeleportCooldown = 2 -- Detik antara teleport

-- Quest Data
AutoQuestModule.Quests = {
    DeepSeaQuest = {
        Name = "Deep Sea Quest",
        Reward = "Ghostfinn Rod",
        Completed = false,
        LocationSet = "Ghostfinn",
        Locations = {"Treasure Room", "Sysiphus Statue"},
        Tasks = {
            {Name = "Catch 300 Rare/Epic fish in Treasure Room", Current = 0, Required = 300, Location = "Treasure Room"},
            {Name = "Catch 3 Mythic fish at Sisyphus Statue", Current = 0, Required = 3, Location = "Sysiphus Statue"},
            {Name = "Catch 1 SECRET fish at Sisyphus Statue", Current = 0, Required = 1, Location = "Sysiphus Statue"},
            {Name = "Earn 1M Coins", Current = 0, Required = 1000000}
        }
    },
    ElementQuest = {
        Name = "Element Quest",
        Reward = "Element Rod",
        Completed = false,
        LocationSet = "Element",
        Locations = {"Ancient Jungle", "Sacred Temple"},
        Tasks = {
            {Name = "Own Ghostfinn Rod", Current = 0, Required = 1},
            {Name = "Catch 1 SECRET fish at Ancient Jungle", Current = 0, Required = 1, Location = "Ancient Jungle"},
            {Name = "Catch 1 SECRET fish at Sacred Temple", Current = 0, Required = 1, Location = "Sacred Temple"},
            {Name = "Create 3 Transcended Stones", Current = 0, Required = 3}
        }
    },
    
    -- ✨ NEW: Diamond Quest (from decompiled game data)
    DiamondQuest = {
        Name = "Diamond Quest",
        Description = "Help Lary the Scientist complete his research to receive the Diamond Rod",
        Reward = "Diamond Key",
        FinalReward = "Diamond Rod",
        Completed = false,
        AssociatedTier = 7,
        LocationSet = "Diamond",
        Locations = {"Coral Reefs", "Tropical Grove"},
        Tasks = {
            -- Task 1: Own Element Rod (auto-check)
            {
                Id = 1,
                Name = "Own an Element Rod",
                Current = 0,
                Required = 1,
                Type = "ElementRodOwner",
                Reconcile = true  -- Auto-check on load
            },
            -- Task 2: SECRET fish at Coral Reefs
            {
                Id = 2,
                Name = "Catch a SECRET fish at Coral Reefs",
                Current = 0,
                Required = 1,
                Type = "Catch",
                Location = "Coral Reefs",
                FishTier = 7  -- SECRET tier
            },
            -- Task 3: SECRET fish at Tropical Grove
            {
                Id = 3,
                Name = "Catch a SECRET fish at Tropical Grove",
                Current = 0,
                Required = 1,
                Type = "Catch",
                Location = "Tropical Grove",
                FishTier = 7
            },
            -- Task 4: Exchange Gemstone Ruby (mutated)
            {
                Id = 4,
                Name = "Bring Lary a mutated Gemstone Ruby",
                Current = 0,
                Required = 1,
                Type = "Exchange",
                ItemId = 243,
                VariantId = 3,  -- Mutated variant
                AssociatedItem = "Ruby",
                AssociatedType = "Fish"
            },
            -- Task 5: Exchange Lochness Monster
            {
                Id = 5,
                Name = "Bring Lary a Lochness Monster",
                Current = 0,
                Required = 1,
                Type = "Exchange",
                ItemId = 228,
                AssociatedItem = "Lochness Monster",
                AssociatedType = "Fish"
            },
            -- Task 6: PERFECT throw fishing
            {
                Id = 6,
                Name = "Catch 1,000 fish while using PERFECT! throw",
                Current = 0,
                Required = 1000,
                Type = "Catch",
                EffectIndex = 5  -- PERFECT throw effect
            }
        }
    }
}

-- ============================================
-- TELEPORT FUNCTION
-- ============================================

function AutoQuestModule.TeleportToLocation(location)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local currentTime = tick()
    if currentTime - AutoQuestModule.LastTeleportTime < AutoQuestModule.TeleportCooldown then
        return false
    end
    
    if not location then
        return false
    end
    
    local offsetPos = location + Vector3.new(0, 3, 0)
    Player.Character.HumanoidRootPart.CFrame = CFrame.new(offsetPos)
    AutoQuestModule.LastTeleportTime = currentTime
    
    return true
end

-- ============================================
-- GET INCOMPLETE TASKS
-- ============================================

function AutoQuestModule.GetIncompleteTaskLocations(questName)
    local quest = AutoQuestModule.Quests[questName]
    if not quest then return {} end
    
    local incompleteLocations = {}
    
    for _, task in ipairs(quest.Tasks) do
        if task.Location and task.Current < task.Required then
            if not table.find(incompleteLocations, task.Location) then
                table.insert(incompleteLocations, task.Location)
            end
        end
    end
    
    return incompleteLocations
end

-- ============================================
-- AUTO TELEPORT LOGIC
-- ============================================

function AutoQuestModule.StartAutoTeleport(questName)
    if AutoQuestModule.AutoTeleportActive then
        return
    end
    
    local quest = AutoQuestModule.Quests[questName]
    if not quest then
        return
    end
    
    AutoQuestModule.AutoTeleportActive = true
    
    task.spawn(function()
        while AutoQuestModule.AutoTeleportActive do
            task.wait(1)
            
            if not AutoQuestModule.AutoTeleportActive then break end
            
            AutoQuestModule.DetectQuestCompletion()
            
            if quest.Completed then
                AutoQuestModule.AutoTeleportActive = false
                break
            end
            
            local incompleteLocations = AutoQuestModule.GetIncompleteTaskLocations(questName)
            
            if #incompleteLocations == 0 then
                AutoQuestModule.AutoTeleportActive = false
                break
            end
            
            local targetLocation = incompleteLocations[1]
            local locationSet = quest.LocationSet
            local coordinates = AutoQuestModule.Locations[locationSet][targetLocation]
            
            if coordinates then
                AutoQuestModule.TeleportToLocation(coordinates)
            end
            
            task.wait(5)
        end
    end)
end

function AutoQuestModule.StopAutoTeleport()
    if not AutoQuestModule.AutoTeleportActive then
        return
    end
    
    AutoQuestModule.AutoTeleportActive = false
end

function AutoQuestModule.ToggleAutoTeleport(questName)
    if AutoQuestModule.AutoTeleportActive then
        AutoQuestModule.StopAutoTeleport()
    else
        AutoQuestModule.StartAutoTeleport(questName)
    end
end

-- ============================================
-- MAIN DETECTION FUNCTION
-- ============================================

function AutoQuestModule.DetectQuestCompletion()
    local currentRod = Player:GetAttribute("FishingRod")
    
    if currentRod then
        if currentRod:find("Ghostfinn") then
            AutoQuestModule.Quests.DeepSeaQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.DeepSeaQuest.Tasks) do
                task.Current = task.Required
            end
            AutoQuestModule.Quests.ElementQuest.Tasks[1].Current = 1
        end
        
        if currentRod:find("Element") then
            AutoQuestModule.Quests.ElementQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.ElementQuest.Tasks) do
                task.Current = task.Required
            end
            AutoQuestModule.Quests.DeepSeaQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.DeepSeaQuest.Tasks) do
                task.Current = task.Required
            end
            
            -- ✨ Unlock Diamond Quest requirement
            AutoQuestModule.Quests.DiamondQuest.Tasks[1].Current = 1
        end
        
        -- ✨ NEW: Diamond Rod detection
        if currentRod:find("Diamond") then
            AutoQuestModule.Quests.DiamondQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.DiamondQuest.Tasks) do
                task.Current = task.Required
            end
            
            -- Mark previous quests as complete
            AutoQuestModule.Quests.ElementQuest.Completed = true
            AutoQuestModule.Quests.DeepSeaQuest.Completed = true
        end
    end
    
    return true
end

-- ============================================
-- GET QUEST INFO
-- ============================================

function AutoQuestModule.GetQuestInfo(questName)
    AutoQuestModule.DetectQuestCompletion()
    
    local quest = AutoQuestModule.Quests[questName]
    if not quest then return "Quest not found" end
    
    local info = quest.Name .. "\n"
    info = info .. "━━━━━━━━━━━━━━━━━━━━━━\n\n"
    
    for i, task in ipairs(quest.Tasks) do
        local status = task.Current >= task.Required and "✅" or "⏳"
        local progress = task.Current .. "/" .. task.Required
        local percentage = math.floor((task.Current / task.Required) * 100)
        
        info = info .. status .. " " .. task.Name .. "\n"
        info = info .. "   " .. progress .. " (" .. percentage .. "%)\n"
    end
    
    return info
end

-- ============================================
-- MANUAL UPDATE (BACKUP)
-- ============================================

function AutoQuestModule.SetTaskProgress(questName, taskIndex, current)
    local quest = AutoQuestModule.Quests[questName]
    if not quest or not quest.Tasks[taskIndex] then return false end
    
    quest.Tasks[taskIndex].Current = math.min(current, quest.Tasks[taskIndex].Required)
    
    local allCompleted = true
    for _, task in ipairs(quest.Tasks) do
        if task.Current < task.Required then
            allCompleted = false
            break
        end
    end
    quest.Completed = allCompleted
    
    return true
end

-- ============================================
-- MONITOR ATTRIBUTE CHANGES
-- ============================================

function AutoQuestModule.StartMonitoring()
    Player:GetAttributeChangedSignal("FishingRod"):Connect(function()
        local rod = Player:GetAttribute("FishingRod")
        AutoQuestModule.DetectQuestCompletion()
    end)
end

-- ============================================
-- DEBUG FUNCTIONS
-- ============================================

function AutoQuestModule.DebugPrintAll()
    print("\n╔════════════════════════════════════════╗")
    print("║       FISH IT QUEST STATUS             ║")
    print("╚════════════════════════════════════════╝\n")
    
    print(AutoQuestModule.GetQuestInfo("DeepSeaQuest"))
    print("\n")
    print(AutoQuestModule.GetQuestInfo("ElementQuest"))
    
    print("\n╚════════════════════════════════════════╝")
end

function AutoQuestModule.DebugCheckRod()
    local currentRod = Player:GetAttribute("FishingRod")
    print("\n🎣 CURRENT ROD CHECK:")
    print("   Rod: " .. tostring(currentRod))
    
    if currentRod then
        if currentRod:find("Ghostfinn") then
            print("   ✅ Has Ghostfinn Rod")
        end
        if currentRod:find("Element") then
            print("   ✅ Has Element Rod")
        end
    end
    print("")
end

-- ============================================
-- ALIASES
-- ============================================

AutoQuestModule.ScanQuestProgress = AutoQuestModule.DetectQuestCompletion
AutoQuestModule.ScanPlayerData = AutoQuestModule.DetectQuestCompletion
AutoQuestModule.DebugCheckItems = AutoQuestModule.DebugCheckRod
AutoQuestModule.SmartDetect = AutoQuestModule.DetectQuestCompletion

-- ============================================
-- AUTO INIT
-- ============================================

task.spawn(function()
    task.wait(2)
    AutoQuestModule.DetectQuestCompletion()
    AutoQuestModule.StartMonitoring()
end)

return AutoQuestModule
