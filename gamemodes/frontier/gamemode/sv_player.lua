--[[
    Frontier Colony - Server Player System
    Handles player data, jobs, currency, and progression
]]

-- Player data storage (in real implementation, use SQL)
PlayerData = PlayerData or {}

-- Initialize player data
function GM:InitializePlayerData(ply)
    local steamID = ply:SteamID()

    PlayerData[steamID] = {
        credits = STARTING_CREDITS,
        alloy = STARTING_ALLOY,
        job = DEFAULT_JOB,
        xp = 0,
        level = 1,
        totalPlaytime = 0,
        joinTime = CurTime()
    }

    -- Sync to client
    self:SyncPlayerData(ply)

    print("[Frontier] Initialized data for " .. ply:Nick())
end

-- Get player data
function GM:GetPlayerData(ply)
    if not IsValid(ply) then return nil end
    return PlayerData[ply:SteamID()]
end

-- Sync player data to client
function GM:SyncPlayerData(ply)
    local data = self:GetPlayerData(ply)
    if not data then return end

    net.Start("Frontier_PlayerData")
    net.WriteInt(data.credits, 32)
    net.WriteInt(data.alloy, 32)
    net.WriteInt(data.job, 8)
    net.WriteInt(data.xp, 32)
    net.WriteInt(data.level, 8)
    net.Send(ply)
end

-- Give currency to player
function GM:GiveCurrency(ply, currencyType, amount)
    local data = self:GetPlayerData(ply)
    if not data then return false end

    if currencyType == CURRENCY_CREDITS then
        data.credits = math.max(0, data.credits + amount)
    elseif currencyType == CURRENCY_ALLOY then
        data.alloy = math.max(0, data.alloy + amount)
    end

    self:SyncPlayerData(ply)
    return true
end

-- Take currency from player
function GM:TakeCurrency(ply, currencyType, amount)
    local data = self:GetPlayerData(ply)
    if not data then return false end

    if currencyType == CURRENCY_CREDITS then
        if data.credits < amount then return false end
        data.credits = data.credits - amount
    elseif currencyType == CURRENCY_ALLOY then
        if data.alloy < amount then return false end
        data.alloy = data.alloy - amount
    end

    self:SyncPlayerData(ply)
    return true
end

-- Check if player can afford something
function GM:CanAfford(ply, currencyType, amount)
    local data = self:GetPlayerData(ply)
    if not data then return false end

    if currencyType == CURRENCY_CREDITS then
        return data.credits >= amount
    elseif currencyType == CURRENCY_ALLOY then
        return data.alloy >= amount
    end

    return false
end

-- Give XP to player
function GM:GiveXP(ply, amount)
    local data = self:GetPlayerData(ply)
    if not data then return end

    data.xp = data.xp + amount
    local newLevel = CalculateLevel(data.xp)

    if newLevel > data.level then
        data.level = newLevel
        self:OnPlayerLevelUp(ply, newLevel)
    end

    self:SyncPlayerData(ply)
end

-- Handle level up
function GM:OnPlayerLevelUp(ply, newLevel)
    -- Notify player
    self:SendNotification(ply, "LEVEL UP!", "You are now level " .. newLevel .. "!", Color(255, 215, 0), 5)

    -- Bonus credits for leveling
    local bonus = newLevel * 50
    self:GiveCurrency(ply, CURRENCY_CREDITS, bonus)

    -- Announce to server
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[Frontier] " .. ply:Nick() .. " has reached Level " .. newLevel .. "!")
    end
end

-- Change player job
function GM:ChangePlayerJob(ply, jobID)
    local data = self:GetPlayerData(ply)
    if not data then return false, "No player data" end

    local job = GetJobByID(jobID)
    if not job then return false, "Invalid job" end

    -- Check max players for this job
    if job.maxPlayers > 0 then
        local count = 0
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply then
                local pData = self:GetPlayerData(p)
                if pData and pData.job == jobID then
                    count = count + 1
                end
            end
        end

        if count >= job.maxPlayers then
            return false, "This job is full (" .. count .. "/" .. job.maxPlayers .. ")"
        end
    end

    -- Change job
    data.job = jobID
    ply:SetTeam(jobID)

    -- Set model
    ply:SetModel(job.model)

    -- Give weapons
    ply:StripWeapons()
    for _, weapon in ipairs(job.weapons) do
        ply:Give(weapon)
    end

    self:SyncPlayerData(ply)
    self:SendNotification(ply, "Job Changed", "You are now a " .. job.name, job.color, 3)

    return true, "Success"
end

-- Player spawn
function GM:PlayerSpawn(ply)
    self.BaseClass:PlayerSpawn(ply)

    local data = self:GetPlayerData(ply)
    if not data then
        self:InitializePlayerData(ply)
        data = self:GetPlayerData(ply)
    end

    local job = GetJobByID(data.job)
    if job then
        ply:SetModel(job.model)
        ply:SetTeam(data.job)

        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply:StripWeapons()
                for _, weapon in ipairs(job.weapons) do
                    ply:Give(weapon)
                end
            end
        end)
    end

    ply:SetHealth(100)
    ply:SetMaxHealth(100)
    ply:SetArmor(0)
end

-- Player initial spawn
function GM:PlayerInitialSpawn(ply)
    self:InitializePlayerData(ply)

    timer.Simple(1, function()
        if IsValid(ply) then
            ply:ChatPrint("[Frontier] Welcome to Frontier Colony!")
            ply:ChatPrint("[Frontier] Press F4 to open the job menu, F3 for the shop.")
            self:SendNotification(ply, "Welcome, Colonist!", "Press F4 for jobs, F3 for shop", Color(100, 200, 255), 8)
        end
    end)
end

-- Player disconnect
function GM:PlayerDisconnected(ply)
    -- Update playtime before leaving
    local data = self:GetPlayerData(ply)
    if data then
        data.totalPlaytime = data.totalPlaytime + (CurTime() - data.joinTime)
    end
end

-- Send notification to player
function GM:SendNotification(ply, title, message, color, duration)
    net.Start("Frontier_Notification")
    net.WriteString(title)
    net.WriteString(message)
    net.WriteColor(color or Color(255, 255, 255))
    net.WriteFloat(duration or 5)
    net.Send(ply)
end

-- Handle job change request
net.Receive("Frontier_ChangeJob", function(len, ply)
    local jobID = net.ReadInt(8)
    local success, message = GAMEMODE:ChangePlayerJob(ply, jobID)

    if not success then
        GAMEMODE:SendNotification(ply, "Cannot Change Job", message, Color(255, 100, 100), 3)
    end
end)

-- Player loadout (empty, handled by job system)
function GM:PlayerLoadout(ply)
    return true
end

-- Prevent default weapon giving
function GM:PlayerCanPickupWeapon(ply, weapon)
    return true
end
