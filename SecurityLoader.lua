-- ============================================
-- SIMPLE SECURITY LOADER FOR MERGED FILE
-- ============================================
local MergedLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "3.0.0",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    ENABLE_DOMAIN_CHECK = true,
}

-- ============================================
-- OBFUSCATED SECRET KEY (SAME AS BEFORE)
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
-- ENCRYPTED URL (SINGLE MERGED FILE)
-- ============================================
-- ✅ GANTI INI DENGAN ENCRYPTED URL FILE MERGED ANDA
local ENCRYPTED_MAIN_URL = "PASTE_YOUR_ENCRYPTED_URL_HERE"

-- ============================================
-- LOAD MAIN SCRIPT
-- ============================================
function MergedLoader.Load()
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("🔒 Loading Merged Script...")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    -- Decrypt URL
    local url = decrypt(ENCRYPTED_MAIN_URL, SECRET_KEY)
    
    -- Validate domain
    if not validateDomain(url) then
        warn("❌ Failed: Invalid domain")
        return nil
    end
    
    print("✅ Domain validated")
    print("⏳ Fetching script...")
    
    -- Load and execute script
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Failed to load script:", result)
        return nil
    end
    
    print("✅ Script loaded successfully!")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    return result
end

-- ============================================
-- AUTO-LOAD ON REQUIRE
-- ============================================
print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔐 Merged Script Loader v" .. CONFIG.VERSION)
print("━━━━━━━━━━━━━━━━━━━━━━")

-- Auto-load when required
return MergedLoader.Load()