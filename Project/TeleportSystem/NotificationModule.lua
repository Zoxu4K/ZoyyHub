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
                -- Path untuk Android Delta
                local filePath = "notification_errors.log"
                
                -- Baca file lama
                local oldContent = ""
                if readfile and isfile and isfile(filePath) then
                    oldContent = readfile(filePath)
                end
                
                -- Log baru
                local newLog = string.format(
                    "[%s] ERROR\nTitle: %s\nText: %s\nError: %s\n---\n\n",
                    os.date("%d/%m/%Y %H:%M:%S"),
                    title,
                    text,
                    tostring(errorMsg)
                )
                
                -- Simpan
                writefile(filePath, oldContent .. newLog)
                print("✓ Error saved to Delta folder")
            end
        end)
        
        print("[" .. title .. "] " .. text)
    end
end

return Notification
