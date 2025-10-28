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
  statsPath = "data/AuroraStats.lua"
}
