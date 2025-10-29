-- Commands/Order.lua
-- 🌌 Aurora Auto Cycle & Webhook System (Fixed & Improved)

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

        ----------------------------------------------------------------------
        -- 🔹 Utility Functions
        ----------------------------------------------------------------------
        local function getPlayerList()
            local list = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                table.insert(list, plr.DisplayName .. " [" .. plr.Name .. "]")
            end
            return list
        end

        local function equipTool(toolName)
            local backpack = player:FindFirstChild("Backpack")
            if not backpack then return end
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    item.Parent = player.Character
                    task.wait(0.2)
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
                end
            end
        end

        local function useTool(tool)
            if tool and tool:IsA("Tool") then
                task.wait(0.3)
                tool:Activate()
            end
        end

        ----------------------------------------------------------------------
        -- 🔹 Webhook Sender
        ----------------------------------------------------------------------
        local function sendWebhook()
            local payload = {
                embeds = {{
                    title = "🌌 AURORA TOTEM LOGGER",
                    color = 3447003,
                    fields = {
                        { name = "Player", value = vars.SelectedPlayer or player.Name, inline = false },
                        { name = "Jumlah Pop", value = vars.JumlahPop ~= "" and vars.JumlahPop or "-", inline = true },
                        { name = "Jumlah Pesanan", value = vars.JumlahPesanan ~= "" and vars.JumlahPesanan or "-", inline = true },
                        { name = "Cycle", value = cycle.Value, inline = true },
                        { name = "Weather", value = weather.Value, inline = true },
                    },
                    footer = { text = "Dikirim otomatis dari Aurora Logger" },
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

        ----------------------------------------------------------------------
        -- 🔹 Core Logic (Totem Handling)
        ----------------------------------------------------------------------
        local function equipAndUse(name)
            unequipTool(name == "Aurora Totem" and "Sundial Totem" or "Aurora Totem")
            local tool = equipTool(name)
            if tool then
                useTool(tool)
                Library:Notify(name .. " digunakan.", 3)
            else
                warn("[Aurora Logger] " .. name .. " tidak ditemukan di Backpack.")
            end
        end

        ----------------------------------------------------------------------
        -- 🔹 Langkah 1: Start dari Night
        ----------------------------------------------------------------------
        local function langkah1()
            Library:Notify("Menjalankan Langkah 1 (Mulai dari Night)...", 4)

            if cycle.Value == "Night" then
                equipAndUse("Sundial Totem")
            end

            repeat task.wait(1) until cycle.Value == "Day"
            equipAndUse("Sundial Totem")

            repeat task.wait(1) until cycle.Value == "Night"
            equipAndUse("Aurora Totem")

            task.wait(1)
            if weather.Value ~= "Aurora_Borealis" then
                sendWebhook()
            end
        end

        ----------------------------------------------------------------------
        -- 🔹 Langkah 2: Start dari Day
        ----------------------------------------------------------------------
        local function langkah2()
            Library:Notify("Menjalankan Langkah 2 (Mulai dari Day)...", 4)

            if cycle.Value == "Day" then
                equipAndUse("Sundial Totem")
            end

            repeat task.wait(1) until cycle.Value == "Night"
            equipAndUse("Aurora Totem")

            task.wait(1)
            if weather.Value ~= "Aurora_Borealis" then
                sendWebhook()
            end
        end

        ----------------------------------------------------------------------
        -- 🔹 UI Components
        ----------------------------------------------------------------------
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

        ----------------------------------------------------------------------
        -- 🔹 Button untuk menjalankan Langkah
        ----------------------------------------------------------------------
        Group:AddButton("Mulai Auto (Langkah 1)", function()
            task.spawn(langkah1)
        end)

        Group:AddButton("Mulai Auto (Langkah 2)", function()
            task.spawn(langkah2)
        end)

        print("[Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
}
