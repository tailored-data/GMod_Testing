--[[
    Frontier Colony - Server Initialization
    A cooperative space colony survival RPG
]]

-- Include shared
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Include client files
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_menus.lua")

-- Include server files
include("sv_player.lua")
include("sv_economy.lua")
include("sv_colony.lua")

-- Initialize gamemode
function GM:Initialize()
    print("==========================================")
    print("  FRONTIER COLONY")
    print("  A Cooperative Space Colony Survival RPG")
    print("==========================================")

    self:CreateTeams()
    self:InitializeColony()
    self:InitializeEconomy()

    print("[Frontier] Gamemode initialized successfully!")
end

-- Main think loop
function GM:Think()
    self:ColonyThink()
    self:EconomyThink()
end

-- Set game description
function GM:GetGameDescription()
    return "Frontier Colony"
end

-- Player say hook for commands
function GM:PlayerSay(ply, text, teamChat)
    local lower = string.lower(text)

    if lower == "/help" then
        ply:ChatPrint("[Frontier] Commands:")
        ply:ChatPrint("  /job - Open job selection menu")
        ply:ChatPrint("  /shop - Open the shop")
        ply:ChatPrint("  Press F3 for shop, F4 for jobs")
        return ""
    end

    return text
end

-- Player connect message
function GM:PlayerConnect(name, ip)
    print("[Frontier] " .. name .. " is connecting to the colony...")
end

-- Player authenticated
function GM:PlayerAuthed(ply, steamid, uniqueid)
    print("[Frontier] " .. ply:Nick() .. " authenticated. SteamID: " .. steamid)
end

-- Player death handling
function GM:PlayerDeath(victim, inflictor, attacker)
    if IsValid(victim) then
        victim:ChatPrint("[Frontier] You have been downed! Respawning in 5 seconds...")

        -- Respawn after delay
        timer.Simple(5, function()
            if IsValid(victim) then
                victim:Spawn()
            end
        end)
    end
end

-- Prevent suicide spam
function GM:CanPlayerSuicide(ply)
    return false
end

-- Scale damage based on job
function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    local data = self:GetPlayerData(ply)
    if not data then return end

    local job = GetJobByID(data.job)
    if not job then return end

    -- Security takes less damage (armor_boost ability)
    if table.HasValue(job.abilities or {}, "armor_boost") then
        dmginfo:ScaleDamage(0.8)
    end
end

-- Scale NPC/entity damage based on job
function GM:EntityTakeDamage(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    if IsValid(attacker) and attacker:IsPlayer() then
        local data = self:GetPlayerData(attacker)
        if data then
            local job = GetJobByID(data.job)
            if job and table.HasValue(job.abilities or {}, "combat_bonus") then
                -- Security deals more damage
                dmginfo:ScaleDamage(1.25)
            end
        end
    end
end

-- Spawn point selection
function GM:PlayerSelectSpawn(ply)
    local spawns = ents.FindByClass("info_player_start")
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_deathmatch")
    end
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_terrorist")
    end
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_counterterrorist")
    end

    if #spawns > 0 then
        return spawns[math.random(#spawns)]
    end

    return nil
end

-- Disable fall damage (optional, for more casual gameplay)
function GM:GetFallDamage(ply, speed)
    return 0
end

-- Allow flashlight
function GM:PlayerSwitchFlashlight(ply, enabled)
    return true
end

print("[Frontier] Server initialization complete.")
