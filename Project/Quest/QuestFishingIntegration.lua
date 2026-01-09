-- ============================================
-- QUEST FISHING INTEGRATION MODULE
-- Auto fishing + auto teleport based on quest requirements
-- ============================================

local QuestFishingIntegration = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- ============================================
-- STATE MANAGEMENT
-- ============================================

QuestFishingIntegration.Active = false
QuestFishingIntegration.CurrentQuest = nil
QuestFishingIntegration.CurrentTask = nil
QuestFishingIntegration.CurrentLocation = nil

-- Stats tracking
QuestFishingIntegration.Stats = {
    SessionStartTime = 0,
    FishCaught = 0,
    RareFish = 0,
    EpicFish = 0,
    LegendaryFish = 0,
    MythicFish = 0,
    SecretFish = 0,
    CoinsEarned = 0
}

-- ============================================
-- MODULES DEPENDENCIES (akan di-load dari main)
-- ============================================

local AutoQuestModule = nil
local BlatantAutoFishing = nil
local NotifyModule = nil

-- ============================================
-- INITIALIZATION
-- ============================================

function QuestFishingIntegration.Initialize(modules)
    AutoQuestModule = modules.AutoQuestModule
    BlatantAutoFishing = modules.BlatantAutoFishing
    NotifyModule = modules.Notify
    
    if not AutoQuestModule or not BlatantAutoFishing then
        error("❌ Required modules not loaded!")
        return false
    end
    
    print("✅ QuestFishingIntegration initialized")
    return true
end

-- ============================================
-- FISH CAUGHT EVENT LISTENER
-- ============================================

local FishCaughtListener = nil
local ObtainedFishListener = nil

-- ✅ FISH IT SPECIFIC: Load Items and Variants modules
local Items, Variants
local function loadGameModules()
    local success = pcall(function()
        Items = require(ReplicatedStorage:WaitForChild("Items"))
        Variants = require(ReplicatedStorage:WaitForChild("Variants"))
    end)
    return success
end

-- ✅ FISH IT: Get fish data by ID
local function getFish(itemId)
    if not Items then return nil end
    
    for _, f in pairs(Items) do
        if f.Data and f.Data.Id == itemId then
            return f
        end
    end
end

-- ✅ FISH IT: Tier names (1-7)
local TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"  -- ⭐ FISH IT uses "SECRET" not "Mythical"!
}

local function setupFishListener()
    if FishCaughtListener then
        FishCaughtListener:Disconnect()
    end
    if ObtainedFishListener then
        ObtainedFishListener:Disconnect()
    end
    
    -- Load game modules
    if not loadGameModules() then
        warn("⚠️ Failed to load Items/Variants modules")
        return
    end
    
    -- ✅ FISH IT SPECIFIC PATH
    local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    
    -- ⭐ USE ObtainedNewFishNotification (Fish It specific event)
    local RE_ObtainedFish = netFolder:WaitForChild("RE/ObtainedNewFishNotification")
    
    ObtainedFishListener = RE_ObtainedFish.OnClientEvent:Connect(function(itemId, metadata, extraData)
        if not QuestFishingIntegration.Active then return end
        
        -- Get fish data from Items module
        local fish = getFish(itemId)
        if not fish then return end
        
        -- ✅ FISH IT: Tier is a number (1-7)
        local tier = fish.Data.Tier or 1
        local rarityName = TIER_NAMES[tier] or "Common"
        local fishName = fish.Data.Name or "Unknown"
        
        -- Update stats
        QuestFishingIntegration.Stats.FishCaught = QuestFishingIntegration.Stats.FishCaught + 1
        
        -- Track by tier/rarity
        if rarityName == "Rare" then
            QuestFishingIntegration.Stats.RareFish = QuestFishingIntegration.Stats.RareFish + 1
        elseif rarityName == "Epic" then
            QuestFishingIntegration.Stats.EpicFish = QuestFishingIntegration.Stats.EpicFish + 1
        elseif rarityName == "Legendary" then
            QuestFishingIntegration.Stats.LegendaryFish = QuestFishingIntegration.Stats.LegendaryFish + 1
        elseif rarityName == "Mythic" then
            QuestFishingIntegration.Stats.MythicFish = QuestFishingIntegration.Stats.MythicFish + 1
        elseif rarityName == "SECRET" then  -- ⭐ FISH IT specific
            QuestFishingIntegration.Stats.SecretFish = QuestFishingIntegration.Stats.SecretFish + 1
        end
        
        -- Update quest task progress
        QuestFishingIntegration.UpdateTaskProgress(fishName, rarityName, fish, metadata)
        
        -- Log
        print(string.format("🐟 Caught: %s [%s Tier %d] | Session: %d fish", 
            fishName, rarityName, tier, QuestFishingIntegration.Stats.FishCaught))
    end)
end

-- ============================================
-- UPDATE TASK PROGRESS
-- ============================================

function QuestFishingIntegration.UpdateTaskProgress(fishName, rarity, fishData)
    if not QuestFishingIntegration.CurrentQuest or not QuestFishingIntegration.CurrentTask then
        return
    end
    
    local quest = AutoQuestModule.Quests[QuestFishingIntegration.CurrentQuest]
    if not quest then return end
    
    for taskIndex, task in ipairs(quest.Tasks) do
        -- Check if this task is about fishing
        if task.Location == QuestFishingIntegration.CurrentLocation then
            
            -- Match rarity requirement
            if task.FishRarity then
                if rarity == task.FishRarity and task.Current < task.Required then
                    task.Current = task.Current + 1
                    
                    -- Notify
                    if NotifyModule then
                        NotifyModule.Send(
                            "Quest Progress",
                            string.format("%s: %d/%d", task.Name, task.Current, task.Required),
                            3
                        )
                    end
                    
                    -- Check if task completed
                    if task.Current >= task.Required then
                        print("✅ Task completed:", task.Name)
                        
                        -- Move to next task
                        QuestFishingIntegration.NextTask()
                    end
                end
            
            -- Match specific fish name
            elseif task.FishName then
                if fishName == task.FishName and task.Current < task.Required then
                    task.Current = task.Current + 1
                    
                    if NotifyModule then
                        NotifyModule.Send(
                            "Quest Progress",
                            string.format("%s: %d/%d", task.Name, task.Current, task.Required),
                            3
                        )
                    end
                    
                    if task.Current >= task.Required then
                        print("✅ Task completed:", task.Name)
                        QuestFishingIntegration.NextTask()
                    end
                end
            
            -- Generic fish count (any fish at this location)
            else
                if task.Current < task.Required then
                    task.Current = task.Current + 1
                    
                    if task.Current >= task.Required then
                        print("✅ Task completed:", task.Name)
                        QuestFishingIntegration.NextTask()
                    end
                end
            end
        end
    end
end

-- ============================================
-- NEXT TASK LOGIC
-- ============================================

function QuestFishingIntegration.NextTask()
    local quest = AutoQuestModule.Quests[QuestFishingIntegration.CurrentQuest]
    if not quest then return end
    
    -- Find next incomplete task with location
    for _, task in ipairs(quest.Tasks) do
        if task.Location and task.Current < task.Required then
            QuestFishingIntegration.CurrentTask = task
            QuestFishingIntegration.CurrentLocation = task.Location
            
            -- Stop fishing
            if BlatantAutoFishing.Enabled then
                BlatantAutoFishing.Stop()
            end
            
            -- Teleport to new location
            local locationSet = quest.LocationSet
            local coordinates = AutoQuestModule.Locations[locationSet][task.Location]
            
            if coordinates then
                print("📍 Moving to:", task.Location)
                AutoQuestModule.TeleportToLocation(coordinates)
                
                -- Wait for teleport
                task.wait(2)
                
                -- Resume fishing
                BlatantAutoFishing.Start()
                
                if NotifyModule then
                    NotifyModule.Send(
                        "Quest Location",
                        "Now at: " .. task.Location,
                        3
                    )
                end
            end
            
            return
        end
    end
    
    -- No more tasks with locations = quest complete or need manual tasks
    print("🎉 All fishing tasks completed for this quest!")
    QuestFishingIntegration.Stop()
end

-- ============================================
-- START QUEST FISHING
-- ============================================

function QuestFishingIntegration.Start(questName)
    if QuestFishingIntegration.Active then
        print("⚠️ Quest fishing already active!")
        return
    end
    
    local quest = AutoQuestModule.Quests[questName]
    if not quest then
        print("❌ Quest not found:", questName)
        return
    end
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🎯 STARTING QUEST FISHING MODE")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📜 Quest:", quest.Name)
    print("🎁 Reward:", quest.Reward)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    QuestFishingIntegration.Active = true
    QuestFishingIntegration.CurrentQuest = questName
    QuestFishingIntegration.Stats.SessionStartTime = tick()
    
    -- Setup listener
    setupFishListener()
    
    -- Find first task with location
    for _, task in ipairs(quest.Tasks) do
        if task.Location and task.Current < task.Required then
            QuestFishingIntegration.CurrentTask = task
            QuestFishingIntegration.CurrentLocation = task.Location
            
            -- Teleport to location
            local locationSet = quest.LocationSet
            local coordinates = AutoQuestModule.Locations[locationSet][task.Location]
            
            if coordinates then
                print("📍 Teleporting to:", task.Location)
                AutoQuestModule.TeleportToLocation(coordinates)
                
                task.wait(2)
                
                -- Start auto fishing
                print("🎣 Starting auto fishing...")
                BlatantAutoFishing.Start()
                
                if NotifyModule then
                    NotifyModule.Send(
                        "Quest Started",
                        quest.Name .. " - " .. task.Location,
                        5
                    )
                end
            end
            
            return
        end
    end
    
    print("⚠️ No fishing tasks found for this quest")
    QuestFishingIntegration.Stop()
end

-- ============================================
-- STOP QUEST FISHING
-- ============================================

function QuestFishingIntegration.Stop()
    if not QuestFishingIntegration.Active then
        print("⚠️ Quest fishing not active")
        return
    end
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🛑 STOPPING QUEST FISHING MODE")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    -- Stop auto fishing
    if BlatantAutoFishing and BlatantAutoFishing.Enabled then
        BlatantAutoFishing.Stop()
    end
    
    -- Disconnect listeners
    if FishCaughtListener then
        FishCaughtListener:Disconnect()
        FishCaughtListener = nil
    end
    
    if ObtainedFishListener then
        ObtainedFishListener:Disconnect()
        ObtainedFishListener = nil
    end
    
    -- Print stats
    local sessionTime = tick() - QuestFishingIntegration.Stats.SessionStartTime
    print(string.format("⏱️ Session Time: %.1f minutes", sessionTime / 60))
    print("📊 Total Fish Caught:", QuestFishingIntegration.Stats.FishCaught)
    print("   Rare:", QuestFishingIntegration.Stats.RareFish)
    print("   Epic:", QuestFishingIntegration.Stats.EpicFish)
    print("   Legendary:", QuestFishingIntegration.Stats.LegendaryFish)
    print("   Mythic:", QuestFishingIntegration.Stats.MythicFish)
    print("   Secret:", QuestFishingIntegration.Stats.SecretFish)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    -- Reset state
    QuestFishingIntegration.Active = false
    QuestFishingIntegration.CurrentQuest = nil
    QuestFishingIntegration.CurrentTask = nil
    QuestFishingIntegration.CurrentLocation = nil
    
    -- Reset stats
    QuestFishingIntegration.Stats = {
        SessionStartTime = 0,
        FishCaught = 0,
        RareFish = 0,
        EpicFish = 0,
        LegendaryFish = 0,
        MythicFish = 0,
        SecretFish = 0,
        CoinsEarned = 0
    }
end

-- ============================================
-- GET STATUS
-- ============================================

function QuestFishingIntegration.GetStatus()
    if not QuestFishingIntegration.Active then
        return "Quest Fishing: Inactive"
    end
    
    local quest = AutoQuestModule.Quests[QuestFishingIntegration.CurrentQuest]
    local task = QuestFishingIntegration.CurrentTask
    
    local status = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    status = status .. "🎯 Quest Fishing Active\n"
    status = status .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    status = status .. "📜 Quest: " .. quest.Name .. "\n"
    status = status .. "📍 Location: " .. (QuestFishingIntegration.CurrentLocation or "Unknown") .. "\n"
    
    if task then
        status = status .. "📋 Current Task: " .. task.Name .. "\n"
        status = status .. string.format("   Progress: %d/%d (%.1f%%)\n", 
            task.Current, task.Required, (task.Current / task.Required) * 100)
    end
    
    status = status .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    status = status .. "📊 Session Stats:\n"
    status = status .. "   Total Fish: " .. QuestFishingIntegration.Stats.FishCaught .. "\n"
    status = status .. "   Rare: " .. QuestFishingIntegration.Stats.RareFish .. "\n"
    status = status .. "   Epic: " .. QuestFishingIntegration.Stats.EpicFish .. "\n"
    status = status .. "   Legendary: " .. QuestFishingIntegration.Stats.LegendaryFish .. "\n"
    status = status .. "   Mythic: " .. QuestFishingIntegration.Stats.MythicFish .. "\n"
    status = status .. "   Secret: " .. QuestFishingIntegration.Stats.SecretFish .. "\n"
    status = status .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    
    return status
end

-- ============================================
-- CLEANUP
-- ============================================

Players.PlayerRemoving:Connect(function(player)
    if player == Player then
        if QuestFishingIntegration.Active then
            QuestFishingIntegration.Stop()
        end
    end
end)

return QuestFishingIntegration
