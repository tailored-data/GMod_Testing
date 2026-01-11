--[[
    Frontier Colony - Shared Configuration
    A cooperative space colony survival RPG
]]

GM.Name = "Frontier Colony"
GM.Author = "Claude"
GM.Email = ""
GM.Website = ""

--[[
    CURRENCY SYSTEM
]]

CURRENCY_CREDITS = 1
CURRENCY_ALLOY = 2

CURRENCY_SYMBOLS = {
    [CURRENCY_CREDITS] = "$",
    [CURRENCY_ALLOY] = "A"
}

CURRENCY_NAMES = {
    [CURRENCY_CREDITS] = "Credits",
    [CURRENCY_ALLOY] = "Alloy"
}

CURRENCY_COLORS = {
    [CURRENCY_CREDITS] = Color(120, 200, 80),
    [CURRENCY_ALLOY] = Color(160, 120, 220)
}

STARTING_CREDITS = 1000
STARTING_ALLOY = 100

--[[
    JOB SYSTEM
]]

JOBS = {
    [1] = {
        id = 1,
        name = "Colonist",
        description = "A new arrival to the colony. Basic pay, no special perks.",
        color = Color(180, 180, 180),
        salary = 75,
        alloyBonus = 0,
        abilities = {},
        model = "models/player/group01/male_01.mdl",
        weapons = {"weapon_crowbar"},
        maxPlayers = 0
    },
    [2] = {
        id = 2,
        name = "Miner",
        description = "Extracts valuable alloy from mineral deposits around the colony.",
        color = Color(200, 140, 60),
        salary = 100,
        alloyBonus = 50,
        abilities = {"mining_boost"},
        model = "models/player/group03/male_01.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 4
    },
    [3] = {
        id = 3,
        name = "Engineer",
        description = "Maintains power generators and repairs colony infrastructure.",
        color = Color(255, 200, 60),
        salary = 125,
        alloyBonus = 0,
        abilities = {"fast_repair", "power_boost"},
        model = "models/player/group03/male_04.mdl",
        weapons = {"weapon_crowbar", "weapon_smg1"},
        maxPlayers = 3
    },
    [4] = {
        id = 4,
        name = "Medic",
        description = "Heals injured colonists and provides emergency medical care.",
        color = Color(80, 180, 255),
        salary = 115,
        alloyBonus = 0,
        abilities = {"heal_boost", "revive"},
        model = "models/player/group03/female_01.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 2
    },
    [5] = {
        id = 5,
        name = "Security",
        description = "Protects colonists from hostile wildlife and raiders.",
        color = Color(220, 60, 60),
        salary = 150,
        alloyBonus = 0,
        abilities = {"combat_bonus", "armor_boost"},
        model = "models/player/combine_soldier.mdl",
        weapons = {"weapon_smg1", "weapon_shotgun", "weapon_pistol"},
        maxPlayers = 3
    },
    [6] = {
        id = 6,
        name = "Scientist",
        description = "Researches new technologies and improves colony efficiency.",
        color = Color(180, 80, 220),
        salary = 110,
        alloyBonus = 0,
        abilities = {"research", "efficiency_boost"},
        model = "models/player/group03/female_06.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 2
    },
    [7] = {
        id = 7,
        name = "Farmer",
        description = "Grows crops and manages food production for the colony.",
        color = Color(100, 180, 60),
        salary = 90,
        alloyBonus = 25,
        abilities = {"food_boost", "harvest_bonus"},
        model = "models/player/group01/female_01.mdl",
        weapons = {"weapon_crowbar"},
        maxPlayers = 2
    }
}

DEFAULT_JOB = 1

--[[
    COLONY SYSTEM
]]

COLONY_MAX_POWER = 1000
COLONY_MAX_FOOD = 500
COLONY_MAX_SHIELDS = 100
COLONY_MAX_MORALE = 100

COLONY_POWER_DRAIN = 3
COLONY_FOOD_DRAIN = 1

--[[
    RESOURCE GATHERING

    How players obtain resources:
    - ALLOY: Mine from ore deposits scattered around the map
    - POWER: Engineers repair/fuel generators
    - FOOD: Farmers harvest from crop nodes
    - CREDITS: Paychecks, selling items, completing tasks
]]

RESOURCE_TYPES = {
    ORE = 1,      -- Gives Alloy
    GENERATOR = 2, -- Gives Power to colony
    CROP = 3,      -- Gives Food to colony
    SALVAGE = 4    -- Gives Credits
}

RESOURCE_RESPAWN_TIME = 120 -- 2 minutes

-- Base amounts (modified by job bonuses)
ORE_ALLOY_AMOUNT = 15
GENERATOR_POWER_AMOUNT = 50
CROP_FOOD_AMOUNT = 25
SALVAGE_CREDIT_AMOUNT = 50

--[[
    HOUSING SYSTEM
]]

HOUSE_DOOR_MODELS = {
    "models/props_c17/door01_left.mdl",
    "models/props_doors/door03_slotted_left.mdl",
    "models/props_doors/door03_slotted_right.mdl",
    "models/props_interiors/door_metal01.mdl",
    "models/props_doors/door_wooden01.mdl",
}

-- Property price multiplier based on door count
PROPERTY_BASE_PRICE = 500
PROPERTY_PRICE_PER_DOOR = 250
PROPERTY_SELL_PERCENTAGE = 0.6 -- Sell for 60% of buy price

--[[
    VEHICLE SYSTEM
]]

VEHICLES = {
    {
        id = "jeep",
        name = "Colony Rover",
        description = "A rugged 4-wheel drive vehicle for traversing rough terrain.",
        price = 2500,
        model = "models/buggy.mdl",
        class = "prop_vehicle_jeep",
        script = "scripts/vehicles/jeep_test.txt"
    },
    {
        id = "airboat",
        name = "Hover Skiff",
        description = "A lightweight hover vehicle for quick transportation.",
        price = 3500,
        model = "models/airboat.mdl",
        class = "prop_vehicle_airboat",
        script = "scripts/vehicles/airboat.txt"
    },
    {
        id = "pod",
        name = "Transport Pod",
        description = "An enclosed pod for safe passenger transport.",
        price = 1500,
        model = "models/vehicles/prisoner_pod.mdl",
        class = "prop_vehicle_prisoner_pod",
        script = "scripts/vehicles/prisoner_pod.txt"
    }
}

--[[
    TIMING
]]

PAYCHECK_INTERVAL = 300
ALIEN_ATTACK_MIN_INTERVAL = 600
ALIEN_ATTACK_MAX_INTERVAL = 900

--[[
    SHOP ITEMS
]]

SHOP_ITEMS = {
    {id = "health_small", name = "Medkit", price = 75, currency = CURRENCY_CREDITS, description = "Restores 25 health instantly.", icon = "icon16/heart.png"},
    {id = "health_large", name = "Trauma Kit", price = 200, currency = CURRENCY_CREDITS, description = "Restores 75 health instantly.", icon = "icon16/heart_add.png"},
    {id = "armor", name = "Body Armor", price = 300, currency = CURRENCY_CREDITS, description = "Adds 50 armor protection.", icon = "icon16/shield.png"},
    {id = "pistol_ammo", name = "Pistol Ammo", price = 30, currency = CURRENCY_CREDITS, description = "Box of 20 pistol rounds.", icon = "icon16/bullet_orange.png"},
    {id = "smg_ammo", name = "SMG Ammo", price = 50, currency = CURRENCY_CREDITS, description = "Box of 45 SMG rounds.", icon = "icon16/bullet_yellow.png"},
    {id = "shotgun_ammo", name = "Shotgun Shells", price = 60, currency = CURRENCY_CREDITS, description = "Box of 12 shotgun shells.", icon = "icon16/bullet_red.png"},
}

COLONY_UPGRADES = {
    {id = "power_cell", name = "Power Cell", price = 150, currency = CURRENCY_ALLOY, description = "Adds 100 power to colony reserves.", icon = "icon16/lightning.png"},
    {id = "food_crate", name = "Food Supplies", price = 75, currency = CURRENCY_ALLOY, description = "Adds 50 food to colony stores.", icon = "icon16/cake.png"},
    {id = "shield_cap", name = "Shield Capacitor", price = 200, currency = CURRENCY_ALLOY, description = "Restores 25% colony shields.", icon = "icon16/weather_lightning.png"},
}

--[[
    LEVELING
]]

XP_PER_LEVEL = 1000
MAX_LEVEL = 50

function CalculateLevel(xp)
    return math.min(MAX_LEVEL, math.floor(xp / XP_PER_LEVEL) + 1)
end

function XPForLevel(level)
    return (level - 1) * XP_PER_LEVEL
end

function XPProgress(xp)
    local currentLevelXP = xp % XP_PER_LEVEL
    return currentLevelXP / XP_PER_LEVEL
end

--[[
    TEAMS
]]

function GM:CreateTeams()
    for id, job in pairs(JOBS) do
        team.SetUp(id, job.name, job.color)
    end
end

--[[
    NETWORKING
]]

if SERVER then
    util.AddNetworkString("Frontier_PlayerData")
    util.AddNetworkString("Frontier_ColonyData")
    util.AddNetworkString("Frontier_Notification")
    util.AddNetworkString("Frontier_OpenMenu")
    util.AddNetworkString("Frontier_ChangeJob")
    util.AddNetworkString("Frontier_BuyItem")
    util.AddNetworkString("Frontier_BuyUpgrade")
    util.AddNetworkString("Frontier_BuyProperty")
    util.AddNetworkString("Frontier_SellProperty")
    util.AddNetworkString("Frontier_PropertyData")
    util.AddNetworkString("Frontier_BuyVehicle")
    util.AddNetworkString("Frontier_SellVehicle")
    util.AddNetworkString("Frontier_ResourceCollect")
end

--[[
    UTILITIES
]]

function GetJobByID(id)
    return JOBS[id]
end

function FormatMoney(amount)
    return "$" .. string.Comma(math.floor(amount))
end

function FormatAlloy(amount)
    return string.Comma(math.floor(amount)) .. " Alloy"
end

function FormatCurrency(amount, currencyType)
    if currencyType == CURRENCY_CREDITS then
        return FormatMoney(amount)
    else
        return FormatAlloy(amount)
    end
end

if not string.Comma then
    function string.Comma(number)
        local formatted = tostring(math.floor(number))
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end
end
