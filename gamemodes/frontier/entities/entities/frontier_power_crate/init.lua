--[[
    Frontier Colony - Power Cell Entity (Server)
    Consumable item that adds power to the colony
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/items/battery.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.PowerAmount = 50
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if FRONTIER and FRONTIER.Colony then
        FRONTIER.Colony.AddPower(self.PowerAmount)
        DarkRP.notify(activator, 0, 4, "Added " .. self.PowerAmount .. " power to the colony!")
    end

    self:EmitSound("items/battery_pickup.wav", 75, 100)
    self:Remove()
end
