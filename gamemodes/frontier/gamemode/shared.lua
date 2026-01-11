--[[
    Frontier Colony - Shared Configuration
    A cooperative space colony survival RPG

    Objective: Work together to keep your colony thriving on an alien world.
    Earn Credits from your job, gather Alloy from the environment, and defend
    against periodic alien attacks.
]]

GM.Name = "Frontier Colony"
GM.Author = "Claude"
GM.Email = ""
GM.Website = ""

--[[
    CURRENCY SYSTEM

    Credits (₵) - Personal currency
        - Earned from job paychecks
        - Used for personal equipment, weapons, food, cosmetics

    Alloy (◆) - Colony resource
        - Earned from mining nodes and salvage
        - Used for colony upgrades, repairs, and defenses
]]

CURRENCY_CREDITS = 1
CURRENCY_ALLOY = 2

CURRENCY_SYMBOLS = {
    [CURRENCY_CREDITS] = "₵",
    [CURRENCY_ALLOY] = "◆"
}

CURRENCY_NAMES = {
    [CURRENCY_CREDITS] = "Credits",
    [CURRENCY_ALLOY] = "Alloy"
}

CURRENCY_COLORS = {
    [CURRENCY_CREDITS] = Color(100, 220, 100),
    [CURRENCY_ALLOY] = Color(180, 130, 255)
}

-- Starting currency for new players
STARTING_CREDITS = 500
STARTING_ALLOY = 50

--[[
    JOB SYSTEM

    Each job has:
    - name: Display name
    - description: What the job does
    - color: Job color for UI
    - salary: Credits earned per paycheck
    - alloyBonus: Bonus Alloy percentage when gathering
    - abilities: Special abilities unlocked
    - model: Player model for this job
    - weapons: Starting weapons
]]

JOBS = {
    [1] = {
        id = 1,
        name = "Colonist",
        description = "A basic colonist. Jack of all trades, master of none.",
        color = Color(150, 150, 150),
        salary = 50,
        alloyBonus = 0,
        abilities = {},
        model = "models/player/group01/male_01.mdl",
        weapons = {"weapon_crowbar"},
        maxPlayers = 0 -- Unlimited
    },
    [2] = {
        id = 2,
        name = "Miner",
        description = "Expert at extracting resources. +25% Alloy from mining.",
        color = Color(180, 120, 60),
        salary = 60,
        alloyBonus = 25,
        abilities = {"mining_boost"},
        model = "models/player/group03/male_01.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 4
    },
    [3] = {
        id = 3,
        name = "Engineer",
        description = "Repairs colony systems and builds defenses. Can repair faster.",
        color = Color(255, 180, 50),
        salary = 75,
        alloyBonus = 0,
        abilities = {"fast_repair", "build_turret"},
        model = "models/player/group03/male_04.mdl",
        weapons = {"weapon_crowbar", "weapon_smg1"},
        maxPlayers = 3
    },
    [4] = {
        id = 4,
        name = "Medic",
        description = "Heals injured colonists. Can revive downed players.",
        color = Color(100, 200, 255),
        salary = 70,
        alloyBonus = 0,
        abilities = {"heal_boost", "revive"},
        model = "models/player/group03/female_01.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 2
    },
    [5] = {
        id = 5,
        name = "Security",
        description = "Protects the colony from threats. Combat bonus damage.",
        color = Color(255, 80, 80),
        salary = 85,
        alloyBonus = 0,
        abilities = {"combat_bonus", "armor_boost"},
        model = "models/player/combine_soldier.mdl",
        weapons = {"weapon_smg1", "weapon_shotgun", "weapon_pistol"},
        maxPlayers = 3
    },
    [6] = {
        id = 6,
        name = "Scientist",
        description = "Researches upgrades for the colony. Passive XP boost for all.",
        color = Color(200, 100, 255),
        salary = 65,
        alloyBonus = 0,
        abilities = {"research", "xp_boost"},
        model = "models/player/group03/female_06.mdl",
        weapons = {"weapon_crowbar", "weapon_pistol"},
        maxPlayers = 2
    },
    [7] = {
        id = 7,
        name = "Farmer",
        description = "Grows food to sustain the colony. Colony food production bonus.",
        color = Color(80, 200, 80),
        salary = 55,
        alloyBonus = 10,
        abilities = {"food_boost", "plant_crops"},
        model = "models/player/group01/female_01.mdl",
        weapons = {"weapon_crowbar"},
        maxPlayers = 2
    }
}

-- Default job when joining
DEFAULT_JOB = 1

--[[
    COLONY SYSTEM

    The colony has vital systems that players must maintain:
    - Power: Runs everything, drains over time
    - Food: Keeps colonists healthy, consumed over time
    - Shields: Protects from alien attacks
    - Morale: Affects productivity and earnings
]]

COLONY_MAX_POWER = 1000
COLONY_MAX_FOOD = 500
COLONY_MAX_SHIELDS = 100
COLONY_MAX_MORALE = 100

-- Drain rates per minute
COLONY_POWER_DRAIN = 5
COLONY_FOOD_DRAIN = 2

--[[
    TIMING
]]

PAYCHECK_INTERVAL = 300 -- 5 minutes between paychecks
ALIEN_ATTACK_MIN_INTERVAL = 600 -- Minimum 10 minutes between attacks
ALIEN_ATTACK_MAX_INTERVAL = 900 -- Maximum 15 minutes

--[[
    ECONOMY
]]

-- Shop items (for credits)
SHOP_ITEMS = {
    {id = "health_kit", name = "Health Kit", price = 100, currency = CURRENCY_CREDITS, description = "Restores 50 health"},
    {id = "armor", name = "Body Armor", price = 250, currency = CURRENCY_CREDITS, description = "+50 armor protection"},
    {id = "pistol_ammo", name = "Pistol Ammo", price = 25, currency = CURRENCY_CREDITS, description = "20 rounds of pistol ammo"},
    {id = "smg_ammo", name = "SMG Ammo", price = 40, currency = CURRENCY_CREDITS, description = "45 rounds of SMG ammo"},
    {id = "shotgun_ammo", name = "Shotgun Ammo", price = 50, currency = CURRENCY_CREDITS, description = "12 shotgun shells"},
    {id = "flashlight", name = "Flashlight", price = 75, currency = CURRENCY_CREDITS, description = "A portable flashlight"},
}

-- Colony upgrades (for alloy)
COLONY_UPGRADES = {
    {id = "power_gen", name = "Power Generator", price = 200, currency = CURRENCY_ALLOY, description = "Restores 200 colony power"},
    {id = "food_crate", name = "Food Supplies", price = 100, currency = CURRENCY_ALLOY, description = "Restores 100 colony food"},
    {id = "shield_boost", name = "Shield Capacitor", price = 150, currency = CURRENCY_ALLOY, description = "Restores 25 colony shields"},
    {id = "turret", name = "Defense Turret", price = 300, currency = CURRENCY_ALLOY, description = "Builds an automated turret"},
}

--[[
    LEVELING SYSTEM
]]

XP_PER_LEVEL = 1000
MAX_LEVEL = 50

function CalculateLevel(xp)
    return math.floor(xp / XP_PER_LEVEL) + 1
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
    util.AddNetworkString("Frontier_ChatCommand")
end

--[[
    SHARED UTILITIES
]]

function GetJobByID(id)
    return JOBS[id]
end

function FormatCurrency(amount, currencyType)
    local symbol = CURRENCY_SYMBOLS[currencyType] or "$"
    return symbol .. string.Comma(math.floor(amount))
end

-- Make string.Comma available if not present
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
