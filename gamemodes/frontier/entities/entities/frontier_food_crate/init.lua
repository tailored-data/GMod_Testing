--[[
    Frontier Colony - Food Crate Entity (Server)
    Consumable item that adds food to the colony
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/garbage_takeoutcarton001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.FoodAmount = 30
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if FRONTIER and FRONTIER.Colony then
        FRONTIER.Colony.AddFood(self.FoodAmount)
        DarkRP.notify(activator, 0, 4, "Added " .. self.FoodAmount .. " food to the colony!")
    end

    self:EmitSound("items/ammo_pickup.wav", 75, 100)
    self:Remove()
end
