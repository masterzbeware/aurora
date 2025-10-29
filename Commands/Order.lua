return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local Library = vars.Library
        local MainTab = tab or Tabs.Fisch

        if not Library or not MainTab then
            warn("Gagal inisialisasi — Library atau Tab tidak ditemukan.")
            return
        end

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")
        local player = Players.LocalPlayer
        local world = ReplicatedStorage:WaitForChild("World", 10)
        if not world then return end

        local cycle = world:WaitForChild("Cycle", 10)
        local weather = world:FindFirstChild("Weather") or Instance.new("StringValue")

        local webhookURL = "https://discord.com/api/webhooks/1426999320590422237/MRBvIpOriZD1sJGd--F2A4RfFYEMdXEvPFHOJ5ZyUjogYlUEeDLkWpGcc0ZI4vn43ofR"

        vars.SelectedPlayer = vars.SelectedPlayer or ""
        vars.JumlahPop = vars.JumlahPop or ""
        vars.JumlahPesanan = vars.JumlahPesanan or ""
        vars.AutoSystemRunning = vars.AutoSystemRunning or false

        local Group = MainTab:AddLeftGroupbox("Aurora Totem System")

        local playerNames = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(playerNames, plr.Name)
        end

        Group:AddDropdown("DropdownPlayer", {
            Values = playerNames,
            Default = player.Name,
            Multi = false,
            Text = "Pilih Player",
        }):OnChanged(function(value)
            vars.SelectedPlayer = value
        end)

        Group:AddInput("JumlahPop", {
            Default = "",
            Text = "Jumlah Pop",
            Placeholder = "Contoh: 5",
        }):OnChanged(function(value)
            vars.JumlahPop = value
        end)

        Group:AddInput("JumlahPesanan", {
            Default = "",
            Text = "Jumlah Pesanan",
            Placeholder = "Contoh: 10",
        }):OnChanged(function(value)
            vars.JumlahPesanan = value
        end)

        local function equipTool(toolName)
            local backpack = player:FindFirstChild("Backpack")
            if not backpack then return end
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    item.Parent = player.Character
                    task.wait(0.3)
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

        local function sendWebhook()
            local payload = {
                embeds = { {
                    title = "AURORA TOTEM LOGGER",
                    color = 3447003,
                    fields = {
                        { name = "Player", value = vars.SelectedPlayer ~= "" and vars.SelectedPlayer or player.Name },
                        { name = "Jumlah Pop", value = vars.JumlahPop ~= "" and vars.JumlahPop or "-" },
                        { name = "Jumlah Pesanan", value = vars.JumlahPesanan ~= "" and vars.JumlahPesanan or "-" },
                        { name = "Cycle", value = cycle.Value },
                        { name = "Weather", value = weather.Value },
                    },
                    footer = { text = "Aurora Logger Otomatis" },
                    timestamp = DateTime.now():ToIsoDate()
                } }
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
                Library:Notify("Webhook terkirim.", 4)
            else
                Library:Notify("Gagal kirim webhook: " .. tostring(err), 4)
            end
        end

        local function startAutoWebhook()
            if vars.AutoSystemRunning then
                Library:Notify("Sistem sudah berjalan.", 3)
                return
            end

            vars.AutoSystemRunning = true
            Library:Notify("Memulai pemantauan realtime Cycle...", 4)

            task.spawn(function()
                local connection
                connection = cycle:GetPropertyChangedSignal("Value"):Connect(function()
                    if not vars.AutoSystemRunning then connection:Disconnect() return end

                    local val = cycle.Value

                    if val == "Night" then
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end

                        repeat task.wait(0.5) until cycle.Value == "Day" or not vars.AutoSystemRunning
                        if not vars.AutoSystemRunning then return end

                        local sundial2 = equipTool("Sundial Totem")
                        if sundial2 then useTool(sundial2) end

                        repeat task.wait(0.5) until cycle.Value == "Night" or not vars.AutoSystemRunning
                        if not vars.AutoSystemRunning then return end

                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end

                        sendWebhook()
                        vars.AutoSystemRunning = false
                        connection:Disconnect()
                    elseif val == "Day" then
                        local sundial = equipTool("Sundial Totem")
                        if sundial then useTool(sundial) end

                        repeat task.wait(0.5) until cycle.Value == "Night" or not vars.AutoSystemRunning
                        if not vars.AutoSystemRunning then return end

                        local aurora = equipTool("Aurora Totem")
                        if aurora then useTool(aurora) end

                        sendWebhook()
                        vars.AutoSystemRunning = false
                        connection:Disconnect()
                    end
                end)

                local firstCheck = cycle.Value
                if firstCheck == "Night" then
                    local sundial = equipTool("Sundial Totem")
                    if sundial then useTool(sundial) end
                elseif firstCheck == "Day" then
                    local sundial = equipTool("Sundial Totem")
                    if sundial then useTool(sundial) end
                end
            end)
        end

        Group:AddButton("Mulai Auto Webhook", function()
            if vars.SelectedPlayer == "" then vars.SelectedPlayer = player.Name end
            startAutoWebhook()
        end)
    end
}
