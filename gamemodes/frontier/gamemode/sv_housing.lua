--[[
    Frontier Colony - Housing System
    Handles property ownership, doors, and the housing dealer
]]

-- Property storage
Properties = Properties or {}
OwnedDoors = OwnedDoors or {}

-- Initialize housing system
function GM:InitializeHousing()
    print("[Frontier] Initializing housing system...")
    self:ScanMapDoors()
end

-- Scan map for purchasable doors
function GM:ScanMapDoors()
    Properties = {}

    -- Find all door entities
    local doors = {}
    for _, ent in ipairs(ents.GetAll()) do
        local class = ent:GetClass()
        if class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating" then
            table.insert(doors, ent)
        end
    end

    -- Group doors into properties by proximity
    local propertyID = 1
    local assignedDoors = {}

    for _, door in ipairs(doors) do
        if not assignedDoors[door:EntIndex()] then
            local property = {
                id = propertyID,
                doors = {door},
                owner = nil,
                ownerName = nil,
                price = PROPERTY_BASE_PRICE
            }

            assignedDoors[door:EntIndex()] = true

            -- Find nearby doors (within 500 units)
            for _, otherDoor in ipairs(doors) do
                if not assignedDoors[otherDoor:EntIndex()] then
                    if door:GetPos():Distance(otherDoor:GetPos()) < 500 then
                        table.insert(property.doors, otherDoor)
                        assignedDoors[otherDoor:EntIndex()] = true
                    end
                end
            end

            -- Calculate price based on door count
            property.price = PROPERTY_BASE_PRICE + (#property.doors - 1) * PROPERTY_PRICE_PER_DOOR

            -- Set door ownership reference
            for _, d in ipairs(property.doors) do
                d.PropertyID = propertyID
                OwnedDoors[d:EntIndex()] = property
            end

            Properties[propertyID] = property
            propertyID = propertyID + 1
        end
    end

    print("[Frontier] Found " .. (propertyID - 1) .. " properties with " .. #doors .. " total doors")
end

-- Get property by ID
function GM:GetProperty(id)
    return Properties[id]
end

-- Get property by door
function GM:GetPropertyByDoor(door)
    if not IsValid(door) then return nil end
    return OwnedDoors[door:EntIndex()]
end

-- Check if player owns a property
function GM:PlayerOwnsProperty(ply, propertyID)
    local property = Properties[propertyID]
    if not property then return false end
    return property.owner == ply:SteamID()
end

-- Buy property
function GM:BuyProperty(ply, propertyID)
    local property = Properties[propertyID]
    if not property then
        return false, "Property not found"
    end

    if property.owner then
        return false, "This property is already owned"
    end

    if not self:CanAfford(ply, CURRENCY_CREDITS, property.price) then
        return false, "You cannot afford this property"
    end

    -- Process purchase
    self:TakeCurrency(ply, CURRENCY_CREDITS, property.price)

    property.owner = ply:SteamID()
    property.ownerName = ply:Nick()

    -- Update door appearance
    for _, door in ipairs(property.doors) do
        if IsValid(door) then
            door:SetNWString("Owner", ply:Nick())
            door:SetNWBool("Owned", true)
        end
    end

    self:SendNotification(ply, "Property Purchased!", "You now own this property.", Color(100, 200, 80), 4)
    self:GiveXP(ply, 100)

    return true, "Success"
end

-- Sell property
function GM:SellProperty(ply, propertyID)
    local property = Properties[propertyID]
    if not property then
        return false, "Property not found"
    end

    if property.owner ~= ply:SteamID() then
        return false, "You don't own this property"
    end

    -- Calculate sell price
    local sellPrice = math.floor(property.price * PROPERTY_SELL_PERCENTAGE)

    -- Process sale
    self:GiveCurrency(ply, CURRENCY_CREDITS, sellPrice)

    property.owner = nil
    property.ownerName = nil

    -- Update door appearance
    for _, door in ipairs(property.doors) do
        if IsValid(door) then
            door:SetNWString("Owner", "")
            door:SetNWBool("Owned", false)
        end
    end

    self:SendNotification(ply, "Property Sold!", "You received " .. FormatMoney(sellPrice), Color(200, 200, 80), 4)

    return true, "Success"
end

-- Handle door use
function GM:PlayerCanUseDoor(ply, door)
    local property = self:GetPropertyByDoor(door)
    if not property then return true end
    if not property.owner then return true end

    -- Owner can always use
    if property.owner == ply:SteamID() then
        return true
    end

    -- Others cannot
    return false
end

-- Door use hook
hook.Add("PlayerUse", "Frontier_DoorCheck", function(ply, ent)
    local class = ent:GetClass()
    if class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating" then
        if not GAMEMODE:PlayerCanUseDoor(ply, ent) then
            GAMEMODE:SendNotification(ply, "Locked", "This property belongs to someone else.", Color(200, 80, 80), 2)
            return false
        end
    end
end)

-- Get all properties for display
function GM:GetAllProperties()
    local list = {}
    for id, property in pairs(Properties) do
        table.insert(list, {
            id = id,
            doorCount = #property.doors,
            price = property.price,
            owner = property.ownerName,
            owned = property.owner ~= nil,
            position = property.doors[1] and property.doors[1]:GetPos() or Vector(0, 0, 0)
        })
    end
    return list
end

-- Get player's owned properties
function GM:GetPlayerProperties(ply)
    local owned = {}
    for id, property in pairs(Properties) do
        if property.owner == ply:SteamID() then
            table.insert(owned, {
                id = id,
                doorCount = #property.doors,
                price = property.price,
                sellPrice = math.floor(property.price * PROPERTY_SELL_PERCENTAGE),
                position = property.doors[1] and property.doors[1]:GetPos() or Vector(0, 0, 0)
            })
        end
    end
    return owned
end

-- Network handlers
net.Receive("Frontier_BuyProperty", function(len, ply)
    local propertyID = net.ReadInt(16)
    local success, message = GAMEMODE:BuyProperty(ply, propertyID)

    if not success then
        GAMEMODE:SendNotification(ply, "Purchase Failed", message, Color(200, 80, 80), 3)
    end
end)

net.Receive("Frontier_SellProperty", function(len, ply)
    local propertyID = net.ReadInt(16)
    local success, message = GAMEMODE:SellProperty(ply, propertyID)

    if not success then
        GAMEMODE:SendNotification(ply, "Sale Failed", message, Color(200, 80, 80), 3)
    end
end)

-- Player disconnect - properties persist (no cleanup needed for persistent ownership)
-- In a real implementation, you'd save to SQL
