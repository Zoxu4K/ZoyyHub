-- =====================================================
-- DISABLE 3D RENDERING MODULE (BLACK SCREEN VERSION)
-- Layar jadi hitam saat aktif
-- =====================================================

local DisableRendering = {}

-- =====================================================
-- SERVICES
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- CONFIGURATION
-- =====================================================
DisableRendering.Settings = {
    AutoPersist = true
}

-- =====================================================
-- STATE VARIABLES
-- =====================================================
local State = {
    RenderingDisabled = false,
    RenderConnection = nil,
    BlackScreen = nil  -- ✅ TAMBAH INI
}

-- =====================================================
-- BLACK SCREEN OVERLAY
-- =====================================================
local function CreateBlackScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DisableRenderingBlackScreen"
    screenGui.DisplayOrder = 999999999
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    
    local blackFrame = Instance.new("Frame")
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.Position = UDim2.new(0, 0, 0, 0)
    blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- ✅ HITAM
    blackFrame.BorderSizePixel = 0
    blackFrame.Parent = screenGui
    
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return screenGui
end

local function RemoveBlackScreen()
    if State.BlackScreen then
        State.BlackScreen:Destroy()
        State.BlackScreen = nil
    end
    
    -- Cleanup semua black screen yang mungkin tersisa
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, child in ipairs(playerGui:GetChildren()) do
            if child.Name == "DisableRenderingBlackScreen" then
                child:Destroy()
            end
        end
    end
end

-- =====================================================
-- PUBLIC API FUNCTIONS
-- =====================================================

-- Start disable rendering
function DisableRendering.Start()
    if State.RenderingDisabled then
        return false, "Already disabled"
    end
    
    local success, err = pcall(function()
        -- ✅ CREATE BLACK SCREEN FIRST
        State.BlackScreen = CreateBlackScreen()
        
        -- Disable 3D rendering
        State.RenderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end)
        
        State.RenderingDisabled = true
    end)
    
    if not success then
        warn("[DisableRendering] Failed to start:", err)
        RemoveBlackScreen()
        return false, "Failed to start"
    end
    
    return true, "Rendering disabled (Black Screen)"
end

-- Stop disable rendering
function DisableRendering.Stop()
    if not State.RenderingDisabled then
        return false, "Already enabled"
    end
    
    local success, err = pcall(function()
        -- Disconnect render loop
        if State.RenderConnection then
            State.RenderConnection:Disconnect()
            State.RenderConnection = nil
        end
        
        -- Re-enable rendering
        RunService:Set3dRenderingEnabled(true)
        
        -- ✅ REMOVE BLACK SCREEN
        RemoveBlackScreen()
        
        State.RenderingDisabled = false
    end)
    
    if not success then
        warn("[DisableRendering] Failed to stop:", err)
        return false, "Failed to stop"
    end
    
    return true, "Rendering enabled"
end

-- Toggle rendering
function DisableRendering.Toggle()
    if State.RenderingDisabled then
        return DisableRendering.Stop()
    else
        return DisableRendering.Start()
    end
end

-- Get current status
function DisableRendering.IsDisabled()
    return State.RenderingDisabled
end

-- =====================================================
-- AUTO-PERSIST ON RESPAWN
-- =====================================================
if DisableRendering.Settings.AutoPersist then
    LocalPlayer.CharacterAdded:Connect(function()
        if State.RenderingDisabled then
            task.wait(0.5)
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
                -- Re-create black screen after respawn
                if not State.BlackScreen or not State.BlackScreen.Parent then
                    State.BlackScreen = CreateBlackScreen()
                end
            end)
        end
    end)
end

-- =====================================================
-- CLEANUP FUNCTION
-- =====================================================
function DisableRendering.Cleanup()
    -- Enable rendering if disabled
    if State.RenderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
    end
    
    -- Remove black screen
    RemoveBlackScreen()
    
    -- Disconnect all connections
    if State.RenderConnection then
        State.RenderConnection:Disconnect()
    end
end

return DisableRendering
