--[[
    Frontier Colony - Vehicle System
    Handles vehicle purchasing, spawning, and ownership
]]

-- Player vehicle storage
PlayerVehicles = PlayerVehicles or {}

-- Initialize vehicle system
function GM:InitializeVehicles()
    print("[Frontier] Vehicle system initialized.")
end

-- Get player's vehicles
function GM:GetPlayerVehicles(ply)
    local steamID = ply:SteamID()
    return PlayerVehicles[steamID] or {}
end

-- Buy vehicle
function GM:BuyVehicle(ply, vehicleID)
    -- Find vehicle data
    local vehicleData = nil
    for _, v in ipairs(VEHICLES) do
        if v.id == vehicleID then
            vehicleData = v
            break
        end
    end

    if not vehicleData then
        return false, "Vehicle not found"
    end

    -- Check affordability
    if not self:CanAfford(ply, CURRENCY_CREDITS, vehicleData.price) then
        return false, "You cannot afford this vehicle"
    end

    -- Check if player already owns this type
    local steamID = ply:SteamID()
    PlayerVehicles[steamID] = PlayerVehicles[steamID] or {}

    for _, owned in ipairs(PlayerVehicles[steamID]) do
        if owned.id == vehicleID then
            return false, "You already own this vehicle"
        end
    end

    -- Process purchase
    self:TakeCurrency(ply, CURRENCY_CREDITS, vehicleData.price)

    table.insert(PlayerVehicles[steamID], {
        id = vehicleID,
        name = vehicleData.name,
        model = vehicleData.model,
        class = vehicleData.class,
        script = vehicleData.script,
        entity = nil
    })

    self:SendNotification(ply, "Vehicle Purchased!", vehicleData.name .. " added to your garage.", Color(100, 200, 80), 4)
    self:GiveXP(ply, 150)

    return true, "Success"
end

-- Sell vehicle
function GM:SellVehicle(ply, vehicleID)
    local steamID = ply:SteamID()
    local vehicles = PlayerVehicles[steamID] or {}

    -- Find the vehicle
    local vehicleIndex = nil
    local vehicleData = nil

    for i, v in ipairs(vehicles) do
        if v.id == vehicleID then
            vehicleIndex = i
            -- Get price from VEHICLES table
            for _, vd in ipairs(VEHICLES) do
                if vd.id == vehicleID then
                    vehicleData = vd
                    break
                end
            end
            break
        end
    end

    if not vehicleIndex then
        return false, "You don't own this vehicle"
    end

    -- Remove spawned entity if exists
    local ownedVehicle = vehicles[vehicleIndex]
    if IsValid(ownedVehicle.entity) then
        ownedVehicle.entity:Remove()
    end

    -- Calculate sell price (60% of buy price)
    local sellPrice = math.floor(vehicleData.price * 0.6)

    -- Process sale
    self:GiveCurrency(ply, CURRENCY_CREDITS, sellPrice)
    table.remove(vehicles, vehicleIndex)

    self:SendNotification(ply, "Vehicle Sold!", "You received " .. FormatMoney(sellPrice), Color(200, 200, 80), 4)

    return true, "Success"
end

-- Spawn player's vehicle
function GM:SpawnVehicle(ply, vehicleID)
    local steamID = ply:SteamID()
    local vehicles = PlayerVehicles[steamID] or {}

    -- Find the vehicle
    local vehicleIndex = nil
    for i, v in ipairs(vehicles) do
        if v.id == vehicleID then
            vehicleIndex = i
            break
        end
    end

    if not vehicleIndex then
        return false, "You don't own this vehicle"
    end

    local vehicleInfo = vehicles[vehicleIndex]

    -- Remove old spawn if exists
    if IsValid(vehicleInfo.entity) then
        vehicleInfo.entity:Remove()
    end

    -- Find spawn position
    local tr = ply:GetEyeTrace()
    local spawnPos = tr.HitPos + Vector(0, 0, 50)

    -- Create vehicle
    local vehicle = ents.Create(vehicleInfo.class)
    if not IsValid(vehicle) then
        return false, "Failed to create vehicle"
    end

    vehicle:SetModel(vehicleInfo.model)
    vehicle:SetPos(spawnPos)
    vehicle:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    vehicle:SetKeyValue("vehiclescript", vehicleInfo.script)
    vehicle:Spawn()
    vehicle:Activate()

    -- Store reference
    vehicleInfo.entity = vehicle
    vehicle.Owner = ply
    vehicle.OwnerSteamID = steamID

    self:SendNotification(ply, "Vehicle Spawned", vehicleInfo.name .. " is ready.", Color(100, 200, 80), 3)

    return true, "Success"
end

-- Despawn vehicle
function GM:DespawnVehicle(ply, vehicleID)
    local steamID = ply:SteamID()
    local vehicles = PlayerVehicles[steamID] or {}

    for _, v in ipairs(vehicles) do
        if v.id == vehicleID and IsValid(v.entity) then
            v.entity:Remove()
            v.entity = nil
            self:SendNotification(ply, "Vehicle Stored", "Vehicle returned to garage.", Color(200, 200, 80), 2)
            return true
        end
    end

    return false, "Vehicle not found or not spawned"
end

-- Check if player can enter vehicle
function GM:CanPlayerEnterVehicle(ply, vehicle)
    -- Anyone can enter unowned vehicles or their own
    if not vehicle.OwnerSteamID then return true end
    if vehicle.OwnerSteamID == ply:SteamID() then return true end

    -- Others need permission (future: key sharing system)
    return false
end

-- Vehicle entry hook
hook.Add("CanPlayerEnterVehicle", "Frontier_VehicleOwnership", function(ply, vehicle)
    if not GAMEMODE:CanPlayerEnterVehicle(ply, vehicle) then
        GAMEMODE:SendNotification(ply, "Locked", "This vehicle belongs to someone else.", Color(200, 80, 80), 2)
        return false
    end
end)

-- Clean up vehicles on disconnect
hook.Add("PlayerDisconnected", "Frontier_CleanupVehicles", function(ply)
    local steamID = ply:SteamID()
    local vehicles = PlayerVehicles[steamID] or {}

    for _, v in ipairs(vehicles) do
        if IsValid(v.entity) then
            v.entity:Remove()
            v.entity = nil
        end
    end
end)

-- Network handlers
net.Receive("Frontier_BuyVehicle", function(len, ply)
    local vehicleID = net.ReadString()
    local success, message = GAMEMODE:BuyVehicle(ply, vehicleID)

    if not success then
        GAMEMODE:SendNotification(ply, "Purchase Failed", message, Color(200, 80, 80), 3)
    end
end)

net.Receive("Frontier_SellVehicle", function(len, ply)
    local vehicleID = net.ReadString()
    local success, message = GAMEMODE:SellVehicle(ply, vehicleID)

    if not success then
        GAMEMODE:SendNotification(ply, "Sale Failed", message, Color(200, 80, 80), 3)
    end
end)

-- Console command to spawn vehicle
concommand.Add("frontier_spawnvehicle", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local vehicleID = args[1]
    if not vehicleID then
        ply:ChatPrint("[Frontier] Usage: frontier_spawnvehicle <vehicle_id>")
        return
    end

    local success, message = GAMEMODE:SpawnVehicle(ply, vehicleID)
    if not success then
        ply:ChatPrint("[Frontier] " .. message)
    end
end)

concommand.Add("frontier_despawnvehicle", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local vehicleID = args[1]
    if not vehicleID then
        ply:ChatPrint("[Frontier] Usage: frontier_despawnvehicle <vehicle_id>")
        return
    end

    GAMEMODE:DespawnVehicle(ply, vehicleID)
end)
