-- Commands/Order.lua
-- Aurora Logger + Auto Webhook System (Fixed Base64 + Auto Load JSON)

return {
    Execute = function(tab)
        -------------------------------------------------
        -- 🔹 Setup variabel utama
        -------------------------------------------------
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local Library = vars.Library
        local MainTab = tab or Tabs.Fisch
        local Config = vars.Config or {}

        if not Library or not MainTab then
            warn("[Aurora Logger] Gagal inisialisasi — Library atau Tab tidak ditemukan.")
            return
        end

        -------------------------------------------------
        -- 🔹 Service dan Variabel
        -------------------------------------------------
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

        -------------------------------------------------
        -- 🔹 Webhook dan Variabel Bot
        -------------------------------------------------
        local webhookURL = "https://discord.com/api/webhooks/1426999320590422237/MRBvIpOriZD1sJGd--F2A4RfFYEMdXEvPFHOJ5ZyUjogYlUEeDLkWpGcc0ZI4vn43ofR"

        vars.SelectedPlayer = vars.SelectedPlayer or ""
        vars.JumlahPop = vars.JumlahPop or ""
        vars.JumlahPesanan = vars.JumlahPesanan or ""
        vars.AutoSystemRunning = vars.AutoSystemRunning or false

        -------------------------------------------------
        -- 🔹 Tab dan UI
        -------------------------------------------------
        local Group = MainTab:AddLeftGroupbox("Aurora Totem")

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
                if name then
                    vars.SelectedPlayer = name
                    task.defer(function()
                        loadAuroraStatsFromGitHub()
                    end)
                end
            end
        })

        Group:AddButton("Refresh List", function()
            playerDropdown:SetValues(getPlayerList())
            Library:Notify("Daftar player diperbarui.", 3)
        end)

        local inputPop = Group:AddInput("AuroraPopInput", {
            Default = "",
            Text = "Jumlah Aurora di-Pop",
            Placeholder = "Contoh: 5",
            Callback = function(value)
                vars.JumlahPop = value
            end
        })

        local inputPesanan = Group:AddInput("AuroraPesananInput", {
            Default = "",
            Text = "Jumlah Aurora di-Pesan",
            Placeholder = "Contoh: 10",
            Callback = function(value)
                vars.JumlahPesanan = value
            end
        })

        -------------------------------------------------
        -- 🔹 Fungsi Equip / Use Tool
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
        -- 🔹 Base64 Encoder / Decoder Manual
        -------------------------------------------------
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

        local function toBase64(data)
            return ((data:gsub('.', function(x)
                local r, b = '', x:byte()
                for i = 8, 1, -1 do
                    r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
                end
                return r
            end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
                if #x < 6 then return '' end
                local c = 0
                for i = 1, 6 do
                    c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
                end
                return b:sub(c + 1, c + 1)
            end) .. ({ '', '==', '=' })[#data % 3 + 1])
        end

        local function fromBase64(data)
            data = string.gsub(data, '[^'..b..'=]', '')
            return (data:gsub('.', function(x)
                if x == '=' then return '' end
                local r, f = '', (string.find(b, x) - 1)
                for i = 6, 1, -1 do
                    r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
                end
                return r
            end):gsub('%d%d%d%d%d%d%d%d', function(x)
                local c = 0
                for i = 1, 8 do
                    c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
                end
                return string.char(c)
            end))
        end

        -------------------------------------------------
        -- 🔹 Fungsi Load AuroraStats.json dari GitHub
        -------------------------------------------------
        function loadAuroraStatsFromGitHub()
            local token = Config.githubToken
            local user = Config.githubUser or "masterzbeware"
            local repo = Config.githubRepo or "aurora"
            local path = Config.statsPath or "Data/AuroraStats.json"

            if not token then
                warn("[Aurora Logger] Token GitHub tidak ditemukan di Config.")
                return
            end

            local req = syn and syn.request or request or http_request or (http and http.request)
            if not req then
                warn("[Aurora Logger] Executor tidak mendukung HTTP Request!")
                return
            end

            local response = req({
                Url = string.format("https://api.github.com/repos/%s/%s/contents/%s", user, repo, path),
                Method = "GET",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["User-Agent"] = "AuroraLoader"
                }
            })

            if response and response.Body then
                local ok, body = pcall(function() return HttpService:JSONDecode(response.Body) end)
                if ok and body.content then
                    local decoded = fromBase64(body.content)
                    local data = HttpService:JSONDecode(decoded)

                    if data.player == vars.SelectedPlayer then
                        vars.JumlahPop = data.jumlah_pop or ""
                        vars.JumlahPesanan = data.jumlah_pesanan or ""

                        inputPop:SetValue(vars.JumlahPop)
                        inputPesanan:SetValue(vars.JumlahPesanan)

                        Library:Notify("✅ Data player dimuat dari GitHub!", 3)
                    end
                end
            end
        end

        -------------------------------------------------
        -- 🔹 Fungsi Simpan ke GitHub
        -------------------------------------------------
        local function saveAuroraStatsToGitHub()
            local token = Config.githubToken
            if not token then
                warn("[Aurora Logger] Token GitHub tidak ditemukan di Config.")
                return
            end

            local user = Config.githubUser or "masterzbeware"
            local repo = Config.githubRepo or "aurora"
            local path = Config.statsPath or "Data/AuroraStats.json"

            local data = {
                player = vars.SelectedPlayer,
                jumlah_pop = vars.JumlahPop,
                jumlah_pesanan = vars.JumlahPesanan,
                cycle = cycle.Value,
                weather = weather.Value,
                timestamp = DateTime.now():ToIsoDate()
            }

            local jsonData = HttpService:JSONEncode(data)
            local base64 = toBase64(jsonData)

            local req = syn and syn.request or request or http_request or (http and http.request)
            local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", user, repo, path)

            -- Cek SHA
            local sha
            local getResponse = req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["User-Agent"] = "AuroraLogger"
                }
            })
            if getResponse and getResponse.Body then
                local ok, body = pcall(function() return HttpService:JSONDecode(getResponse.Body) end)
                if ok and body.sha then sha = body.sha end
            end

            -- PUT update
            local patchBody = {
                message = "Auto update AuroraStats.json",
                content = base64,
                sha = sha
            }

            local response = req({
                Url = url,
                Method = "PUT",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["User-Agent"] = "AuroraLogger",
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(patchBody)
            })

            if response and (response.StatusCode == 200 or response.StatusCode == 201) then
                Library:Notify("✅ AuroraStats.json berhasil disimpan ke GitHub!", 3)
            else
                warn("[Aurora Logger] Gagal menyimpan AuroraStats.json:", response and response.Body)
            end
        end

        -------------------------------------------------
        -- 🔹 Kirim Webhook
        -------------------------------------------------
        local function sendWebhook()
            if vars.SelectedPlayer == "" or vars.JumlahPop == "" or vars.JumlahPesanan == "" then
                Library:Notify("Isi Player, Pop, dan Pesanan dulu!", 3)
                return
            end

            local payload = {
                embeds = {{
                    title = "AURORA POP TOTEM",
                    color = 3447003,
                    fields = {
                        { name = "Player", value = vars.SelectedPlayer },
                        { name = "Jumlah Pop", value = vars.JumlahPop },
                        { name = "Jumlah Pesanan", value = vars.JumlahPesanan },
                        { name = "Cycle", value = cycle.Value, inline = true },
                        { name = "Weather", value = weather.Value, inline = true },
                    },
                    footer = { text = "Dikirim otomatis dari Aurora Logger" },
                    timestamp = DateTime.now():ToIsoDate()
                }}
            }

            local req = syn and syn.request or request or http_request or (http and http.request)
            pcall(function()
                req({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)

            saveAuroraStatsToGitHub()
        end

        -------------------------------------------------
        -- 🔹 Tombol mulai
        -------------------------------------------------
        Group:AddButton("Mulai Auto Webhook", function()
            if vars.SelectedPlayer == "" or vars.JumlahPop == "" or vars.JumlahPesanan == "" then
                Library:Notify("Isi semua data dulu!", 4)
                return
            end
            Library:Notify("Auto system dimulai.", 4)
            sendWebhook()
        end)

        print("✅ [Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
}
