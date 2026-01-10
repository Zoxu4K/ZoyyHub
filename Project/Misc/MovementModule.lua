-- Movement Features
local catMovement = makeCategory(settingsPage, "Player Utility", "🏃")

-- Sprint Speed Input
InputReferences.SprintSpeed = makeInput(catMovement, "Sprint Speed", GetConfigValue("Movement.SprintSpeed", 50), function(v)
    SetConfigValue("Movement.SprintSpeed", v)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then MovementModule.SetSprintSpeed(v) end
end)

-- Sprint Toggle
ToggleReferences.Sprint = makeToggle(catMovement, "Enable Sprint", function(on)
    SetConfigValue("Movement.SprintEnabled", on)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then
        if on then 
            MovementModule.EnableSprint()
        else 
            MovementModule.DisableSprint()
        end
    end
end)

-- Infinite Jump Toggle
ToggleReferences.InfiniteJump = makeToggle(catMovement, "Enable Infinite Jump", function(on)
    SetConfigValue("Movement.InfiniteJump", on)
    local MovementModule = GetModule("MovementModule")
    if MovementModule then
        if on then 
            MovementModule.EnableInfiniteJump()
        else 
            MovementModule.DisableInfiniteJump()
        end
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
```

## **2. Update MovementModule.lua (FULL CODE):**

```lua
local MovementModule = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

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
-- NO CLIP FUNCTIONS (NEW!)
-- ============================================
local function setCharacterCollision(enabled)
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = enabled
        end
    end
end

local function enableNoClip()
    if noClipConnection then
        noClipConnection:Disconnect()
    end
    
    -- Disable collision
    setCharacterCollision(false)
    
    -- Loop to maintain no collision
    noClipConnection = RunService.Stepped:Connect(function()
        if MovementModule.Settings.NoClipEnabled and character then
            setCharacterCollision(false)
        end
    end)
end

function MovementModule.EnableNoClip()
    if MovementModule.Settings.NoClipEnabled then return false end
    
    MovementModule.Settings.NoClipEnabled = true
    enableNoClip()
    
    return true
end

function MovementModule.DisableNoClip()
    if not MovementModule.Settings.NoClipEnabled then return false end
    
    MovementModule.Settings.NoClipEnabled = false
    
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
    
    -- Re-enable collision
    setCharacterCollision(true)
    
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
        task.wait(0.1)
        enableNoClip()
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
