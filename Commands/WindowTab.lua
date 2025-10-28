-- Commands/WindowTab.lua
-- Modul UI Tab MasterZ HUB

local Tabs = {}

-- Pastikan Library dan MainWindow sudah siap
if not _G.BotVars or not _G.BotVars.Library or not _G.BotVars.MainWindow then
    warn("[OctoraStore | Roblox] WindowTab.lua gagal — Library/MainWindow belum tersedia.")
    return Tabs
end

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

---------------------------------------------------
-- ✅ INFO TAB
---------------------------------------------------
Tabs.Info = MainWindow:AddTab("Info", "info")

---------------------------------------------------
-- 🔹 Group kiri: Bot Info
---------------------------------------------------
local BotGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
BotGroup:AddLabel("OctoraStore | Roblox")
BotGroup:AddLabel("Script loaded")

---------------------------------------------------
-- 🔹 Group kanan: Server Info
---------------------------------------------------
local ServerGroup = Tabs.Info:AddRightGroupbox("Server Info")

-- Label dinamis
local playersLabel = ServerGroup:AddLabel("Players: ...")
local latencyLabel = ServerGroup:AddLabel("Latency: ...")
local regionLabel  = ServerGroup:AddLabel("Server Region: ...")
local timeLabel    = ServerGroup:AddLabel("In Server: ...")

---------------------------------------------------
-- ✅ Group tambahan: Aurora Stats
---------------------------------------------------
local AuroraGroup = Tabs.Info:AddRightGroupbox("Aurora Stats")

-- Label awal
local playerLabel = AuroraGroup:AddLabel("Player: ...")
local popLabel = AuroraGroup:AddLabel("Jumlah Pop: ...")
local orderLabel = AuroraGroup:AddLabel("Jumlah Pesanan: ...")

-- Fungsi untuk memuat data dari AuroraStats.json
local function updateAuroraStats()
    local statsPath = "AuroraStats.json"
    if not isfile or not readfile then
        warn("[AuroraStats] Fungsi file tidak tersedia (executor tidak mendukung).")
        return
    end

    if not isfile(statsPath) then
        -- Jika belum ada file, buat dummy
        local dummy = {
            player = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown",
            pop = 0,
            orders = 0
        }
        writefile(statsPath, game:GetService("HttpService"):JSONEncode(dummy))
    end

    -- Coba baca file JSON
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(statsPath))
    end)

    if success and type(data) == "table" then
        playerLabel:SetText("Player: " .. tostring(data.player or "N/A"))
        popLabel:SetText("Jumlah Pop: " .. tostring(data.pop or 0))
        orderLabel:SetText("Jumlah Pesanan: " .. tostring(data.orders or 0))
    else
        warn("[AuroraStats] Gagal membaca JSON.")
    end
end

-- Jalankan update awal
updateAuroraStats()

-- Loop update tiap 5 detik
task.spawn(function()
    while task.wait(5) do
        pcall(updateAuroraStats)
    end
end)

---------------------------------------------------
-- ✅ Fungsi update otomatis Info Tab
---------------------------------------------------

-- Jumlah pemain
local function updatePlayers()
    local players = game:GetService("Players")
    local playerCount = #players:GetPlayers()
    local maxPlayers = players.MaxPlayers
    playersLabel:SetText("Players: " .. playerCount .. "/" .. maxPlayers)
end

-- Ping/Latency
local function updateLatency()
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    latencyLabel:SetText("Latency: " .. math.floor(ping) .. "ms")
end

-- Region server
local function updateRegion()
    local success, region = pcall(function()
        return game:GetService("LocalizationService").RobloxLocaleId
    end)
    if not success or not region then region = "Unknown" end
    regionLabel:SetText("Server Region: " .. tostring(region))
end

-- Lama waktu di server
local startTime = os.time()
local function updateTime()
    local elapsed = os.time() - startTime
    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = elapsed % 60
    timeLabel:SetText(string.format("In Server: %02d:%02d:%02d", h, m, s))
end

---------------------------------------------------
-- ✅ Loop update tiap 1 detik
---------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        pcall(updatePlayers)
        pcall(updateLatency)
        pcall(updateRegion)
        pcall(updateTime)
    end
end)

---------------------------------------------------
-- ✅ TAB LAIN (Contoh Combat/Fisch)
---------------------------------------------------
Tabs.Fisch = MainWindow:AddTab("Fisch", "crosshair")

---------------------------------------------------
-- ✅ Simpan di Global
---------------------------------------------------
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua berhasil dimuat — Tabs siap digunakan.")
return Tabs
