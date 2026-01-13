--[[
    Frontier Colony - Server Init
    DarkRP-based space colony survival
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Include our custom darkrp_customthings
AddCSLuaFile("darkrp_customthings/jobs.lua")
AddCSLuaFile("darkrp_customthings/entities.lua")
AddCSLuaFile("darkrp_customthings/vehicles.lua")

-- Server-side custom things loading happens after DarkRP initializes
hook.Add("DarkRPFinishedLoading", "Frontier_LoadCustomThings", function()
    include("darkrp_customthings/jobs.lua")
    include("darkrp_customthings/entities.lua")
    include("darkrp_customthings/vehicles.lua")
end)

-- Include colony module
include("modules/colony/sv/colony.lua")
include("modules/colony/sv/resources.lua")
include("modules/colony/sv/attacks.lua")

AddCSLuaFile("modules/colony/sh/config.lua")
AddCSLuaFile("modules/colony/cl/hud.lua")

print("")
print("========================================")
print("  FRONTIER COLONY")
print("  DarkRP-based Colony Survival")
print("========================================")
print("")
