--[[
    Frontier Colony - Crop Node Entity (Server)
    Produces food for the colony when harvested
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/plasticcrate01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetColor(Color(100, 180, 60))

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    -- Crop settings
    self.GrowTime = 60  -- Seconds to grow
    self.PlantedTime = CurTime()
    self.Grown = false
    self.HarvestsRemaining = 3
end

function ENT:Think()
    if not self.Grown and CurTime() - self.PlantedTime >= self.GrowTime then
        self.Grown = true
        self:SetColor(Color(50, 255, 50))
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if not self.Grown then
        local remaining = math.ceil(self.GrowTime - (CurTime() - self.PlantedTime))
        DarkRP.notify(activator, 1, 3, "Crops still growing... " .. remaining .. " seconds remaining")
        return
    end

    -- Harvest
    self.HarvestsRemaining = self.HarvestsRemaining - 1

    local baseFood = FRONTIER and FRONTIER.Config and FRONTIER.Config.FoodBaseReward or 20
    local foodAmount = baseFood

    -- Farmer bonus
    local jobTable = activator:getJobTable()
    if jobTable and jobTable.frontierBonus == "farmer" then
        foodAmount = math.floor(foodAmount * 1.5)
    end

    -- Add to colony
    if FRONTIER and FRONTIER.Colony then
        FRONTIER.Colony.AddFood(foodAmount)
    end

    DarkRP.notify(activator, 0, 3, "Harvested " .. foodAmount .. " food! (" .. self.HarvestsRemaining .. " harvests remaining)")
    self:EmitSound("physics/body/body_medium_break2.wav", 70, 120)

    if self.HarvestsRemaining <= 0 then
        DarkRP.notify(activator, 0, 3, "Crops depleted!")
        self:Remove()
    else
        -- Reset growth
        self.Grown = false
        self.PlantedTime = CurTime()
        self:SetColor(Color(100, 180, 60))
    end
end
