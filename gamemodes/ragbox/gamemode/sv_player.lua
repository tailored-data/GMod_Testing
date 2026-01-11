--[[
    Ragdoll Boxing - Server Player System
    Handles ragdoll-based player control with upright posture and walking wheel
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
        if GAMEMODE and GAMEMODE.CheckRoundStart then
            GAMEMODE:CheckRoundStart()
        end
    end)
end

-- Create the ragdoll for a player with upright posture and walking wheel
function GM:CreatePlayerRagdoll(ply)
    -- Remove old ragdoll system if exists
    self:CleanupPlayerRagdoll(ply)

    -- Get spawn position
    local spawnPos = ply:GetPos() + Vector(0, 0, 10)
    local spawnAng = ply:GetAngles()

    -- Create the ragdoll entity
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(spawnPos)
    ragdoll:SetAngles(spawnAng)
    ragdoll:Spawn()
    ragdoll:Activate()

    -- Store references
    ply.Ragdoll = ragdoll
    ply.RagdollHealth = PLAYER_MAX_HEALTH
    ragdoll.Owner = ply
    ragdoll.OwnerHealth = PLAYER_MAX_HEALTH

    -- Create the walking wheel (invisible ball between legs)
    local wheel = ents.Create("prop_physics")
    wheel:SetModel("models/hunter/misc/sphere2x2.mdl")
    wheel:SetPos(spawnPos - Vector(0, 0, 35))
    wheel:SetAngles(Angle(0, 0, 0))
    wheel:Spawn()
    wheel:Activate()
    wheel:SetNoDraw(true) -- Invisible
    wheel:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- Don't collide with players

    local wheelPhys = wheel:GetPhysicsObject()
    if IsValid(wheelPhys) then
        wheelPhys:SetMass(50)
        wheelPhys:SetMaterial("gmod_ice") -- Low friction for smooth rolling
        wheelPhys:EnableDrag(false)
    end

    ply.WalkingWheel = wheel
    ragdoll.WalkingWheel = wheel

    -- Get bone indices for constraints
    local pelvisBone = ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")
    local spineBone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
    local lThighBone = ragdoll:LookupBone("ValveBiped.Bip01_L_Thigh")
    local rThighBone = ragdoll:LookupBone("ValveBiped.Bip01_R_Thigh")
    local lUpperArmBone = ragdoll:LookupBone("ValveBiped.Bip01_L_UpperArm")
    local rUpperArmBone = ragdoll:LookupBone("ValveBiped.Bip01_R_UpperArm")
    local lForearmBone = ragdoll:LookupBone("ValveBiped.Bip01_L_Forearm")
    local rForearmBone = ragdoll:LookupBone("ValveBiped.Bip01_R_Forearm")

    -- Store constraints for cleanup
    ply.RagdollConstraints = {}

    -- Weld the wheel to the pelvis area to create movement base
    if pelvisBone then
        local pelvisPhysObj = ragdoll:GetPhysicsObjectNum(pelvisBone)
        if IsValid(pelvisPhysObj) and IsValid(wheelPhys) then
            local weld = constraint.Weld(ragdoll, wheel, pelvisBone, 0, 0, false, false)
            if IsValid(weld) then
                table.insert(ply.RagdollConstraints, weld)
            end
        end
    end

    -- Create upright constraint - keep spine vertical using KeepUpright
    -- This applies angular force to keep the ragdoll standing
    timer.Simple(0.1, function()
        if not IsValid(ragdoll) then return end

        -- Apply keep upright to the spine
        if spineBone then
            local spinePhysObj = ragdoll:GetPhysicsObjectNum(spineBone)
            if IsValid(spinePhysObj) then
                local keepUpright = constraint.Keepupright(ragdoll, Angle(0, spawnAng.y, 0), spineBone, 5000)
                if IsValid(keepUpright) then
                    table.insert(ply.RagdollConstraints, keepUpright)
                end
            end
        end

        -- Also keep pelvis upright
        if pelvisBone then
            local pelvisPhysObj = ragdoll:GetPhysicsObjectNum(pelvisBone)
            if IsValid(pelvisPhysObj) then
                local keepUpright = constraint.Keepupright(ragdoll, Angle(0, spawnAng.y, 0), pelvisBone, 3000)
                if IsValid(keepUpright) then
                    table.insert(ply.RagdollConstraints, keepUpright)
                end
            end
        end
    end)

    -- Position arms in fighting stance using muscle constraints
    timer.Simple(0.15, function()
        if not IsValid(ragdoll) then return end
        self:SetupFightingStance(ply, ragdoll)
    end)

    -- Make player invisible and link to ragdoll
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:SetMoveType(MOVETYPE_NONE)
    ply:SetPos(spawnPos + Vector(0, 0, 100)) -- Move player entity above ragdoll

    print("[RagBox] Created ragdoll with walking wheel for " .. ply:Nick())
end

-- Setup fighting stance for arms
function GM:SetupFightingStance(ply, ragdoll)
    local lUpperArmBone = ragdoll:LookupBone("ValveBiped.Bip01_L_UpperArm")
    local rUpperArmBone = ragdoll:LookupBone("ValveBiped.Bip01_R_UpperArm")
    local lForearmBone = ragdoll:LookupBone("ValveBiped.Bip01_L_Forearm")
    local rForearmBone = ragdoll:LookupBone("ValveBiped.Bip01_R_Forearm")
    local spineBone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")

    -- Apply upward angular velocity to upper arms to raise them
    if lUpperArmBone then
        local phys = ragdoll:GetPhysicsObjectNum(lUpperArmBone)
        if IsValid(phys) then
            -- Keep left arm raised and bent inward
            local muscle = constraint.Muscle(ragdoll, ragdoll, lUpperArmBone, spineBone or 0,
                Vector(0, 5, 0), Vector(-10, 0, 10), 0, 0, 1000, 0.2, 100, false)
            if IsValid(muscle) then
                table.insert(ply.RagdollConstraints, muscle)
            end
        end
    end

    if rUpperArmBone then
        local phys = ragdoll:GetPhysicsObjectNum(rUpperArmBone)
        if IsValid(phys) then
            -- Keep right arm raised and bent inward
            local muscle = constraint.Muscle(ragdoll, ragdoll, rUpperArmBone, spineBone or 0,
                Vector(0, -5, 0), Vector(10, 0, 10), 0, 0, 1000, 0.2, 100, false)
            if IsValid(muscle) then
                table.insert(ply.RagdollConstraints, muscle)
            end
        end
    end

    -- Bend forearms upward for guard position
    if lForearmBone and lUpperArmBone then
        local muscle = constraint.Muscle(ragdoll, ragdoll, lForearmBone, lUpperArmBone,
            Vector(0, 0, 5), Vector(0, 0, 15), 0, 0, 800, 0.3, 80, false)
        if IsValid(muscle) then
            table.insert(ply.RagdollConstraints, muscle)
        end
    end

    if rForearmBone and rUpperArmBone then
        local muscle = constraint.Muscle(ragdoll, ragdoll, rForearmBone, rUpperArmBone,
            Vector(0, 0, 5), Vector(0, 0, 15), 0, 0, 800, 0.3, 80, false)
        if IsValid(muscle) then
            table.insert(ply.RagdollConstraints, muscle)
        end
    end
end

-- Cleanup player's ragdoll and associated entities
function GM:CleanupPlayerRagdoll(ply)
    -- Remove constraints
    if ply.RagdollConstraints then
        for _, const in ipairs(ply.RagdollConstraints) do
            if IsValid(const) then
                const:Remove()
            end
        end
        ply.RagdollConstraints = nil
    end

    -- Remove walking wheel
    if IsValid(ply.WalkingWheel) then
        ply.WalkingWheel:Remove()
        ply.WalkingWheel = nil
    end

    -- Remove ragdoll
    if IsValid(ply.Ragdoll) then
        ply.Ragdoll:Remove()
        ply.Ragdoll = nil
    end
end

-- Handle player input to control ragdoll via the walking wheel
function GM:StartCommand(ply, cmd)
    if not IsValid(ply.Ragdoll) or not IsValid(ply.WalkingWheel) then return end

    local ragdoll = ply.Ragdoll
    local wheel = ply.WalkingWheel

    -- Get the wheel physics object
    local wheelPhys = wheel:GetPhysicsObject()
    if not IsValid(wheelPhys) then return end

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

    -- Update the keepupright angle to face movement direction
    if moveForward ~= 0 or moveSide ~= 0 then
        local moveDir = (forward * moveForward + right * moveSide):GetNormalized()
        local targetYaw = moveDir:Angle().y

        -- Update keepupright constraints to face movement direction
        -- This makes the ragdoll turn toward movement
    end

    -- Calculate force direction
    local moveDir = (forward * moveForward + right * moveSide)
    local isMoving = moveDir:Length() > 0

    if isMoving then
        moveDir:Normalize()

        -- Apply torque to wheel to make it roll (creates walking animation)
        local torqueAxis = moveDir:Cross(Vector(0, 0, 1))
        local torque = torqueAxis * RAGDOLL_MOVE_FORCE * 0.5
        wheelPhys:ApplyTorqueCenter(torque)

        -- Also apply some direct force for responsiveness
        local force = moveDir * RAGDOLL_MOVE_FORCE * 0.3
        wheelPhys:ApplyForceCenter(force)

        -- Rotate the wheel visual if it were visible (it's not, but physics still work)
        ply.IsWalking = true
    else
        -- Apply damping when not moving
        local vel = wheelPhys:GetVelocity()
        wheelPhys:ApplyForceCenter(-vel * 2)
        ply.IsWalking = false
    end

    -- Jump (apply upward force to the whole ragdoll)
    if cmd:KeyDown(IN_JUMP) then
        -- Ground check
        local tr = util.TraceLine({
            start = wheel:GetPos(),
            endpos = wheel:GetPos() - Vector(0, 0, 30),
            filter = {ragdoll, wheel}
        })

        if tr.Hit and (not ply.LastJump or CurTime() - ply.LastJump > 0.5) then
            ply.LastJump = CurTime()

            -- Apply jump force to wheel
            wheelPhys:ApplyForceCenter(Vector(0, 0, RAGDOLL_JUMP_FORCE * wheelPhys:GetMass()))

            -- Also apply force to pelvis for extra lift
            local pelvisBone = ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")
            if pelvisBone then
                local pelvisPhys = ragdoll:GetPhysicsObjectNum(pelvisBone)
                if IsValid(pelvisPhys) then
                    pelvisPhys:ApplyForceCenter(Vector(0, 0, RAGDOLL_JUMP_FORCE * pelvisPhys:GetMass() * 0.5))
                end
            end
        end
    end
end

-- Handle punching
net.Receive("RagBox_Punch", function(len, ply)
    if not IsValid(ply) or not IsValid(ply.Ragdoll) then return end
    if GAMEMODE.GameState ~= GAMESTATE_PLAYING then return end

    -- Check cooldown
    if CurTime() < (ply.NextPunch or 0) then return end
    ply.NextPunch = CurTime() + PUNCH_COOLDOWN

    local ragdoll = ply.Ragdoll
    local punchPos = ragdoll:GetPos()
    local punchDir = ply:GetAimVector()

    -- Apply punch animation force to the player's arms
    local rForearmBone = ragdoll:LookupBone("ValveBiped.Bip01_R_Forearm")
    if rForearmBone then
        local forearmPhys = ragdoll:GetPhysicsObjectNum(rForearmBone)
        if IsValid(forearmPhys) then
            -- Punch outward
            forearmPhys:ApplyForceCenter(punchDir * 500 * forearmPhys:GetMass())
        end
    end

    -- Find ragdolls in range
    for _, ent in ipairs(ents.FindInSphere(punchPos, PUNCH_RANGE)) do
        if ent:GetClass() == "prop_ragdoll" and ent ~= ragdoll and IsValid(ent.Owner) then
            -- Calculate direction to target
            local toTarget = (ent:GetPos() - punchPos):GetNormalized()

            -- Check if target is roughly in front of us
            local dot = punchDir:Dot(toTarget)
            if dot > 0.3 then
                -- Apply damage
                GAMEMODE:DamageRagdoll(ent, ply, PUNCH_DAMAGE, punchDir)

                -- Apply knockback force to all physics bones
                for i = 0, ent:GetPhysicsObjectCount() - 1 do
                    local bonePhys = ent:GetPhysicsObjectNum(i)
                    if IsValid(bonePhys) then
                        local knockback = punchDir * PUNCH_FORCE * bonePhys:GetMass() * 0.3
                        knockback.z = PUNCH_FORCE * 0.3 * bonePhys:GetMass()
                        bonePhys:ApplyForceCenter(knockback)
                    end
                end

                -- Extra force on the walking wheel for big knockback
                if IsValid(ent.WalkingWheel) then
                    local wheelPhys = ent.WalkingWheel:GetPhysicsObject()
                    if IsValid(wheelPhys) then
                        local bigKnockback = punchDir * PUNCH_FORCE * wheelPhys:GetMass() * 2
                        bigKnockback.z = PUNCH_FORCE * wheelPhys:GetMass()
                        wheelPhys:ApplyForceCenter(bigKnockback)
                    end
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

    local victim = ragdoll.Owner
    victim.RagdollHealth = (victim.RagdollHealth or PLAYER_MAX_HEALTH) - damage
    ragdoll.OwnerHealth = victim.RagdollHealth

    -- Update player's networked health for HUD
    victim:SetHealth(math.max(0, victim.RagdollHealth))

    -- Check for death
    if victim.RagdollHealth <= 0 then
        self:PlayerRagdollDeath(victim, attacker)
    end
end

-- Handle ragdoll death
function GM:PlayerRagdollDeath(victim, attacker)
    if not IsValid(victim) then return end

    local attackerName = IsValid(attacker) and attacker:Nick() or "Unknown"
    print("[RagBox] " .. victim:Nick() .. " was knocked out by " .. attackerName)

    -- Create death effect
    if IsValid(victim.Ragdoll) then
        local effectData = EffectData()
        effectData:SetOrigin(victim.Ragdoll:GetPos())
        util.Effect("cball_explode", effectData)
    end

    -- Cleanup ragdoll system
    self:CleanupPlayerRagdoll(victim)

    -- Set player as spectator temporarily
    victim:Spectate(OBS_MODE_ROAMING)
    victim:SetTeam(2)
    victim.RagdollHealth = 0

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
    ply.RagdollHealth = PLAYER_MAX_HEALTH
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

-- Player disconnect cleanup
function GM:PlayerDisconnected(ply)
    self:CleanupPlayerRagdoll(ply)
end
