local MovementModule = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Settings
MovementModule.Settings = {
    SprintSpeed = 50,
    DefaultSpeed = 16,
    SprintEnabled = false,
    InfiniteJumpEnabled = false,
    NoClipEnabled = false
}

-- Internal State
local connections = {}
local jumpConnection = nil
local sprintConnection = nil
local noClipConnection = nil

-- ============================================
-- CLEANUP FUNCTION
-- ============================================
local function cleanup()
    for _, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
    
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
end

-- ============================================
-- SPRINT FUNCTIONS
-- ============================================
local function maintainSprintSpeed()
    if sprintConnection then
        sprintConnection:Disconnect()
    end
    
    sprintConnection = RunService.Heartbeat:Connect(function()
        if MovementModule.Settings.SprintEnabled and humanoid and humanoid.WalkSpeed ~= MovementModule.Settings.SprintSpeed then
            humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        end
    end)
end

function MovementModule.SetSprintSpeed(speed)
    MovementModule.Settings.SprintSpeed = math.clamp(speed, 16, 200)
    
    if MovementModule.Settings.SprintEnabled and humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
end

function MovementModule.EnableSprint()
    if MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = true
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
    
    maintainSprintSpeed()
    
    return true
end

function MovementModule.DisableSprint()
    if not MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = false
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.DefaultSpeed
    end
    
    return true
end

function MovementModule.IsSprintEnabled()
    return MovementModule.Settings.SprintEnabled
end

function MovementModule.GetSprintSpeed()
    return MovementModule.Settings.SprintSpeed
end

-- ============================================
-- INFINITE JUMP FUNCTIONS
-- ============================================
local function enableInfiniteJump()
    if jumpConnection then
        jumpConnection:Disconnect()
    end
    
    jumpConnection = UserInputService.JumpRequest:Connect(function()
        if MovementModule.Settings.InfiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function MovementModule.EnableInfiniteJump()
    if MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = true
    enableInfiniteJump()
    
    return true
end

function MovementModule.DisableInfiniteJump()
    if not MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = false
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    return true
end

function MovementModule.IsInfiniteJumpEnabled()
    return MovementModule.Settings.InfiniteJumpEnabled
end

-- ============================================
-- NO CLIP FUNCTIONS (FIXED!)
-- ============================================
local function enableNoClip()
    if noClipConnection then
        noClipConnection:Disconnect()
    end
    
    -- Disable collision immediately
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end
    
    -- Loop untuk maintain no collision (gunakan Stepped untuk lebih responsif)
    noClipConnection = RunService.Stepped:Connect(function()
        if not MovementModule.Settings.NoClipEnabled then return end
        
        pcall(function()
            -- Disable collision untuk semua parts
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            -- Pastikan humanoid tetap bisa jalan
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)
end

function MovementModule.EnableNoClip()
    if MovementModule.Settings.NoClipEnabled then return false end
    
    MovementModule.Settings.NoClipEnabled = true
    
    -- Pastikan character dan rootPart ada
    if not character or not rootPart then
        character = player.Character
        if character then
            rootPart = character:WaitForChild("HumanoidRootPart")
            humanoid = character:WaitForChild("Humanoid")
        end
    end
    
    enableNoClip()
    print("[NoClip] ENABLED")
    
    return true
end

function MovementModule.DisableNoClip()
    if not MovementModule.Settings.NoClipEnabled then return false end
    
    MovementModule.Settings.NoClipEnabled = false
    
    -- Disconnect loop
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
    
    -- Re-enable collision
    pcall(function()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
    
    print("[NoClip] DISABLED")
    
    return true
end

function MovementModule.IsNoClipEnabled()
    return MovementModule.Settings.NoClipEnabled
end

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================
table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Re-apply sprint if enabled
    if MovementModule.Settings.SprintEnabled then
        task.wait(0.1)
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        maintainSprintSpeed()
    end
    
    -- Re-apply infinite jump if enabled
    if MovementModule.Settings.InfiniteJumpEnabled then
        enableInfiniteJump()
    end
    
    -- Re-apply no clip if enabled
    if MovementModule.Settings.NoClipEnabled then
        task.wait(0.2) -- Delay lebih lama untuk pastikan semua part sudah load
        enableNoClip()
        print("[NoClip] Re-enabled after respawn")
    end
end))

-- ============================================
-- MODULE LIFECYCLE
-- ============================================
function MovementModule.Start()
    MovementModule.Settings.SprintEnabled = false
    MovementModule.Settings.InfiniteJumpEnabled = false
    MovementModule.Settings.NoClipEnabled = false
    return true
end

function MovementModule.Stop()
    MovementModule.DisableSprint()
    MovementModule.DisableInfiniteJump()
    MovementModule.DisableNoClip()
    cleanup()
    return true
end

-- Initialize
MovementModule.Start()

return MovementModule
