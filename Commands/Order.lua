-- Commands/Order.lua
-- 🌌 Aurora Auto Webhook Realtime (Stop setelah webhook terkirim)

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local Library = vars.Library
        local MainTab = tab or Tabs.Fisch

        if not Library or not MainTab then
            warn("[Aurora Logger] Gagal inisialisasi — Library atau Tab tidak ditemukan.")
            return
        end

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")

        local player = Players.LocalPlayer
        local world = ReplicatedStorage:WaitForChild("world", 10)
        if not world then
            warn("[Aurora Logger] world tidak ditemukan di ReplicatedStorage")
            return
        end

        local cycle = world:WaitForChild("cycle", 10)
        local weather = world:WaitForChild("weather", 10)
        if not cycle or not weather then
            warn("[Aurora Logger] cycle/weather tidak ditemukan")
            return
        end

        -----------------------------------------------------
        -- 🔹 Konfigurasi
        -----------------------------------------------------
        local webhookURL = "https://discord.com/api/webhooks/1426999320590422237/MRBvIpOriZD1sJGd--F2A4RfFYEMdXEvPFHOJ5ZyUjogYlUEeDLkWpGcc0ZI4vn43ofR"

        vars.SelectedPlayer = vars.SelectedPlayer or ""
        vars.JumlahPop = vars.JumlahPop or ""
        vars.JumlahPesanan = vars.JumlahPesanan or ""
        vars.AutoSystemRunning = vars.AutoSystemRunning or false

        local Group = MainTab:AddLeftGroupbox("Aurora Totem")

        -----------------------------------------------------
        -- 🔹 Utility
        -----------------------------------------------------
        local function equipTool(toolName)
            local backpack = player:FindFirstChild("Backpack")
            if not backpack then return end
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    item.Parent = player.Character
                    task.wait(0.3)
                    print("[Equip] " .. toolName)
                    return item
                end
            end
        end

        local function unequipTool(toolName)
            local char = player.Character
            if not char then return end
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    item.Parent = player.Backpack
                    print("[Unequip] " .. toolName)
                end
            end
        end

        local function useTool(tool)
            if tool and tool:IsA("Tool") then
                task.wait(0.4)
                tool:Activate()
                print("[Use] " .. tool.Name)
            end
        end

        -----------------------------------------------------
        -- 🔹 Webhook Kirim
        -----------------------------------------------------
        local function sendWebhook()
            local payload = {
                embeds = {{
                    title = "🌌 AURORA TOTEM LOGGER",
                    color = 3447003,
                    fields = {
                        { name = "Player", value = vars.SelectedPlayer ~= "" and vars.SelectedPlayer or player.Name, inline = false },
                        { name = "Jumlah Pop", value = vars.JumlahPop ~= "" and vars.JumlahPop or "-", inline = true },
                        { name = "Jumlah Pesanan", value = vars.JumlahPesanan ~= "" and vars.JumlahPesanan or "-", inline = true },
                        { name = "Cycle", value = cycle.Value, inline = true },
                        { name = "Weather", value = weather.Value, inline = true },
                    },
                    footer = { text = "Aurora Logger Otomatis" },
                    timestamp = DateTime.now():ToIsoDate()
                }}
            }

            local req = syn and syn.request or request or http_request or (http and http.request)
            if not req then
                Library:Notify("Executor tidak mendukung HTTP Request!", 4)
                return
            end

            local ok, err = pcall(function()
                req({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)

            if ok then
                Library:Notify("Webhook terkirim — Aurora Borealis aktif!", 4)
            else
                Library:Notify("Gagal kirim webhook: " .. tostring(err), 4)
            end
        end

        -----------------------------------------------------
        -- 🔹 Fungsi Utama (Realtime)
        -----------------------------------------------------
        local function startAutoWebhook()
            if vars.AutoSystemRunning then
                Library:Notify("Sistem sudah berjalan.", 3)
                return
            end

            vars.AutoSystemRunning = true
            Library:Notify("Memulai Auto Webhook Realtime...", 4)

            task.spawn(function()
                while vars.AutoSystemRunning do
                    task.wait(1)

                    if cycle.Value == "Night" then
                        print("[Cycle] Night terdeteksi — gunakan Sundial Totem")
                        unequipTool("Aurora Totem")
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end

                        repeat task.wait(1) until cycle.Value == "Day"
                        print("[Cycle] Day terdeteksi — gunakan Sundial Totem ulang")
                        local sundial2 = equipTool("Sundial Totem")
                        if sundial2 then useTool(sundial2) end

                        repeat task.wait(1) until cycle.Value == "Night"
                        print("[Cycle] Night lagi — gunakan Aurora Totem")
                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end

                        task.wait(2)
                        if weather.Value ~= "Aurora_Borealis" then
                            sendWebhook()
                            vars.AutoSystemRunning = false
                            Library:Notify("Webhook terkirim — sistem otomatis berhenti.", 5)
                            break
                        end

                    elseif cycle.Value == "Day" then
                        print("[Cycle] Day terdeteksi — gunakan Sundial Totem")
                        unequipTool("Aurora Totem")
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end

                        repeat task.wait(1) until cycle.Value == "Night"
                        print("[Cycle] Night terdeteksi — gunakan Aurora Totem")
                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end

                        task.wait(2)
                        if weather.Value ~= "Aurora_Borealis" then
                            sendWebhook()
                            vars.AutoSystemRunning = false
                            Library:Notify("Webhook terkirim — sistem otomatis berhenti.", 5)
                            break
                        end
                    end
                end
            end)
        end

        -----------------------------------------------------
        -- 🔹 Tombol UI
        -----------------------------------------------------
        Group:AddButton("Mulai Auto Webhook", function()
            if vars.SelectedPlayer == "" then vars.SelectedPlayer = player.Name end
            Library:Notify("Auto Webhook dimulai.", 4)
            startAutoWebhook()
        end)

        print("[Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
}
