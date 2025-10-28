-- main.lua
-- MasterZ HUB Loader (tanpa VIP)

---------------------------------------------------
-- 🔹 Repositori
---------------------------------------------------
local repoBase = "https://raw.githubusercontent.com/masterzbeware/aurora/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local configRepo = "https://raw.githubusercontent.com/masterzbeware/aurora/main/config.lua"

---------------------------------------------------
-- 🔹 Load Library
---------------------------------------------------
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

---------------------------------------------------
-- 🔹 Debug print helper
---------------------------------------------------
local function debugPrint(msg)
    print("[OctoraStore | Roblox] " .. tostring(msg))
end

---------------------------------------------------
-- 🔹 Load Config dari GitHub
---------------------------------------------------
local config = nil
local success, result = pcall(function()
    local code = game:HttpGet(configRepo)
    return loadstring(code)()
end)

if success and type(result) == "table" then
    config = result
    debugPrint("✅ Config.lua berhasil dimuat dari GitHub.")

    ---------------------------------------------------
    -- 🧠 Tambahan: ambil token dari file lokal
    ---------------------------------------------------
    local ok, localToken = pcall(function()
        if isfile and readfile and isfile("token.lua") then
            return loadstring(readfile("token.lua"))()
        end
        return nil
    end)

    if ok and type(localToken) == "string" and localToken ~= "" then
        config.githubToken = localToken
        debugPrint("🔒 Token GitHub dimuat dari file lokal (token.lua).")
    else
        warn("⚠️ Gagal memuat token lokal, update ke GitHub tidak akan berfungsi.")
    end
else
    warn("[OctoraStore] Gagal memuat config.lua dari GitHub:", result)
    config = {
        githubToken = "TOKEN_NOT_FOUND",
        githubUser = "unknown",
        githubRepo = "unknown",
        statsPath = "data/AuroraStats.lua"
    }
end

---------------------------------------------------
-- 🔹 Global Variabel
---------------------------------------------------
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
    Config = config, -- simpan config ke variabel global
}

---------------------------------------------------
-- 🔹 Buat Window Utama
---------------------------------------------------
local MainWindow = Library:CreateWindow({
    Title = "OctoraStore | Roblox",
    Footer = "1.3.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

---------------------------------------------------
-- 🔹 Fungsi untuk load semua script dari repo
---------------------------------------------------
local LoadedModules = {}
local commandFiles = {"WindowTab.lua", "Order.lua"} -- urutan penting

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

---------------------------------------------------
-- 🔹 Load semua command
---------------------------------------------------
loadScripts(commandFiles, repoBase, LoadedModules)

---------------------------------------------------
-- 🔹 Jalankan module yang memiliki fungsi Execute()
---------------------------------------------------
for name, module in pairs(LoadedModules) do
    if type(module) == "table" and module.Execute then
        debugPrint("Menjalankan module: " .. name)
        pcall(module.Execute)
    end
end

debugPrint("✅ Semua UI aktif — Tabs seharusnya sudah muncul di jendela utama.")
