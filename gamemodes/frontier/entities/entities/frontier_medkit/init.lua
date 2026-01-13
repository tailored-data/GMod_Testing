--[[
    Frontier Colony - Medical Kit Entity (Server)
    Consumable item that heals the player
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/items/healthkit.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.HealAmount = 50
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local currentHealth = activator:Health()
    local maxHealth = activator:GetMaxHealth()

    if currentHealth >= maxHealth then
        DarkRP.notify(activator, 1, 3, "You are already at full health!")
        return
    end

    local healedTo = math.min(currentHealth + self.HealAmount, maxHealth)
    local actualHeal = healedTo - currentHealth

    activator:SetHealth(healedTo)
    DarkRP.notify(activator, 0, 3, "Healed for " .. actualHeal .. " health!")

    self:EmitSound("items/smallmedkit1.wav", 75, 100)
    self:Remove()
end
