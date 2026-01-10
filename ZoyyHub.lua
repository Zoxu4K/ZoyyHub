-- ZoyyHub GUI v2.3.1 - Cleaned Version
repeat task.wait() until game:IsLoaded()

-- Anti-Duplicate Check
if getgenv then
    if getgenv().ZOYY_GUI_RUNNING then
        warn("⚠️ GUI already running!")
        return
    end
    getgenv().ZOYY_GUI_RUNNING = true
elseif _G then
    if _G.ZOYY_GUI_RUNNING then
        warn("⚠️ GUI already running!")
        return
    end
    _G.ZOYY_GUI_RUNNING = true
end

local GUI_IDENTIFIER = "ZoyyHubGUI v1"
local INSTANCE_ID = tick()

if getgenv then
    getgenv().ZoyyHub_ActiveInstance = INSTANCE_ID
elseif _G then
    _G.ZoyyHub_ActiveInstance = INSTANCE_ID
end

-- Close Existing GUI
local function CloseExistingGUI()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("ScreenGui") and (
            string.find(child.Name, "Zoyy") or 
            string.find(child.Name, "Zoyy") or 
            child.Name == GUI_IDENTIFIER or
            child.Name == "ZoyyGUI_Galaxy"
        ) then
            pcall(function() child:Destroy() end)
        end
    end
    
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if descendant.Name == "ZoyyHubFloatingButton" or 
           string.find(tostring(descendant.Name):lower(), "floating") then 
            pcall(function() descendant:Destroy() end)
        end
    end
    
    task.wait(0.15)
end

CloseExistingGUI()

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer
local CleanupGUI

repeat task.wait() until localPlayer:FindFirstChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Connection Manager
local ConnectionManager = {
    connections = {},
    tweens = {}
}

function ConnectionManager:Add(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        table.insert(self.connections, connection)
    end
    return connection
end

function ConnectionManager:AddTween(tween)
    if tween then
        table.insert(self.tweens, tween)
    end
    return tween
end

function ConnectionManager:Cleanup()
    for i = #self.connections, 1, -1 do
        local conn = self.connections[i]
        if conn and conn.Connected then
            conn:Disconnect()
        end
        self.connections[i] = nil
    end
    
    for i = #self.tweens, 1, -1 do
        local tween = self.tweens[i]
        if tween then
            tween:Cancel()
        end
        self.tweens[i] = nil
    end
    
    table.clear(self.connections)
    table.clear(self.tweens)
end

-- Global Cleanup on Restart
if getgenv then
    if getgenv().ZoyyHub_ConnectionManager then
        pcall(function() getgenv().ZoyyHub_ConnectionManager:Cleanup() end)
    end
    getgenv().ZoyyHub_ConnectionManager = ConnectionManager
elseif _G then
    if _G.ZoyyHub_ConnectionManager then
        pcall(function() _G.ZoyyHub_ConnectionManager:Cleanup() end)
    end
    _G.ZoyyHub_ConnectionManager = ConnectionManager
end

-- Task Tracking
local RunningTasks = {}

local function TrackedSpawn(func)
    local thread = task.spawn(func)
    table.insert(RunningTasks, thread)
    return thread
end

-- Utility Functions
local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do 
        inst[k] = v 
    end
    return inst
end

local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = "rbxthumb://type=Asset&id=91891350821146&w=420&h=420"
        })
    end)
end

-- Loading Notification
local LoadingNotification = {
    Active = false,
    NotificationId = nil,
    StatusLabel = nil,
    ProgressBar = nil,
    ProgressBg = nil,
    TitleLabel = nil
}

function LoadingNotification.Create()
    if LoadingNotification.Active then return end
    LoadingNotification.Active = true
    
    pcall(function()
        local notifGui = new("ScreenGui", {
            Name = "ZoyyHubLoadingNotification",
            Parent = localPlayer.PlayerGui,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999999999
        })
        
        local notifFrame = new("Frame", {
            Parent = notifGui,
            Size = UDim2.new(0, 340, 0, 100),
            Position = UDim2.new(0.5, -170, 0.5, -50),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = notifFrame, CornerRadius = UDim.new(0, 16)})
        
        new("ImageLabel", {
            Parent = notifFrame,
            Size = UDim2.new(0, 45, 0, 45),
            Position = UDim2.new(0, 18, 0, 12),
            BackgroundTransparency = 1,
            Image = "rbxthumb://type=Asset&id=91891350821146&w=420&h=420",
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3
        })
        
        local titleLabel = new("TextLabel", {
            Parent = notifFrame,
            Size = UDim2.new(1, -80, 0, 24),
            Position = UDim2.new(0, 70, 0, 12),
            BackgroundTransparency = 1,
            Text = "ZoyyHub Script Loading",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3
        })
        
        local statusLabel = new("TextLabel", {
            Parent = notifFrame,
            Size = UDim2.new(1, -80, 0, 18),
            Position = UDim2.new(0, 70, 0, 40),
            BackgroundTransparency = 1,
            Text = "Initializing...",
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3
        })
        
        local progressBg = new("Frame", {
            Parent = notifFrame,
            Size = UDim2.new(1, -36, 0, 4),
            Position = UDim2.new(0, 18, 1, -16),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 2
        })
        new("UICorner", {Parent = progressBg, CornerRadius = UDim.new(1, 0)})
        
        local progressBar = new("Frame", {
            Parent = progressBg,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 3
        })
        new("UICorner", {Parent = progressBar, CornerRadius = UDim.new(1, 0)})
        
        LoadingNotification.NotificationId = notifGui
        LoadingNotification.StatusLabel = statusLabel
        LoadingNotification.ProgressBar = progressBar
        LoadingNotification.ProgressBg = progressBg
        LoadingNotification.TitleLabel = titleLabel
        
        notifFrame.Position = UDim2.new(0.5, -170, -0.5, 0)
        local tween = TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -170, 0.5, -50)
        })
        ConnectionManager:AddTween(tween)
        tween:Play()
    end)
end

function LoadingNotification.Update(loadedCount, totalCount, currentModule)
    if not LoadingNotification.Active then return end
    
    pcall(function()
        if LoadingNotification.StatusLabel then
            local percent = math.floor((loadedCount / totalCount) * 100)
            LoadingNotification.StatusLabel.Text = string.format("Loading modules... %d%%", percent)
        end
        
        if LoadingNotification.ProgressBar and LoadingNotification.ProgressBg then
            local targetWidth = (loadedCount / totalCount) * LoadingNotification.ProgressBg.AbsoluteSize.X
            local tween = TweenService:Create(LoadingNotification.ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, targetWidth, 1, 0)
            })
            ConnectionManager:AddTween(tween)
            tween:Play()
        end
    end)
end

function LoadingNotification.Complete(success, loadedCount, totalCount)
    if not LoadingNotification.Active then return end
    
    pcall(function()
        if LoadingNotification.TitleLabel then
            LoadingNotification.TitleLabel.Text = success and "ZoyyHub Ready!" or "Loading Complete"
        end
        
        if LoadingNotification.StatusLabel then
            LoadingNotification.StatusLabel.Text = success 
                and "✓ All systems ready"
                or "⚠ Loading complete"
        end
        
        if LoadingNotification.ProgressBar then
            local tween = TweenService:Create(LoadingNotification.ProgressBar, TweenInfo.new(0.3), {
                BackgroundColor3 = success and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 159, 10)
            })
            ConnectionManager:AddTween(tween)
            tween:Play()
        end
        
        task.wait(2.5)
        if LoadingNotification.NotificationId then
            local frame = LoadingNotification.NotificationId:FindFirstChildOfClass("Frame")
            if frame then
                local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, 20, 1, -120)
                })
                ConnectionManager:AddTween(tween)
                tween:Play()
            end
            task.wait(0.5)
            LoadingNotification.NotificationId:Destroy()
            LoadingNotification.NotificationId = nil
        end
        
        LoadingNotification.Active = false
        LoadingNotification.StatusLabel = nil
        LoadingNotification.ProgressBar = nil
        LoadingNotification.ProgressBg = nil
        LoadingNotification.TitleLabel = nil
    end)
end

-- Module Loading
local Modules = {}
local ModuleStatus = {}
local totalModules = 0
local loadedModules = 0
local failedModules = {}

local CRITICAL_MODULES = {"HideStats", "Webhook", "Notify"}

LoadingNotification.Create()

local Loader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Zoxu4K/ZoyyHub/main/Loader.lua"))()

if not Loader then
    LoadingNotification.Complete(false, 0, 1)
    SendNotification("❌ ERROR", "Loader failed!", 10)
    return
end

LoadingNotification.Update(1, 32, "Loader")

local ModuleList = {
    "Notify", "HideStats", "Webhook", "PingFPSMonitor",
    "instant", "instant2", "blatantv1", "UltraBlatant", "blatantv2", "blatantv2fix", "AutoFavorite",
    "GoodPerfectionStable",
    "NoFishingAnimation", "LockPosition", "AutoEquipRod", "DisableCutscenes",
    "DisableExtras", "AutoTotem3X", "SkinAnimation", "WalkOnWater",
    "TeleportModule", "TeleportToPlayer", "SavedLocation", "EventTeleportDynamic",
    "AutoQuestModule", "AutoTemple", "TempleDataReader",
    "AutoSell", "AutoSellTimer", "MerchantSystem", "RemoteBuyer", "AutoBuyWeather",
    "FreecamModule", "UnlimitedZoomModule", "AntiAFK", "UnlockFPS", "FPSBooster", "DisableRendering", "MovementModule"
}

totalModules = #ModuleList

if totalModules == 0 then
    LoadingNotification.Complete(false, 0, 0)
    SendNotification("❌ Error", "Module list empty!", 10)
    return
end

local MAX_RETRIES = 3
local RETRY_DELAY = 1
local moduleRetryCount = {}

local function LoadModuleWithRetry(moduleName, retryCount)
    retryCount = retryCount or 0
    
    if not moduleRetryCount[moduleName] then
        moduleRetryCount[moduleName] = 0
    end
    
    moduleRetryCount[moduleName] = moduleRetryCount[moduleName] + 1
    
    if moduleRetryCount[moduleName] > 10 then
        warn("⚠️ Module " .. moduleName .. " exceeded retry limit!")
        return false
    end
    
    local success, result = pcall(function()
        return Loader.LoadModule(moduleName)
    end)
    
    if success and result then
        Modules[moduleName] = result
        ModuleStatus[moduleName] = "✅"
        loadedModules = loadedModules + 1
        moduleRetryCount[moduleName] = nil
        return true
    else
        if retryCount < MAX_RETRIES then
            task.wait(RETRY_DELAY)
            return LoadModuleWithRetry(moduleName, retryCount + 1)
        else
            Modules[moduleName] = nil
            ModuleStatus[moduleName] = "❌"
            table.insert(failedModules, moduleName)
            moduleRetryCount[moduleName] = nil
            return false
        end
    end
end

local function LoadAllModules()
    for _, moduleName in ipairs(ModuleList) do
        local isCritical = table.find(CRITICAL_MODULES, moduleName) ~= nil
        LoadingNotification.Update(loadedModules, totalModules, moduleName)
        
        local success = LoadModuleWithRetry(moduleName)
        
        if not success and isCritical then
            LoadingNotification.Complete(false, loadedModules, totalModules)
            SendNotification("❌ CRITICAL", moduleName .. " failed!", 10)
            error("CRITICAL MODULE FAILED: " .. moduleName)
            return false
        end
    end
    
    LoadingNotification.Complete(true, loadedModules, totalModules)
    return true
end

local loadSuccess = LoadAllModules()

if not loadSuccess then
    error("Module loading failed")
    return
end

local function GetModule(name)
    return Modules[name]
end

-- Color Palette
local colors = {
    primary   = Color3.fromRGB(70, 70, 75),
    secondary = Color3.fromRGB(70, 70, 70),

    success = Color3.fromRGB(60, 180, 110),
    warning = Color3.fromRGB(255, 170, 60),
    danger  = Color3.fromRGB(230, 80, 80),

    bg1 = Color3.fromRGB(14, 14, 14),
    bg2 = Color3.fromRGB(20, 20, 20),
    bg3 = Color3.fromRGB(28, 28, 28),
    bg4 = Color3.fromRGB(38, 38, 38),

    accent = Color3.fromRGB(90, 150, 255),
    text    = Color3.fromRGB(240, 240, 240),
    textDim = Color3.fromRGB(160, 160, 160)
}

-- GUI Structure
local viewport = workspace.CurrentCamera.ViewportSize
local isSmallScreen = viewport.X < 800 or UserInputService.TouchEnabled

local windowSize
if isSmallScreen then
    local w = math.clamp(viewport.X * 0.85, 400, 600)
    local h = math.clamp(viewport.Y * 0.70, 300, 450)
    windowSize = UDim2.new(0, w, 0, h)
else
    windowSize = UDim2.new(0, 680, 0, 450)
end

local gui = new("ScreenGui", {
    Name = GUI_IDENTIFIER,
    Parent = localPlayer.PlayerGui,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 2147483647
})

local function bringToFront() gui.DisplayOrder = 2147483647 end

local win = new("Frame", {
    Parent = gui,
    Size = windowSize,
    Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
    BackgroundColor3 = colors.bg1,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    ZIndex = 3
})
new("UICorner", {Parent = win, CornerRadius = UDim.new(0, 16)})
new("UIStroke", {Parent = win, Color = colors.primary, Thickness = 1, Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})

-- Header
local scriptHeader = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 5
})

local appTitle = new("TextLabel", {
    Parent = scriptHeader,
    Text = "ZoyyHub",
    Font = Enum.Font.GothamBlack,
    TextSize = 22,
    TextColor3 = colors.text,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
})

local titleGradient = new("UIGradient", {
    Parent = appTitle,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, colors.primary),
        ColorSequenceKeypoint.new(1, colors.secondary)
    },
    Rotation = 45
})

-- Header Buttons
local headerBtns = new("Frame", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(1, -110, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 6
})
new("UIListLayout", {Parent = headerBtns, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,8)})

local btnMinHeader = new("TextButton", {
    Parent = headerBtns,
    Size = UDim2.new(0, 32, 0, 32),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0,
    Text = "—",
    Font=Enum.Font.GothamBold,
    TextColor3=colors.textDim,
    AutoButtonColor=false,
    ZIndex=7
})
new("UICorner", {Parent = btnMinHeader, CornerRadius=UDim.new(1,0)})

local btnCloseHeader = new("TextButton", {
    Parent = headerBtns,
    Size = UDim2.new(0, 32, 0, 32),
    BackgroundColor3 = colors.danger,
    BackgroundTransparency = 0,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.new(1,1,1),
    AutoButtonColor = false,
    ZIndex = 7
})
new("UICorner", {Parent = btnCloseHeader, CornerRadius=UDim.new(1,0)})

ConnectionManager:Add(btnCloseHeader.MouseButton1Click:Connect(function()
    if CleanupGUI then CleanupGUI() else if gui then gui:Destroy() end end
end))

-- Top Nav
local navContainer = new("ScrollingFrame", {
    Parent = win,
    Size = UDim2.new(1, -40, 0, 45),
    Position = UDim2.new(0, 20, 0, 60),
    BackgroundTransparency = 1,
    ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    CanvasSize = UDim2.new(0,0,0,0),
    ClipsDescendants = true,
    ZIndex = 5
})
new("UIListLayout", {Parent = navContainer, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center})

-- Content Area
local contentBg = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, -40, 1, -120),
    Position = UDim2.new(0, 20, 0, 115),
    BackgroundColor3 = colors.bg1,
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 4
})

-- Resize Handle
local resizeHandle = new("TextButton", {
    Parent = win,
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(1, -18, 1, -18),
    BackgroundTransparency = 1,
    Text = "◢",
    TextColor3 = colors.textDim,
    ZIndex = 100
})

-- Minimize Logic
local isMinimized = false
local originalSize = windowSize
local isToggling = false

local function ToggleMinimize()
    if not gui or not gui.Parent then return end
    if isToggling then return end
    isToggling = true
    
    if win.Visible then
        win.Visible = false
        isMinimized = true
    else
        win.Visible = true
        win.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = originalSize}):Play()
        isMinimized = false
    end
    
    task.delay(0.35, function() isToggling = false end)
end

local pGui = localPlayer:WaitForChild("PlayerGui")
for _, child in ipairs(pGui:GetChildren()) do
    if child.Name == "ZoyyHubFloatingButtonGui" then
        child:Destroy()
    end
end

-- Pages Setup
local pages = {}
local currentPage = "Main"
local navButtons = {}

local function createPage(name)
    local page = new("ScrollingFrame", {
        Parent = contentBg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = colors.bg1,
        BackgroundTransparency = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.primary,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ClipsDescendants = false,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    new("UIListLayout", {Parent = page, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder})
    new("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 4)})
    pages[name] = page
    return page
end

local mainPage = createPage("Main")
local teleportPage = createPage("Teleport")
local shopPage = createPage("Shop")
local webhookPage = createPage("Webhook")
local cameraViewPage = createPage("CameraView")
local settingsPage = createPage("Settings")
local infoPage = createPage("Info")
mainPage.Visible = true

-- Welcome Card
local welcomeCard = new("Frame", {
    Parent = mainPage,
    Size = UDim2.new(1, -12, 0, 80),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    LayoutOrder = -1 
})
new("UICorner", {Parent = welcomeCard, CornerRadius = UDim.new(0, 12)})
new("UIStroke", {Parent = welcomeCard, Color = colors.bg3, Thickness = 1.5})
new("UIPadding", {Parent = welcomeCard, PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})

local avatarContainer = new("Frame", {
    Parent = welcomeCard,
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0, 0, 0.5, -25),
    BackgroundTransparency = 1
})
local avatarImg = new("ImageLabel", {
    Parent = avatarContainer,
    Size = UDim2.new(1, 0, 1, 0),
    Image = game:GetService("Players"):GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150),
    BackgroundTransparency = 1,
    ZIndex = 2
})
new("UICorner", {Parent = avatarImg, CornerRadius = UDim.new(1, 0)})
new("UIStroke", {Parent = avatarImg, Color = colors.primary, Thickness = 2})

local textContainer = new("Frame", {
    Parent = welcomeCard,
    Size = UDim2.new(1, -66, 1, 0),
    Position = UDim2.new(0, 66, 0, 0),
    BackgroundTransparency = 1
})

new("TextLabel", {
    Parent = textContainer,
    Text = "Welcome Back,",
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0.5, -14),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = colors.textDim,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
})

new("TextLabel", {
    Parent = textContainer,
    Text = localPlayer.DisplayName,
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 0.5, 6),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = colors.text,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
})

local function switchPage(pageName)
    if currentPage == pageName then return end
    currentPage = pageName
    for name, page in pairs(pages) do page.Visible = (name == pageName) end
    for name, btnData in pairs(navButtons) do
        local isActive = (name == pageName)
        TweenService:Create(btnData.btn, TweenInfo.new(0.3), {BackgroundTransparency = isActive and 0 or 1, BackgroundColor3 = isActive and colors.bg3 or colors.bg1}):Play()
        TweenService:Create(btnData.label, TweenInfo.new(0.3), {TextColor3 = isActive and colors.text or colors.textDim}):Play()
        TweenService:Create(btnData.icon, TweenInfo.new(0.3), {TextColor3 = isActive and colors.primary or colors.textDim}):Play()
    end
end

local function createNavButton(text, icon, page, order)
    local btn = new("TextButton", {
        Parent = navContainer,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = colors.bg1,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 6
    })
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(1,0)})
    new("UIPadding", {Parent = btn, PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})
    
    local content = new("Frame", {
        Parent = btn,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ZIndex=7
    })
    new("UIListLayout", {Parent=content, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), VerticalAlignment=Enum.VerticalAlignment.Center, HorizontalAlignment=Enum.HorizontalAlignment.Center})
    
    local iconLabel = new("TextLabel", {
        Parent = content,
        Text = icon,
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextColor3 = colors.textDim,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        LayoutOrder = 1,
        ZIndex = 7
    })
    
    local textLabel = new("TextLabel", {
        Parent = content,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = colors.textDim,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        LayoutOrder = 2,
        ZIndex = 7
    })

    ConnectionManager:Add(btn.MouseEnter:Connect(function()
        if page ~= currentPage then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=colors.bg3, BackgroundTransparency=0}):Play()
        end
    end))
    ConnectionManager:Add(btn.MouseLeave:Connect(function()
        if page ~= currentPage then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency=1}):Play()
        end
    end))
    ConnectionManager:Add(btn.MouseButton1Click:Connect(function() switchPage(page) end))

    navButtons[page] = {btn=btn, icon=iconLabel, label=textLabel}
    return btn
end

createNavButton("Dashboard", "🏠", "Main", 1)
createNavButton("Teleport", "🌍", "Teleport", 2)
createNavButton("Shop", "🛒", "Shop", 3)
createNavButton("Webhook", "🔗", "Webhook", 4)
createNavButton("Camera", "📷", "CameraView", 5)
createNavButton("Settings", "⚙️", "Settings", 6)
createNavButton("About", "ℹ️", "Info", 7)

switchPage("Main")

-- UI Components
local function makeCategory(parent, title, icon)
    local categoryFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        ZIndex = 6
    })
    new("UICorner", {Parent = categoryFrame, CornerRadius = UDim.new(0, 8)})
    
    local header = new("TextButton", {
        Parent = categoryFrame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 7
    })
    
    new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 8
    })
    
    local contentContainer = new("Frame", {
        Parent = categoryFrame,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 38),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7
    })
    new("UIListLayout", {Parent = contentContainer, Padding = UDim.new(0, 6)})
    new("UIPadding", {Parent = contentContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    ConnectionManager:Add(header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        contentContainer.Visible = isOpen
        local tween = TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = isOpen and 180 or 0})
        ConnectionManager:AddTween(tween)
        tween:Play()
    end))
    
    return contentContainer
end

local function makeToggle(parent, label, callback)
    local frame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 7
    })
    
    new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.68, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextWrapped = true,
        ZIndex = 8
    })
    
    local toggleBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = colors.bg4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(1, 0)})
    
    local toggleCircle = new("Frame", {
        Parent = toggleBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = colors.textDim,
        BorderSizePixel = 0,
        ZIndex = 9
    })
    new("UICorner", {Parent = toggleCircle, CornerRadius = UDim.new(1, 0)})
    
    local btn = new("TextButton", {
        Parent = toggleBg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10
    })
    
    local on = false
    local isUpdating = false
    
    local function updateVisual(newState, animate)
        on = newState
        local duration = animate and 0.25 or 0
        
        local t1 = TweenService:Create(toggleBg, TweenInfo.new(duration), {
            BackgroundColor3 = on and colors.primary or colors.bg4
        })
        
        local t2 = TweenService:Create(toggleCircle, TweenInfo.new(duration, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = on and colors.text or colors.textDim
        })
        
        ConnectionManager:AddTween(t1)
        ConnectionManager:AddTween(t2)
        t1:Play()
        t2:Play()
    end
    
    ConnectionManager:Add(btn.MouseButton1Click:Connect(function()
        if isUpdating then return end
        on = not on
        updateVisual(on, true)
        pcall(callback, on)
    end))
    
    return {
        toggle = btn,
        setOn = function(val, silent)
            if on == val then return end
            isUpdating = silent or false
            updateVisual(val, not silent)
            if not silent then pcall(callback, val) end
            isUpdating = false
        end,
        getState = function() return on end
    }
end

local function makeInput(parent, label, defaultValue, callback)
    local frame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 7
    })
    
    new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.55, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 8
    })
    
    local inputBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0.42, 0, 0, 28),
        Position = UDim2.new(0.58, 0, 0.5, -14),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = inputBg, CornerRadius = UDim.new(0, 6)})
    
    local inputBox = new("TextBox", {
        Parent = inputBg,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue),
        PlaceholderText = "0.00",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        PlaceholderColor3 = colors.textDim,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 9
    })
    
    ConnectionManager:Add(inputBox.FocusLost:Connect(function()
        local value = tonumber(inputBox.Text)
        if value then pcall(callback, value) else inputBox.Text = tostring(defaultValue) end
    end))
    
    return {
        Instance = inputBox,
        SetValue = function(val)
            inputBox.Text = tostring(val)
            pcall(callback, val)
        end
    }
end

local function makeButton(parent, label, callback)
    local btnFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = colors.primary,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = btnFrame, CornerRadius = UDim.new(0, 8)})
    
    local button = new("TextButton", {
        Parent = btnFrame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        ZIndex = 9
    })
    
    ConnectionManager:Add(button.MouseButton1Click:Connect(function()
        local t1 = TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 30)})
        ConnectionManager:AddTween(t1)
        t1:Play()
        task.wait(0.1)
        local t2 = TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 32)})
        ConnectionManager:AddTween(t2)
        t2:Play()
        pcall(callback)
    end))
    
    return btnFrame
end

local function makeDropdown(parent, title, icon, items, onSelect, uniqueId, defaultValue)
    local dropdownFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7,
        Name = uniqueId or "Dropdown"
    })
    new("UICorner", {Parent = dropdownFrame, CornerRadius = UDim.new(0, 8)})
    
    local header = new("TextButton", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 36),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 8
    })
    
    new("TextLabel", {
        Parent = header,
        Text = icon,
        Size = UDim2.new(0, 24, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = colors.primary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -70, 0, 14),
        Position = UDim2.new(0, 26, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local statusLabel = new("TextLabel", {
        Parent = header,
        Text = "None Selected",
        Size = UDim2.new(1, -70, 0, 12),
        Position = UDim2.new(0, 26, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = colors.textDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 9
    })
    
    local listContainer = new("ScrollingFrame", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.new(0, 6, 0, 42),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = colors.primary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10
    })
    new("UIListLayout", {Parent = listContainer, Padding = UDim.new(0, 4)})
    new("UIPadding", {Parent = listContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    local selectedItem = nil
    
    local function setSelectedItem(itemName, triggerCallback)
        selectedItem = itemName
        statusLabel.Text = "✓ " .. itemName
        statusLabel.TextColor3 = colors.success
        if triggerCallback then pcall(onSelect, itemName) end
    end
    
    ConnectionManager:Add(header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listContainer.Visible = isOpen
        local tween = TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = isOpen and 180 or 0})
        ConnectionManager:AddTween(tween)
        tween:Play()
        if isOpen then listContainer.Size = UDim2.new(1, -12, 0, math.min(#items * 28, 140)) end
    end))
    
    for _, itemName in ipairs(items) do
        local itemBtn = new("TextButton", {
            Parent = listContainer,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = colors.bg3,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 11
        })
        new("UICorner", {Parent = itemBtn, CornerRadius = UDim.new(0, 6)})
        
        local btnLabel = new("TextLabel", {
            Parent = itemBtn,
            Text = itemName,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 8,
            TextColor3 = colors.textDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12
        })
        
        ConnectionManager:Add(itemBtn.MouseEnter:Connect(function()
            if selectedItem ~= itemName then
                TweenService:Create(itemBtn, TweenInfo.new(0.2), {BackgroundColor3 = colors.bg4}):Play()
                TweenService:Create(btnLabel, TweenInfo.new(0.2), {TextColor3 = colors.text}):Play()
            end
        end))
        
        ConnectionManager:Add(itemBtn.MouseLeave:Connect(function()
            if selectedItem ~= itemName then
                TweenService:Create(itemBtn, TweenInfo.new(0.2), {BackgroundColor3 = colors.bg3}):Play()
                TweenService:Create(btnLabel, TweenInfo.new(0.2), {TextColor3 = colors.textDim}):Play()
            end
        end))
        
        ConnectionManager:Add(itemBtn.MouseButton1Click:Connect(function()
            setSelectedItem(itemName, true)
            task.wait(0.1)
            isOpen = false
            listContainer.Visible = false
            TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = 0}):Play()
        end))
    end
    
    if defaultValue and table.find(items, defaultValue) then
        TrackedSpawn(function()
            task.wait(0.1)
            setSelectedItem(defaultValue, false)
        end)
    end
    
    return {
        Instance = dropdownFrame,
        SetValue = function(val) setSelectedItem(val, true) end
    }
end

local function makeCheckboxList(parent, items, colorMap, onSelectionChange)
    local selectedItems = {}
    local checkboxRefs = {}
    
    local listContainer = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, #items * 33 + 10),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    new("UICorner", {Parent = listContainer, CornerRadius = UDim.new(0, 8)})
    
    local function createCheckbox(itemName, yPos)
        local checkboxRow = new("Frame", {
            Parent = listContainer,
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, yPos),
            BackgroundColor3 = colors.bg3,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 8
        })
        new("UICorner", {Parent = checkboxRow, CornerRadius = UDim.new(0, 6)})
        
        local checkbox = new("TextButton", {
            Parent = checkboxRow,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 8, 0, 3),
            BackgroundColor3 = colors.bg1,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 9
        })
        new("UICorner", {Parent = checkbox, CornerRadius = UDim.new(0, 4)})
        
        local itemColor = (colorMap and colorMap[itemName]) or colors.primary
        new("UIStroke", {
            Parent = checkbox,
            Color = itemColor,
            Thickness = 2,
            Transparency = 0.7
        })
        
        local checkmark = new("TextLabel", {
            Parent = checkbox,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✓",
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = colors.text,
            Visible = false,
            ZIndex = 10
        })
        
        new("TextLabel", {
            Parent = checkboxRow,
            Size = UDim2.new(1, -45, 1, 0),
            Position = UDim2.new(0, 40, 0, 0),
            BackgroundTransparency = 1,
            Text = itemName,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9
        })
        
        local isSelected = false
        
        ConnectionManager:Add(checkbox.MouseButton1Click:Connect(function()
            isSelected = not isSelected
            checkmark.Visible = isSelected
            
            if isSelected then
                if not table.find(selectedItems, itemName) then
                    table.insert(selectedItems, itemName)
                end
                TweenService:Create(checkbox, TweenInfo.new(0.25), {
                    BackgroundColor3 = itemColor,
                    BackgroundTransparency = 0.2
                }):Play()
            else
                local idx = table.find(selectedItems, itemName)
                if idx then table.remove(selectedItems, idx) end
                TweenService:Create(checkbox, TweenInfo.new(0.25), {
                    BackgroundColor3 = colors.bg1,
                    BackgroundTransparency = 0.4
                }):Play()
            end
            
            if onSelectionChange then pcall(onSelectionChange, selectedItems) end
        end))
        
        return {
            checkbox = checkbox,
            checkmark = checkmark,
            isSelected = function() return isSelected end,
            setSelected = function(val)
                if isSelected ~= val then checkbox.MouseButton1Click:Fire() end
            end
        }
    end
    
    for i, itemName in ipairs(items) do
        checkboxRefs[itemName] = createCheckbox(itemName, (i - 1) * 33 + 5)
    end
    
    return {
        GetSelected = function() return selectedItems end,
        SelectAll = function()
            for _, item in ipairs(items) do
                if checkboxRefs[item] and not checkboxRefs[item].isSelected() then
                    checkboxRefs[item].setSelected(true)
                end
            end
        end,
        ClearAll = function()
            for _, item in ipairs(items) do
                if checkboxRefs[item] and checkboxRefs[item].isSelected() then
                    checkboxRefs[item].setSelected(false)
                end
            end
        end,
        SelectSpecific = function(itemList)
            for _, item in ipairs(items) do
                if checkboxRefs[item] then
                    local shouldSelect = table.find(itemList, item) ~= nil
                    if checkboxRefs[item].isSelected() ~= shouldSelect then
                        checkboxRefs[item].setSelected(shouldSelect)
                    end
                end
            end
        end
    }
end

local function makeCheckboxDropdown(parent, title, items, colorMap, onChange)
    local selected = {}
    local refs = {}
    
    local frame = new("Frame", {
        Parent = parent, 
        Size = UDim2.new(1, 0, 0, 40), 
        BackgroundColor3 = colors.bg4, 
        BackgroundTransparency = 0.5, 
        BorderSizePixel = 0, 
        AutomaticSize = Enum.AutomaticSize.Y, 
        ZIndex = 7
    })
    new("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 6)})
    
    local header = new("TextButton", {
        Parent = frame, 
        Size = UDim2.new(1, -12, 0, 36), 
        Position = UDim2.new(0, 6, 0, 2), 
        BackgroundTransparency = 1, 
        Text = "", 
        ZIndex = 8
    })
    
    new("TextLabel", {
        Parent = header, 
        Text = title, 
        Size = UDim2.new(1, -30, 1, 0), 
        Position = UDim2.new(0, 8, 0, 0), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 9, 
        TextColor3 = colors.text, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        ZIndex = 9
    })
    
    local status = new("TextLabel", {
        Parent = header, 
        Text = "0", 
        Size = UDim2.new(0, 24, 1, 0), 
        Position = UDim2.new(1, -24, 0, 0), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 10, 
        TextColor3 = colors.primary, 
        ZIndex = 9
    })
    
    local list = new("ScrollingFrame", {
        Parent = frame, 
        Size = UDim2.new(1, -12, 0, 0), 
        Position = UDim2.new(0, 6, 0, 42), 
        BackgroundTransparency = 1, 
        Visible = false, 
        AutomaticCanvasSize = Enum.AutomaticSize.Y, 
        CanvasSize = UDim2.new(0, 0, 0, 0), 
        ScrollBarThickness = 2, 
        ScrollBarImageColor3 = colors.primary, 
        BorderSizePixel = 0, 
        ZIndex = 10
    })
    new("UIListLayout", {Parent = list, Padding = UDim.new(0, 3)})
    
    local open = false
    ConnectionManager:Add(header.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
        if open then list.Size = UDim2.new(1, -12, 0, math.min(#items * 24 + 6, 180)) end
    end))
    
    for _, name in ipairs(items) do
        local row = new("TextButton", {
            Parent = list, 
            Size = UDim2.new(1, 0, 0, 22), 
            BackgroundColor3 = colors.bg4, 
            BackgroundTransparency = 0.7, 
            BorderSizePixel = 0, 
            Text = "", 
            ZIndex = 11
        })
        new("UICorner", {Parent = row, CornerRadius = UDim.new(0, 4)})
        
        local check = new("TextLabel", {
            Parent = row, 
            Size = UDim2.new(0, 16, 0, 16), 
            Position = UDim2.new(0, 4, 0, 3), 
            BackgroundColor3 = colors.bg1, 
            BackgroundTransparency = 0.5, 
            BorderSizePixel = 0, 
            Text = "", 
            Font = Enum.Font.GothamBold, 
            TextSize = 12, 
            TextColor3 = colors.text, 
            ZIndex = 12
        })
        new("UICorner", {Parent = check, CornerRadius = UDim.new(0, 3)})
        if colorMap and colorMap[name] then 
            new("UIStroke", {
                Parent = check, 
                Color = colorMap[name], 
                Thickness = 2, 
                Transparency = 0.7
            }) 
        end
        
        new("TextLabel", {
            Parent = row, 
            Size = UDim2.new(1, -26, 1, 0), 
            Position = UDim2.new(0, 24, 0, 0), 
            BackgroundTransparency = 1, 
            Text = name, 
            Font = Enum.Font.GothamBold, 
            TextSize = 8, 
            TextColor3 = colors.text, 
            TextXAlignment = Enum.TextXAlignment.Left, 
            ZIndex = 12
        })
        
        local on = false
        
        local function toggleCheckbox()
            on = not on
            check.Text = on and "✓" or ""
            if on then 
                table.insert(selected, name) 
            else 
                local idx = table.find(selected, name)
                if idx then table.remove(selected, idx) end
            end
            status.Text = tostring(#selected)
            pcall(onChange, selected)
        end
        
        ConnectionManager:Add(row.MouseButton1Click:Connect(toggleCheckbox))
        
        refs[name] = {
            set = function(v) 
                if on ~= v then toggleCheckbox() end 
            end, 
            get = function() return on end
        }
    end
    
    return {
        GetSelected = function() return selected end,
        SelectSpecific = function(list) 
            for n, r in pairs(refs) do 
                r.set(table.find(list, n) ~= nil) 
            end 
        end
    }
end

-- Config System
local ConfigSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Zoxu4K/ZoyyHub/main/Loader.lua"))()

if ConfigSystem then
    ConfigSystem.ConfigValues = {}
    
    function ConfigSystem.Set(path, value)
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local current = ConfigSystem.ConfigValues
        for i = 1, #parts - 1 do
            local key = parts[i]
            if not current[key] then current[key] = {} end
            current = current[key]
        end
        
        if type(value) == "table" then
            if table and table.clone then
                 current[parts[#parts]] = table.clone(value)
            else
                 local clone = {}
                 for k, v in pairs(value) do clone[k] = v end
                 current[parts[#parts]] = clone
            end
        else
            current[parts[#parts]] = value
        end
    end
    
    function ConfigSystem.Get(path)
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local current = ConfigSystem.ConfigValues
        for i = 1, #parts - 1 do
            local key = parts[i]
            if not current[key] then return nil end
            current = current[key]
        end
        return current[parts[#parts]]
    end
    
    function ConfigSystem.GetConfig()
        return ConfigSystem.ConfigValues
    end
end

local function GetConfigValue(path, default)
    if ConfigSystem and ConfigSystem.Get then
        local success, value = pcall(function() return ConfigSystem.Get(path) end)
        if success and value ~= nil then return value end
    end
    return default
end

local function SetConfigValue(path, value)
    if ConfigSystem and ConfigSystem.Set then
        pcall(function() ConfigSystem.Set(path, value) end)
    end
end

-- Toggle References
local ToggleReferences = {}
local InputReferences = {}
local DropdownReferences = {}
local CheckboxReferences = {}

-- AUTO FISHING
do
local catAutoFishing = makeCategory(mainPage, "Auto Fishing", "🎣")

local savedInstantMode = GetConfigValue("InstantFishing.Mode", "Fast")
local savedFishingDelay = GetConfigValue("InstantFishing.FishingDelay", 1.30)
local savedCancelDelay = GetConfigValue("InstantFishing.CancelDelay", 0.19)
local savedInstantEnabled = GetConfigValue("InstantFishing.Enabled", false)

local currentInstantMode = savedInstantMode
local fishingDelayValue = savedFishingDelay
local cancelDelayValue = savedCancelDelay
local isInstantFishingEnabled = false

TrackedSpawn(function()
    task.wait(0.5)
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    
    if instant then
        instant.Settings.MaxWaitTime = savedFishingDelay
        instant.Settings.CancelDelay = savedCancelDelay
    end
    
    if instant2 then
        instant2.Settings.MaxWaitTime = savedFishingDelay
        instant2.Settings.CancelDelay = savedCancelDelay
    end
end)

DropdownReferences.InstantFishingMode = makeDropdown(catAutoFishing, "Instant Fishing Mode", "⚡", {"Fast", "Perfect"}, function(mode)
    currentInstantMode = mode
    SetConfigValue("InstantFishing.Mode", mode)
    
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    
    if instant then instant.Stop() end
    if instant2 then instant2.Stop() end
    
    if instant then
        instant.Settings.MaxWaitTime = fishingDelayValue
        instant.Settings.CancelDelay = cancelDelayValue
    end
    if instant2 then
        instant2.Settings.MaxWaitTime = fishingDelayValue
        instant2.Settings.CancelDelay = cancelDelayValue
    end
    
    if isInstantFishingEnabled then
        if mode == "Fast" and instant then instant.Start()
        elseif mode == "Perfect" and instant2 then instant2.Start() end
    end
end)

ToggleReferences.InstantFishing = makeToggle(catAutoFishing, "Enable Instant Fishing", function(on)
    isInstantFishingEnabled = on
    SetConfigValue("InstantFishing.Enabled", on)
    
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    
    if on then
        if currentInstantMode == "Fast" and instant then instant.Start()
        elseif currentInstantMode == "Perfect" and instant2 then instant2.Start() end
    else
        if instant then instant.Stop() end
        if instant2 then instant2.Stop() end
    end
end)

TrackedSpawn(function()
    task.wait(0.5)
    if savedInstantEnabled and ToggleReferences.InstantFishing then
        ToggleReferences.InstantFishing.setOn(savedInstantEnabled, true)
        isInstantFishingEnabled = true
        
        local instant = GetModule("instant")
        local instant2 = GetModule("instant2")
        
        if currentInstantMode == "Fast" and instant then instant.Start()
        elseif currentInstantMode == "Perfect" and instant2 then instant2.Start() end
    end
end)

InputReferences.FishingDelay = makeInput(catAutoFishing, "Fishing Delay", savedFishingDelay, function(v)
    fishingDelayValue = v
    SetConfigValue("InstantFishing.FishingDelay", v)
    
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    if instant then instant.Settings.MaxWaitTime = v end
    if instant2 then instant2.Settings.MaxWaitTime = v end
end)

InputReferences.CancelDelay = makeInput(catAutoFishing, "Cancel Delay", savedCancelDelay, function(v)
    cancelDelayValue = v
    SetConfigValue("InstantFishing.CancelDelay", v)
    
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    if instant then instant.Settings.CancelDelay = v end
    if instant2 then instant2.Settings.CancelDelay = v end
end)
end

-- BLATANT MODES
do
local catBlatantV2 = makeCategory(mainPage, "Blatant Tester", "🎯")

local savedBlatantTesterCompleteDelay = GetConfigValue("BlatantTester.CompleteDelay", 0.5)
local savedBlatantTesterCancelDelay = GetConfigValue("BlatantTester.CancelDelay", 0.1)

TrackedSpawn(function()
    task.wait(0.5)
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then
        blatantv2fix.Settings.CompleteDelay = savedBlatantTesterCompleteDelay
        blatantv2fix.Settings.CancelDelay = savedBlatantTesterCancelDelay
    end
end)

ToggleReferences.BlatantTester = makeToggle(catBlatantV2, "Blatant Tester", function(on)
    SetConfigValue("BlatantTester.Enabled", on)
    
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then
        if on then blatantv2fix.Start() else blatantv2fix.Stop() end
    end
end)

InputReferences.BlatantCompleteDelay = makeInput(catBlatantV2, "Complete Delay", savedBlatantTesterCompleteDelay, function(v)
    SetConfigValue("BlatantTester.CompleteDelay", v)
    
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then blatantv2fix.Settings.CompleteDelay = v end
end)

InputReferences.BlatantCancelDelay = makeInput(catBlatantV2, "Cancel Delay", savedBlatantTesterCancelDelay, function(v)
    SetConfigValue("BlatantTester.CancelDelay", v)
    
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then blatantv2fix.Settings.CancelDelay = v end
end)
end

do
local catBlatantV1 = makeCategory(mainPage, "Blatant V1", "💀")

local savedBlatantV1CompleteDelay = GetConfigValue("BlatantV1.CompleteDelay", 0.05)
local savedBlatantV1CancelDelay = GetConfigValue("BlatantV1.CancelDelay", 0.1)

TrackedSpawn(function()
    task.wait(0.5)
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then
        blatantv1.Settings.CompleteDelay = savedBlatantV1CompleteDelay
        blatantv1.Settings.CancelDelay = savedBlatantV1CancelDelay
    end
end)

ToggleReferences.BlatantV1 = makeToggle(catBlatantV1, "Blatant Mode", function(on)
    SetConfigValue("BlatantV1.Enabled", on)
    
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then
        if on then blatantv1.Start() else blatantv1.Stop() end
    end
end)

InputReferences.BlatantV1CompleteDelay = makeInput(catBlatantV1, "Complete Delay", savedBlatantV1CompleteDelay, function(v)
    SetConfigValue("BlatantV1.CompleteDelay", v)
    
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then blatantv1.Settings.CompleteDelay = v end
end)

InputReferences.BlatantV1CancelDelay = makeInput(catBlatantV1, "Cancel Delay", savedBlatantV1CancelDelay, function(v)
    SetConfigValue("BlatantV1.CancelDelay", v)
    
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then blatantv1.Settings.CancelDelay = v end
end)
end

do
local catUltraBlatant = makeCategory(mainPage, "Blatant V2", "⚡")

local savedUltraBlatantCompleteDelay = GetConfigValue("UltraBlatant.CompleteDelay", 0.05)
local savedUltraBlatantCancelDelay = GetConfigValue("UltraBlatant.CancelDelay", 0.1)

TrackedSpawn(function()
    task.wait(0.5)
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then
        if UltraBlatant.Settings then
            UltraBlatant.Settings.CompleteDelay = savedUltraBlatantCompleteDelay
            UltraBlatant.Settings.CancelDelay = savedUltraBlatantCancelDelay
        elseif UltraBlatant.UpdateSettings then
            UltraBlatant.UpdateSettings(savedUltraBlatantCompleteDelay, savedUltraBlatantCancelDelay, nil)
        end
    end
end)

ToggleReferences.UltraBlatant = makeToggle(catUltraBlatant, "Blatant Mode", function(on)
    SetConfigValue("UltraBlatant.Enabled", on)
    
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then
        if on then UltraBlatant.Start() else UltraBlatant.Stop() end
    end
end)

InputReferences.UltraBlatantCompleteDelay = makeInput(catUltraBlatant, "Complete Delay", savedUltraBlatantCompleteDelay, function(v)
    SetConfigValue("UltraBlatant.CompleteDelay", v)
    
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then
        if UltraBlatant.Settings then
            UltraBlatant.Settings.CompleteDelay = v
        elseif UltraBlatant.UpdateSettings then
            UltraBlatant.UpdateSettings(v, nil, nil)
        end
    end
end)

InputReferences.UltraBlatantCancelDelay = makeInput(catUltraBlatant, "Cancel Delay", savedUltraBlatantCancelDelay, function(v)
    SetConfigValue("UltraBlatant.CancelDelay", v)
    
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then
        if UltraBlatant.Settings then
            UltraBlatant.Settings.CancelDelay = v
        elseif UltraBlatant.UpdateSettings then
            UltraBlatant.UpdateSettings(nil, v, nil)
        end
    end
end)
end

do
local catBlatantV2Fast = makeCategory(mainPage, "Fast Auto Fishing Perfect", "🔥")

ToggleReferences.FastAutoPerfect = makeToggle(catBlatantV2Fast, "Fast Fishing Features", function(on)
    SetConfigValue("FastAutoPerfect.Enabled", on)
    
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then
        if on then blatantv2.Start() else blatantv2.Stop() end
    end
end)

InputReferences.FastAutoFishingDelay = makeInput(catBlatantV2Fast, "Fishing Delay", GetConfigValue("FastAutoPerfect.FishingDelay", 0.05), function(v)
    SetConfigValue("FastAutoPerfect.FishingDelay", v)
    
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.FishingDelay = v end
end)

InputReferences.FastAutoCancelDelay = makeInput(catBlatantV2Fast, "Cancel Delay", GetConfigValue("FastAutoPerfect.CancelDelay", 0.01), function(v)
    SetConfigValue("FastAutoPerfect.CancelDelay", v)
    
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.CancelDelay = v end
end)

InputReferences.FastAutoTimeoutDelay = makeInput(catBlatantV2Fast, "Timeout Delay", GetConfigValue("FastAutoPerfect.TimeoutDelay", 0.8), function(v)
    SetConfigValue("FastAutoPerfect.TimeoutDelay", v)
    
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.TimeoutDelay = v end
end)
end

-- SUPPORT FEATURES
do
local catSupport = makeCategory(mainPage, "Support Features", "🛠️")

ToggleReferences.NoFishingAnimation = makeToggle(catSupport, "No Fishing Animation", function(on)
    SetConfigValue("Support.NoFishingAnimation", on)
    local NoFishingAnimation = GetModule("NoFishingAnimation")
    if NoFishingAnimation then
        if on then NoFishingAnimation.StartWithDelay() else NoFishingAnimation.Stop() end
    end
end)

ToggleReferences.PingFPSMonitor = makeToggle(catSupport, "Ping & FPS Monitor", function(on)
    SetConfigValue("Support.PingFPSMonitor", on)
    local PingFPSMonitor = GetModule("PingFPSMonitor")
    if PingFPSMonitor then
        if on then PingFPSMonitor:Show() else PingFPSMonitor:Hide() end
    end
end)

ToggleReferences.LockPosition = makeToggle(catSupport, "Lock Position", function(on)
    SetConfigValue("Support.LockPosition", on)
    local LockPosition = GetModule("LockPosition")
    if LockPosition then
        if on then LockPosition.Start() else LockPosition.Stop() end
    end
end)

ToggleReferences.AutoEquipRod = makeToggle(catSupport, "Auto Equip Rod", function(on)
    SetConfigValue("Support.AutoEquipRod", on)
    local AutoEquipRod = GetModule("AutoEquipRod")
    if AutoEquipRod then
        if on then AutoEquipRod.Start() else AutoEquipRod.Stop() end
    end
end)

ToggleReferences.DisableCutscenes = makeToggle(catSupport, "Disable Cutscenes", function(on)
    SetConfigValue("Support.DisableCutscenes", on)
    local DisableCutscenes = GetModule("DisableCutscenes")
    if DisableCutscenes then
        if on then DisableCutscenes.Start() else DisableCutscenes.Stop() end
    end
end)

ToggleReferences.DisableObtainedNotif = makeToggle(catSupport, "Disable Obtained Fish Notification", function(on)
    SetConfigValue("Support.DisableObtainedNotif", on)
    local DisableExtras = GetModule("DisableExtras")
    if DisableExtras then
        if on then DisableExtras.StartSmallNotification() else DisableExtras.StopSmallNotification() end
    end
end)

ToggleReferences.DisableSkinEffect = makeToggle(catSupport, "Disable Skin Effect", function(on)
    SetConfigValue("Support.DisableSkinEffect", on)
    local DisableExtras = GetModule("DisableExtras")
    if DisableExtras then
        if on then DisableExtras.StartSkinEffect() else DisableExtras.StopSkinEffect() end
    end
end)

ToggleReferences.WalkOnWater = makeToggle(catSupport, "Walk On Water", function(on)
    SetConfigValue("Support.WalkOnWater", on)
    local WalkOnWater = GetModule("WalkOnWater")
    if WalkOnWater then
        if on then WalkOnWater.Start() else WalkOnWater.Stop() end
    end
end)

ToggleReferences.GoodPerfectionStable = makeToggle(catSupport, "Good/Perfection Stable Mode", function(on)
    SetConfigValue("Support.GoodPerfectionStable", on)
    local GoodPerfectionStable = GetModule("GoodPerfectionStable")
    if GoodPerfectionStable then
        if on then GoodPerfectionStable.Start() else GoodPerfectionStable.Stop() end
    end
end)
end

-- AUTO FAVORITE
local catAutoFav = makeCategory(mainPage, "Auto Favorite", "⭐")
local AutoFavorite = GetModule("AutoFavorite")

if AutoFavorite then
    CheckboxReferences.AutoFavTiers = makeCheckboxDropdown(catAutoFav, "Tier Filter", AutoFavorite.GetAllTiers(), {
        Common = Color3.fromRGB(150, 150, 150), 
        Uncommon = Color3.fromRGB(76, 175, 80), 
        Rare = Color3.fromRGB(33, 150, 243), 
        Epic = Color3.fromRGB(156, 39, 176), 
        Legendary = Color3.fromRGB(255, 152, 0), 
        Mythic = Color3.fromRGB(255, 0, 0), 
        SECRET = Color3.fromRGB(0, 255, 170)
    }, function(sel) 
        AutoFavorite.ClearTiers() 
        AutoFavorite.EnableTiers(sel) 
        SetConfigValue("AutoFavorite.EnabledTiers", sel) 
    end)
    
    CheckboxReferences.AutoFavVariants = makeCheckboxDropdown(catAutoFav, "Variant Filter", AutoFavorite.GetAllVariants(), nil, function(sel) 
        AutoFavorite.ClearVariants() 
        AutoFavorite.EnableVariants(sel) 
        SetConfigValue("AutoFavorite.EnabledVariants", sel) 
    end)
    
    TrackedSpawn(function()
        task.wait(0.5)
        local tiers = GetConfigValue("AutoFavorite.EnabledTiers", {})
        if CheckboxReferences.AutoFavTiers then CheckboxReferences.AutoFavTiers.SelectSpecific(tiers) end
        if AutoFavorite then
            pcall(function()
                AutoFavorite.ClearTiers()
                AutoFavorite.EnableTiers(tiers)
            end)
        end
        
        local variants = GetConfigValue("AutoFavorite.EnabledVariants", {})
        if CheckboxReferences.AutoFavVariants then CheckboxReferences.AutoFavVariants.SelectSpecific(variants) end
        if AutoFavorite then
             pcall(function()
                AutoFavorite.ClearVariants()
                AutoFavorite.EnableVariants(variants)
            end)
        end
    end)
end

-- Auto Totem
local catAutoTotem = makeCategory(mainPage, "Auto Spawn 3X Totem", "🛠️")
makeButton(catAutoTotem, "Auto Totem 3X", function()
    local AutoTotem3X = GetModule("AutoTotem3X")
    local Notify = GetModule("Notify")
    if AutoTotem3X then
        if AutoTotem3X.IsRunning() then
            local success, message = AutoTotem3X.Stop()
            if success and Notify then Notify.Send("Auto Totem 3X", "⏹ " .. message, 4) end
        else
            local success, message = AutoTotem3X.Start()
            if Notify then
                if success then Notify.Send("Auto Totem 3X", "▶ " .. message, 4)
                else Notify.Send("Auto Totem 3X", "⚠ " .. message, 3) end
            end
        end
    end
end)

-- Skin Animation
do
local catSkin = makeCategory(mainPage, "Skin Animation", "✨")

makeButton(catSkin, "⚔️ Eclipse Katana", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("Eclipse")
        if success then
            SetConfigValue("Support.SkinAnimation.Current", "Eclipse")
            if Notify then Notify.Send("Skin Animation", "⚔️ Eclipse Katana diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then SkinAnimation.Enable() end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

makeButton(catSkin, "🔱 Holy Trident", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("HolyTrident")
        if success then
            SetConfigValue("Support.SkinAnimation.Current", "HolyTrident")
            if Notify then Notify.Send("Skin Animation", "🔱 Holy Trident diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then SkinAnimation.Enable() end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

makeButton(catSkin, "💀 Soul Scythe", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("SoulScythe")
        if success then
            SetConfigValue("Support.SkinAnimation.Current", "SoulScythe")
            if Notify then Notify.Send("Skin Animation", "💀 Soul Scythe diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then SkinAnimation.Enable() end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

ToggleReferences.SkinAnimation = makeToggle(catSkin, "Enable Skin Animation", function(on)
    SetConfigValue("Support.SkinAnimation.Enabled", on)
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        if on then
            local success = SkinAnimation.Enable()
            if Notify then
                if success then
                    local currentSkin = SkinAnimation.GetCurrentSkin()
                    local icon = currentSkin == "Eclipse" and "⚔️" or (currentSkin == "HolyTrident" and "🔱" or "💀")
                    Notify.Send("Skin Animation", "✓ " .. icon .. " " .. currentSkin .. " aktif!", 4)
                else
                    Notify.Send("Skin Animation", "⚠ Sudah aktif!", 3)
                end
            end
        else
            local success = SkinAnimation.Disable()
            if Notify then
                if success then Notify.Send("Skin Animation", "✓ Skin Animation dimatikan!", 4)
                else Notify.Send("Skin Animation", "⚠ Sudah nonaktif!", 3) end
            end
        end
    end
end)
end

-- TELEPORT PAGE
do
local TeleportModule = GetModule("TeleportModule")
local TeleportToPlayer = GetModule("TeleportToPlayer")
local SavedLocation = GetModule("SavedLocation")

if TeleportModule then
    local locationItems = {}
    for name, _ in pairs(TeleportModule.Locations) do
        table.insert(locationItems, name)
    end
    table.sort(locationItems)
    
    makeDropdown(teleportPage, "Teleport to Location", "📍", locationItems, function(selectedLocation)
        TeleportModule.TeleportTo(selectedLocation)
    end, "LocationTeleport")
end

local playerDropdown
local playerUpdateTask = nil
local isUpdatingPlayerList = false

local function updatePlayerList()
    if isUpdatingPlayerList then return end
    isUpdatingPlayerList = true
    
    local playerItems = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(playerItems, player.Name)
        end
    end
    table.sort(playerItems)
    
    if #playerItems == 0 then playerItems = {"No other players"} end
    
    if teleportPage then
        for _, child in ipairs(teleportPage:GetChildren()) do
            if child.Name == "PlayerTeleport" then
                pcall(function() child:Destroy() end)
            end
        end
    end
    
    if playerDropdown and playerDropdown.Parent then 
        playerDropdown:Destroy() 
        playerDropdown = nil
    end
    
    task.wait(0.05)
    
    if TeleportToPlayer then
        playerDropdown = makeDropdown(teleportPage, "Teleport to Player", "👤", playerItems, function(selectedPlayer)
            if selectedPlayer ~= "No other players" then
                TeleportToPlayer.TeleportTo(selectedPlayer)
            end
        end, "PlayerTeleport")
    end
    
    isUpdatingPlayerList = false
end

updatePlayerList()

ConnectionManager:Add(Players.PlayerAdded:Connect(function()
    if playerUpdateTask then task.cancel(playerUpdateTask) end
    playerUpdateTask = task.delay(0.5, updatePlayerList)
end))

ConnectionManager:Add(Players.PlayerRemoving:Connect(function()
    if playerUpdateTask then task.cancel(playerUpdateTask) end
    playerUpdateTask = task.delay(0.1, updatePlayerList)
end))

local catSaved = makeCategory(teleportPage, "Saved Location", "⭐")

makeButton(catSaved, "Save Current Location", function()
    if SavedLocation then
        SavedLocation.Save()
        SendNotification("Saved Location", "Lokasi berhasil disimpan.", 3)
    end
end)

makeButton(catSaved, "Teleport Saved Location", function()
    if SavedLocation then
        if SavedLocation.Teleport() then
            SendNotification("Teleported", "Berhasil teleport ke lokasi tersimpan.", 3)
        else
            SendNotification("Error", "Tidak ada lokasi yang disimpan!", 3)
        end
    end
end)

makeButton(catSaved, "Reset Saved Location", function()
    if SavedLocation then
        SavedLocation.Reset()
        SendNotification("Reset", "Lokasi tersimpan telah dihapus.", 3)
    end
end)

local catTeleport = makeCategory(teleportPage, "Event Teleport", "🎯")
local selectedEventName = GetConfigValue("Teleport.LastEventSelected", nil)
local EventTeleport = GetModule("EventTeleportDynamic")

if EventTeleport then
    local eventNames = EventTeleport.GetEventNames() or {}
    if #eventNames == 0 then eventNames = {"- No events available -"} end
    
    DropdownReferences.EventTeleport = makeDropdown(catTeleport, "Pilih Event", "📌", eventNames, function(selected)
        if selected ~= "- No events available -" then
            selectedEventName = selected
            SetConfigValue("Teleport.LastEventSelected", selected)
            SendNotification("Event", "Event dipilih: " .. tostring(selected), 3)
        end
    end, "EventTeleport")
    
    ToggleReferences.AutoTeleportEvent = makeToggle(catTeleport, "Enable Auto Teleport", function(on)
        SetConfigValue("Teleport.AutoTeleportEvent", on)
        
        if on then
            if selectedEventName and selectedEventName ~= "- No events available -" and EventTeleport.HasCoords(selectedEventName) then
                EventTeleport.Start(selectedEventName)
                SendNotification("Auto Teleport", "Mulai auto teleport ke " .. selectedEventName, 4)
            else
                SendNotification("Auto Teleport", "Pilih event yang memiliki koordinat dulu!", 3)
            end
        else
            EventTeleport.Stop()
            SendNotification("Auto Teleport", "Auto teleport dihentikan.", 3)
        end
    end)
    
    makeButton(catTeleport, "Teleport Now", function()
        if selectedEventName and selectedEventName ~= "- No events available -" then
            local ok = EventTeleport.TeleportNow(selectedEventName)
            if ok then SendNotification("Teleport", "Teleported ke " .. selectedEventName, 3)
            else SendNotification("Teleport", "Teleport gagal!", 3) end
        else
            SendNotification("Teleport", "Event belum dipilih!", 3)
        end
    end)
end
end

-- SHOP PAGE
do
local AutoSell = GetModule("AutoSell")
local MerchantSystem = GetModule("MerchantSystem")
local RemoteBuyer = GetModule("RemoteBuyer")

local catSell = makeCategory(shopPage, "Sell All", "💰")
makeButton(catSell, "Sell All Now", function()
    if AutoSell and AutoSell.SellOnce then AutoSell.SellOnce() end
end)

local catTimer = makeCategory(shopPage, "Auto Sell Timer", "⏰")
local AutoSellTimer = GetModule("AutoSellTimer")

if AutoSellTimer then
    InputReferences.AutoSellInterval = makeInput(catTimer, "Sell Interval (seconds)", GetConfigValue("Shop.AutoSellTimer.Interval", 5), function(value)
        SetConfigValue("Shop.AutoSellTimer.Interval", value)
        if AutoSellTimer then pcall(function() AutoSellTimer.SetInterval(value) end) end
    end)

    ToggleReferences.AutoSellTimer = makeToggle(catTimer, "Auto Sell Timer", function(on)
        SetConfigValue("Shop.AutoSellTimer.Enabled", on)
        if AutoSellTimer then
            pcall(function()
                if on then
                    local interval = GetConfigValue("Shop.AutoSellTimer.Interval", 5)
                    AutoSellTimer.Start(interval)
                else
                    AutoSellTimer.Stop()
                end
            end)
        end
    end)
end

local catWeather = makeCategory(shopPage, "Auto Buy Weather", "🌦️")
local AutoBuyWeather = GetModule("AutoBuyWeather")

if AutoBuyWeather then
    CheckboxReferences.AutoBuyWeather = makeCheckboxList(
        catWeather,
        AutoBuyWeather.AllWeathers,
        nil,
        function(selectedWeathers)
            AutoBuyWeather.SetSelected(selectedWeathers)
            SetConfigValue("Shop.AutoBuyWeather.SelectedWeathers", selectedWeathers)
        end
    )
    
    ToggleReferences.AutoBuyWeather = makeToggle(catWeather, "Enable Auto Weather", function(on)
        SetConfigValue("Shop.AutoBuyWeather.Enabled", on)
        
        if on then
            local selected = CheckboxReferences.AutoBuyWeather.GetSelected()
            if #selected == 0 then
                SendNotification("Auto Weather", "Pilih minimal 1 cuaca!", 3)
                return
            end
            AutoBuyWeather.Start()
            SendNotification("Auto Weather", "Auto buy weather aktif!", 3)
        else
            AutoBuyWeather.Stop()
            SendNotification("Auto Weather", "Auto buy weather dimatikan.", 3)
        end
    end)
end

local catMerchant = makeCategory(shopPage, "Remote Merchant", "🛒")

makeButton(catMerchant, "Open Merchant", function()
    if MerchantSystem then
        MerchantSystem.Open()
        SendNotification("Merchant", "Merchant dibuka!", 3)
    end
end)

makeButton(catMerchant, "Close Merchant", function()
    if MerchantSystem then
        MerchantSystem.Close()
        SendNotification("Merchant", "Merchant ditutup!", 3)
    end
end)

local catRod = makeCategory(shopPage, "Buy Rod", "🎣")

if RemoteBuyer then
    local RodData = {
        ["Chrome Rod"] = {id = 7, price = 437000},
        ["Lucky Rod"] = {id = 4, price = 15000},
        ["Starter Rod"] = {id = 1, price = 50},
        ["Carbon Rod"] = {id = 76, price = 750},
        ["Astral Rod"] = {id = 5, price = 1000000},
    }
    
    local RodList = {}
    local RodMap = {}
    for rodName, info in pairs(RodData) do
        local display = rodName .. " (" .. tostring(info.price) .. ")"
        table.insert(RodList, display)
        RodMap[display] = rodName
    end
    
    local SelectedRod = nil
    
    DropdownReferences.RodSelector = makeDropdown(catRod, "Select Rod", "🎣", RodList, function(displayName)
        SelectedRod = RodMap[displayName]
        SetConfigValue("Shop.SelectedRod", displayName)
        SendNotification("Rod Selected", "Rod: " .. SelectedRod, 3)
    end, "RodDropdown")
    
    makeButton(catRod, "BUY SELECTED ROD", function()
        if SelectedRod then
            RemoteBuyer.BuyRod(RodData[SelectedRod].id)
            SendNotification("Buy Rod", "Membeli " .. SelectedRod .. "...", 3)
        else
            SendNotification("Buy Rod", "Pilih rod dulu!", 3)
        end
    end)
end

local catBait = makeCategory(shopPage, "Buy Bait", "🪱")

if RemoteBuyer then
    local BaitData = {
        ["Chroma Bait"] = {id = 6, price = 290000},
        ["Luck Bait"] = {id = 2, price = 1000},
        ["Midnight Bait"] = {id = 3, price = 3000},
    }
    
    local BaitList = {}
    local BaitMap = {}
    for baitName, info in pairs(BaitData) do
        local display = baitName .. " (" .. tostring(info.price) .. ")"
        table.insert(BaitList, display)
        BaitMap[display] = baitName
    end
    
    local SelectedBait = nil
    
    DropdownReferences.BaitSelector = makeDropdown(catBait, "Select Bait", "🪱", BaitList, function(displayName)
        SelectedBait = BaitMap[displayName]
        SetConfigValue("Shop.SelectedBait", displayName)
        SendNotification("Bait Selected", "Bait: " .. SelectedBait, 3)
    end, "BaitDropdown")
    
    makeButton(catBait, "BUY SELECTED BAIT", function()
        if SelectedBait then
            RemoteBuyer.BuyBait(BaitData[SelectedBait].id)
            SendNotification("Buy Bait", "Membeli " .. SelectedBait .. "...", 3)
        else
            SendNotification("Buy Bait", "Pilih bait dulu!", 3)
        end
    end)
end
end

-- WEBHOOK PAGE
local catWebhook = makeCategory(webhookPage, "Webhook Configuration", "🔗")
local WebhookModule = GetModule("Webhook")
local currentWebhookURL = GetConfigValue("Webhook.URL", "")
local currentDiscordID = GetConfigValue("Webhook.DiscordID", "")

local isWebhookSupported = false
if WebhookModule then
    isWebhookSupported = WebhookModule:IsSupported()
    
    if not isWebhookSupported then
        local warningFrame = new("Frame", {
            Parent = catWebhook,
            Size = UDim2.new(1, 0, 0, 70),
            BackgroundColor3 = colors.danger,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            ZIndex = 7
        })
        new("UICorner", {Parent = warningFrame, CornerRadius = UDim.new(0, 8)})
        
        new("TextLabel", {
            Parent = warningFrame,
            Size = UDim2.new(1, -24, 1, -24),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Text = "⚠️ WEBHOOK NOT SUPPORTED\n\nYour executor doesn't support HTTP requests.\nPlease use: Xeno, Synapse X, Script-Ware, or Fluxus.",
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = colors.text,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 8
        })
    else
        WebhookModule:SetSimpleMode(true)
    end
end

local webhookURLFrame = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 7
})

new("TextLabel", {
    Parent = webhookURLFrame,
    Text = "Webhook URL" .. (not isWebhookSupported and " (Disabled)" or ""),
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    TextColor3 = not isWebhookSupported and colors.textDim or colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 8
})

local webhookURLBg = new("Frame", {
    Parent = webhookURLFrame,
    Size = UDim2.new(1, 0, 0, 35),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = not isWebhookSupported and 0.8 or 0.4,
    BorderSizePixel = 0,
    ZIndex = 8
})
new("UICorner", {Parent = webhookURLBg, CornerRadius = UDim.new(0, 6)})

local webhookTextBox = new("TextBox", {
    Parent = webhookURLBg,
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1,
    Text = currentWebhookURL,
    PlaceholderText = not isWebhookSupported and "Not supported on this executor" or "https://discord.com/api/webhooks/...",
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextColor3 = not isWebhookSupported and colors.textDim or colors.text,
    PlaceholderColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    TextEditable = isWebhookSupported,
    ZIndex = 9
})

InputReferences.WebhookURL = {
    Instance = webhookTextBox,
    SetValue = function(val)
        webhookTextBox.Text = tostring(val)
        currentWebhookURL = tostring(val)
        if WebhookModule and currentWebhookURL ~= "" then
            pcall(function() WebhookModule:SetWebhookURL(currentWebhookURL) end)
        end
    end
}

if isWebhookSupported then
    ConnectionManager:Add(webhookTextBox.FocusLost:Connect(function()
        currentWebhookURL = webhookTextBox.Text
        SetConfigValue("Webhook.URL", currentWebhookURL)
        
        if WebhookModule and currentWebhookURL ~= "" then
            pcall(function() WebhookModule:SetWebhookURL(currentWebhookURL) end)
            SendNotification("Webhook", "Webhook URL tersimpan!", 2)
        end
    end))
end

local discordIDFrame = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 7
})

new("TextLabel", {
    Parent = discordIDFrame,
    Text = "Discord User ID (Optional)" .. (not isWebhookSupported and " (Disabled)" or ""),
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    TextColor3 = not isWebhookSupported and colors.textDim or colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 8
})

local discordIDBg = new("Frame", {
    Parent = discordIDFrame,
    Size = UDim2.new(1, 0, 0, 35),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = not isWebhookSupported and 0.8 or 0.4,
    BorderSizePixel = 0,
    ZIndex = 8
})
new("UICorner", {Parent = discordIDBg, CornerRadius = UDim.new(0, 6)})

local discordIDTextBox = new("TextBox", {
    Parent = discordIDBg,
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1,
    Text = currentDiscordID,
    PlaceholderText = not isWebhookSupported and "Not supported on this executor" or "123456789012345678",
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextColor3 = not isWebhookSupported and colors.textDim or colors.text,
    PlaceholderColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    TextEditable = isWebhookSupported,
    ZIndex = 9
})

InputReferences.DiscordID = {
    Instance = discordIDTextBox,
    SetValue = function(val)
        discordIDTextBox.Text = tostring(val)
        currentDiscordID = tostring(val)
        if WebhookModule then
            pcall(function() WebhookModule:SetDiscordUserID(currentDiscordID) end)
        end
    end
}

if isWebhookSupported then
    ConnectionManager:Add(discordIDTextBox.FocusLost:Connect(function()
        currentDiscordID = discordIDTextBox.Text
        SetConfigValue("Webhook.DiscordID", currentDiscordID)
        
        if WebhookModule then
            pcall(function() WebhookModule:SetDiscordUserID(currentDiscordID) end)
            if currentDiscordID ~= "" then

                SendNotification("Webhook", "Discord ID tersimpan!", 2)
            end
        end
    end))
end

local AllRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}
local rarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Uncommon = Color3.fromRGB(76, 175, 80),
    Rare = Color3.fromRGB(33, 150, 243),
    Epic = Color3.fromRGB(156, 39, 176),
    Legendary = Color3.fromRGB(255, 152, 0),
    Mythic = Color3.fromRGB(255, 0, 0),
    SECRET = Color3.fromRGB(0, 255, 170)
}

local rarityCheckboxSystem = makeCheckboxList(
    catWebhook,
    AllRarities,
    rarityColors,
    function(selectedRarities)
        if WebhookModule and isWebhookSupported then
            pcall(function() WebhookModule:SetEnabledRarities(selectedRarities) end)
        end
        SetConfigValue("Webhook.EnabledRarities", selectedRarities)
    end
)

ToggleReferences.Webhook = makeToggle(catWebhook, "Enable Webhook" .. (not isWebhookSupported and " (Not Supported)" or ""), function(on)
    if not isWebhookSupported then
        SendNotification("Error", "Webhook not supported on this executor!", 3)
        if ToggleReferences.Webhook then
            TrackedSpawn(function()
                task.wait(0.1)
                ToggleReferences.Webhook.setOn(false, true)
            end)
        end
        return
    end
    
    SetConfigValue("Webhook.Enabled", on)
    
    if not WebhookModule then
        SendNotification("Error", "Webhook module tidak tersedia!", 3)
        return
    end
    
    if on then
        if currentWebhookURL == "" then
            SendNotification("Error", "Masukkan Webhook URL dulu!", 3)
            if ToggleReferences.Webhook then
                TrackedSpawn(function()
                    task.wait(0.1)
                    ToggleReferences.Webhook.setOn(false, true)
                end)
            end
            return
        end
        
        local success = pcall(function()
            WebhookModule:SetWebhookURL(currentWebhookURL)
            if currentDiscordID ~= "" then
                WebhookModule:SetDiscordUserID(currentDiscordID)
            end
            local selected = rarityCheckboxSystem.GetSelected()
            WebhookModule:SetEnabledRarities(selected)
            WebhookModule:Start()
        end)
        
        if success then
            local selected = rarityCheckboxSystem.GetSelected()
            local filterInfo = #selected > 0 
                and (" (Filter: " .. table.concat(selected, ", ") .. ")")
                or " (All rarities)"
            SendNotification("Webhook", "Webhook logging aktif!" .. filterInfo, 4)
        else
            SendNotification("Error", "Failed to start webhook!", 3)
            if ToggleReferences.Webhook then
                TrackedSpawn(function()
                    task.wait(0.1)
                    ToggleReferences.Webhook.setOn(false, true)
                end)
            end
        end
    else
        pcall(function() WebhookModule:Stop() end)
        SendNotification("Webhook", "Webhook logging dinonaktifkan.", 3)
    end
end)

if not isWebhookSupported then
    TrackedSpawn(function()
        task.wait(0.5)
        if ToggleReferences.Webhook then
            ToggleReferences.Webhook.setOn(false, true)
        end
    end)
end

-- CAMERA VIEW PAGE
local catZoom = makeCategory(cameraViewPage, "Unlimited Zoom", "🔍")
local UnlimitedZoomModule = GetModule("UnlimitedZoomModule")

ToggleReferences.UnlimitedZoom = makeToggle(catZoom, "Enable Unlimited Zoom", function(on)
    SetConfigValue("CameraView.UnlimitedZoom", on)
    if UnlimitedZoomModule then
        if on then
            local success = UnlimitedZoomModule.Enable()
            if success then SendNotification("Zoom", "Unlimited Zoom aktif!", 4) end
        else
            UnlimitedZoomModule.Disable()
            SendNotification("Zoom", "Unlimited Zoom nonaktif.", 3)
        end
    end
end)

local catFreecam = makeCategory(cameraViewPage, "Freecam", "📹")
local FreecamModule = GetModule("FreecamModule")

ToggleReferences.Freecam = makeToggle(catFreecam, "Enable Freecam", function(on)
    SetConfigValue("CameraView.Freecam.Enabled", on)
    if FreecamModule then
        if on then
            if not isMobile then
                FreecamModule.EnableF3Keybind(true)
                SendNotification("Freecam", "Freecam siap! Tekan F3.", 4)
            else
                FreecamModule.Start()
                SendNotification("Freecam", "Freecam aktif!", 4)
            end
        else
            FreecamModule.EnableF3Keybind(false)
            SendNotification("Freecam", "Freecam nonaktif.", 3)
        end
    end
end)

InputReferences.FreecamSpeed = makeInput(catFreecam, "Movement Speed", GetConfigValue("CameraView.Freecam.Speed", 50), function(value)
    SetConfigValue("CameraView.Freecam.Speed", value)
    if FreecamModule then FreecamModule.SetSpeed(value) end
end)

InputReferences.FreecamSensitivity = makeInput(catFreecam, "Mouse Sensitivity", GetConfigValue("CameraView.Freecam.Sensitivity", 0.3), function(value)
    SetConfigValue("CameraView.Freecam.Sensitivity", value)
    if FreecamModule then FreecamModule.SetSensitivity(value) end
end)

-- SETTINGS PAGE
local catAFK = makeCategory(settingsPage, "Anti-AFK", "⏱️")
local AntiAFK = GetModule("AntiAFK")

ToggleReferences.AntiAFK = makeToggle(catAFK, "Enable Anti-AFK", function(on)
    SetConfigValue("Settings.AntiAFK", on)
    if AntiAFK then
        if on then AntiAFK.Start() else AntiAFK.Stop() end
    end
end)

local catMovement = makeCategory(settingsPage, "Player Utility", "🏃")

InputReferences.SprintSpeed = makeInput(catMovement, "Sprint Speed", GetConfigValue("Movement.SprintSpeed", 50), function(v)
    SetConfigValue("Movement.SprintSpeed", v)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then MovementModule.SetSprintSpeed(v) end
end)

ToggleReferences.Sprint = makeToggle(catMovement, "Enable Sprint", function(on)
    SetConfigValue("Movement.SprintEnabled", on)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then
        if on then MovementModule.EnableSprint() else MovementModule.DisableSprint() end
    end
end)

ToggleReferences.InfiniteJump = makeToggle(catMovement, "Enable Infinite Jump", function(on)
    SetConfigValue("Movement.InfiniteJump", on)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then
        if on then MovementModule.EnableInfiniteJump() else MovementModule.DisableInfiniteJump() end
    end
end)

-- No Clip Toggle (NEW!)
ToggleReferences.NoClip = makeToggle(catMovement, "Enable No Clip", function(on)
    SetConfigValue("Movement.NoClip", on)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then
        if on then 
            MovementModule.EnableNoClip()
        else 
            MovementModule.DisableNoClip()
        end
    end
end)

local catBoost = makeCategory(settingsPage, "Performance", "⚡")
local FPSBooster = GetModule("FPSBooster")
local DisableRenderingModule = GetModule("DisableRendering")

ToggleReferences.FPSBooster = makeToggle(catBoost, "Enable FPS Booster", function(on)
    SetConfigValue("Settings.FPSBooster", on)
    if FPSBooster then
        if on then
            FPSBooster.Enable()
            SendNotification("FPS Booster", "FPS Booster diaktifkan!", 3)
        else
            FPSBooster.Disable()
            SendNotification("FPS Booster", "FPS Booster dimatikan.", 3)
        end
    end
end)

ToggleReferences.DisableRendering = makeToggle(catBoost, "Disable 3D Rendering", function(on)
    SetConfigValue("Settings.DisableRendering", on)
    if DisableRenderingModule then
        if on then DisableRenderingModule.Start() else DisableRenderingModule.Stop() end
    end
end)

local catFPS = makeCategory(settingsPage, "FPS Settings", "🎮")
local UnlockFPS = GetModule("UnlockFPS")

makeDropdown(catFPS, "Select FPS Limit", "⚙️", {"60 FPS", "90 FPS", "120 FPS", "240 FPS"}, function(selected)
    local fpsValue = tonumber(selected:match("%d+"))
    SetConfigValue("Settings.FPSLimit", fpsValue)
    if fpsValue and UnlockFPS then UnlockFPS.SetCap(fpsValue) end
end, "FPSDropdown")

local catHideStats = makeCategory(settingsPage, "Hide Stats", "👤")
local HideStats = GetModule("HideStats")
local currentFakeName = GetConfigValue("Settings.HideStats.FakeName", "ZoyyHub")
local currentFakeLevel = GetConfigValue("Settings.HideStats.FakeLevel", "1")

local fakeNameFrame = new("Frame", {
    Parent = catHideStats,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 7
})

new("TextLabel", {
    Parent = fakeNameFrame,
    Text = "Fake Name",
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    TextColor3 = colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 8
})

local fakeNameBg = new("Frame", {
    Parent = fakeNameFrame,
    Size = UDim2.new(1, 0, 0, 35),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ZIndex = 8
})
new("UICorner", {Parent = fakeNameBg, CornerRadius = UDim.new(0, 6)})

local fakeNameTextBox = new("TextBox", {
    Parent = fakeNameBg,
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1,
    Text = currentFakeName,
    PlaceholderText = "ZoyyHub",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    PlaceholderColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 9
})

ConnectionManager:Add(fakeNameTextBox.FocusLost:Connect(function()
    local value = fakeNameTextBox.Text
    if value and value ~= "" then
        currentFakeName = value
        SetConfigValue("Settings.HideStats.FakeName", value)
        if HideStats then
            pcall(function() HideStats.SetFakeName(value) end)
            SendNotification("Hide Stats", "Fake name set: " .. value, 2)
        end
    end
end))

local fakeLevelFrame = new("Frame", {
    Parent = catHideStats,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 7
})

new("TextLabel", {
    Parent = fakeLevelFrame,
    Text = "Fake Level",
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    TextColor3 = colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 8
})

local fakeLevelBg = new("Frame", {
    Parent = fakeLevelFrame,
    Size = UDim2.new(1, 0, 0, 35),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ZIndex = 8
})
new("UICorner", {Parent = fakeLevelBg, CornerRadius = UDim.new(0, 6)})

local fakeLevelTextBox = new("TextBox", {
    Parent = fakeLevelBg,
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1,
    Text = currentFakeLevel,
    PlaceholderText = "1",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    PlaceholderColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 9
})

ConnectionManager:Add(fakeLevelTextBox.FocusLost:Connect(function()
    local value = fakeLevelTextBox.Text
    if value and value ~= "" then
        currentFakeLevel = value
        SetConfigValue("Settings.HideStats.FakeLevel", value)
        if HideStats then
            pcall(function() HideStats.SetFakeLevel(value) end)
            SendNotification("Hide Stats", "Fake level set: " .. value, 2)
        end
    end
end))

ToggleReferences.HideStats = makeToggle(catHideStats, "⚡ Enable Hide Stats", function(on)
    SetConfigValue("Settings.HideStats.Enabled", on)
    
    if not HideStats then
        SendNotification("Error", "Hide Stats module tidak tersedia!", 3)
        return
    end
    
    if on then
        pcall(function()
            if currentFakeName ~= "" and currentFakeName ~= "ZoyyHub" then
                HideStats.SetFakeName(currentFakeName)
            end
            if currentFakeLevel ~= "" and currentFakeLevel ~= "1" then
                HideStats.SetFakeLevel(currentFakeLevel)
            end
            HideStats.Enable()
        end)
        SendNotification("Hide Stats", "✓ Hide Stats aktif!\nName: " .. currentFakeName .. " | Level: " .. currentFakeLevel, 4)
    else
        pcall(function() HideStats.Disable() end)
        SendNotification("Hide Stats", "✓ Hide Stats dimatikan!", 3)
    end
end)

local catServer = makeCategory(settingsPage, "Server Features", "🔄")

makeButton(catServer, "Rejoin Server", function()
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
    SendNotification("Rejoin", "Teleporting to new server...", 3)
end)

-- Apply Config to GUI
local function ApplyConfigToGUI()
    local toggleMappings = {
        {"InstantFishing", "InstantFishing.Enabled"},
        {"BlatantTester", "BlatantTester.Enabled"},
        {"BlatantV1", "BlatantV1.Enabled"},
        {"UltraBlatant", "UltraBlatant.Enabled"},
        {"FastAutoPerfect", "FastAutoPerfect.Enabled"},
        {"NoFishingAnimation", "Support.NoFishingAnimation"},
        {"LockPosition", "Support.LockPosition"},
        {"AutoEquipRod", "Support.AutoEquipRod"},
        {"DisableCutscenes", "Support.DisableCutscenes"},
        {"DisableObtainedNotif", "Support.DisableObtainedNotif"},
        {"DisableSkinEffect", "Support.DisableSkinEffect"},
        {"WalkOnWater", "Support.WalkOnWater"},
        {"GoodPerfectionStable", "Support.GoodPerfectionStable"},
        {"AutoSellTimer", "Shop.AutoSellTimer.Enabled"},
        {"AutoBuyWeather", "Shop.AutoBuyWeather.Enabled"},
        {"Webhook", "Webhook.Enabled"},
        {"UnlimitedZoom", "CameraView.UnlimitedZoom"},
        {"Freecam", "CameraView.Freecam.Enabled"},
        {"AntiAFK", "Settings.AntiAFK"},
        {"FPSBooster", "Settings.FPSBooster"},
        {"DisableRendering", "Settings.DisableRendering"},
        {"HideStats", "Settings.HideStats.Enabled"},
        {"Sprint", "Movement.SprintEnabled"},
        {"InfiniteJump", "Movement.InfiniteJump"},
        {"PingFPSMonitor", "Support.PingFPSMonitor"},
        {"AutoTeleportEvent", "Teleport.AutoTeleportEvent"},
        {"SkinAnimation", "Support.SkinAnimation.Enabled"},
    }
    
    local inputMappings = {
        {"FishingDelay", "InstantFishing.FishingDelay"},
        {"CancelDelay", "InstantFishing.CancelDelay"},
        {"AutoSellInterval", "Shop.AutoSellTimer.Interval"},
        {"WebhookURL", "Webhook.URL"},
        {"DiscordID", "Webhook.DiscordID"},
        {"FreecamSpeed", "CameraView.Freecam.Speed"},
        {"FreecamSensitivity", "CameraView.Freecam.Sensitivity"},
        {"BlatantCompleteDelay", "BlatantTester.CompleteDelay"},
        {"BlatantCancelDelay", "BlatantTester.CancelDelay"},
        {"SprintSpeed", "Movement.SprintSpeed"},
        {"BlatantV1CompleteDelay", "BlatantV1.CompleteDelay"},
        {"BlatantV1CancelDelay", "BlatantV1.CancelDelay"},
        {"UltraBlatantCompleteDelay", "UltraBlatant.CompleteDelay"},
        {"UltraBlatantCancelDelay", "UltraBlatant.CancelDelay"},
        {"FastAutoFishingDelay", "FastAutoPerfect.FishingDelay"},
        {"FastAutoCancelDelay", "FastAutoPerfect.CancelDelay"},
        {"FastAutoTimeoutDelay", "FastAutoPerfect.TimeoutDelay"},
    }
    
    local dropdownMappings = {
        {"InstantFishingMode", "InstantFishing.Mode"},
        {"EventTeleport", "Teleport.LastEventSelected"},
        {"RodSelector", "Shop.SelectedRod"},
        {"BaitSelector", "Shop.SelectedBait"},
    }

    local checkboxMappings = {
        {"AutoFavTiers", "AutoFavorite.EnabledTiers"},
        {"AutoFavVariants", "AutoFavorite.EnabledVariants"},
        {"AutoBuyWeather", "Shop.AutoBuyWeather.SelectedWeathers"},
    }
    
    for _, mapping in ipairs(toggleMappings) do
        local refKey, configPath = mapping[1], mapping[2]
        if ToggleReferences[refKey] and ToggleReferences[refKey].setOn then
            local val = GetConfigValue(configPath, false)
            if type(val) == "boolean" then
                ToggleReferences[refKey].setOn(val, false) 
            end
        end
    end
    
    for _, mapping in ipairs(inputMappings) do
        local refKey, configPath = mapping[1], mapping[2]
        if InputReferences[refKey] and InputReferences[refKey].SetValue then
            local val = GetConfigValue(configPath, nil)
            if val ~= nil then
                InputReferences[refKey].SetValue(val)
            end
        end
    end
    
    for _, mapping in ipairs(dropdownMappings) do
        local refKey, configPath = mapping[1], mapping[2]
        if DropdownReferences[refKey] and DropdownReferences[refKey].SetValue then
            local val = GetConfigValue(configPath, nil)
            if val ~= nil then
                DropdownReferences[refKey].SetValue(val)
            end
        end
    end

    for _, mapping in ipairs(checkboxMappings) do
        local refKey, configPath = mapping[1], mapping[2]
        if CheckboxReferences[refKey] and CheckboxReferences[refKey].SelectSpecific then
            local val = GetConfigValue(configPath, {})
            if type(val) == "table" then
                CheckboxReferences[refKey].SelectSpecific(val)
            end
        end
    end

    local savedSkin = GetConfigValue("Support.SkinAnimation.Current", nil)
    local SkinAnimation = GetModule("SkinAnimation")
    if savedSkin and SkinAnimation then
        SkinAnimation.SwitchSkin(savedSkin)
    end
    
    SendNotification("Config", "✓ All settings applied!", 2)
end

local catConfig = makeCategory(settingsPage, "Save Config", "💾")

local configInputContainer = new("Frame", {
    Parent = catConfig,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = configInputContainer, CornerRadius = UDim.new(0, 8)})

local configNameInput = new("TextBox", {
    Parent = configInputContainer,
    Size = UDim2.new(1, -120, 0, 30),
    Position = UDim2.new(0, 10, 0.5, -15),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Enter config name...",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = colors.text,
    PlaceholderColor3 = colors.textDim,
    ClearTextOnFocus = false,
    ZIndex = 8
})
new("UICorner", {Parent = configNameInput, CornerRadius = UDim.new(0, 6)})

local saveConfigBtn = new("TextButton", {
    Parent = configInputContainer,
    Size = UDim2.new(0, 90, 0, 30),
    Position = UDim2.new(1, -100, 0.5, -15),
    BackgroundColor3 = colors.primary,
    BorderSizePixel = 0,
    Text = "💾 Save",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = colors.text,
    AutoButtonColor = true,
    ZIndex = 8
})
new("UICorner", {Parent = saveConfigBtn, CornerRadius = UDim.new(0, 6)})

local savedConfigsLabel = new("TextLabel", {
    Parent = catConfig,
    Size = UDim2.new(1, 0, 0, 25),
    BackgroundTransparency = 1,
    Text = "📁 Saved Configs:",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

local configListContainer = new("ScrollingFrame", {
    Parent = catConfig,
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = colors.primary,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 7
})
new("UICorner", {Parent = configListContainer, CornerRadius = UDim.new(0, 8)})
new("UIListLayout", {Parent = configListContainer, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name})
new("UIPadding", {Parent = configListContainer, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

local function GetSavedConfigs()
    local configs = {}
    pcall(function()
        if isfolder and isfolder("ZoyyHubGUI_Configs") then
            local files = listfiles("ZoyyHubGUI_Configs")
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(configs, name)
                end
            end
        end
    end)
    return configs
end

local function RefreshConfigList()
    for _, child in ipairs(configListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local configs = GetSavedConfigs()
    
    if #configs == 0 then
        new("TextLabel", {
            Parent = configListContainer,
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundTransparency = 1,
            Text = "No saved configs yet",
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = colors.textDim,
            ZIndex = 8
        })
    else
        for _, configName in ipairs(configs) do
            local itemFrame = new("Frame", {
                Parent = configListContainer,
                Size = UDim2.new(1, -8, 0, 32),
                BackgroundColor3 = colors.bg2,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ZIndex = 8
            })
            new("UICorner", {Parent = itemFrame, CornerRadius = UDim.new(0, 6)})
            
            new("TextLabel", {
                Parent = itemFrame,
                Size = UDim2.new(1, -140, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "📄 " .. configName,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = colors.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 9
            })
            
            local loadBtn = new("TextButton", {
                Parent = itemFrame,
                Size = UDim2.new(0, 55, 0, 24),
                Position = UDim2.new(1, -130, 0.5, -12),
                BackgroundColor3 = colors.success,
                BorderSizePixel = 0,
                Text = "Load",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = colors.text,
                AutoButtonColor = true,
                ZIndex = 9
            })
            new("UICorner", {Parent = loadBtn, CornerRadius = UDim.new(0, 4)})
            
            local deleteBtn = new("TextButton", {
                Parent = itemFrame,
                Size = UDim2.new(0, 55, 0, 24),
                Position = UDim2.new(1, -70, 0.5, -12),
                BackgroundColor3 = colors.danger,
                BorderSizePixel = 0,
                Text = "Delete",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = colors.text,
                AutoButtonColor = true,
                ZIndex = 9
            })
            new("UICorner", {Parent = deleteBtn, CornerRadius = UDim.new(0, 4)})
            
            ConnectionManager:Add(loadBtn.MouseButton1Click:Connect(function()
                local loaded = false
                local success, err = pcall(function()
                    local filePath = "ZoyyHubGUI_Configs/" .. configName .. ".json"
                    if isfile(filePath) then
                        local content = readfile(filePath)
                        local data = game:GetService("HttpService"):JSONDecode(content)
                        
                        local function ApplyRecursive(tbl, prefix)
                            for key, value in pairs(tbl) do
                                local path = prefix == "" and key or (prefix .. "." .. key)
                                if type(value) == "table" then
                                    local isArray = true
                                    local maxIndex = 0
                                    for k, v in pairs(value) do
                                        if type(k) ~= "number" then
                                            isArray = false
                                            break
                                        end
                                        maxIndex = math.max(maxIndex, k)
                                    end
                                    
                                    if isArray and maxIndex > 0 then
                                        if ConfigSystem and ConfigSystem.Set then
                                            ConfigSystem.Set(path, value)
                                        end
                                    else
                                        ApplyRecursive(value, path)
                                    end
                                else
                                    if ConfigSystem and ConfigSystem.Set then
                                        ConfigSystem.Set(path, value)
                                    end
                                end
                            end
                        end
                        
                        ApplyRecursive(data, "")
                        
                        if ConfigSystem and ConfigSystem.Save then
                            ConfigSystem.Save()
                        end
                        loaded = true
                    else
                        error("File not found")
                    end
                end)
                
                if success and loaded then
                    SendNotification("Config", "✓ Loaded: " .. configName, 2)
                    task.delay(0.3, function()
                        ApplyConfigToGUI()
                    end)
                else
                    SendNotification("Config", "⚠ Load Fail: " .. tostring(err), 4)
                end
            end))
            
            ConnectionManager:Add(deleteBtn.MouseButton1Click:Connect(function()
                local success = pcall(function()
                    local filePath = "ZoyyHubGUI_Configs/" .. configName .. ".json"
                    if isfile(filePath) then
                        delfile(filePath)
                    end
                end)
                
                if success then
                    SendNotification("Config", "🗑️ Deleted: " .. configName, 3)
                    if itemFrame then itemFrame:Destroy() end
                    task.delay(0.05, function()
                        local layout = configListContainer:FindFirstChild("UIListLayout")
                        if layout then
                            configListContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
                        end
                    end)
                else
                    SendNotification("Config", "⚠ Failed to delete", 3)
                end
            end))
        end
    end
    
    local layout = configListContainer:FindFirstChild("UIListLayout")
    if layout then
        configListContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end
end

ConnectionManager:Add(saveConfigBtn.MouseButton1Click:Connect(function()
    local configName = configNameInput.Text:gsub("[^%w%s%-_]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    if configName == "" then
        configName = "Config_" .. os.date("%Y%m%d_%H%M%S")
    end
    
    local success, err = pcall(function()
        if not isfolder("ZoyyHubGUI_Configs") then
            makefolder("ZoyyHubGUI_Configs")
        end
        
        local configData = {}
        local cfStatus, cfResult = pcall(function()
            if ConfigSystem and ConfigSystem.GetConfig then
                return ConfigSystem.GetConfig()
            end
            return {}
        end)
        
        if not cfStatus then error("GetConfig Logic Error: " .. tostring(cfResult)) end
        configData = cfResult or {}
        
        local function Sanitize(tbl, depth, seen)
            if depth and depth > 50 then return nil end
            depth = depth or 0
            seen = seen or {}
            
            if type(tbl) ~= "table" then return tbl end
            if seen[tbl] then return nil end
            seen[tbl] = true
            
            local clean = {}
            for k, v in pairs(tbl) do
                if type(k) == "string" or type(k) == "number" then
                    local t = typeof(v)
                    if t == "table" then
                        local res = Sanitize(v, depth + 1, seen)
                        if res ~= nil then clean[k] = res end
                    elseif t == "string" or t == "number" or t == "boolean" then
                        clean[k] = v
                    end
                end
            end
            return clean
        end
        
        local cleanData = Sanitize(configData)
        if not cleanData then cleanData = {} end
        
        local jsonSuccess, json = pcall(function() return game:GetService("HttpService"):JSONEncode(cleanData) end)
        if not jsonSuccess then error("JSON Encode Fail: " .. tostring(json)) end
        
        local filePath = "ZoyyHubGUI_Configs/" .. configName .. ".json"
        writefile(filePath, json)
        return #json
    end)
    
    if success then
        local displaySize = type(err) == "number" and err or "?"
        SendNotification("Config", "💾 Saved: " .. configName .. " (" .. tostring(displaySize) .. " B)", 3)
        configNameInput.Text = ""
        task.delay(0.1, function()
            pcall(RefreshConfigList)
        end)
    else
        SendNotification("Config", "⚠ Save Error: " .. tostring(err), 5)
    end
end))

TrackedSpawn(function()
    task.wait(0.5)
    RefreshConfigList()
end)

makeButton(catConfig, "🔄 Refresh List", function()
    RefreshConfigList()
    SendNotification("Config", "✓ Config list refreshed!", 2)
end)

makeButton(catConfig, "🔃 Reset to Default", function()
    if ConfigSystem then
        local success, message = ConfigSystem.Reset()
        if success then
            SendNotification("Config", "✓ Reset to defaults!", 3)
        else
            SendNotification("Error", message or "Failed to reset", 3)
        end
    else
        SendNotification("Error", "ConfigSystem not loaded!", 3)
    end
end)

-- INFO PAGE
local infoContainer = new("Frame", {
    Parent = infoPage,
    Size = UDim2.new(1, 0, 0, 220),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = infoContainer, CornerRadius = UDim.new(0, 12)})

local logoIcon = new("ImageLabel", {
    Parent = infoContainer,
    Size = UDim2.new(0, 60, 0, 60),
    Position = UDim2.new(0, 15, 0, 15),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Image = "rbxthumb://type=Asset&id=91891350821146&w=420&h=420",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 7
})
new("UICorner", {Parent = logoIcon, CornerRadius = UDim.new(0, 12)})

new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -90, 0, 28),
    Position = UDim2.new(0, 85, 0, 18),
    BackgroundTransparency = 1,
    Text = "ZoyyHub V1",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = colors.primary,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -90, 0, 18),
    Position = UDim2.new(0, 85, 0, 48),
    BackgroundTransparency = 1,
    Text = "Premium",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

new("Frame", {
    Parent = infoContainer,
    Size = UDim2.new(1, -30, 0, 1),
    Position = UDim2.new(0, 15, 0, 85),
    BackgroundColor3 = colors.primary,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})

new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -30, 0, 20),
    Position = UDim2.new(0, 15, 0, 95),
    BackgroundTransparency = 1,
    Text = "FEATURE:",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.primary,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -30, 0, 100),
    Position = UDim2.new(0, 15, 0, 118),
    BackgroundTransparency = 1,
    Text = "• Ultra-Fast Auto Fishing (Multiple Modes)\n• Smart Teleport System\n• Auto Sell & Merchant\n• Webhook Integration\n• Hide Stats & Anti-AFK\n• Memory Optimized",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LineHeight = 1.2,
    ZIndex = 7
})

local discordContainer = new("Frame", {
    Parent = infoPage,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = Color3.fromRGB(88, 101, 242),
    BackgroundTransparency = 0.95,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = discordContainer, CornerRadius = UDim.new(0, 12)})

local linkButton = new("TextButton", {
    Parent = discordContainer,
    Size = UDim2.new(1, -24, 0, 40),
    Position = UDim2.new(0, 12, 0, 10),
    BackgroundColor3 = Color3.fromRGB(88, 101, 242),
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Text = "🔗 discord.gg/XXXXX  (Click to Copy)",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(88, 101, 242),
    ZIndex = 7
})
new("UICorner", {Parent = linkButton, CornerRadius = UDim.new(0, 8)})

ConnectionManager:Add(linkButton.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://discord.gg/XXXXX")
        linkButton.Text = "✅ Copied to Clipboard!"
        task.wait(2)
        linkButton.Text = "🔗 discord.gg/XXXXX  (Click to Copy)"
    end)
end))

-- MINIMIZE SYSTEM
local minimized = false
local icon
local savedIconPos = UDim2.new(0, 20, 0, 100)

local function createMinimizedIcon()
    local pGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    if icon and icon.Parent then return end
    
    for _, child in ipairs(pGui:GetDescendants()) do
        if child:IsA("ImageLabel") and child.ZIndex >= 100 then
            if string.find(tostring(child.Image), "91891350821146") then
                pcall(function() child:Destroy() end)
            end
        end
    end
    
    task.wait(0.1)
    
    icon = new("ImageLabel", {
        Name = "ZoyyHubMinimizeIcon",
        Parent = gui,
        Size = UDim2.new(0, 50, 0, 50),
        Position = savedIconPos,
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=Asset&id=91891350821146&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 100
    })
    new("UICorner", {Parent = icon, CornerRadius = UDim.new(0, 10)})
    
    local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
    
    ConnectionManager:Add(icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragMoved, dragStart, startPos = true, false, input.Position, icon.Position
        end
    end))
    
    ConnectionManager:Add(icon.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.sqrt(delta.X^2 + delta.Y^2) > 5 then dragMoved = true end
            icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    
    ConnectionManager:Add(icon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                savedIconPos = icon.Position
                if not dragMoved then
                    bringToFront()
                    win.Visible = true
                    local tween = TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = windowSize,
                        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
                    })
                    ConnectionManager:AddTween(tween)
                    tween:Play()
                    if icon then icon:Destroy() icon = nil end
                    minimized = false
                end
            end
        end
    end))
end

TrackedSpawn(function()
    while task.wait(2) do
        pcall(function()
            if not gui or not gui.Parent then return end
            
            local pGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local foundIcons = {}
            
            for _, child in ipairs(pGui:GetDescendants()) do
                if child:IsA("ImageLabel") and child.ZIndex >= 100 then
                    if string.find(tostring(child.Image), "91891350821146") then
                        table.insert(foundIcons, child)
                    end
                end
            end
            
            if #foundIcons > 1 then
                for i = 2, #foundIcons do
                    pcall(function() foundIcons[i]:Destroy() end)
                end
            end
        end)
    end
end)

ConnectionManager:Add(btnMinHeader.MouseButton1Click:Connect(function()
    if not minimized then
        local hasUnsaved = false
        if ConfigSystem then
            pcall(function()
                hasUnsaved = ConfigSystem.HasUnsavedChanges()
            end)
        end
        
        if hasUnsaved then
            SendNotification("Minimizing...", "Saving config...", 2)
        end
        
        local tween = TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        ConnectionManager:AddTween(tween)
        tween:Play()
        
        TrackedSpawn(function()
            if hasUnsaved and ConfigSystem then
                pcall(function()
                    ConfigSystem.SaveSelective()
                    ConfigSystem.MarkAsSaved()
                end)
            end
            
            task.wait(0.35)
            win.Visible = false
            createMinimizedIcon()
            minimized = true
        end)
    end
end))

-- DRAGGING SYSTEM
local dragging, dragStart, startPos = false, nil, nil

ConnectionManager:Add(scriptHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bringToFront()
        dragging, dragStart, startPos = true, input.Position, win.Position
    end
end))

ConnectionManager:Add(UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        local focused = UserInputService:GetFocusedTextBox()
        if not focused then 
            if not gui or not gui.Parent then return end
            if win.Visible then
                win.Visible = false
                local pGui = localPlayer:FindFirstChild("PlayerGui")
                if pGui then
                    local floatingGui = pGui:FindFirstChild("ZoyyHubFloatingButtonGui")
                    if floatingGui then
                        local btn = floatingGui:FindFirstChild("ZoyyHubFloatingButton")
                        if btn then btn.Visible = true end
                    end
                end
            else
                win.Visible = true
                win.Size = UDim2.new(0, 0, 0, 0)
                TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = windowSize}):Play()
                local pGui = localPlayer:FindFirstChild("PlayerGui")
                if pGui then
                    local floatingGui = pGui:FindFirstChild("ZoyyHubFloatingButtonGui")
                    if floatingGui then
                        local btn = floatingGui:FindFirstChild("ZoyyHubFloatingButton")
                        if btn then btn.Visible = false end
                    end
                end
            end
        end
    end
end))

ConnectionManager:Add(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

ConnectionManager:Add(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- RESIZING SYSTEM
local resizing = false
local resizeStart, startSize = nil, nil
local minWindowSize = UDim2.new(0, 500, 0, 350)
local maxWindowSize = UDim2.new(0, 1000, 0, 700)

ConnectionManager:Add(resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing, resizeStart, startSize = true, input.Position, win.Size
    end
end))

ConnectionManager:Add(UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if not startSize or not resizeStart then resizing = false return end
        local delta = input.Position - resizeStart
        local newWidth = math.clamp(startSize.X.Offset + delta.X, minWindowSize.X.Offset, maxWindowSize.X.Offset)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minWindowSize.Y.Offset, maxWindowSize.Y.Offset)
        win.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end))

ConnectionManager:Add(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end))

-- OPENING ANIMATION
TrackedSpawn(function()
    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    win.BackgroundTransparency = 1
    
    task.wait(0.1)
    
    local tween1 = TweenService:Create(win, TweenInfo.new(0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        Size = windowSize
    })
    
    local tween2 = TweenService:Create(win, TweenInfo.new(0.5), {
        BackgroundTransparency = 0
    })
    
    ConnectionManager:AddTween(tween1)
    ConnectionManager:AddTween(tween2)
    tween1:Play()
    tween2:Play()
end)

-- APPLY LOADED CONFIG
local function ApplyLoadedConfig()
    if not ConfigSystem then return end
    
    TrackedSpawn(function()
        task.wait(0.5)
        
        local toggleConfigs = {
            {ref = "InstantFishing", path = "InstantFishing.Enabled", default = false},
            {ref = "BlatantTester", path = "BlatantTester.Enabled", default = false},
            {ref = "BlatantV1", path = "BlatantV1.Enabled", default = false},
            {ref = "UltraBlatant", path = "UltraBlatant.Enabled", default = false},
            {ref = "FastAutoPerfect", path = "FastAutoPerfect.Enabled", default = false},
            {ref = "NoFishingAnimation", path = "Support.NoFishingAnimation", default = false},
            {ref = "LockPosition", path = "Support.LockPosition", default = false},
            {ref = "AutoEquipRod", path = "Support.AutoEquipRod", default = false},
            {ref = "DisableCutscenes", path = "Support.DisableCutscenes", default = false},
            {ref = "DisableObtainedNotif", path = "Support.DisableObtainedNotif", default = false},
            {ref = "DisableSkinEffect", path = "Support.DisableSkinEffect", default = false},
            {ref = "WalkOnWater", path = "Support.WalkOnWater", default = false},
            {ref = "GoodPerfectionStable", path = "Support.GoodPerfectionStable", default = false},
            {ref = "PingFPSMonitor", path = "Support.PingFPSMonitor", default = false},
            {ref = "AutoTeleportEvent", path = "Teleport.AutoTeleportEvent", default = false},
            {ref = "AutoSellTimer", path = "Shop.AutoSellTimer.Enabled", default = false},
            {ref = "AutoBuyWeather", path = "Shop.AutoBuyWeather.Enabled", default = false},
            {ref = "Webhook", path = "Webhook.Enabled", default = false},
            {ref = "UnlimitedZoom", path = "CameraView.UnlimitedZoom", default = false},
            {ref = "Freecam", path = "CameraView.Freecam.Enabled", default = false},
            {ref = "AntiAFK", path = "Settings.AntiAFK", default = false},
            {ref = "FPSBooster", path = "Settings.FPSBooster", default = false},
            {ref = "DisableRendering", path = "Settings.DisableRendering", default = false},
            {ref = "HideStats", path = "Settings.HideStats.Enabled", default = false},
        }
        
        for _, config in ipairs(toggleConfigs) do
            if ToggleReferences[config.ref] then
                local value = GetConfigValue(config.path, config.default)
                ToggleReferences[config.ref].setOn(value, true)
            end
        end
    end)
    
    TrackedSpawn(function()
        task.wait(1)
        
        if GetConfigValue("InstantFishing.Enabled", false) then
            local instant = GetModule("instant")
            local instant2 = GetModule("instant2")
            if currentInstantMode == "Fast" and instant then
                instant.Settings.MaxWaitTime = fishingDelayValue
                instant.Settings.CancelDelay = cancelDelayValue
                instant.Start()
            elseif currentInstantMode == "Perfect" and instant2 then
                instant2.Settings.MaxWaitTime = fishingDelayValue
                instant2.Settings.CancelDelay = cancelDelayValue
                instant2.Start()
            end
        end
        
        if GetConfigValue("Support.NoFishingAnimation", false) then
            local NoFishingAnimation = GetModule("NoFishingAnimation")
            if NoFishingAnimation then NoFishingAnimation.StartWithDelay() end
        end
        
        if GetConfigValue("Support.LockPosition", false) then
            local LockPosition = GetModule("LockPosition")
            if LockPosition then LockPosition.Start() end
        end
        
        if GetConfigValue("Support.AutoEquipRod", false) then
            local AutoEquipRod = GetModule("AutoEquipRod")
            if AutoEquipRod then AutoEquipRod.Start() end
        end
        
        if GetConfigValue("Support.DisableCutscenes", false) then
            local DisableCutscenes = GetModule("DisableCutscenes")
            if DisableCutscenes then DisableCutscenes.Start() end
        end
        
        if GetConfigValue("Support.DisableObtainedNotif", false) then
            local DisableExtras = GetModule("DisableExtras")
            if DisableExtras then DisableExtras.StartSmallNotification() end
        end
        
        if GetConfigValue("Support.DisableSkinEffect", false) then
            local DisableExtras = GetModule("DisableExtras")
            if DisableExtras then DisableExtras.StartSkinEffect() end
        end
        
        if GetConfigValue("Support.WalkOnWater", false) then
            local WalkOnWater = GetModule("WalkOnWater")
            if WalkOnWater then WalkOnWater.Start() end
        end
        
        if GetConfigValue("Support.GoodPerfectionStable", false) then
            local GoodPerfectionStable = GetModule("GoodPerfectionStable")
            if GoodPerfectionStable then GoodPerfectionStable.Start() end
        end
        
        if GetConfigValue("Support.PingFPSMonitor", false) then
            local PingFPSMonitor = GetModule("PingFPSMonitor")
            if PingFPSMonitor then PingFPSMonitor:Show() end
        end
        
        if GetConfigValue("BlatantTester.Enabled", false) then
            local blatantv2fix = GetModule("blatantv2fix")
            if blatantv2fix then blatantv2fix.Start() end
        end
        
        if GetConfigValue("BlatantV1.Enabled", false) then
            local blatantv1 = GetModule("blatantv1")
            if blatantv1 then blatantv1.Start() end
        end
        
        if GetConfigValue("UltraBlatant.Enabled", false) then
            local UltraBlatant = GetModule("UltraBlatant")
            if UltraBlatant then UltraBlatant.Start() end
        end
        
        if GetConfigValue("FastAutoPerfect.Enabled", false) then
            local blatantv2 = GetModule("blatantv2")
            if blatantv2 then blatantv2.Start() end
        end
        
        if GetConfigValue("Teleport.AutoTeleportEvent", false) and EventTeleport then
            if selectedEventName and selectedEventName ~= "- No events available -" and EventTeleport.HasCoords(selectedEventName) then
                EventTeleport.Start(selectedEventName)
            end
        end
        
        if GetConfigValue("Shop.AutoSellTimer.Enabled", false) and AutoSellTimer then
            local interval = GetConfigValue("Shop.AutoSellTimer.Interval", 5)
            pcall(function()
                AutoSellTimer.SetInterval(interval)
                AutoSellTimer.Start(interval)
            end)
        end
        
        if GetConfigValue("Shop.AutoBuyWeather.Enabled", false) and AutoBuyWeather then
            local savedWeathers = GetConfigValue("Shop.AutoBuyWeather.SelectedWeathers", {})
            if #savedWeathers > 0 then
                AutoBuyWeather.SetSelected(savedWeathers)
                AutoBuyWeather.Start()
            end
        end
        
        if WebhookModule and GetConfigValue("Webhook.Enabled", false) and isWebhookSupported then
            local savedURL = GetConfigValue("Webhook.URL", "")
            local savedID = GetConfigValue("Webhook.DiscordID", "")
            local savedRarities = GetConfigValue("Webhook.EnabledRarities", {})
            
            if savedURL ~= "" then
                pcall(function()
                    WebhookModule:SetWebhookURL(savedURL)
                    if savedID ~= "" then
                        WebhookModule:SetDiscordUserID(savedID)
                    end
                    if #savedRarities > 0 and rarityCheckboxSystem then
                        rarityCheckboxSystem.SelectSpecific(savedRarities)
                        WebhookModule:SetEnabledRarities(savedRarities)
                    end
                    WebhookModule:Start()
                end)
            end
        end
        
        if GetConfigValue("CameraView.UnlimitedZoom", false) and UnlimitedZoomModule then
            UnlimitedZoomModule.Enable()
        end
        
        if GetConfigValue("CameraView.Freecam.Enabled", false) and FreecamModule then
            if not isMobile then
                FreecamModule.EnableF3Keybind(true)
            else
                FreecamModule.Start()
            end
        end
        
        if GetConfigValue("Settings.AntiAFK", false) and AntiAFK then
            AntiAFK.Start()
        end
        
        if GetConfigValue("Settings.FPSBooster", false) and FPSBooster then
            FPSBooster.Enable()
        end
        
        if GetConfigValue("Settings.DisableRendering", false) and DisableRenderingModule then
            DisableRenderingModule.Start()
        end
        
        local savedFPS = GetConfigValue("Settings.FPSLimit", nil)
        if savedFPS and UnlockFPS then
            UnlockFPS.SetCap(savedFPS)
        end
        
        if HideStats and GetConfigValue("Settings.HideStats.Enabled", false) then
            local savedName = GetConfigValue("Settings.HideStats.FakeName", "ZoyyHub")
            local savedLevel = GetConfigValue("Settings.HideStats.FakeLevel", "1")
            
            pcall(function()
                HideStats.SetFakeName(savedName)
                HideStats.SetFakeLevel(savedLevel)
                HideStats.Enable()
            end)
        end
        
        if GetConfigValue("Support.SkinAnimation.Enabled", false) then
            local SkinAnimation = GetModule("SkinAnimation")
            if SkinAnimation then
                local savedSkin = GetConfigValue("Support.SkinAnimation.Current", "Eclipse")
                pcall(function()
                    SkinAnimation.SwitchSkin(savedSkin)
                    SkinAnimation.Enable()
                end)
            end
        end
    end)
end

TrackedSpawn(function()
    task.wait(1.5)
    pcall(function()
        ApplyLoadedConfig()
    end)
end)

-- CLEANUP FUNCTION
CleanupGUI = function()
    for i = #RunningTasks, 1, -1 do
        local thread = RunningTasks[i]
        if thread then
            pcall(function() task.cancel(thread) end)
        end
        RunningTasks[i] = nil
    end
    table.clear(RunningTasks)
    
    if playerUpdateTask then
        task.cancel(playerUpdateTask)
        playerUpdateTask = nil
    end
    
    for name, module in pairs(Modules) do
        if module and type(module) == "table" then
            if module.Stop then
                pcall(function() module.Stop() end)
            end
            Modules[name] = nil
        end
    end
    
    ConnectionManager:Cleanup()
    
    if playerDropdown and playerDropdown.Parent then
        playerDropdown:Destroy()
        playerDropdown = nil
    end
    
    table.clear(Modules)
    table.clear(ModuleStatus)
    table.clear(ToggleReferences)
    table.clear(pages)
    table.clear(navButtons)
    table.clear(failedModules)
    
    currentWebhookURL = nil
    currentDiscordID = nil
    currentFakeName = nil
    currentFakeLevel = nil
    
    if gui then
        gui:Destroy()
        gui = nil
    end
    
    if icon then
        icon:Destroy()
        icon = nil
    end
    
    _G.ZoyyHubGUI = nil
    
    if getgenv then
        getgenv().ZOYY_GUI_RUNNING = false
        getgenv().ZoyyHub_ActiveInstance = nil
    elseif _G then
        _G.ZOYY_GUI_RUNNING = false
        _G.ZoyyHub_ActiveInstance = nil
    end
    
    for i = 1, 3 do
        pcall(function() collectgarbage("collect") end)
        task.wait(0.1)
    end
end

-- EXPORT
local ZoyyHubGUI = {
    Version = "2.3.1",
    IsLoaded = function() return true end,
    GetModule = GetModule,
    GetConfig = GetConfigValue,
    SetConfig = SetConfigValue,
    Cleanup = CleanupGUI
}

_G.ZoyyHubGUI = ZoyyHubGUI

function ZoyyHubGUI:Destroy()
    CleanupGUI()
end

SendNotification("ZoyyHub", "Script loaded successfully!", 5)

return ZoyyHubGUI
