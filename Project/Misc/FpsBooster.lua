-- ==============================================================
--           ⚡ FPS BOOSTER MODULE (GREY/RAW MODE) ⚡
--              Map jadi Abu-abu seperti belum di-render
-- ==============================================================

local FPSBooster = {}
FPSBooster.Enabled = false

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Storage untuk restore
local originalStates = {
    parts = {},
    lighting = {},
    effects = {},
    terrain = {}
}

local newObjectConnection = nil

-- Warna abu-abu untuk raw mode
local GREY_COLOR = Color3.fromRGB(180, 180, 180)

-- Fungsi untuk optimize single object
local function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    
    pcall(function()
        -- ========================================
        -- PARTS - Ubah jadi ABU-ABU & MATTE
        -- ========================================
        if obj:IsA("BasePart") then
            if not originalStates.parts[obj] then
                originalStates.parts[obj] = {
                    Color = obj.Color,
                    Material = obj.Material,
                    Reflectance = obj.Reflectance,
                    CastShadow = obj.CastShadow
                }
            end
            
            -- Ubah ke grey & material paling ringan
            obj.Color = GREY_COLOR
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        
        -- ========================================
        -- MATIKAN VISUAL EFFECTS (JANGAN DESTROY)
        -- ========================================
        
        -- Decals & Textures (invisible, bukan destroy)
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
        
        -- SurfaceAppearance (disable)
        if obj:IsA("SurfaceAppearance") then
            obj.ColorMap = ""
            obj.NormalMap = ""
            obj.RoughnessMap = ""
            obj.MetalnessMap = ""
        end
        
        -- Particles
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false
        end
        
        -- Trail & Beam
        if obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        end
        
        -- Fire, Smoke, Sparkles
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        
        -- Lights (matikan)
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
        
        -- MeshPart optimization
        if obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end
        
        -- SpecialMesh (hapus texture)
        if obj:IsA("SpecialMesh") then
            obj.TextureId = ""
        end
    end)
end

-- Fungsi untuk restore single object
local function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") and originalStates.parts[obj] then
            local state = originalStates.parts[obj]
            obj.Color = state.Color
            obj.Material = state.Material
            obj.Reflectance = state.Reflectance
            obj.CastShadow = state.CastShadow
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 0
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = true
        end
        
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = true
        end
        
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = true
        end
    end)
end

-- ============================================
-- MAIN ENABLE FUNCTION
-- ============================================
function FPSBooster.Enable()
    if FPSBooster.Enabled then
        return false, "Already enabled"
    end
    
    FPSBooster.Enabled = true
    
    -----------------------------------------
    -- 1. Ubah semua object jadi GREY
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end
    
    -----------------------------------------
    -- 2. TERRAIN - Matikan animasi air
    -----------------------------------------
    if Terrain then
        pcall(function()
            originalStates.terrain = {
                WaterReflectance = Terrain.WaterReflectance,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
                Decoration = Terrain.Decoration
            }
            
            -- Matikan wave & reflections
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.Decoration = false -- Hapus rumput
        end)
    end
    
    -----------------------------------------
    -- 3. MATIKAN POST-PROCESSING
    -----------------------------------------
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end
    
    -----------------------------------------
    -- 4. SET RENDERING QUALITY
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -----------------------------------------
    -- 5. Hook new objects
    -----------------------------------------
    newObjectConnection = workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then
            task.wait(0.05)
            optimizeObject(obj)
        end
    end)
    
    return true, "Grey Mode enabled - Map sekarang abu-abu"
end

-- ============================================
-- MAIN DISABLE FUNCTION
-- ============================================
function FPSBooster.Disable()
    if not FPSBooster.Enabled then
        return false, "Already disabled"
    end
    
    FPSBooster.Enabled = false
    
    -----------------------------------------
    -- 1. Restore semua objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        restoreObject(obj)
    end
    
    -----------------------------------------
    -- 2. Restore Terrain
    -----------------------------------------
    if Terrain and originalStates.terrain then
        pcall(function()
            for prop, value in pairs(originalStates.terrain) do
                Terrain[prop] = value
            end
        end)
    end
    
    -----------------------------------------
    -- 3. Restore Post-Processing
    -----------------------------------------
    for effect, state in pairs(originalStates.effects) do
        if effect and effect.Parent then
            effect.Enabled = state
        end
    end
    
    -----------------------------------------
    -- 4. Restore Render Quality
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    
    -----------------------------------------
    -- 5. Disconnect hooks
    -----------------------------------------
    if newObjectConnection then
        newObjectConnection:Disconnect()
        newObjectConnection = nil
    end
    
    -- Clear states
    originalStates = {
        parts = {},
        lighting = {},
        effects = {},
        terrain = {}
    }
    
    return true, "Grey Mode disabled - Warna kembali normal"
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function FPSBooster.IsEnabled()
    return FPSBooster.Enabled
end

-- Ganti warna grey (customizable)
function FPSBooster.SetGreyColor(r, g, b)
    GREY_COLOR = Color3.fromRGB(r, g, b)
    
    -- Update semua part yang sudah di-grey
    if FPSBooster.Enabled then
        for obj, state in pairs(originalStates.parts) do
            if obj and obj.Parent then
                obj.Color = GREY_COLOR
            end
        end
    end
end

return FPSBooster
