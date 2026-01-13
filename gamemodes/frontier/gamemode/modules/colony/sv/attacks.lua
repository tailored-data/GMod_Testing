--[[
    Frontier Colony - Alien Attack System (Server)
    Spawns hostile NPCs that attack the colony
]]

FRONTIER.Attacks = FRONTIER.Attacks or {}

-- Track active attack state
local AttackState = {
    active = false,
    wave = 0,
    enemiesRemaining = 0,
    totalKilled = 0,
    spawnedEnemies = {},
}

--[[
    Start an Attack Wave
]]
function FRONTIER.Attacks.StartAttack()
    if AttackState.active then return false end

    AttackState.active = true
    AttackState.wave = AttackState.wave + 1
    AttackState.totalKilled = 0

    FRONTIER.Colony.SetUnderAttack(true)

    -- Calculate wave size based on player count and wave number
    local playerCount = #player.GetAll()
    local baseSize = FRONTIER.Config.AttackWaveSize
    local waveSize = baseSize + math.floor(playerCount * 0.5) + math.floor(AttackState.wave * 0.5)

    AttackState.enemiesRemaining = waveSize

    -- Notify all players
    DarkRP.notifyAll(1, 6, "ALERT: Hostile forces detected! Wave " .. AttackState.wave .. " incoming!")

    -- Broadcast attack start
    net.Start("Frontier_ColonyAttack")
        net.WriteBool(true)
        net.WriteInt(AttackState.wave, 8)
        net.WriteInt(waveSize, 8)
    net.Broadcast()

    -- Spawn enemies over time
    local spawned = 0
    timer.Create("Frontier_SpawnEnemies", 2, waveSize, function()
        if not AttackState.active then return end

        spawned = spawned + 1
        FRONTIER.Attacks.SpawnEnemy()
    end)

    return true
end

--[[
    Spawn a Single Enemy
]]
function FRONTIER.Attacks.SpawnEnemy()
    -- Find spawn position (away from players)
    local spawnPos = FRONTIER.Attacks.FindEnemySpawn()
    if not spawnPos then return end

    -- Choose enemy type based on wave
    local enemyType = FRONTIER.Attacks.ChooseEnemyType()

    -- Create NPC
    local npc = ents.Create("npc_combine_s")
    if not IsValid(npc) then return end

    npc:SetPos(spawnPos)
    npc:SetAngles(Angle(0, math.random(0, 360), 0))
    npc:SetHealth(enemyType.health)
    npc:SetMaxHealth(enemyType.health)
    npc:Spawn()
    npc:Activate()

    -- Set as enemy to players
    npc:SetKeyValue("squadname", "alien_attackers")
    npc:Fire("SetRelationship", "player D_HT 99")

    -- Store reference
    table.insert(AttackState.spawnedEnemies, npc)

    -- Track death
    npc.FrontierEnemy = true
    npc.FrontierDamage = enemyType.damage
end

--[[
    Find Spawn Position for Enemies
]]
function FRONTIER.Attacks.FindEnemySpawn()
    -- Try to find a position away from players
    local players = player.GetAll()
    if #players == 0 then return nil end

    -- Get map bounds from spawn points
    local spawns = ents.FindByClass("info_player_start")
    if #spawns == 0 then
        spawns = player.GetAll()
    end

    for i = 1, 10 do  -- Try 10 times
        local basePos
        if #spawns > 0 then
            basePos = table.Random(spawns):GetPos()
        else
            basePos = Vector(0, 0, 0)
        end

        -- Offset from base position
        local offset = Vector(math.random(-1000, 1000), math.random(-1000, 1000), 0)
        local testPos = basePos + offset

        -- Check if too close to players
        local tooClose = false
        for _, ply in ipairs(players) do
            if ply:GetPos():Distance(testPos) < 500 then
                tooClose = true
                break
            end
        end

        if not tooClose then
            -- Trace to find ground
            local tr = util.TraceLine({
                start = testPos + Vector(0, 0, 200),
                endpos = testPos - Vector(0, 0, 500),
                mask = MASK_SOLID_BRUSHONLY
            })

            if tr.Hit then
                return tr.HitPos + Vector(0, 0, 20)
            end
        end
    end

    return nil
end

--[[
    Choose Enemy Type Based on Wave
]]
function FRONTIER.Attacks.ChooseEnemyType()
    local types = FRONTIER.EnemyTypes
    local wave = AttackState.wave

    -- Higher waves have chance for stronger enemies
    local roll = math.random(1, 100)

    if wave >= 5 and roll <= 20 then
        return types[3]  -- Heavy
    elseif wave >= 3 and roll <= 40 then
        return types[2]  -- Soldier
    else
        return types[1]  -- Drone
    end
end

--[[
    Enemy Death Handler
]]
hook.Add("OnNPCKilled", "Frontier_EnemyKilled", function(npc, attacker, inflictor)
    if not npc.FrontierEnemy then return end
    if not AttackState.active then return end

    AttackState.enemiesRemaining = AttackState.enemiesRemaining - 1
    AttackState.totalKilled = AttackState.totalKilled + 1

    -- Remove from tracking
    for i, enemy in ipairs(AttackState.spawnedEnemies) do
        if enemy == npc then
            table.remove(AttackState.spawnedEnemies, i)
            break
        end
    end

    -- Reward killer
    if IsValid(attacker) and attacker:IsPlayer() then
        local reward = 50
        attacker:addMoney(reward)
        DarkRP.notify(attacker, 0, 4, "Enemy eliminated! +" .. reward .. " credits")
    end

    -- Check if wave complete
    if AttackState.enemiesRemaining <= 0 then
        FRONTIER.Attacks.EndAttack(true)
    end
end)

--[[
    End Attack Wave
]]
function FRONTIER.Attacks.EndAttack(victory)
    AttackState.active = false
    timer.Remove("Frontier_SpawnEnemies")

    FRONTIER.Colony.SetUnderAttack(false)

    -- Clean up remaining enemies
    for _, enemy in ipairs(AttackState.spawnedEnemies) do
        if IsValid(enemy) then
            enemy:Remove()
        end
    end
    AttackState.spawnedEnemies = {}

    if victory then
        -- Victory rewards
        FRONTIER.Colony.AddMorale(FRONTIER.Config.MoraleBoostOnAttackWin)
        DarkRP.notifyAll(0, 6, "Wave " .. AttackState.wave .. " defeated! Colony morale boosted!")

        -- Bonus rewards for all players
        for _, ply in ipairs(player.GetAll()) do
            local bonus = 100 * AttackState.wave
            ply:addMoney(bonus)
            DarkRP.notify(ply, 0, 4, "Wave bonus: +" .. bonus .. " credits!")
        end
    else
        -- Defeat penalties
        FRONTIER.Colony.AddMorale(-FRONTIER.Config.MoraleLossOnAttackFail)
        FRONTIER.Colony.AddShields(-20)
        DarkRP.notifyAll(1, 6, "Colony defenses have been breached!")
    end

    -- Broadcast attack end
    net.Start("Frontier_ColonyAttack")
        net.WriteBool(false)
        net.WriteInt(AttackState.wave, 8)
        net.WriteInt(AttackState.totalKilled, 8)
    net.Broadcast()
end

--[[
    Periodic Attack Timer
]]
timer.Create("Frontier_AttackTimer", 60, 0, function()
    if AttackState.active then return end
    if #player.GetAll() == 0 then return end

    -- Check if enough time has passed since last attack
    local timeSinceAttack = CurTime() - (FRONTIER.Colony.lastAttack or 0)
    local minInterval = FRONTIER.Config.AttackMinInterval

    if timeSinceAttack < minInterval then return end

    -- Random chance to start attack
    local attackChance = math.Clamp((timeSinceAttack - minInterval) / 300, 0.1, 0.5)

    if math.random() < attackChance then
        FRONTIER.Attacks.StartAttack()
    end
end)

--[[
    Console Command to Manually Trigger Attack (Admin Only)
]]
concommand.Add("frontier_attack", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        DarkRP.notify(ply, 1, 4, "You must be a super admin to use this command!")
        return
    end

    if FRONTIER.Attacks.StartAttack() then
        print("[Frontier] Attack manually triggered by " .. (IsValid(ply) and ply:Nick() or "Console"))
    else
        print("[Frontier] Attack already in progress!")
    end
end)

print("[Frontier] Attack system loaded")
