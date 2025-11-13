-- Punch.lua — Auto Punch Dirt (Smart, Fast, Safe, Toggle-based)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        local Library = vars.Library
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Fisch

        if not Library or not MainTab then
            warn("Gagal inisialisasi — Library atau Tab tidak ditemukan.")
            return
        end

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer

        local PunchEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PunchBlock")
        local WorldBlocks = workspace:WaitForChild("WorldBlocks")

        vars.AutoPunchEnabled = vars.AutoPunchEnabled or false

        -- parameter umum
        local range = 3       -- jarak maksimum untuk pukul block
        local delay = 0.12    -- delay antar pukulan (aman & cepat)

        ----------------------------------------------------------------
        -- Fungsi: cari block Dirt terdekat dalam jarak yang bisa dijangkau
        ----------------------------------------------------------------
        local function getClosestDirt()
            if not player.Character then return nil end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end

            local nearest, minDist = nil, range
            for _, block in ipairs(WorldBlocks:GetChildren()) do
                if block.Name == "Dirt" then
                    local pos = block:GetPivot().Position
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = block
                    end
                end
            end
            return nearest
        end

        ----------------------------------------------------------------
        -- Fungsi: punch block aman
        ----------------------------------------------------------------
        local function punchBlock(block)
            if block and block.Parent == WorldBlocks then
                local args = { block }
                pcall(function()
                    PunchEvent:FireServer(unpack(args))
                end)
            end
        end

        ----------------------------------------------------------------
        -- Fungsi utama auto punch (loop background)
        ----------------------------------------------------------------
        local function startAutoPunch()
            if vars._PunchLoop then
                Library:Notify("Auto Punch sudah aktif.", 3)
                return
            end

            vars._PunchLoop = task.spawn(function()
                Library:Notify("Auto Punch diaktifkan ✅", 3)
                while vars.AutoPunchEnabled do
                    local target = getClosestDirt()
                    if target then
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then break end

                        while vars.AutoPunchEnabled and target.Parent == WorldBlocks and hrp and (target:GetPivot().Position - hrp.Position).Magnitude <= range do
                            punchBlock(target)
                            task.wait(delay)
                        end
                    else
                        task.wait(0.3)
                    end
                end
                Library:Notify("Auto Punch dimatikan ❌", 3)
                vars._PunchLoop = nil
            end)
        end

        ----------------------------------------------------------------
        -- UI Toggle
        ----------------------------------------------------------------
        local Group = MainTab:AddLeftGroupbox("Auto Punch")

        Group:AddToggle("AutoPunchToggle", {
            Text = "Aktifkan Auto Punch",
            Default = false,
            Tooltip = "Otomatis memukul Dirt terdekat sampai hancur."
        }):OnChanged(function(state)
            vars.AutoPunchEnabled = state
            if state then
                startAutoPunch()
            end
        end)
    end
}
