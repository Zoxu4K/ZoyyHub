-- UPDATED SECURITY LOADER - Includes EventTeleportDynamiefws
-- Replace your ZoyyLoader.lua with this

local ZoyyLoader = {}

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
local encryptedURLs = {
    instant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYnFjQhKDEnWxwQEw==",
    instant2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYnFjQhKDEnR14JBzI=",
    blatantv1 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHARGREREz0RNUNLGCpT",
    UltraBlatant = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2dAQC1CC2cyLQ0PFjMDe3E/ABE=",
    blatantv2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYsFCYhKDEnI0JLHiYE",
    blatantv2fix = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2dAQC1CC2cyLQ0PFjMTICc2ESZUXD8QAg==",
    NoFishingAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAdGjYMATsMDRUkGjZfUUZdTi4NSFA/",
    LockPosition = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAfGhMOIjwWCgYMGzEcXEdV",
    AutoEquipRod = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHASAAQKNyIQCgI3GzscXEdV",
    DisableCutscenes = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAXHAMEED8AIAcRBzxXXldHDyxWRQ==",
    DisableExtras = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAXHAMEED8AJgoRBj5BHl5BQA==",
    AutoTotem3X = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHASAAQKJjwRBh9WDHFeRVM=",
    SkinAnimation = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2dAQC1CC3Y1JRc9DyYlCDE6GBERGzwLTR4QFQ==",
    WalkOnWater = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY7DCY4KHAEFBwOPT0yAgYABnFeRVM=",
    TeleportModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhAT0KFiYJBlwJAT4=",
    TeleportToPlayer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl0xETNXQF1GVRRMdEk/NRwcVisgKA==",
    SavedLocation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl02FSlXVH5bQiFXTUowYhUbGQ==",
    AutoQuestModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY/DSImPXASAAQKIyYAEAYoGztHXFcaTTVC",
    AutoTemple = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2NBRDNXC2k7OhwcKTIwOit9GQUE",
    TempleDataReader = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY/DSImPXAHEB0VHjYhAgYEJjpTVFdGDyxWRQ==",
    AutoSell = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF4aTTVC",
    AutoSellTimer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF5gSC1GVgsyORg=",
    MerchantSystem = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2FcTjBlQUQqOQsLC2gaOTo9JhgKAn0JFhM=",
    RemoteBuyer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKMRcIGytXckdNRDINSFA/",
    FreecamModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYtGSowOz52R0AzGzYSTDQXETpRUV95TiRWSEBwIAwP",
    UnlimitedZoomModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYtGSowOz52R0AzGzYSTCcLGDZfWUZRRRpMS0hwIAwP",
    AntiAFK = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zh49ARkkNBhLDwcE",
    UnlockFPS = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zgo9GR8GGRU1MFwJAT4=",
    FPSBooster = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhkjBjIKHSARBgBLGCpT",
    AutoBuyWeather = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGx1HSWVRQDRLQVdwIAwP",
    Notify = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2ZRTSVTS1cqHwAdDCI4ZhE8ARkDGzAEFxsKGhJdVEdYRG5PUUQ=",
    EventTeleportDynamic = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY6HSswOTAhASMcAScADl0gAjpcRGZRTSVTS1cqCAAAGSo8KnE/ABE=",
    HideStats = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zhc6ERU2BjIREFwJAT4=",
    Webhook = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zgg2FxgKHThLDwcE",
    GoodPerfectionStable = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH2dAQC1CC3U7Ph8LGzM8JjEUGh8BXD8QAg==",
    DisableRendering = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2Zhs6BhEHHjY3BhwBES1bXlUaTTVC",
    AutoFavorite = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYvDTM6Dz4lGgIMBjZLDwcE",
    PingFPSMonitor = "JA0aCDRvZnA0HAQNBzFLAB0IWwVdSEcAam95S1wnBAwMVyU5Jj18GBEMHHw1ER0PETxGH39dUiMMdEwwKykPFiI5ZzMmFA==",
    MovementModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhI8AxUIFz0RLh0BATNXHl5BQA==",
    AutoSellSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFY9ECglDzoyAQUXFyBKIgcRGwxXXF5nWDNXQUhwIAwP",
    ManualSave = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVx06MSpnPl8/HSocKwcHWzJTWVwbcTJMTkA9OFYjETQ2ZhIyGwUEHgAEFRdLGCpT",
}


-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function ZoyyLoader.LoadModule(moduleName)
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
function ZoyyLoader.EnableAntiDump()
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
function ZoyyLoader.GetSessionInfo()
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

function ZoyyLoader.ResetRateLimit()
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    loadCounts[identifier] = 0
    lastLoadTime[identifier] = 0
    print("✅ Rate limit reset")
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 ZoyyHub Security Loader v" .. CONFIG.VERSION)
print("✅ Total Modules: 28 (EventTeleport added!)")
print("✅ Rate Limiting:", CONFIG.ENABLE_RATE_LIMITING and "ENABLED" or "DISABLED")
print("✅ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED")
print("━━━━━━━━━━━━━━━━━━━━━━")

return ZoyyLoader
