--[[
    Frontier Colony - Vehicle Dealer NPC
    Server-side entity
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/humans/group02/male_07.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()

    self:SetMaxYawSpeed(90)
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        -- Open vehicle menu for player
        net.Start("Frontier_OpenMenu")
        net.WriteString("vehicles")
        net.Send(caller)
        return true
    end
end

function ENT:OnTakeDamage(dmginfo)
    -- NPCs are invincible
    return 0
end
