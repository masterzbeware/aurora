-- main.lua
-- MasterZ HUB Loader (tanpa VIP)

-- Repositori
local repoBase = "https://raw.githubusercontent.com/masterzbeware/aurora/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

-- Debug print
local function debugPrint(msg)
    print("[OctoraStore | Roblox] " .. tostring(msg))
end

-- Global Variabel
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
}

-- Buat Window Utama
local MainWindow = Library:CreateWindow({
    Title = "OctoraStore | Roblox",
    Footer = "1.0.0",
    Icon = 0,
})

-- Simpan ke _G agar dapat diakses oleh module lain
_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

---------------------------------------------------
-- ✅ Fungsi untuk load semua script dari repo
---------------------------------------------------
local LoadedModules = {}
local commandFiles = {"WindowTab.lua", "Order.lua"} -- urutan penting: Tab dulu, baru lainnya

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

-- Load semua file command
loadScripts(commandFiles, repoBase, LoadedModules)

---------------------------------------------------
-- ✅ Jalankan module yang memiliki fungsi Execute()
---------------------------------------------------
for name, module in pairs(LoadedModules) do
    if type(module) == "table" and module.Execute then
        debugPrint("Menjalankan module: " .. name)
        pcall(module.Execute)
    end
end

debugPrint("✅ Semua UI aktif — Tabs seharusnya sudah muncul di jendela utama.")
