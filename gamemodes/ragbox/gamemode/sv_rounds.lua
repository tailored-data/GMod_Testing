--[[
    Ragdoll Boxing - Round System
    Handles round timing, start/end conditions, and scoring
]]

-- Initialize round variables
function GM:InitializeRounds()
    self.GameState = GAMESTATE_WAITING
    self.RoundStartTime = 0
    self.RoundEndTime = 0
    self.Scores = {}
end

-- Check if we can start a round
function GM:CheckRoundStart()
    if self.GameState ~= GAMESTATE_WAITING then return end

    -- Count alive players with ragdolls
    local alivePlayers = self:GetAlivePlayers()

    if #alivePlayers >= MIN_PLAYERS then
        self:StartRound()
    else
        -- Notify players we're waiting
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("[RagBox] Waiting for " .. MIN_PLAYERS .. " players to start... (" .. #alivePlayers .. "/" .. MIN_PLAYERS .. ")")
        end
    end
end

-- Get all alive players (with valid ragdolls)
function GM:GetAlivePlayers()
    local alive = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply.Ragdoll) and (ply.RagdollHealth or 0) > 0 then
            table.insert(alive, ply)
        end
    end
    return alive
end

-- Start a new round
function GM:StartRound()
    print("[RagBox] Starting new round!")

    self.GameState = GAMESTATE_PLAYING
    self.RoundStartTime = CurTime()
    self.RoundEndTime = CurTime() + ROUND_TIME

    -- Reset all players
    for _, ply in ipairs(player.GetAll()) do
        ply:SetTeam(1)
        ply:Spawn()
    end

    -- Broadcast game state
    net.Start("RagBox_GameState")
    net.WriteInt(GAMESTATE_PLAYING, 4)
    net.Broadcast()

    -- Announce round start
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[RagBox] ROUND STARTED! You have " .. ROUND_TIME .. " seconds. FIGHT!")
    end
end

-- Round think - called every frame
function GM:RoundThink()
    if self.GameState ~= GAMESTATE_PLAYING then return end

    -- Calculate time left
    local timeLeft = self.RoundEndTime - CurTime()

    -- Broadcast time update (throttled to once per second)
    if not self.LastTimeUpdate or CurTime() - self.LastTimeUpdate >= 1 then
        self.LastTimeUpdate = CurTime()

        net.Start("RagBox_RoundTime")
        net.WriteFloat(timeLeft)
        net.Broadcast()
    end

    -- Check for time up
    if timeLeft <= 0 then
        self:EndRound(nil, "Time's up!")
    end
end

-- Check if round should end
function GM:CheckRoundEnd()
    if self.GameState ~= GAMESTATE_PLAYING then return end

    local alivePlayers = self:GetAlivePlayers()

    if #alivePlayers <= 1 then
        if #alivePlayers == 1 then
            self:EndRound(alivePlayers[1], alivePlayers[1]:Nick() .. " wins by knockout!")
        else
            self:EndRound(nil, "Draw - everyone was knocked out!")
        end
    end
end

-- End the round
function GM:EndRound(winner, reason)
    print("[RagBox] Round ended: " .. reason)

    self.GameState = GAMESTATE_ROUNDEND

    -- Broadcast game state
    net.Start("RagBox_GameState")
    net.WriteInt(GAMESTATE_ROUNDEND, 4)
    net.Broadcast()

    -- Broadcast winner
    local winnerName = winner and winner:Nick() or "No one"
    net.Start("RagBox_RoundEnd")
    net.WriteString(winnerName)
    net.Broadcast()

    -- Update scores
    if IsValid(winner) then
        self.Scores[winner:SteamID()] = (self.Scores[winner:SteamID()] or 0) + 1
        winner:ChatPrint("[RagBox] You won! Total wins: " .. self.Scores[winner:SteamID()])
    end

    -- Announce to all players
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("[RagBox] " .. reason)
        ply:ChatPrint("[RagBox] Next round starting in " .. ROUND_END_TIME .. " seconds...")
    end

    -- Schedule next round
    timer.Simple(ROUND_END_TIME, function()
        self:PrepareNewRound()
    end)
end

-- Prepare for a new round
function GM:PrepareNewRound()
    print("[RagBox] Preparing new round...")

    self.GameState = GAMESTATE_WAITING

    -- Broadcast game state
    net.Start("RagBox_GameState")
    net.WriteInt(GAMESTATE_WAITING, 4)
    net.Broadcast()

    -- Respawn all players
    for _, ply in ipairs(player.GetAll()) do
        ply:SetTeam(1)

        -- Clean up old ragdoll
        if IsValid(ply.Ragdoll) then
            ply.Ragdoll:Remove()
        end

        -- Reset player visibility
        ply:SetNoDraw(false)
        ply:SetNotSolid(false)
        ply:UnSpectate()

        -- Respawn
        ply:Spawn()
    end

    -- Check if we can start immediately
    timer.Simple(1, function()
        self:CheckRoundStart()
    end)
end

-- Get time remaining in round (for HUD)
function GM:GetRoundTimeRemaining()
    if self.GameState ~= GAMESTATE_PLAYING then
        return 0
    end
    return math.max(0, self.RoundEndTime - CurTime())
end

-- Console command to force start round (for testing)
concommand.Add("ragbox_forcestart", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[RagBox] You must be an admin to use this command.")
        return
    end

    GAMEMODE:StartRound()
end)

-- Console command to end round (for testing)
concommand.Add("ragbox_forceend", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[RagBox] You must be an admin to use this command.")
        return
    end

    GAMEMODE:EndRound(nil, "Round force ended by admin")
end)
