--[[
    Frontier Colony - Resource System (Server)
    Handles resource node spawning and gathering
]]

FRONTIER.Resources = FRONTIER.Resources or {}

-- Track active resource nodes
local ActiveNodes = {}

--[[
    Resource Node Registration
]]
function FRONTIER.Resources.RegisterNode(ent, nodeType)
    if not IsValid(ent) then return end

    ActiveNodes[ent:EntIndex()] = {
        entity = ent,
        type = nodeType,
        created = CurTime(),
    }
end

function FRONTIER.Resources.UnregisterNode(ent)
    if not IsValid(ent) then return end
    ActiveNodes[ent:EntIndex()] = nil
end

--[[
    Resource Gathering
]]
function FRONTIER.Resources.GatherResource(ply, nodeType, baseAmount)
    if not IsValid(ply) then return 0 end

    -- Calculate bonus based on job
    local bonus = 1.0
    local jobTable = ply:getJobTable()

    if jobTable and jobTable.frontierBonus then
        local bonusData = FRONTIER.JobBonuses[jobTable.frontierBonus]
        if bonusData and bonusData.resourceType == nodeType then
            bonus = 1.0 + bonusData.bonus
        end
    end

    local finalAmount = math.floor(baseAmount * bonus)

    -- Apply resource to colony
    if nodeType == "ore" then
        -- Ore converts to money for the player
        ply:addMoney(finalAmount)
        DarkRP.notify(ply, 0, 4, "Gathered " .. finalAmount .. " credits worth of ore!")
    elseif nodeType == "power" then
        FRONTIER.Colony.AddPower(finalAmount)
        DarkRP.notify(ply, 0, 4, "Added " .. finalAmount .. " power to the colony!")
    elseif nodeType == "food" then
        FRONTIER.Colony.AddFood(finalAmount)
        DarkRP.notify(ply, 0, 4, "Harvested " .. finalAmount .. " food for the colony!")
    end

    -- Notify client
    net.Start("Frontier_ResourceGathered")
        net.WriteString(nodeType)
        net.WriteInt(finalAmount, 16)
    net.Send(ply)

    return finalAmount
end

--[[
    Consumable Resource Items
]]

-- Power Cell usage
hook.Add("PlayerUse", "Frontier_UsePowerCell", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "frontier_power_crate" then return end

    local powerAmount = ent.PowerAmount or 50
    FRONTIER.Colony.AddPower(powerAmount)
    DarkRP.notify(ply, 0, 4, "Added " .. powerAmount .. " power to the colony!")

    ent:Remove()
end)

-- Food Crate usage
hook.Add("PlayerUse", "Frontier_UseFoodCrate", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "frontier_food_crate" then return end

    local foodAmount = ent.FoodAmount or 30
    FRONTIER.Colony.AddFood(foodAmount)
    DarkRP.notify(ply, 0, 4, "Added " .. foodAmount .. " food to the colony!")

    ent:Remove()
end)

-- Shield Capacitor usage
hook.Add("PlayerUse", "Frontier_UseShieldCrate", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "frontier_shield_crate" then return end

    local shieldAmount = ent.ShieldAmount or 15
    FRONTIER.Colony.AddShields(shieldAmount)
    DarkRP.notify(ply, 0, 4, "Added " .. shieldAmount .. " shield power!")

    ent:Remove()
end)

--[[
    Natural Resource Spawning
    Spawns ore nodes around the map periodically
]]
local function FindSpawnPosition()
    local spawns = ents.FindByClass("info_player_start")
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_terrorist")
    end
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_counterterrorist")
    end

    if #spawns > 0 then
        local spawn = table.Random(spawns)
        local pos = spawn:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), 0)

        -- Trace down to find ground
        local tr = util.TraceLine({
            start = pos + Vector(0, 0, 100),
            endpos = pos - Vector(0, 0, 500),
            mask = MASK_SOLID_BRUSHONLY
        })

        if tr.Hit then
            return tr.HitPos + Vector(0, 0, 10)
        end
    end

    return nil
end

timer.Create("Frontier_SpawnResources", 120, 0, function()
    -- Count existing ore nodes
    local oreNodes = ents.FindByClass("frontier_ore_node")

    -- Spawn more if below threshold
    if #oreNodes < 5 then
        local pos = FindSpawnPosition()
        if pos then
            local node = ents.Create("frontier_ore_node")
            if IsValid(node) then
                node:SetPos(pos)
                node:Spawn()
                node.NaturalSpawn = true
                FRONTIER.Resources.RegisterNode(node, "ore")
            end
        end
    end
end)

print("[Frontier] Resource system loaded")
