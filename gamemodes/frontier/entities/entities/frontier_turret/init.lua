--[[
    Frontier Colony - Defense Turret Entity (Server)
    Automated defense turret that attacks hostile NPCs
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/combine_mortar01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    -- Turret settings
    self.Range = 800
    self.Damage = 15
    self.FireRate = 1  -- Seconds between shots
    self.LastFire = 0
    self.Health = 200
    self.MaxHealth = 200
    self.Active = true
end

function ENT:Think()
    if not self.Active then return end

    self:NextThink(CurTime() + 0.5)

    if CurTime() - self.LastFire < self.FireRate then return true end

    -- Find target
    local target = self:FindTarget()
    if IsValid(target) then
        self:FireAt(target)
    end

    return true
end

function ENT:FindTarget()
    local nearbyEnts = ents.FindInSphere(self:GetPos(), self.Range)

    for _, ent in ipairs(nearbyEnts) do
        if ent:IsNPC() and ent.FrontierEnemy then
            -- Check line of sight
            local tr = util.TraceLine({
                start = self:GetPos() + Vector(0, 0, 30),
                endpos = ent:GetPos() + Vector(0, 0, 30),
                filter = self
            })

            if tr.Entity == ent then
                return ent
            end
        end
    end

    return nil
end

function ENT:FireAt(target)
    self.LastFire = CurTime()

    -- Muzzle flash effect
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos() + Vector(0, 0, 40))
    effectdata:SetNormal((target:GetPos() - self:GetPos()):GetNormalized())
    util.Effect("MuzzleEffect", effectdata)

    -- Sound
    self:EmitSound("weapons/ar2/fire1.wav", 80, 100)

    -- Damage
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(self.Damage)
    dmginfo:SetAttacker(self:Getowning_ent() or self)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamageType(DMG_BULLET)

    target:TakeDamageInfo(dmginfo)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local healthPercent = math.floor((self.Health / self.MaxHealth) * 100)
    DarkRP.notify(activator, 0, 3, "Turret Status: " .. healthPercent .. "% health, " .. (self.Active and "ACTIVE" or "DISABLED"))
end

function ENT:OnTakeDamage(dmginfo)
    self.Health = self.Health - dmginfo:GetDamage()

    if self.Health <= 0 then
        self.Active = false

        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("Explosion", effectdata)

        self:EmitSound("ambient/explosions/explode_4.wav", 100, 100)
        self:Remove()
    end
end
