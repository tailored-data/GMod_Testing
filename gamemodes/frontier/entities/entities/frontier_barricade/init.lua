--[[
    Frontier Colony - Barricade Entity (Server)
    Defensive barrier that absorbs damage
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/concrete_barrier001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(500)
    end

    self.Health = 500
    self.MaxHealth = 500
end

function ENT:OnTakeDamage(dmginfo)
    self.Health = self.Health - dmginfo:GetDamage()

    -- Visual damage feedback
    local healthRatio = self.Health / self.MaxHealth
    self:SetColor(Color(255, 255 * healthRatio, 255 * healthRatio))

    if self.Health <= 0 then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("Explosion", effectdata)

        self:EmitSound("physics/concrete/concrete_break3.wav", 100, 100)
        self:Remove()
    end
end
