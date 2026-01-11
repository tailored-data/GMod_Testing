--[[
    Ragdoll Boxing - Server Player System
    Handles ragdoll-based player control and combat
]]

-- Player loadout
function GM:PlayerLoadout(ply)
    -- No weapons - this is a boxing game
    ply:StripWeapons()
    return true
end

-- Player spawn handling
function GM:PlayerSpawn(ply)
    self.BaseClass:PlayerSpawn(ply)

    -- Set player model
    ply:SetModel("models/player/kleiner.mdl")

    -- Set health
    ply:SetHealth(PLAYER_MAX_HEALTH)
    ply:SetMaxHealth(PLAYER_MAX_HEALTH)

    -- Set team
    ply:SetTeam(1)

    -- Initialize punch cooldown
    ply.NextPunch = 0
    ply.RagdollHealth = PLAYER_MAX_HEALTH

    -- Give them a small delay before creating ragdoll
    timer.Simple(0.1, function()
        if IsValid(ply) then
            self:CreatePlayerRagdoll(ply)
        end
    end)

    -- Check if we can start the round
    timer.Simple(0.5, function()
        self:CheckRoundStart()
    end)
end

-- Create the ragdoll for a player
function GM:CreatePlayerRagdoll(ply)
    -- Remove old ragdoll if exists
    if IsValid(ply.Ragdoll) then
        ply.Ragdoll:Remove()
    end

    -- Get spawn position
    local spawnPos = ply:GetPos() + Vector(0, 0, 50)

    -- Create the ragdoll entity
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(spawnPos)
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:Spawn()
    ragdoll:Activate()

    -- Store reference
    ply.Ragdoll = ragdoll
    ragdoll.Owner = ply
    ragdoll.Health = PLAYER_MAX_HEALTH

    -- Make player invisible and spectate their ragdoll
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(ragdoll)

    -- Set the player's view entity to the ragdoll
    ply:SetViewEntity(ragdoll)

    print("[RagBox] Created ragdoll for " .. ply:Nick())
end

-- Handle player input to control ragdoll
function GM:StartCommand(ply, cmd)
    if not IsValid(ply.Ragdoll) then return end

    local ragdoll = ply.Ragdoll

    -- Get the main physics object (pelvis/hip bone)
    local physObj = ragdoll:GetPhysicsObject()
    if not IsValid(physObj) then return end

    -- Get movement input
    local moveForward = cmd:GetForwardMove()
    local moveSide = cmd:GetSideMove()

    -- Calculate movement direction based on player view angles
    local ang = cmd:GetViewAngles()
    local forward = ang:Forward()
    local right = ang:Right()

    -- Flatten the vectors (no vertical movement from looking up/down)
    forward.z = 0
    right.z = 0
    forward:Normalize()
    right:Normalize()

    -- Calculate force direction
    local moveDir = (forward * moveForward + right * moveSide)
    if moveDir:Length() > 0 then
        moveDir:Normalize()

        -- Apply force to ragdoll
        local force = moveDir * RAGDOLL_MOVE_FORCE
        physObj:ApplyForceCenter(force)
    end

    -- Jump (apply upward force)
    if cmd:KeyDown(IN_JUMP) and ragdoll:GetPos().z < ply:GetPos().z + 100 then
        -- Simple ground check - only jump if not too high
        local tr = util.TraceLine({
            start = ragdoll:GetPos(),
            endpos = ragdoll:GetPos() - Vector(0, 0, 50),
            filter = ragdoll
        })

        if tr.Hit then
            physObj:ApplyForceCenter(Vector(0, 0, RAGDOLL_JUMP_FORCE * physObj:GetMass()))
        end
    end
end

-- Handle punching
net.Receive("RagBox_Punch", function(len, ply)
    if not IsValid(ply) or not IsValid(ply.Ragdoll) then return end
    if GAMEMODE.GameState ~= GAMESTATE_PLAYING then return end

    -- Check cooldown
    if CurTime() < ply.NextPunch then return end
    ply.NextPunch = CurTime() + PUNCH_COOLDOWN

    local ragdoll = ply.Ragdoll
    local punchPos = ragdoll:GetPos()
    local punchDir = ply:GetAimVector()

    -- Find ragdolls in range
    for _, ent in ipairs(ents.FindInSphere(punchPos, PUNCH_RANGE)) do
        if ent:GetClass() == "prop_ragdoll" and ent ~= ragdoll and IsValid(ent.Owner) then
            -- Calculate direction to target
            local toTarget = (ent:GetPos() - punchPos):GetNormalized()

            -- Check if target is roughly in front of us
            local dot = punchDir:Dot(toTarget)
            if dot > 0.5 then
                -- Apply damage
                GAMEMODE:DamageRagdoll(ent, ply, PUNCH_DAMAGE, punchDir)

                -- Apply knockback force
                local physObj = ent:GetPhysicsObject()
                if IsValid(physObj) then
                    local knockback = punchDir * PUNCH_FORCE * physObj:GetMass()
                    knockback.z = PUNCH_FORCE * 0.5 * physObj:GetMass() -- Add some upward force
                    physObj:ApplyForceCenter(knockback)
                end

                -- Send hit effect to clients
                net.Start("RagBox_PlayerHit")
                net.WriteVector(ent:GetPos())
                net.Broadcast()

                break -- Only hit one target per punch
            end
        end
    end
end)

-- Handle ragdoll damage
function GM:DamageRagdoll(ragdoll, attacker, damage, direction)
    if not IsValid(ragdoll) or not IsValid(ragdoll.Owner) then return end

    ragdoll.Health = ragdoll.Health - damage
    local victim = ragdoll.Owner

    -- Update player's networked health for HUD
    victim:SetHealth(ragdoll.Health)

    -- Check for death
    if ragdoll.Health <= 0 then
        self:PlayerRagdollDeath(victim, attacker)
    end
end

-- Handle ragdoll death
function GM:PlayerRagdollDeath(victim, attacker)
    if not IsValid(victim) then return end

    print("[RagBox] " .. victim:Nick() .. " was knocked out by " .. attacker:Nick())

    -- Remove the ragdoll
    if IsValid(victim.Ragdoll) then
        -- Create a death effect
        local effectData = EffectData()
        effectData:SetOrigin(victim.Ragdoll:GetPos())
        util.Effect("cball_explode", effectData)

        victim.Ragdoll:Remove()
    end

    -- Set player as spectator temporarily
    victim:Spectate(OBS_MODE_ROAMING)
    victim:SetTeam(2)

    -- Check if round should end
    self:CheckRoundEnd()
end

-- Get valid spawn points
function GM:PlayerSelectSpawn(ply)
    local spawns = ents.FindByClass("info_player_start")
    if #spawns == 0 then
        spawns = ents.FindByClass("info_player_deathmatch")
    end
    if #spawns == 0 then
        -- Fallback: create spawn at origin
        return nil
    end

    return spawns[math.random(#spawns)]
end

-- Player initial spawn
function GM:PlayerInitialSpawn(ply)
    ply:SetTeam(1)
    print("[RagBox] " .. ply:Nick() .. " has joined the game!")
end

-- Prevent normal death
function GM:PlayerDeath(ply, inflictor, attacker)
    -- Handled by ragdoll system
end

function GM:PlayerDeathThink(ply)
    -- Auto respawn after round ends
    if self.GameState == GAMESTATE_WAITING then
        ply:Spawn()
        return true
    end
    return false
end
