--[[
    Frontier Colony - Shared Configuration
    Colony system settings shared between server and client
]]

FRONTIER = FRONTIER or {}

-- Colony resource limits
FRONTIER.Config = {
    -- Resource maximums
    MaxPower = 1000,
    MaxFood = 500,
    MaxShields = 100,
    MaxMorale = 100,

    -- Drain rates (per minute)
    PowerDrain = 3,
    FoodDrain = 1,
    ShieldDrain = 0,  -- Shields only drain during attacks

    -- Starting values
    StartPower = 500,
    StartFood = 250,
    StartShields = 50,
    StartMorale = 75,

    -- Resource gathering amounts
    OreBaseReward = 25,
    PowerBaseReward = 30,
    FoodBaseReward = 20,

    -- Attack settings
    AttackMinInterval = 300,  -- 5 minutes minimum between attacks
    AttackMaxInterval = 600,  -- 10 minutes maximum
    AttackWaveSize = 3,       -- Base number of enemies per wave
    AttackDamageToShields = 10,

    -- Morale effects
    MoraleBoostOnAttackWin = 10,
    MoraleLossOnAttackFail = 15,
    MoraleLossOnDeath = 5,

    -- Job bonus multiplier (added to base 1.0)
    JobBonusMultiplier = 0.5,
}

-- Job bonus definitions
FRONTIER.JobBonuses = {
    ["miner"] = {
        resourceType = "ore",
        bonus = 0.5,
        description = "+50% ore when mining"
    },
    ["engineer"] = {
        resourceType = "power",
        bonus = 0.5,
        description = "+50% power contribution"
    },
    ["farmer"] = {
        resourceType = "food",
        bonus = 0.5,
        description = "+50% food when harvesting"
    },
    ["security"] = {
        damageBonus = 0.25,
        armorBonus = 0.2,
        description = "+25% damage, -20% damage taken"
    },
}

-- Resource node models
FRONTIER.NodeModels = {
    ore = "models/props_lab/reciever01d.mdl",
    power = "models/props_combine/combine_generator01.mdl",
    food = "models/props_junk/PlasticCrate01a.mdl",
}

-- Alien enemy types
FRONTIER.EnemyTypes = {
    {
        name = "Drone",
        model = "models/combine_scanner.mdl",
        health = 50,
        damage = 10,
        speed = 200,
    },
    {
        name = "Soldier",
        model = "models/combine_soldier.mdl",
        health = 100,
        damage = 20,
        speed = 150,
    },
    {
        name = "Heavy",
        model = "models/combine_soldier_prisonguard.mdl",
        health = 200,
        damage = 35,
        speed = 100,
    },
}
