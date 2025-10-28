-- Commands/Order.lua
-- Aurora Logger + Auto Webhook System (Vulcano Compatible + Base64 Manual + GitHub Auto Update JSON)
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
  
        -------------------------------------------------
        -- 🔹 Base64 Encoder Manual
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
  
        -------------------------------------------------
        -- 🔹 Load AuroraStats.json dari GitHub
        -------------------------------------------------
        local function loadAuroraStatsFromGitHub(selectedName)
            local token = Config.githubToken or "TOKEN_NOT_FOUND"
            local user = Config.githubUser or "unknown"
            local repo = Config.githubRepo or "aurora"
            local path = Config.statsPath or "Data/AuroraStats.json"
  
            local req = syn and syn.request or request or http_request or (http and http.request)
            if not req then
                Library:Notify("Executor tidak mendukung HTTP Request!", 4)
                return
            end
  
            local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", user, repo, path)
            local response = req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["User-Agent"] = "AuroraLogger"
                }
            })
  
            if not response or not response.Body then
                Library:Notify("Gagal membaca AuroraStats.json dari GitHub.", 4)
                return
            end
  
            local ok, body = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if not ok or not body or not body.content then
                Library:Notify("Format AuroraStats.json tidak valid.", 4)
                return
            end
  
            local decoded = HttpService:Base64Decode(body.content)
            local jsonData = HttpService:JSONDecode(decoded)
  
            if jsonData.player == selectedName then
                vars.JumlahPop = jsonData.jumlah_pop or ""
                vars.JumlahPesanan = jsonData.jumlah_pesanan or ""
  
                -- Update input field di UI
                Library.Flags.AuroraPopInput:Set(vars.JumlahPop)
                Library.Flags.AuroraPesananInput:Set(vars.JumlahPesanan)
  
                Library:Notify("Data " .. selectedName .. " berhasil dimuat dari JSON!", 4)
            end
        end
  
        -------------------------------------------------
        -- 🔹 Dropdown Player
        -------------------------------------------------
        local playerDropdown = Group:AddDropdown("AuroraPlayerDropdown", {
            Values = getPlayerList(),
            Multi = false,
            Text = "Pilih Player",
            Callback = function(value)
                local name = string.match(value, "%[(.-)%]$")
                if name then
                    vars.SelectedPlayer = name
                    loadAuroraStatsFromGitHub(name)
                end
            end
        })
  
        Group:AddButton("Refresh List", function()
            playerDropdown:SetValues(getPlayerList())
            Library:Notify("Daftar player diperbarui.", 3)
        end)
  
        Group:AddInput("AuroraPopInput", {
            Default = vars.JumlahPop or "",
            Text = "Jumlah Aurora di-Pop",
            Placeholder = "Contoh: 5",
            Callback = function(value)
                vars.JumlahPop = value
            end
        })
  
        Group:AddInput("AuroraPesananInput", {
            Default = vars.JumlahPesanan or "",
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
        -- 🔹 Simpan ke GitHub sebagai AuroraStats.json
        -------------------------------------------------
        local function saveAuroraStatsToGitHub()
            local token = Config.githubToken or "TOKEN_NOT_FOUND"
            if token == "TOKEN_NOT_FOUND" then
                warn("[Aurora Logger] Token GitHub tidak ditemukan di Config.")
                return
            end
  
            local user = Config.githubUser or "unknown"
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
            if not req then
                Library:Notify("Executor tidak mendukung HTTP Request!", 4)
                return
            end
  
            local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", user, repo, path)
  
            -- Ambil SHA jika file sudah ada
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
  
            -- PUT request
            local patchBody = {
                message = "Auto update AuroraStats.json from Aurora Logger",
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
                Library:Notify("✅ AuroraStats.json berhasil disimpan ke GitHub!", 4)
            else
                warn("[Aurora Logger] Gagal menyimpan AuroraStats.json:", response and response.Body)
            end
        end
  
        -------------------------------------------------
        -- 🔹 Kirim Webhook + Simpan JSON
        -------------------------------------------------
        local function sendWebhook()
            if vars.SelectedPlayer == "" or vars.JumlahPop == "" or vars.JumlahPesanan == "" then
                Library:Notify("Isi Player, Jumlah Pop, dan Pesanan dulu!", 4)
                return
            end
  
            local payload = {
                embeds = {{
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
                }}
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
                saveAuroraStatsToGitHub()
            else
                Library:Notify("Gagal mengirim webhook: " .. tostring(err), 4)
            end
        end
  
        -------------------------------------------------
        -- 🔹 Auto Webhook Sequence
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
                    useTool(sundial)
                    Library:Notify("Sundial Totem digunakan.", 3)
                end
            end
  
            local function equipAndUseAurora()
                unequipTool("Sundial Totem")
                local aurora = equipTool("Aurora Totem")
                if aurora then
                    useTool(aurora)
                    Library:Notify("Aurora Totem digunakan.", 3)
  
                    if weather.Value ~= "Aurora_Borealis" then
                        Library:Notify("Menunggu Aurora Borealis aktif...", 4)
                        local connection
                        connection = weather:GetPropertyChangedSignal("Value"):Connect(function()
                            if weather.Value == "Aurora_Borealis" then
                                Library:Notify("Aurora Borealis aktif! Mengirim webhook...", 4)
                                sendWebhook()
                                connection:Disconnect()
                            end
                        end)
                    else
                        sendWebhook()
                    end
                end
            end
  
            if cycle.Value == "Day" then
                equipAndUseSundial()
                Library:Notify("Menunggu Night...", 3)
                cycle:GetPropertyChangedSignal("Value"):Connect(function()
                    if cycle.Value == "Night" then
                        equipAndUseAurora()
                    end
                end)
            elseif cycle.Value == "Night" then
                equipAndUseSundial()
                Library:Notify("Menunggu Day untuk reset...", 3)
                cycle:GetPropertyChangedSignal("Value"):Connect(function()
                    if cycle.Value == "Day" then
                        equipAndUseSundial()
                    end
                end)
            end
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
            startAutoSequence()
        end)
  
        print("✅ [Aurora Order] Sistem aktif di tab:", tostring(MainTab.Title or "Fisch"))
    end
  }
  