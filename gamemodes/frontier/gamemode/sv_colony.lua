--[[
    Frontier Colony - Server Colony System
    Handles colony vitals, alien attacks, and the main objective
]]

-- Colony state (global)
Colony = Colony or {
    power = COLONY_MAX_POWER,
    food = COLONY_MAX_FOOD,
    shields = COLONY_MAX_SHIELDS,
    morale = 100,
    isUnderAttack = false,
    attackWave = 0,
    nextAttack = 0,
    prosperity = 0 -- Overall score/objective
}

-- Initialize colony
function GM:InitializeColony()
    Colony.power = COLONY_MAX_POWER
    Colony.food = COLONY_MAX_FOOD
    Colony.shields = COLONY_MAX_SHIELDS
    Colony.morale = 100
    Colony.isUnderAttack = false
    Colony.attackWave = 0
    Colony.nextAttack = CurTime() + math.random(ALIEN_ATTACK_MIN_INTERVAL, ALIEN_ATTACK_MAX_INTERVAL)
    Colony.prosperity = 0

    print("[Frontier] Colony systems initialized.")
    print("[Frontier] First alien attack in " .. math.floor((Colony.nextAttack - CurTime()) / 60) .. " minutes.")
end

-- Colony think (called from main Think)
function GM:ColonyThink()
    -- Resource drain (every 60 seconds)
    if not Colony.lastDrain or CurTime() - Colony.lastDrain >= 60 then
        Colony.lastDrain = CurTime()
        self:DrainColonyResources()
    end

    -- Check for alien attack
    if not Colony.isUnderAttack and CurTime() >= Colony.nextAttack then
        self:StartAlienAttack()
    end

    -- Sync colony data periodically
    if not Colony.lastSync or CurTime() - Colony.lastSync >= 5 then
        Colony.lastSync = CurTime()
        self:SyncColonyData()
    end

    -- Calculate morale based on resources
    self:UpdateMorale()

    -- Check for colony failure
    if Colony.power <= 0 or Colony.food <= 0 then
        self:OnColonyFailure()
    end
end

-- Drain resources over time
function GM:DrainColonyResources()
    local playerCount = #player.GetAll()
    if playerCount == 0 then return end

    -- Power drain (more players = more drain)
    local powerDrain = COLONY_POWER_DRAIN + (playerCount - 1)
    Colony.power = math.max(0, Colony.power - powerDrain)

    -- Food drain (based on player count)
    local foodDrain = math.ceil(COLONY_FOOD_DRAIN * playerCount / 2)
    Colony.food = math.max(0, Colony.food - foodDrain)

    -- Warn if low
    if Colony.power <= 100 and Colony.power > 0 then
        PrintMessage(HUD_PRINTTALK, "[ALERT] Colony power critically low! (" .. Colony.power .. "/" .. COLONY_MAX_POWER .. ")")
    end

    if Colony.food <= 50 and Colony.food > 0 then
        PrintMessage(HUD_PRINTTALK, "[ALERT] Colony food supplies running out! (" .. Colony.food .. "/" .. COLONY_MAX_FOOD .. ")")
    end
end

-- Update morale based on colony status
function GM:UpdateMorale()
    local targetMorale = 100

    -- Power affects morale
    local powerPercent = Colony.power / COLONY_MAX_POWER
    if powerPercent < 0.5 then
        targetMorale = targetMorale - (0.5 - powerPercent) * 40
    end

    -- Food affects morale
    local foodPercent = Colony.food / COLONY_MAX_FOOD
    if foodPercent < 0.5 then
        targetMorale = targetMorale - (0.5 - foodPercent) * 30
    end

    -- Under attack tanks morale
    if Colony.isUnderAttack then
        targetMorale = targetMorale - 20
    end

    -- Slowly adjust morale toward target
    if Colony.morale < targetMorale then
        Colony.morale = math.min(targetMorale, Colony.morale + 0.5)
    elseif Colony.morale > targetMorale then
        Colony.morale = math.max(targetMorale, Colony.morale - 0.5)
    end

    Colony.morale = math.Clamp(Colony.morale, 0, 100)
end

-- Add power to colony
function GM:AddColonyPower(amount)
    Colony.power = math.min(COLONY_MAX_POWER, Colony.power + amount)
end

-- Add food to colony
function GM:AddColonyFood(amount)
    Colony.food = math.min(COLONY_MAX_FOOD, Colony.food + amount)
end

-- Add shields to colony
function GM:AddColonyShields(amount)
    Colony.shields = math.min(COLONY_MAX_SHIELDS, Colony.shields + amount)
end

-- Sync colony data to all clients
function GM:SyncColonyData()
    net.Start("Frontier_ColonyData")
    net.WriteFloat(Colony.power)
    net.WriteFloat(Colony.food)
    net.WriteFloat(Colony.shields)
    net.WriteFloat(Colony.morale)
    net.WriteBool(Colony.isUnderAttack)
    net.WriteInt(Colony.attackWave, 16)
    net.WriteInt(Colony.prosperity, 32)
    net.Broadcast()
end

-- Start an alien attack
function GM:StartAlienAttack()
    Colony.isUnderAttack = true
    Colony.attackWave = Colony.attackWave + 1

    print("[Frontier] Alien attack wave " .. Colony.attackWave .. " starting!")

    -- Notify all players
    for _, ply in ipairs(player.GetAll()) do
        self:SendNotification(ply, "ALIEN ATTACK!",
            "Wave " .. Colony.attackWave .. " - Defend the colony!",
            Color(255, 50, 50), 8)
    end

    -- Play alarm sound
    for _, ply in ipairs(player.GetAll()) do
        ply:EmitSound("ambient/alarms/warningbell1.wav", 100, 100)
    end

    -- Spawn aliens (would spawn NPCs in real implementation)
    local alienCount = 3 + Colony.attackWave * 2
    print("[Frontier] Spawning " .. alienCount .. " aliens...")

    -- Simulate attack duration (in real implementation, track alien kills)
    timer.Create("Frontier_AttackTimer", 60 + Colony.attackWave * 10, 1, function()
        self:EndAlienAttack(true)
    end)

    -- Shields take damage during attack
    timer.Create("Frontier_ShieldDamage", 5, 0, function()
        if Colony.isUnderAttack then
            Colony.shields = math.max(0, Colony.shields - 5)
            if Colony.shields <= 0 then
                -- Shields down, colony takes direct damage
                Colony.power = math.max(0, Colony.power - 10)
            end
        else
            timer.Remove("Frontier_ShieldDamage")
        end
    end)
end

-- End alien attack
function GM:EndAlienAttack(success)
    Colony.isUnderAttack = false
    timer.Remove("Frontier_AttackTimer")
    timer.Remove("Frontier_ShieldDamage")

    if success then
        -- Reward players
        local reward = 100 + Colony.attackWave * 25
        local alloyReward = 25 + Colony.attackWave * 10

        for _, ply in ipairs(player.GetAll()) do
            self:GiveCurrency(ply, CURRENCY_CREDITS, reward)
            self:GiveCurrency(ply, CURRENCY_ALLOY, alloyReward)
            self:GiveXP(ply, 100 + Colony.attackWave * 20)
            self:SendNotification(ply, "ATTACK REPELLED!",
                "+" .. FormatCurrency(reward, CURRENCY_CREDITS) .. ", +" .. FormatCurrency(alloyReward, CURRENCY_ALLOY),
                Color(100, 255, 100), 6)
        end

        -- Increase prosperity
        Colony.prosperity = Colony.prosperity + 100 * Colony.attackWave

        -- Regenerate some shields
        Colony.shields = math.min(COLONY_MAX_SHIELDS, Colony.shields + 20)

        PrintMessage(HUD_PRINTTALK, "[Frontier] Wave " .. Colony.attackWave .. " defeated! Colony prosperity: " .. Colony.prosperity)
    else
        PrintMessage(HUD_PRINTTALK, "[Frontier] The colony was overwhelmed...")
    end

    -- Schedule next attack
    local nextDelay = math.random(ALIEN_ATTACK_MIN_INTERVAL, ALIEN_ATTACK_MAX_INTERVAL)
    Colony.nextAttack = CurTime() + nextDelay
    print("[Frontier] Next attack in " .. math.floor(nextDelay / 60) .. " minutes.")

    self:SyncColonyData()
end

-- Colony failure
function GM:OnColonyFailure()
    if Colony.failed then return end
    Colony.failed = true

    local reason = ""
    if Colony.power <= 0 then
        reason = "Power systems failed!"
    elseif Colony.food <= 0 then
        reason = "Colony starved!"
    end

    PrintMessage(HUD_PRINTTALK, "[FRONTIER] COLONY LOST! " .. reason)
    PrintMessage(HUD_PRINTTALK, "[FRONTIER] Final Prosperity Score: " .. Colony.prosperity)
    PrintMessage(HUD_PRINTTALK, "[FRONTIER] Waves Survived: " .. Colony.attackWave)

    for _, ply in ipairs(player.GetAll()) do
        self:SendNotification(ply, "COLONY LOST", reason .. " Restarting...", Color(255, 50, 50), 10)
    end

    -- Reset after delay
    timer.Simple(15, function()
        Colony.failed = false
        self:InitializeColony()
        PrintMessage(HUD_PRINTTALK, "[Frontier] Colony has been re-established. Good luck, colonists!")

        for _, ply in ipairs(player.GetAll()) do
            ply:Spawn()
        end
    end)
end

-- Admin command to trigger attack
concommand.Add("frontier_attack", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    GAMEMODE:StartAlienAttack()
end)

-- Admin command to restore colony
concommand.Add("frontier_restore", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    Colony.power = COLONY_MAX_POWER
    Colony.food = COLONY_MAX_FOOD
    Colony.shields = COLONY_MAX_SHIELDS
    Colony.morale = 100
    GAMEMODE:SyncColonyData()
    PrintMessage(HUD_PRINTTALK, "[Frontier] Colony resources restored by admin.")
end)
