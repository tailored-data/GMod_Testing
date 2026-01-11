--[[
    Ragdoll Boxing - Server Initialization
    Main server-side entry point
]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_camera.lua")

include("shared.lua")
include("sv_player.lua")
include("sv_rounds.lua")

-- Current game state
GM.GameState = GAMESTATE_WAITING
GM.RoundStartTime = 0
GM.RoundEndTime = 0

function GM:Initialize()
    self.BaseClass:Initialize()
    self:CreateTeams()
    print("[RagBox] Server initialized!")
end

function GM:PlayerConnect(name, ip)
    print("[RagBox] " .. name .. " is connecting...")
end

function GM:PlayerDisconnected(ply)
    -- Clean up ragdoll if player disconnects
    if IsValid(ply.Ragdoll) then
        ply.Ragdoll:Remove()
    end

    -- Check if we need to end round due to lack of players
    timer.Simple(0.1, function()
        self:CheckRoundEnd()
    end)
end

function GM:PlayerAuthed(ply, steamid, uniqueid)
    print("[RagBox] " .. ply:Nick() .. " has authenticated.")
end

function GM:ShowHelp(ply)
    -- Could show help menu here
end

function GM:ShowTeam(ply)
    -- Could show team selection here
end

function GM:ShowSpare1(ply)
    -- F3 key
end

function GM:ShowSpare2(ply)
    -- F4 key
end

-- Think hook to update game logic
function GM:Think()
    self:RoundThink()
end
