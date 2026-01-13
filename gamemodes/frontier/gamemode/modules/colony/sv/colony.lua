--[[
    Frontier Colony - Colony Management (Server)
    Manages colony-wide resources and state
]]

include("modules/colony/sh/config.lua")
AddCSLuaFile("modules/colony/sh/config.lua")

FRONTIER.Colony = FRONTIER.Colony or {}

-- Colony state
local ColonyState = {
    power = FRONTIER.Config.StartPower,
    food = FRONTIER.Config.StartFood,
    shields = FRONTIER.Config.StartShields,
    morale = FRONTIER.Config.StartMorale,
    underAttack = false,
    lastAttack = 0,
}

-- Network strings
util.AddNetworkString("Frontier_ColonyUpdate")
util.AddNetworkString("Frontier_ColonyAttack")
util.AddNetworkString("Frontier_ResourceGathered")

--[[
    Colony State Getters
]]
function FRONTIER.Colony.GetPower()
    return ColonyState.power
end

function FRONTIER.Colony.GetFood()
    return ColonyState.food
end

function FRONTIER.Colony.GetShields()
    return ColonyState.shields
end

function FRONTIER.Colony.GetMorale()
    return ColonyState.morale
end

function FRONTIER.Colony.IsUnderAttack()
    return ColonyState.underAttack
end

--[[
    Colony State Modifiers
]]
function FRONTIER.Colony.AddPower(amount)
    ColonyState.power = math.Clamp(ColonyState.power + amount, 0, FRONTIER.Config.MaxPower)
    FRONTIER.Colony.BroadcastState()
end

function FRONTIER.Colony.AddFood(amount)
    ColonyState.food = math.Clamp(ColonyState.food + amount, 0, FRONTIER.Config.MaxFood)
    FRONTIER.Colony.BroadcastState()
end

function FRONTIER.Colony.AddShields(amount)
    ColonyState.shields = math.Clamp(ColonyState.shields + amount, 0, FRONTIER.Config.MaxShields)
    FRONTIER.Colony.BroadcastState()
end

function FRONTIER.Colony.AddMorale(amount)
    ColonyState.morale = math.Clamp(ColonyState.morale + amount, 0, FRONTIER.Config.MaxMorale)
    FRONTIER.Colony.BroadcastState()
end

function FRONTIER.Colony.SetUnderAttack(attacking)
    ColonyState.underAttack = attacking
    if attacking then
        ColonyState.lastAttack = CurTime()
    end
    FRONTIER.Colony.BroadcastState()
end

--[[
    Network State to Clients
]]
function FRONTIER.Colony.BroadcastState()
    net.Start("Frontier_ColonyUpdate")
        net.WriteFloat(ColonyState.power)
        net.WriteFloat(ColonyState.food)
        net.WriteFloat(ColonyState.shields)
        net.WriteFloat(ColonyState.morale)
        net.WriteBool(ColonyState.underAttack)
    net.Broadcast()
end

function FRONTIER.Colony.SendStateToPlayer(ply)
    net.Start("Frontier_ColonyUpdate")
        net.WriteFloat(ColonyState.power)
        net.WriteFloat(ColonyState.food)
        net.WriteFloat(ColonyState.shields)
        net.WriteFloat(ColonyState.morale)
        net.WriteBool(ColonyState.underAttack)
    net.Send(ply)
end

--[[
    Resource Drain Timer
]]
timer.Create("Frontier_ResourceDrain", 60, 0, function()
    -- Power drain
    ColonyState.power = math.max(0, ColonyState.power - FRONTIER.Config.PowerDrain)

    -- Food drain (based on player count)
    local playerCount = #player.GetAll()
    local foodDrain = FRONTIER.Config.FoodDrain * math.max(1, playerCount * 0.5)
    ColonyState.food = math.max(0, ColonyState.food - foodDrain)

    -- Morale effects from low resources
    if ColonyState.power < 100 then
        ColonyState.morale = math.max(0, ColonyState.morale - 2)
    end
    if ColonyState.food < 50 then
        ColonyState.morale = math.max(0, ColonyState.morale - 3)
    end

    -- Low morale effects
    if ColonyState.morale < 25 then
        -- Notify players
        DarkRP.notifyAll(1, 4, "Colony morale is critically low!")
    end

    FRONTIER.Colony.BroadcastState()
end)

--[[
    Player Spawns - Send Colony State
]]
hook.Add("PlayerInitialSpawn", "Frontier_SendColonyState", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            FRONTIER.Colony.SendStateToPlayer(ply)
        end
    end)
end)

--[[
    Player Death - Morale Loss
]]
hook.Add("PlayerDeath", "Frontier_MoraleLoss", function(victim, inflictor, attacker)
    if ColonyState.underAttack then
        FRONTIER.Colony.AddMorale(-FRONTIER.Config.MoraleLossOnDeath)
    end
end)

--[[
    Job Bonus Helper
]]
function FRONTIER.Colony.GetPlayerJobBonus(ply, bonusType)
    if not IsValid(ply) then return 1.0 end

    local jobTable = ply:getJobTable()
    if not jobTable or not jobTable.frontierBonus then return 1.0 end

    local bonusData = FRONTIER.JobBonuses[jobTable.frontierBonus]
    if not bonusData then return 1.0 end

    if bonusType == "resource" and bonusData.resourceType then
        return 1.0 + bonusData.bonus
    elseif bonusType == "damage" and bonusData.damageBonus then
        return 1.0 + bonusData.damageBonus
    elseif bonusType == "armor" and bonusData.armorBonus then
        return 1.0 - bonusData.armorBonus
    end

    return 1.0
end

--[[
    Security Job Combat Bonuses
]]
hook.Add("EntityTakeDamage", "Frontier_SecurityBonus", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    -- Damage bonus for security
    if IsValid(attacker) and attacker:IsPlayer() then
        local bonus = FRONTIER.Colony.GetPlayerJobBonus(attacker, "damage")
        if bonus > 1.0 then
            dmginfo:ScaleDamage(bonus)
        end
    end

    -- Armor bonus for security
    if IsValid(target) and target:IsPlayer() then
        local armorMult = FRONTIER.Colony.GetPlayerJobBonus(target, "armor")
        if armorMult < 1.0 then
            dmginfo:ScaleDamage(armorMult)
        end
    end
end)

print("[Frontier] Colony management system loaded")
