--[[
    Frontier Colony - Resource Gathering System
    Handles ore nodes, generators, crops, and salvage
]]

-- Store resource node positions
ResourceNodes = ResourceNodes or {}

-- Initialize resource system
function GM:InitializeResources()
    print("[Frontier] Initializing resource system...")
    self:SpawnResourceNodes()
end

-- Spawn resource nodes around the map
function GM:SpawnResourceNodes()
    -- Find suitable spawn points
    local spawnPoints = {}

    -- Use nav mesh if available
    if navmesh.IsLoaded() then
        local areas = navmesh.GetAllNavAreas()
        for _, area in ipairs(areas) do
            if math.random() < 0.1 then -- 10% chance per area
                table.insert(spawnPoints, area:GetCenter())
            end
        end
    end

    -- Fallback: use info_player spawns as reference
    if #spawnPoints < 10 then
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetClass():find("info_player") then
                local pos = ent:GetPos()
                for i = 1, 5 do
                    local offset = Vector(math.random(-1000, 1000), math.random(-1000, 1000), 0)
                    local testPos = pos + offset
                    local tr = util.TraceLine({
                        start = testPos + Vector(0, 0, 100),
                        endpos = testPos - Vector(0, 0, 100),
                        mask = MASK_SOLID_BRUSHONLY
                    })
                    if tr.Hit then
                        table.insert(spawnPoints, tr.HitPos + Vector(0, 0, 5))
                    end
                end
            end
        end
    end

    -- Spawn nodes at positions
    local nodeCount = math.min(20, #spawnPoints)
    for i = 1, nodeCount do
        local pos = spawnPoints[math.random(#spawnPoints)]
        local nodeType = math.random(1, 4)
        self:CreateResourceNode(pos, nodeType)
        table.remove(spawnPoints, math.random(#spawnPoints))
    end

    print("[Frontier] Spawned " .. #ResourceNodes .. " resource nodes")
end

-- Create a resource node entity
function GM:CreateResourceNode(pos, nodeType)
    local node = ents.Create("prop_physics")

    -- Set model based on type
    local models = {
        [RESOURCE_TYPES.ORE] = "models/props_debris/concrete_chunk04a.mdl",
        [RESOURCE_TYPES.GENERATOR] = "models/props_c17/furnitureradiator001a.mdl",
        [RESOURCE_TYPES.CROP] = "models/props_junk/watermelon01.mdl",
        [RESOURCE_TYPES.SALVAGE] = "models/props_junk/cardboard_box004a.mdl"
    }

    node:SetModel(models[nodeType] or models[1])
    node:SetPos(pos)
    node:Spawn()
    node:GetPhysicsObject():EnableMotion(false)

    -- Store node data
    node.ResourceType = nodeType
    node.ResourceAmount = 100
    node.LastHarvest = 0
    node.IsResource = true

    -- Set color based on type
    local colors = {
        [RESOURCE_TYPES.ORE] = Color(150, 100, 200),
        [RESOURCE_TYPES.GENERATOR] = Color(255, 200, 50),
        [RESOURCE_TYPES.CROP] = Color(100, 200, 80),
        [RESOURCE_TYPES.SALVAGE] = Color(200, 150, 100)
    }
    node:SetColor(colors[nodeType] or Color(255, 255, 255))

    table.insert(ResourceNodes, node)
    return node
end

-- Handle player using a resource node
function GM:PlayerUse(ply, ent)
    if not IsValid(ent) or not ent.IsResource then return end

    -- Check cooldown
    if CurTime() - ent.LastHarvest < 1 then return end
    ent.LastHarvest = CurTime()

    -- Check if depleted
    if ent.ResourceAmount <= 0 then
        self:SendNotification(ply, "Depleted", "This resource is empty. Wait for respawn.", Color(200, 200, 200), 2)
        return
    end

    local data = self:GetPlayerData(ply)
    if not data then return end

    local job = GetJobByID(data.job)
    local bonus = 1

    -- Apply job bonuses
    if ent.ResourceType == RESOURCE_TYPES.ORE then
        bonus = 1 + (job.alloyBonus or 0) / 100
    elseif ent.ResourceType == RESOURCE_TYPES.GENERATOR and table.HasValue(job.abilities, "power_boost") then
        bonus = 1.5
    elseif ent.ResourceType == RESOURCE_TYPES.CROP and table.HasValue(job.abilities, "food_boost") then
        bonus = 1.5
    end

    -- Calculate harvest amount
    local harvestAmount = math.min(25, ent.ResourceAmount)
    ent.ResourceAmount = ent.ResourceAmount - harvestAmount

    -- Give rewards based on type
    local rewardAmount = math.floor(harvestAmount * bonus / 5)

    if ent.ResourceType == RESOURCE_TYPES.ORE then
        self:GiveCurrency(ply, CURRENCY_ALLOY, rewardAmount)
        self:SendNotification(ply, "Mined Ore", "+" .. rewardAmount .. " Alloy", CURRENCY_COLORS[CURRENCY_ALLOY], 1.5)
        self:GiveXP(ply, rewardAmount)

    elseif ent.ResourceType == RESOURCE_TYPES.GENERATOR then
        self:AddColonyPower(rewardAmount * 2)
        self:SendNotification(ply, "Powered Generator", "+" .. (rewardAmount * 2) .. " Colony Power", Color(255, 200, 50), 1.5)
        self:GiveXP(ply, rewardAmount * 2)

    elseif ent.ResourceType == RESOURCE_TYPES.CROP then
        self:AddColonyFood(rewardAmount)
        self:SendNotification(ply, "Harvested Crops", "+" .. rewardAmount .. " Colony Food", Color(100, 200, 80), 1.5)
        self:GiveXP(ply, rewardAmount)

    elseif ent.ResourceType == RESOURCE_TYPES.SALVAGE then
        self:GiveCurrency(ply, CURRENCY_CREDITS, rewardAmount * 3)
        self:SendNotification(ply, "Salvaged Parts", "+" .. FormatMoney(rewardAmount * 3), CURRENCY_COLORS[CURRENCY_CREDITS], 1.5)
        self:GiveXP(ply, rewardAmount)
    end

    -- Visual feedback
    local effectData = EffectData()
    effectData:SetOrigin(ent:GetPos())
    util.Effect("cball_bounce", effectData)
    ent:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav", 60)

    -- Check if depleted
    if ent.ResourceAmount <= 0 then
        self:DepleteResource(ent)
    end

    -- Update transparency based on remaining amount
    local alpha = math.Clamp(ent.ResourceAmount * 2.55, 100, 255)
    local col = ent:GetColor()
    ent:SetColor(Color(col.r, col.g, col.b, alpha))
end

-- Handle depleted resource
function GM:DepleteResource(node)
    if not IsValid(node) then return end

    node:SetNoDraw(true)
    node:SetNotSolid(true)

    -- Schedule respawn
    timer.Simple(RESOURCE_RESPAWN_TIME, function()
        if IsValid(node) then
            node.ResourceAmount = 100
            node:SetNoDraw(false)
            node:SetNotSolid(false)
            local col = node:GetColor()
            node:SetColor(Color(col.r, col.g, col.b, 255))
        end
    end)
end

-- Resource think (respawn depleted nodes)
function GM:ResourceThink()
    -- Handled by individual timers
end

-- Admin command to spawn resources
concommand.Add("frontier_spawnnode", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local nodeType = tonumber(args[1]) or 1
    local pos = ply:GetEyeTrace().HitPos + Vector(0, 0, 20)
    GAMEMODE:CreateResourceNode(pos, nodeType)

    if IsValid(ply) then
        ply:ChatPrint("[Frontier] Spawned resource node type " .. nodeType)
    end
end)
