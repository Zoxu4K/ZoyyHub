local Notification = {}

function Notification.Send(title, text, duration)
    duration = duration or 4
    task.wait(0.5)
    
    local success, errorMsg = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
    
    if not success then
        pcall(function()
            if writefile then
                local filePath = "Delta/Error/notification_errors.log"
                
                -- Baca file lama (jika ada)
                local oldContent = ""
                if readfile and isfile(filePath) then
                    oldContent = readfile(filePath)
                end
                
                -- Tambahkan error baru
                local newLog = string.format(
                    "[%s] %s - %s | Error: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    title,
                    text,
                    errorMsg
                )
                
                writefile(filePath, oldContent .. newLog)
                print("✓ Error logged to Delta/Error/notification_errors.log")
            end
        end)
        
        print("[" .. title .. "] " .. text)
    end
end

return Notification
