--[[
    Frontier Colony - Client Init
    DarkRP-based space colony survival
]]

include("shared.lua")

-- Include colony client modules
include("modules/colony/sh/config.lua")
include("modules/colony/cl/hud.lua")

-- Load custom things on client
hook.Add("DarkRPFinishedLoading", "Frontier_LoadClientCustomThings", function()
    include("darkrp_customthings/jobs.lua")
end)

print("")
print("========================================")
print("  FRONTIER COLONY")
print("  Welcome to the colony!")
print("========================================")
print("")
