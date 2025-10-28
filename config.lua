return {
  githubToken = (function()
    local token = nil
    pcall(function()
      if isfile("token.lua") then
        token = loadstring(readfile("token.lua"))()
      end
    end)
    return token or "TOKEN_NOT_FOUND"
  end)(),

  githubUser = "masterzbeware",
  githubRepo = "aurora",

  -- 🔹 Jalur file yang akan digunakan untuk menyimpan AuroraStats.json
  -- Pastikan folder "Data" sudah dibuat di repo GitHub kamu (case-sensitive)
  statsPath = "Data/AuroraStats.json"
}
