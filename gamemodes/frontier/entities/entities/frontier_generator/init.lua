--[[
    Frontier Colony - Generator Entity (Server)
    Produces power for the colony over time
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_combine/combine_generator01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    -- Generator settings
    self.PowerOutput = 5
    self.GenerateInterval = 30  -- Every 30 seconds
    self.Active = true
    self.FuelRemaining = 10  -- 10 cycles

    -- Start generation timer
    timer.Create("FrontierGen_" .. self:EntIndex(), self.GenerateInterval, 0, function()
        if IsValid(self) then
            self:GeneratePower()
        end
    end)
end

function ENT:GeneratePower()
    if not self.Active then return end
    if self.FuelRemaining <= 0 then
        self.Active = false
        return
    end

    self.FuelRemaining = self.FuelRemaining - 1

    -- Add power to colony
    if FRONTIER and FRONTIER.Colony then
        -- Check owner for engineer bonus
        local owner = self:Getowning_ent()
        local powerAmount = self.PowerOutput

        if IsValid(owner) then
            local jobTable = owner:getJobTable()
            if jobTable and jobTable.frontierBonus == "engineer" then
                powerAmount = math.floor(powerAmount * 1.5)
            end
        end

        FRONTIER.Colony.AddPower(powerAmount)
    end

    -- Sound/effect
    self:EmitSound("ambient/machines/thumper_amb.wav", 60, 120, 0.5)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if self.FuelRemaining > 0 then
        DarkRP.notify(activator, 0, 3, "Generator active. Fuel remaining: " .. self.FuelRemaining .. " cycles")
    else
        DarkRP.notify(activator, 1, 3, "Generator depleted! Purchase a new one.")
    end
end

function ENT:OnRemove()
    timer.Remove("FrontierGen_" .. self:EntIndex())
end
