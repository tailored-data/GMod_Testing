--[[
    Frontier Colony - Shield Capacitor Entity (Server)
    Consumable item that adds shields to the colony
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/health_charger001.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.ShieldAmount = 15
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if FRONTIER and FRONTIER.Colony then
        FRONTIER.Colony.AddShields(self.ShieldAmount)
        DarkRP.notify(activator, 0, 4, "Added " .. self.ShieldAmount .. " shield power!")
    end

    self:EmitSound("items/suitchargeok1.wav", 75, 100)
    self:Remove()
end
