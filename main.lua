local repoBase = "https://raw.githubusercontent.com/masterzbeware/aurora/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

local function debugPrint(msg)
    print("[OctoraStore | Roblox] " .. tostring(msg))
end

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
}

local MainWindow = Library:CreateWindow({
    Title = "MasterZ Hub Roblox",
    Footer = "1.0.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

local LoadedModules = {}
local commandFiles = {"WindowTab.lua", "Order.lua"}

local function loadScripts(files, repo, targetTable)
    for _, fileName in ipairs(files) do
        local url = repo .. fileName
        debugPrint("Mengambil file: " .. url)
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success and response then
            local func, err = loadstring(response)
            if func then
                local status, module = pcall(func)
                if status then
                    targetTable[fileName:lower()] = module
                    debugPrint("Berhasil load: " .. fileName)
                else
                    warn("Gagal eksekusi module " .. fileName .. ": " .. tostring(module))
                end
            else
                warn("Gagal compile " .. fileName .. ": " .. tostring(err))
            end
        else
            warn("Gagal fetch " .. fileName)
        end
    end
end

loadScripts(commandFiles, repoBase, LoadedModules)

for name, module in pairs(LoadedModules) do
    if type(module) == "table" and module.Execute then
        debugPrint("Menjalankan module: " .. name)
        pcall(module.Execute)
    end
end

debugPrint("Semua UI aktif — Tabs seharusnya sudah muncul di jendela utama.")
