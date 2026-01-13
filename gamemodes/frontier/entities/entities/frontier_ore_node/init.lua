--[[
    Frontier Colony - Ore Node Entity (Server)
    Mineable resource node that gives ore/credits
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01d.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    -- Resource settings
    self.ResourcesRemaining = 5
    self.MineDelay = 2
    self.LastMine = 0
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Check cooldown
    if CurTime() - self.LastMine < self.MineDelay then
        DarkRP.notify(activator, 1, 2, "Mining... please wait")
        return
    end

    self.LastMine = CurTime()
    self.ResourcesRemaining = self.ResourcesRemaining - 1

    -- Calculate reward with job bonus
    local baseReward = FRONTIER and FRONTIER.Config and FRONTIER.Config.OreBaseReward or 25
    local reward = baseReward

    -- Check for miner bonus
    local jobTable = activator:getJobTable()
    if jobTable and jobTable.frontierBonus == "miner" then
        reward = math.floor(reward * 1.5)
    end

    -- Give reward
    activator:addMoney(reward)
    DarkRP.notify(activator, 0, 3, "Mined ore worth " .. reward .. " credits! (" .. self.ResourcesRemaining .. " remaining)")

    -- Play sound
    self:EmitSound("physics/concrete/concrete_break2.wav", 75, 100)

    -- Deplete check
    if self.ResourcesRemaining <= 0 then
        DarkRP.notify(activator, 0, 3, "Node depleted!")
        self:EmitSound("physics/concrete/concrete_break3.wav", 75, 80)

        -- Spawn effect
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("Explosion", effectdata)

        self:Remove()
    end
end

function ENT:OnRemove()
    if FRONTIER and FRONTIER.Resources then
        FRONTIER.Resources.UnregisterNode(self)
    end
end
