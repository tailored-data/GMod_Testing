--[[
    Frontier Colony - Shared
    A DarkRP-based space colony survival gamemode
]]

GM.Name = "Frontier Colony"
GM.Author = "Claude"
GM.Website = ""

-- Derive from DarkRP
DeriveGamemode("darkrp")

--[[
    COLONY CONFIGURATION
    These are our custom additions on top of DarkRP
]]

-- Colony resource maximums
COLONY_MAX_POWER = 1000
COLONY_MAX_FOOD = 500
COLONY_MAX_SHIELDS = 100

-- Resource drain rates (per minute)
COLONY_POWER_DRAIN = 3
COLONY_FOOD_DRAIN = 1

-- Alien attack timing (seconds)
COLONY_ATTACK_MIN_INTERVAL = 600  -- 10 minutes
COLONY_ATTACK_MAX_INTERVAL = 900  -- 15 minutes

-- Resource node rewards
ORE_ALLOY_REWARD = 50       -- Money from ore nodes
GENERATOR_POWER_REWARD = 50  -- Power added to colony
CROP_FOOD_REWARD = 25        -- Food added to colony
SALVAGE_MONEY_REWARD = 75    -- Money from salvage

-- Resource respawn time
RESOURCE_RESPAWN_TIME = 120  -- 2 minutes

--[[
    JOB BONUSES
    Extra bonuses our jobs provide beyond DarkRP defaults
]]

FRONTIER_JOB_BONUSES = {
    ["miner"] = {resourceBonus = 0.5, type = "ore"},        -- +50% ore rewards
    ["engineer"] = {resourceBonus = 0.5, type = "power"},   -- +50% power contribution
    ["farmer"] = {resourceBonus = 0.5, type = "food"},      -- +50% food contribution
    ["security"] = {damageBonus = 0.25, armorBonus = 0.2},  -- +25% damage, -20% damage taken
}
