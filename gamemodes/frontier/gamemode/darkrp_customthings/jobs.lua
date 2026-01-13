--[[
    Frontier Colony - Custom Jobs
    Using DarkRP.createJob syntax
]]

--[[
    COLONIST (Default citizen replacement)
    Basic colonist with no special abilities
]]
TEAM_COLONIST = DarkRP.createJob("Colonist", {
    color = Color(180, 180, 180),
    model = {"models/player/group01/male_01.mdl", "models/player/group01/male_02.mdl", "models/player/group01/female_01.mdl"},
    description = [[A new arrival to the colony.
    Basic pay, no special bonuses.
    This is the default starting job.]],
    weapons = {},
    command = "colonist",
    max = 0,
    salary = 50,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Colonists"
})

--[[
    MINER
    Extracts resources from ore nodes - +50% ore rewards
]]
TEAM_MINER = DarkRP.createJob("Miner", {
    color = Color(200, 140, 60),
    model = "models/player/group03/male_01.mdl",
    description = [[Extracts valuable minerals from ore deposits.
    +50% bonus rewards when mining ore nodes.
    Essential for gathering Alloy resources.]],
    weapons = {"weapon_crowbar"},
    command = "miner",
    max = 4,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Workers",

    -- Custom field for our job bonus system
    frontierBonus = "miner"
})

--[[
    ENGINEER
    Maintains colony power systems - +50% power contribution
]]
TEAM_ENGINEER = DarkRP.createJob("Engineer", {
    color = Color(255, 200, 60),
    model = "models/player/group03/male_04.mdl",
    description = [[Maintains power generators and infrastructure.
    +50% bonus when contributing to colony power.
    Can repair and upgrade colony systems.]],
    weapons = {"weapon_crowbar", "weapon_pistol"},
    command = "engineer",
    max = 3,
    salary = 85,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Workers",

    frontierBonus = "engineer"
})

--[[
    FARMER
    Grows food for the colony - +50% food contribution
]]
TEAM_FARMER = DarkRP.createJob("Farmer", {
    color = Color(100, 180, 60),
    model = "models/player/group01/female_01.mdl",
    description = [[Cultivates crops to feed the colony.
    +50% bonus when harvesting food.
    Keeps the colony from starving.]],
    weapons = {},
    command = "farmer",
    max = 3,
    salary = 55,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Workers",

    frontierBonus = "farmer"
})

--[[
    MEDIC
    Heals colonists - Can sell medical supplies
]]
TEAM_MEDIC = DarkRP.createJob("Medic", {
    color = Color(80, 180, 255),
    model = "models/player/group03/female_01.mdl",
    description = [[Provides medical care to colonists.
    Can heal injured players.
    Has access to medical supplies.]],
    weapons = {"med_kit"},
    command = "medic",
    max = 2,
    salary = 75,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Services",
    medic = true,  -- DarkRP built-in medic functionality
})

--[[
    SECURITY
    Protects the colony - Combat bonuses
]]
TEAM_SECURITY = DarkRP.createJob("Security", {
    color = Color(220, 60, 60),
    model = {"models/player/combine_soldier.mdl", "models/player/combine_soldier_prisonguard.mdl"},
    description = [[Protects colonists from hostile threats.
    +25% damage dealt, -20% damage taken.
    Armed and ready for alien attacks.]],
    weapons = {"arrest_stick", "unarrest_stick", "weapon_pistol", "weapon_stunstick"},
    command = "security",
    max = 4,
    salary = 100,
    admin = 0,
    vote = false,
    hasLicense = true,
    category = "Protection",

    frontierBonus = "security"
})

--[[
    SECURITY CHIEF
    Leads security forces
]]
TEAM_CHIEF = DarkRP.createJob("Security Chief", {
    color = Color(180, 40, 40),
    model = "models/player/combine_soldier_prisonguard.mdl",
    description = [[Commands the colony security forces.
    Has access to heavier weapons.
    Coordinates defense during attacks.]],
    weapons = {"arrest_stick", "unarrest_stick", "weapon_pistol", "weapon_smg1", "weapon_stunstick"},
    command = "chief",
    max = 1,
    salary = 125,
    admin = 0,
    vote = true,
    hasLicense = true,
    category = "Protection",
    chief = true,

    frontierBonus = "security"
})

--[[
    SCIENTIST
    Researches upgrades - Passive colony bonuses
]]
TEAM_SCIENTIST = DarkRP.createJob("Scientist", {
    color = Color(180, 80, 220),
    model = "models/player/group03/female_06.mdl",
    description = [[Researches new technologies for the colony.
    Provides passive efficiency bonuses.
    Can analyze alien specimens.]],
    weapons = {},
    command = "scientist",
    max = 2,
    salary = 70,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Services",
})

--[[
    MAYOR / COLONY DIRECTOR
    Manages the colony
]]
TEAM_DIRECTOR = DarkRP.createJob("Colony Director", {
    color = Color(255, 215, 0),
    model = "models/player/breen.mdl",
    description = [[Manages all colony operations.
    Can set colony-wide policies.
    Distributes resources during emergencies.]],
    weapons = {},
    command = "director",
    max = 1,
    salary = 150,
    admin = 0,
    vote = true,
    hasLicense = false,
    category = "Government",
    mayor = true,  -- DarkRP built-in mayor functionality

    -- Mayor/Director specific
    PlayerDeath = function(ply, weapon, killer)
        ply:teamBan()
        ply:changeTeam(TEAM_COLONIST, true)
        DarkRP.notifyAll(0, 4, "The Colony Director has died!")
    end
})

--[[
    GUN DEALER
    Sells weapons to colonists
]]
TEAM_GUNDEALER = DarkRP.createJob("Arms Dealer", {
    color = Color(139, 69, 19),
    model = "models/player/group03/male_07.mdl",
    description = [[Sells weapons and ammunition.
    Essential for colony defense.
    Can set up a weapon shop.]],
    weapons = {},
    command = "gundealer",
    max = 2,
    salary = 45,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Services",
})

--[[
    CATEGORIES
]]
DarkRP.createCategory{
    name = "Colonists",
    categorises = "jobs",
    startExpanded = true,
    color = Color(180, 180, 180),
    canSee = function(ply) return true end,
    sortOrder = 1
}

DarkRP.createCategory{
    name = "Workers",
    categorises = "jobs",
    startExpanded = true,
    color = Color(200, 150, 60),
    canSee = function(ply) return true end,
    sortOrder = 2
}

DarkRP.createCategory{
    name = "Services",
    categorises = "jobs",
    startExpanded = true,
    color = Color(80, 180, 220),
    canSee = function(ply) return true end,
    sortOrder = 3
}

DarkRP.createCategory{
    name = "Protection",
    categorises = "jobs",
    startExpanded = true,
    color = Color(220, 80, 80),
    canSee = function(ply) return true end,
    sortOrder = 4
}

DarkRP.createCategory{
    name = "Government",
    categorises = "jobs",
    startExpanded = true,
    color = Color(255, 215, 0),
    canSee = function(ply) return true end,
    sortOrder = 5
}

--[[
    SET DEFAULTS
]]
GAMEMODE.DefaultTeam = TEAM_COLONIST

GAMEMODE.CivilProtection = {
    [TEAM_SECURITY] = true,
    [TEAM_CHIEF] = true,
}
