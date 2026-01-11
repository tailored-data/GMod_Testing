--[[
    Frontier Colony - Server Economy System
    Handles paychecks, shops, and purchases
]]

-- Paycheck timer
local nextPaycheck = 0

-- Initialize economy
function GM:InitializeEconomy()
    nextPaycheck = CurTime() + PAYCHECK_INTERVAL
    print("[Frontier] Economy system initialized. First paycheck in " .. PAYCHECK_INTERVAL .. " seconds.")
end

-- Economy think (called from main Think)
function GM:EconomyThink()
    if CurTime() >= nextPaycheck then
        self:DistributePaychecks()
        nextPaycheck = CurTime() + PAYCHECK_INTERVAL
    end
end

-- Distribute paychecks to all players
function GM:DistributePaychecks()
    for _, ply in ipairs(player.GetAll()) do
        local data = self:GetPlayerData(ply)
        if data then
            local job = GetJobByID(data.job)
            if job then
                local salary = job.salary

                -- Apply morale bonus/penalty
                local moraleMod = Colony.morale / 100
                salary = math.floor(salary * moraleMod)

                -- Apply level bonus (+2% per level)
                local levelBonus = 1 + (data.level * 0.02)
                salary = math.floor(salary * levelBonus)

                -- Give the credits
                self:GiveCurrency(ply, CURRENCY_CREDITS, salary)

                -- Give some XP for working
                self:GiveXP(ply, 25)

                -- Notify player
                self:SendNotification(ply, "Paycheck Received",
                    "+" .. FormatCurrency(salary, CURRENCY_CREDITS) .. " for your work as " .. job.name,
                    CURRENCY_COLORS[CURRENCY_CREDITS], 4)
            end
        end
    end

    -- Announce to all
    PrintMessage(HUD_PRINTTALK, "[Frontier] Paychecks distributed! Next paycheck in " .. math.floor(PAYCHECK_INTERVAL / 60) .. " minutes.")
end

-- Handle shop purchase
net.Receive("Frontier_BuyItem", function(len, ply)
    local itemID = net.ReadString()

    -- Find the item
    local item = nil
    for _, shopItem in ipairs(SHOP_ITEMS) do
        if shopItem.id == itemID then
            item = shopItem
            break
        end
    end

    if not item then
        GAMEMODE:SendNotification(ply, "Purchase Failed", "Item not found", Color(255, 100, 100), 3)
        return
    end

    -- Check if can afford
    if not GAMEMODE:CanAfford(ply, item.currency, item.price) then
        GAMEMODE:SendNotification(ply, "Purchase Failed", "Not enough " .. CURRENCY_NAMES[item.currency], Color(255, 100, 100), 3)
        return
    end

    -- Process purchase
    GAMEMODE:TakeCurrency(ply, item.currency, item.price)

    -- Give the item
    if item.id == "health_kit" then
        ply:SetHealth(math.min(ply:Health() + 50, ply:GetMaxHealth()))
    elseif item.id == "armor" then
        ply:SetArmor(math.min(ply:Armor() + 50, 100))
    elseif item.id == "pistol_ammo" then
        ply:GiveAmmo(20, "Pistol")
    elseif item.id == "smg_ammo" then
        ply:GiveAmmo(45, "SMG1")
    elseif item.id == "shotgun_ammo" then
        ply:GiveAmmo(12, "Buckshot")
    elseif item.id == "flashlight" then
        ply:Give("weapon_flashlight")
    end

    GAMEMODE:SendNotification(ply, "Purchase Complete", "Bought " .. item.name, CURRENCY_COLORS[item.currency], 3)
    GAMEMODE:GiveXP(ply, 10)
end)

-- Handle colony upgrade purchase
net.Receive("Frontier_BuyUpgrade", function(len, ply)
    local upgradeID = net.ReadString()

    -- Find the upgrade
    local upgrade = nil
    for _, colonyUpgrade in ipairs(COLONY_UPGRADES) do
        if colonyUpgrade.id == upgradeID then
            upgrade = colonyUpgrade
            break
        end
    end

    if not upgrade then
        GAMEMODE:SendNotification(ply, "Purchase Failed", "Upgrade not found", Color(255, 100, 100), 3)
        return
    end

    -- Check if can afford
    if not GAMEMODE:CanAfford(ply, upgrade.currency, upgrade.price) then
        GAMEMODE:SendNotification(ply, "Purchase Failed", "Not enough " .. CURRENCY_NAMES[upgrade.currency], Color(255, 100, 100), 3)
        return
    end

    -- Process purchase
    GAMEMODE:TakeCurrency(ply, upgrade.currency, upgrade.price)

    -- Apply the upgrade
    if upgrade.id == "power_gen" then
        GAMEMODE:AddColonyPower(200)
        PrintMessage(HUD_PRINTTALK, "[Frontier] " .. ply:Nick() .. " restored 200 colony power!")
    elseif upgrade.id == "food_crate" then
        GAMEMODE:AddColonyFood(100)
        PrintMessage(HUD_PRINTTALK, "[Frontier] " .. ply:Nick() .. " added 100 food supplies!")
    elseif upgrade.id == "shield_boost" then
        GAMEMODE:AddColonyShields(25)
        PrintMessage(HUD_PRINTTALK, "[Frontier] " .. ply:Nick() .. " boosted colony shields!")
    elseif upgrade.id == "turret" then
        -- Would spawn a turret entity
        PrintMessage(HUD_PRINTTALK, "[Frontier] " .. ply:Nick() .. " built a defense turret!")
    end

    GAMEMODE:SendNotification(ply, "Colony Upgraded", upgrade.name .. " activated!", Color(100, 255, 100), 4)
    GAMEMODE:GiveXP(ply, 50)

    -- Sync colony data
    GAMEMODE:SyncColonyData()
end)

-- Alloy node collection (would be called when player interacts with mining nodes)
function GM:CollectAlloy(ply, baseAmount)
    local data = self:GetPlayerData(ply)
    if not data then return end

    local job = GetJobByID(data.job)
    local bonus = job and job.alloyBonus or 0
    local totalAmount = math.floor(baseAmount * (1 + bonus / 100))

    self:GiveCurrency(ply, CURRENCY_ALLOY, totalAmount)
    self:GiveXP(ply, totalAmount)

    if bonus > 0 then
        self:SendNotification(ply, "Alloy Collected",
            "+" .. FormatCurrency(totalAmount, CURRENCY_ALLOY) .. " (+" .. bonus .. "% job bonus)",
            CURRENCY_COLORS[CURRENCY_ALLOY], 2)
    else
        self:SendNotification(ply, "Alloy Collected",
            "+" .. FormatCurrency(totalAmount, CURRENCY_ALLOY),
            CURRENCY_COLORS[CURRENCY_ALLOY], 2)
    end
end

-- Chat commands for giving currency (admin only, for testing)
hook.Add("PlayerSay", "Frontier_ChatCommands", function(ply, text)
    local args = string.Explode(" ", text)
    local cmd = string.lower(args[1])

    if cmd == "/givecredits" and ply:IsAdmin() then
        local target = player.GetBySteamID(args[2]) or ply
        local amount = tonumber(args[3]) or tonumber(args[2]) or 100
        GAMEMODE:GiveCurrency(target, CURRENCY_CREDITS, amount)
        return ""
    elseif cmd == "/givealloy" and ply:IsAdmin() then
        local target = player.GetBySteamID(args[2]) or ply
        local amount = tonumber(args[3]) or tonumber(args[2]) or 100
        GAMEMODE:GiveCurrency(target, CURRENCY_ALLOY, amount)
        return ""
    elseif cmd == "/givexp" and ply:IsAdmin() then
        local amount = tonumber(args[2]) or 100
        GAMEMODE:GiveXP(ply, amount)
        return ""
    elseif cmd == "/job" then
        net.Start("Frontier_OpenMenu")
        net.WriteString("jobs")
        net.Send(ply)
        return ""
    elseif cmd == "/shop" then
        net.Start("Frontier_OpenMenu")
        net.WriteString("shop")
        net.Send(ply)
        return ""
    end
end)
