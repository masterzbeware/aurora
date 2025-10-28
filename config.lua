-- Config/config.lua
local success, secret = pcall(function()
  return loadfile("Config/secret.lua")()
end)

return {
  githubToken = (success and secret.githubToken) or "TOKEN_NOT_FOUND",
  githubUser = "masterzbeware",
  githubRepo = "aurora",
  statsPath = "data/AuroraStats.lua"
}
