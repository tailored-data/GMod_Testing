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
include("sv_resources.lua")
include("sv_housing.lua")
include("sv_vehicles.lua")

-- Initialize gamemode
function GM:Initialize()
    print("")
    print("========================================")
    print("  FRONTIER COLONY")
    print("  Cooperative Space Colony Survival RPG")
    print("========================================")
    print("")

    self:CreateTeams()
    self:InitializeColony()
    self:InitializeEconomy()
    self:InitializeHousing()
    self:InitializeVehicles()

    -- Delayed resource spawn (after map loads)
    timer.Simple(2, function()
        self:InitializeResources()
    end)

    print("[Frontier] All systems initialized!")
    print("")
end

-- Main think loop
function GM:Think()
    self:ColonyThink()
    self:EconomyThink()
end

-- Game description
function GM:GetGameDescription()
    return "Frontier Colony"
end

-- Player commands
function GM:PlayerSay(ply, text, teamChat)
    local cmd = string.lower(text)

    if cmd == "/help" then
        ply:ChatPrint("")
        ply:ChatPrint("[Frontier Colony] Commands:")
        ply:ChatPrint("  /job - Open job selection")
        ply:ChatPrint("  /shop - Open the shop")
        ply:ChatPrint("  F3 - Quick shop access")
        ply:ChatPrint("  F4 - Quick job access")
        ply:ChatPrint("")
        ply:ChatPrint("How to play:")
        ply:ChatPrint("  - Choose a job to earn Credits")
        ply:ChatPrint("  - Mine ore nodes for Alloy")
        ply:ChatPrint("  - Keep colony Power and Food above zero")
        ply:ChatPrint("  - Defend against alien attacks")
        ply:ChatPrint("")
        return ""
    end

    return text
end

-- Player connect
function GM:PlayerConnect(name, ip)
    print("[Frontier] " .. name .. " connecting...")
end

-- Player authenticated
function GM:PlayerAuthed(ply, steamid, uniqueid)
    print("[Frontier] " .. ply:Nick() .. " authenticated")
end

-- Player death
function GM:PlayerDeath(victim, inflictor, attacker)
    if IsValid(victim) then
        victim:ChatPrint("[Frontier] You have been downed. Respawning in 5 seconds...")

        timer.Simple(5, function()
            if IsValid(victim) then
                victim:Spawn()
            end
        end)
    end
end

-- Prevent suicide
function GM:CanPlayerSuicide(ply)
    return false
end

-- Scale damage based on job abilities
function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    local data = self:GetPlayerData(ply)
    if not data then return end

    local job = GetJobByID(data.job)
    if not job then return end

    -- Security takes less damage
    if table.HasValue(job.abilities or {}, "armor_boost") then
        dmginfo:ScaleDamage(0.8)
    end
end

-- Entity damage scaling
function GM:EntityTakeDamage(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    if IsValid(attacker) and attacker:IsPlayer() then
        local data = self:GetPlayerData(attacker)
        if data then
            local job = GetJobByID(data.job)
            if job and table.HasValue(job.abilities or {}, "combat_bonus") then
                dmginfo:ScaleDamage(1.25)
            end
        end
    end
end

-- Spawn point selection
function GM:PlayerSelectSpawn(ply)
    local classes = {
        "info_player_start",
        "info_player_deathmatch",
        "info_player_terrorist",
        "info_player_counterterrorist",
        "info_player_combine",
        "info_player_rebel"
    }

    for _, class in ipairs(classes) do
        local spawns = ents.FindByClass(class)
        if #spawns > 0 then
            return spawns[math.random(#spawns)]
        end
    end

    return nil
end

-- No fall damage
function GM:GetFallDamage(ply, speed)
    return 0
end

-- Allow flashlight
function GM:PlayerSwitchFlashlight(ply, enabled)
    return true
end

-- Spawn NPCs on map load
hook.Add("InitPostEntity", "Frontier_SpawnNPCs", function()
    timer.Simple(3, function()
        -- Find a good spot to spawn dealer NPCs
        local spawns = ents.FindByClass("info_player_start")
        if #spawns > 0 then
            local basePos = spawns[1]:GetPos()

            -- Spawn Housing Dealer
            local housing = ents.Create("frontier_npc_housing")
            if IsValid(housing) then
                housing:SetPos(basePos + Vector(100, 0, 0))
                housing:SetAngles(Angle(0, 180, 0))
                housing:Spawn()
                print("[Frontier] Spawned Property Dealer")
            end

            -- Spawn Vehicle Dealer
            local vehicles = ents.Create("frontier_npc_vehicles")
            if IsValid(vehicles) then
                vehicles:SetPos(basePos + Vector(-100, 0, 0))
                vehicles:SetAngles(Angle(0, 0, 0))
                vehicles:Spawn()
                print("[Frontier] Spawned Vehicle Dealer")
            end
        end
    end)
end)

print("[Frontier] Server script loaded.")
