-- Commands/Order.lua
-- 🌌 Aurora Auto Cycle & Webhook System (Realtime Cycle Monitor)

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

        local webhookURL = "https://discord.com/api/webhooks/1426999320590422237/MRBvIpOriZD1sJGd--F2A4RfFYEMdXEvPFHOJ5ZyUjogYlUEeDLkWpGcc0ZI4vn43ofR"

        vars.SelectedPlayer = vars.SelectedPlayer or ""
        vars.JumlahPop = vars.JumlahPop or ""
        vars.JumlahPesanan = vars.JumlahPesanan or ""
        vars.AutoSystemRunning = vars.AutoSystemRunning or false

        local Group = MainTab:AddLeftGroupbox("Aurora Totem")

        -----------------------------------------------------
        -- 🔹 UI INPUT
        -----------------------------------------------------
        local function getPlayerList()
            local list = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                table.insert(list, plr.DisplayName .. " [" .. plr.Name .. "]")
            end
            return list
        end

        local playerDropdown = Group:AddDropdown("AuroraPlayerDropdown", {
            Values = getPlayerList(),
            Multi = false,
            Text = "Pilih Player",
            Callback = function(value)
                local name = string.match(value, "%[(.-)%]$")
                if name then vars.SelectedPlayer = name end
            end
        })

        Group:AddButton("Refresh List", function()
            playerDropdown:SetValues(getPlayerList())
            Library:Notify("Daftar player diperbarui.", 3)
        end)

        Group:AddInput("AuroraPopInput", {
            Default = "",
            Text = "Jumlah Aurora di-Pop",
            Placeholder = "Contoh: 5",
            Callback = function(value)
                vars.JumlahPop = value
            end
        })

        Group:AddInput("AuroraPesananInput", {
            Default = "",
            Text = "Jumlah Aurora di-Pesan",
            Placeholder = "Contoh: 10",
            Callback = function(value)
                vars.JumlahPesanan = value
            end
        })

        -----------------------------------------------------
        -- 🔹 UTILITAS
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
        -- 🔹 WEBHOOK FUNCTION
        -----------------------------------------------------
        local function sendWebhook()
            local payload = {
                embeds = {{
                    title = "🌌 AURORA POP TOTEM",
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
                Library:Notify("Gagal mengirim webhook: " .. tostring(err), 4)
            end
        end

        -----------------------------------------------------
        -- 🔹 FUNGSI UTAMA (REALTIME CHECK)
        -----------------------------------------------------
        local function realtimeCycleMonitor()
            if vars.AutoSystemRunning then
                Library:Notify("Sistem sudah berjalan.", 3)
                return
            end
            vars.AutoSystemRunning = true

            Library:Notify("Memulai pemantauan cycle secara realtime...", 4)

            task.spawn(function()
                while vars.AutoSystemRunning do
                    task.wait(2)

                    if cycle.Value == "Night" then
                        -- Night: Gunakan Sundial, tunggu jadi Day
                        unequipTool("Aurora Totem")
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end
                        print("[Cycle] Night → Sundial digunakan")

                        repeat task.wait(1) until cycle.Value == "Day"
                        local sundial2 = equipTool("Sundial Totem")
                        if sundial2 then useTool(sundial2) end
                        print("[Cycle] Day → Sundial digunakan ulang")

                        repeat task.wait(1) until cycle.Value == "Night"
                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end
                        print("[Cycle] Night lagi → Aurora digunakan")

                        task.wait(2)
                        if weather.Value ~= "Aurora_Borealis" then
                            sendWebhook()
                        end

                    elseif cycle.Value == "Day" then
                        -- Day: Gunakan Sundial, tunggu Night, lalu Aurora
                        unequipTool("Aurora Totem")
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end
                        print("[Cycle] Day → Sundial digunakan")

                        repeat task.wait(1) until cycle.Value == "Night"
                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end
                        print("[Cycle] Night → Aurora digunakan")

                        task.wait(2)
                        if weather.Value ~= "Aurora_Borealis" then
                            sendWebhook()
                        end
                    end
                end
            end)
        end

        -----------------------------------------------------
        -- 🔹 TOMBOL UTAMA
        -----------------------------------------------------
        Group:AddButton("Mulai Kirim Webhook (Realtime)", function()
            if vars.SelectedPlayer == "" then
                vars.SelectedPlayer = player.Name
            end
            Library:Notify("Sistem webhook realtime dijalankan.", 4)
            realtimeCycleMonitor()
        end)

        Group:AddButton("Hentikan Sistem", function()
            vars.AutoSystemRunning = false
            Library:Notify("Sistem dihentikan.", 4)
        end)

        print("[Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
}
