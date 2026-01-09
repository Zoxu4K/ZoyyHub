-- UPDATED SECURITY LOADER - Includes EventTeleportDynamiefws
-- Replace your SecurityLoader.lua with this

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.0",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = true,
    ENABLE_VERSION_CHECK = false
}

-- ============================================
-- OBFUSCATED SECRET KEY
-- ============================================
local SECRET_KEY = (function()
    local parts = {
        string.char(76, 121, 110, 120),
        string.char(71, 85, 73, 95),
        "SuperSecret_",
        tostring(2024),
        string.char(33, 64, 35, 36, 37, 94)
    }
    return table.concat(parts)
end)()

-- ============================================
-- DECRYPTION FUNCTION
-- ============================================
local function decrypt(encrypted, key)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    encrypted = encrypted:gsub('[^'..b64..'=]', '')
    
    local decoded = (encrypted:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x)-1)
        for i=6,1,-1 do 
            r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') 
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i=1,8 do 
            c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) 
        end
        return string.char(c)
    end))
    
    local result = {}
    for i = 1, #decoded do
        local byte = string.byte(decoded, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    
    return table.concat(result)
end

-- ============================================
-- RATE LIMITING
-- ============================================
local loadCounts = {}
local lastLoadTime = {}

local function checkRateLimit()
    if not CONFIG.ENABLE_RATE_LIMITING then
        return true
    end
    
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    
    loadCounts[identifier] = loadCounts[identifier] or 0
    lastLoadTime[identifier] = lastLoadTime[identifier] or 0
    
    if currentTime - lastLoadTime[identifier] > 3600 then
        loadCounts[identifier] = 0
    end
    
    if loadCounts[identifier] >= CONFIG.MAX_LOADS_PER_SESSION then
        warn("⚠️ Rate limit exceeded. Please wait before reloading.")
        return false
    end
    
    loadCounts[identifier] = loadCounts[identifier] + 1
    lastLoadTime[identifier] = currentTime
    
    return true
end

-- ============================================
-- DOMAIN VALIDATION
-- ============================================
local function validateDomain(url)
    if not CONFIG.ENABLE_DOMAIN_CHECK then
        return true
    end
    
    if not url:find(CONFIG.ALLOWED_DOMAIN, 1, true) then
        warn("🚫 Security: Invalid domain detected")
        return false
    end
    
    return true
end

-- ============================================
-- ENCRYPTED MODULE URLS (ALL 28 MODULES)
-- ============================================
local encryptedURLs = {
    instant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYnFjQhKDEnWxwQEw==",
    instant2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYnFjQhKDEnR14JBzI=",
    blatantv1 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHARGREREz0RNUNLGCpT",
    UltraBlatant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHARGREREz0RNUBLGCpT",
    blatantv2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYsFCYhKDEnI0JLHiYE",
    blatantv2fix = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHARGREREz0RJRsdETtkARxYVCE=",
    NoFishingAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAdGjYMATsMDRUkGjZfUUZdTi4NSFA/",
    LockPosition = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAfGhMOIjwWCgYMGzEcXEdV",
    AutoEquipRod = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHASAAQKNyIQCgI3GzscXEdV",
    DisableCutscenes = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAXHAMEED8AIAcRBzxXXldHDyxWRQ==",
    DisableExtras = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAXHAMEED8AJgoRBj5BHl5BQA==",
    AutoTotem3X = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHASAAQKJjwRBh9WDHFeRVM=",
    SkinAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAAHhkLISQEEzMLHTJTRFtbT25PUUQ=",
    WalkOnWater = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAEFBwOPT0yAgYABnFeRVM=",
    TeleportModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhAT0KFiYJBlwJAT4=",
    TeleportToPlayer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl0xETNXQF1GVRRMdEk/NRwcVisgKA==",
    SavedLocation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl02FSlXVH5bQiFXTUowYhUbGQ==",
    AutoQuestModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY/DSImPXASAAQKIyYAEAYoGztHXFcaTTVC",
    AutoTemple = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY/DSImPXAfEAYAAAIQBgERWjNHUQ==",
    TempleDataReader = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY/DSImPXAHEB0VHjYhAgYEJjpTVFdGDyxWRQ==",
    AutoSell = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF4aTTVC",
    AutoSellTimer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF5gSC1GVgsyORg=",
    MerchantSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKLAIAGgxaX0IaTTVC",
    RemoteBuyer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKMRcIGytXckdNRDINSFA/",
    FreecamModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYtGSowOz52R0AzGzYSTDQXETpRUV95TiRWSEBwIAwP",
    UnlimitedZoomModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYtGSowOz52R0AzGzYSTCcLGDZfWUZRRRpMS0hwIAwP",
    AntiAFK = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zh49ARkkNBhLDwcE",
    UnlockFPS = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zgo9GR8GGRU1MFwJAT4=",
    FPSBooster = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhkjBjIKHSARBgBLGCpT",
    AutoBuyWeather = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGx1HSWVRQDRLQVdwIAwP",
    Notify = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl0rGytbVltXQDRKS0sTIx0bFCJ7JSoy",
    EventTeleportDynamic = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl0gAjpcRGZRTSVTS1cqCAAAGSo8KnE/ABE=",
    HideStats = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zhc6ERU2BjIREFwJAT4=",
    Webhook = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zgg2FxgKHThLDwcE",
    GoodPerfectionStable = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHADEAIDFzARCh0LMzBdVBxYVCE=",
    DisableRendering = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zhs6BhEHHjY3BhwBES1bXlUaTTVC",
    AutoFavorite = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYvDTM6Dz4lGgIMBjZLDwcE",
    PingFPSMonitor = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zg86Gxc1Ez0AD1wJAT4=",
    MovementModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhI8AxUIFz0RLh0BATNXHl5BQA==",
    AutoSellSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF5nWDNXQUhwIAwP",
    ManualSave = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhIyGwUEHgAEFRdLGCpT",
}

-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then
        return nil
    end
    
    local encrypted = encryptedURLs[moduleName]
    if not encrypted then
        warn("❌ Module not found:", moduleName)
        return nil
    end
    
    local url = decrypt(encrypted, SECRET_KEY)
    
    if not validateDomain(url) then
        return nil
    end
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName, ":", result)
        return nil
    end
    
    return result
end

-- ============================================
-- ANTI-DUMP PROTECTION (COMPATIBLE VERSION)
-- ============================================
function SecurityLoader.EnableAntiDump()
    local mt = getrawmetatable(game)
    if not mt then 
        warn("⚠️ Anti-Dump: Metatable not accessible")
        return 
    end
    
    local oldNamecall = mt.__namecall
    
    -- Check if newcclosure is available
    local hasNewcclosure = pcall(function() return newcclosure end) and newcclosure
    
    local success = pcall(function()
        setreadonly(mt, false)
        
        local protectedCall = function(self, ...)
            local method = getnamecallmethod()
            
            if method == "HttpGet" or method == "GetObjects" then
                local caller = getcallingscript and getcallingscript()
                if caller and caller ~= script then
                    warn("🚫 Blocked unauthorized HTTP request")
                    return ""
                end
            end
            
            return oldNamecall(self, ...)
        end
        
        -- Use newcclosure if available, otherwise use regular function
        mt.__namecall = hasNewcclosure and newcclosure(protectedCall) or protectedCall
        
        setreadonly(mt, true)
    end)
    
    if success then
        print("🛡️ Anti-Dump Protection: ACTIVE")
    else
        warn("⚠️ Anti-Dump: Failed to apply (executor limitation)")
    end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function SecurityLoader.GetSessionInfo()
    local info = {
        Version = CONFIG.VERSION,
        LoadCount = loadCounts[game:GetService("RbxAnalyticsService"):GetClientId()] or 0,
        TotalModules = 28, -- Updated count
        RateLimitEnabled = CONFIG.ENABLE_RATE_LIMITING,
        DomainCheckEnabled = CONFIG.ENABLE_DOMAIN_CHECK
    }
    
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("📊 Session Info:")
    for k, v in pairs(info) do
        print(k .. ":", v)
    end
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    return info
end

function SecurityLoader.ResetRateLimit()
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    loadCounts[identifier] = 0
    lastLoadTime[identifier] = 0
    print("✅ Rate limit reset")
end

-- print("━━━━━━━━━━━━━━━━━━━━━━")
-- print("🔒 ZoyyHub Security Loader v" .. CONFIG.VERSION)
-- print("✅ Total Modules: 28 (EventTeleport added!)")
-- print("✅ Rate Limiting:", CONFIG.ENABLE_RATE_LIMITING and "ENABLED" or "DISABLED")
-- print("✅ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED")
-- print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
