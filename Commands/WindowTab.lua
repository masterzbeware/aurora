local Tabs = {}

if not _G.BotVars or not _G.BotVars.Library or not _G.BotVars.MainWindow then
    warn("[OctoraStore | Roblox] WindowTab.lua gagal — Library/MainWindow belum tersedia.")
    return Tabs
end

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

Tabs.Info = MainWindow:AddTab("Info", "info")

local BotGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
BotGroup:AddLabel("OctoraStore | Roblox")
BotGroup:AddLabel("Script loaded")

local ServerGroup = Tabs.Info:AddRightGroupbox("Server Info")
local latencyLabel = ServerGroup:AddLabel("Latency: ...")
local regionLabel  = ServerGroup:AddLabel("Server Region: ...")
local timeLabel    = ServerGroup:AddLabel("In Server: ...")

local function updateLatency()
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    latencyLabel:SetText("Latency: " .. math.floor(ping) .. "ms")
end

local function updateRegion()
    local success, region = pcall(function()
        return game:GetService("LocalizationService").RobloxLocaleId
    end)
    if not success or not region then region = "Unknown" end
    regionLabel:SetText("Server Region: " .. tostring(region))
end

local startTime = os.time()
local function updateTime()
    local elapsed = os.time() - startTime
    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = elapsed % 60
    timeLabel:SetText(string.format("In Server: %02d:%02d:%02d", h, m, s))
end

task.spawn(function()
    while task.wait(1) do
        pcall(updateLatency)
        pcall(updateRegion)
        pcall(updateTime)
    end
end)

Tabs.Fisch = MainWindow:AddTab("Fisch", "crosshair")

_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua berhasil dimuat — Tabs siap digunakan.")
return Tabs
