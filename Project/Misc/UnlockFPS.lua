-- ⚡ FungsiKeaby/Misc/UnlockFPS.lua
local UnlockFPS = {
    Enabled = true,
    CurrentCap = 240,
}

-- daftar pilihan FPS yang bisa dipilih dari dropdown GUI
UnlockFPS.AvailableCaps = {60, 90, 120, 240}

function UnlockFPS.SetCap(fps)
    if setfpscap then
        setfpscap(fps)
        UnlockFPS.CurrentCap = fps
        print(string.format("🎯 [UnlockFPS] FPS cap diatur ke %d", fps))
    else
        warn("⚠️ setfpscap() tidak tersedia di executor kamu.")
    end
end

function UnlockFPS.Start()
    if UnlockFPS.Enabled then return end
    UnlockFPS.Enabled = true
    UnlockFPS.SetCap(UnlockFPS.CurrentCap)
    print(string.format("⚡ [UnlockFPS] Aktif (cap: %d)", UnlockFPS.CurrentCap))
end

function UnlockFPS.Stop()
    if not UnlockFPS.Enabled then return end
    UnlockFPS.Enabled = false
    if setfpscap then
        setfpscap(60)
        print("🛑 [UnlockFPS] Dinonaktifkan (kembali ke 60fps)")
    end
end

return UnlockFPS
