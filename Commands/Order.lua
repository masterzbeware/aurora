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

        -------------------------------------------------
        -- UI Elements
        -------------------------------------------------
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

        -------------------------------------------------
        -- Core Helper Functions
        -------------------------------------------------
        local function equipTool(toolName)
            local backpack = player:FindFirstChild("Backpack")
            if not backpack then return end
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    item.Parent = player.Character
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
                task.wait(0.3)
                tool:Activate()
                print("[Use] " .. tool.Name)
            end
        end

        -------------------------------------------------
        -- Webhook Function
        -------------------------------------------------
        local function sendWebhook()
            if vars.SelectedPlayer == "" or vars.JumlahPop == "" or vars.JumlahPesanan == "" then
                Library:Notify("Isi Player, Jumlah Pop, dan Pesanan dulu!", 4)
                return
            end

            local payload = {
                embeds = { {
                    title = "AURORA POP TOTEM",
                    color = 3447003,
                    fields = {
                        { name = "Player", value = vars.SelectedPlayer, inline = false },
                        { name = "Jumlah Pop", value = vars.JumlahPop, inline = false },
                        { name = "Jumlah Pesanan", value = vars.JumlahPesanan, inline = false },
                        { name = "Cycle", value = cycle.Value, inline = true },
                        { name = "Weather", value = weather.Value, inline = true },
                    },
                    footer = { text = "Dikirim otomatis dari Aurora Logger" },
                    timestamp = DateTime.now():ToIsoDate()
                } }
            }

            local req = syn and syn.request or request or http_request or (http and http.request)
            if not req then
                Library:Notify("Executor tidak mendukung HTTP Request!", 4)
                return
            end

            local success, err = pcall(function()
                req({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)

            if success then
                Library:Notify("Webhook terkirim! Aurora Borealis aktif!", 4)
            else
                Library:Notify("Gagal mengirim webhook: " .. tostring(err), 4)
            end
        end

        -------------------------------------------------
        -- 🔁 AUTO LOOP REALTIME (FINAL FIX)
        -------------------------------------------------
        local function startAutoSequence()
            if vars.AutoSystemRunning then
                Library:Notify("Auto system sudah berjalan.", 3)
                return
            end
            vars.AutoSystemRunning = true

            local function equipAndUseSundial()
                unequipTool("Aurora Totem")
                local sundial = equipTool("Sundial Totem")
                if sundial then
                    task.wait(0.5)
                    useTool(sundial)
                    Library:Notify("☀️ Sundial Totem digunakan.", 3)
                else
                    Library:Notify("Sundial Totem tidak ditemukan!", 3)
                end
            end

            local function equipAndUseAurora()
                unequipTool("Sundial Totem")
                local aurora = equipTool("Aurora Totem")
                if aurora then
                    task.wait(0.5)
                    useTool(aurora)
                    Library:Notify("🌌 Aurora Totem digunakan.", 3)

                    if weather.Value ~= "Aurora_Borealis" then
                        local connection
                        connection = weather:GetPropertyChangedSignal("Value"):Connect(function()
                            if weather.Value == "Aurora_Borealis" then
                                Library:Notify("✨ Aurora Borealis aktif! Mengirim webhook...", 4)
                                sendWebhook()
                                connection:Disconnect()
                            end
                        end)
                    else
                        sendWebhook()
                    end
                else
                    Library:Notify("Aurora Totem tidak ditemukan!", 3)
                end
            end

            task.spawn(function()
                local state = "INIT" -- INIT / WAIT_DAY / WAIT_NIGHT
                local lastCycle = cycle.Value

                while vars.AutoSystemRunning do
                    task.wait(1) -- cek setiap 1 detik
                    local now = cycle.Value

                    if state == "INIT" then
                        if now == "Night" then
                            equipAndUseSundial()
                            state = "WAIT_DAY"
                            print("[STATE] Night detected → use Sundial → waiting Day")
                        elseif now == "Day" then
                            equipAndUseSundial()
                            state = "WAIT_NIGHT"
                            print("[STATE] Day detected → Sundial refresh → waiting Night")
                        end

                    elseif state == "WAIT_DAY" and now == "Day" then
                        equipAndUseSundial()
                        state = "WAIT_NIGHT"
                        print("[STATE] Switched to Day → Sundial used again → waiting Night")

                    elseif state == "WAIT_NIGHT" and now == "Night" then
                        equipAndUseAurora()
                        state = "WAIT_DAY"
                        print("[STATE] Switched to Night → Aurora used → waiting Day")
                    end
                end
            end)

            Library:Notify("🔄 Sistem realtime aktif — akan cek cycle setiap 1 detik.", 5)
        end

        -------------------------------------------------
        -- Button Start
        -------------------------------------------------
        Group:AddButton("Mulai Auto Webhook", function()
            if vars.SelectedPlayer == "" or vars.JumlahPop == "" or vars.JumlahPesanan == "" then
                Library:Notify("Isi semua data dulu!", 4)
                return
            end
            startAutoSequence()
        end)

        print("[Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
}
