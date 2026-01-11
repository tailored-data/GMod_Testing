--[[
    Ragdoll Boxing - Shared
    Shared variables and functions between client and server
]]

GM.Name = "Ragdoll Boxing"
GM.Author = "Claude"
GM.Email = ""
GM.Website = ""

-- Game States
GAMESTATE_WAITING = 0
GAMESTATE_PLAYING = 1
GAMESTATE_ROUNDEND = 2

-- Round Configuration
ROUND_TIME = 120 -- 2 minutes in seconds
ROUND_END_TIME = 5 -- Time between rounds
MIN_PLAYERS = 2

-- Player Configuration
PLAYER_MAX_HEALTH = 100
PUNCH_DAMAGE = 10
PUNCH_FORCE = 500
PUNCH_COOLDOWN = 0.5
PUNCH_RANGE = 100

-- Ragdoll force multipliers
RAGDOLL_MOVE_FORCE = 1000
RAGDOLL_JUMP_FORCE = 400

-- Team setup
function GM:CreateTeams()
    team.SetUp(1, "Fighters", Color(255, 100, 100))
    team.SetUp(2, "Spectators", Color(200, 200, 200))
end

-- Shared initialization
function GM:Initialize()
    self:CreateTeams()
end

-- Network strings
if SERVER then
    util.AddNetworkString("RagBox_GameState")
    util.AddNetworkString("RagBox_RoundTime")
    util.AddNetworkString("RagBox_Punch")
    util.AddNetworkString("RagBox_PlayerHit")
    util.AddNetworkString("RagBox_RoundEnd")
end
