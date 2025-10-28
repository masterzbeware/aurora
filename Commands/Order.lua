-- Commands/Order.lua
-- Aurora Logger + Auto Webhook System (Fixed Sequence + Inline Embed + Save AuroraStats)

return {
  Execute = function(tab)
      -------------------------------------------------
      -- 🔹 Setup variabel utama
      -------------------------------------------------
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local Library = vars.Library
      local MainTab = tab or Tabs.Fisch

      if not Library or not MainTab then
          warn("[Aurora Logger] Gagal inisialisasi — Library atau Tab tidak ditemukan.")
          return
      end

      -------------------------------------------------
      -- 🔹 Group utama
      -------------------------------------------------
      local Group = MainTab:AddLeftGroupbox("Aurora Totem")

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
      -- 🔹 Variabel & Webhook
      -------------------------------------------------
      local webhookURL = "https://discord.com/api/webhooks/1426999320590422237/MRBvIpOriZD1sJGd--F2A4RfFYEMdXEvPFHOJ5ZyUjogYlUEeDLkWpGcc0ZI4vn43ofR"

      vars.SelectedPlayer = vars.SelectedPlayer or ""
      vars.JumlahPop = vars.JumlahPop or ""
      vars.JumlahPesanan = vars.JumlahPesanan or ""
      vars.AutoSystemRunning = vars.AutoSystemRunning or false

      -------------------------------------------------
      -- 🔹 Fungsi Simpan Data Aurora ke File Lokal
      -------------------------------------------------
      local function saveAuroraData(username, jumlahPop, jumlahPesanan)
          local statsUrl = "https://raw.githubusercontent.com/masterzbeware/aurora/main/data/AuroraStats.lua"
          local localPath = "AuroraStats.lua"

          local success, result = pcall(function()
              return game:HttpGet(statsUrl)
          end)

          if not success or not result then
              warn("[Aurora Logger] Gagal ambil AuroraStats.lua dari repo.")
              return
          end

          local newLine = string.format('    { "%s", "%s", "%s" },', username, jumlahPop, jumlahPesanan)
          local updated = result:gsub("}%s*$", newLine .. "\n}")

          writefile(localPath, updated)
          print("[Aurora Logger] ✅ Data AuroraStats diperbarui dan disimpan ke file lokal.")
      end

      -------------------------------------------------
      -- 🔹 Dropdown Player
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

      -------------------------------------------------
      -- 🔹 Input jumlah Pop & Pesanan
      -------------------------------------------------
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
              task.wait(0.4)
              tool:Activate()
              print("[Use] " .. tool.Name)
          end
      end

      -------------------------------------------------
      -- 🔹 Fungsi Kirim Webhook
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
              saveAuroraData(vars.SelectedPlayer, vars.JumlahPop, vars.JumlahPesanan)
          else
              Library:Notify("Gagal mengirim webhook: " .. tostring(err), 4)
          end
      end

      -------------------------------------------------
      -- 🔹 Auto Sequence (baru)
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
                  sendWebhook()
              end
          end

          -------------------------------------------------
          -- Jalur Night → Day → Night
          -------------------------------------------------
          if cycle.Value == "Night" then
              Library:Notify("Mode: Night - Memulai siklus panjang.", 4)
              equipAndUseSundial()

              local c1
              c1 = cycle:GetPropertyChangedSignal("Value"):Connect(function()
                  if cycle.Value == "Day" then
                      equipAndUseSundial()
                      Library:Notify("Menunggu Night berikutnya...", 4)

                      local c2
                      c2 = cycle:GetPropertyChangedSignal("Value"):Connect(function()
                          if cycle.Value == "Night" then
                              equipAndUseAurora()
                              Library:Notify("Menjalankan Aurora Totem & Kirim Webhook", 4)
                              c2:Disconnect()
                          end
                      end)

                      c1:Disconnect()
                  end
              end)

          -------------------------------------------------
          -- Jalur Day → Night
          -------------------------------------------------
          elseif cycle.Value == "Day" then
              Library:Notify("Mode: Day - Menunggu Night...", 4)
              equipAndUseSundial()

              local c3
              c3 = cycle:GetPropertyChangedSignal("Value"):Connect(function()
                  if cycle.Value == "Night" then
                      equipAndUseAurora()
                      Library:Notify("Menjalankan Aurora Totem & Kirim Webhook", 4)
                      c3:Disconnect()
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
