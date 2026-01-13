--[[
    Frontier Colony - Custom Entities
    Purchasable entities for the F4 menu
]]

--[[
    RESOURCE GATHERERS
    These spawn nodes that players can harvest
]]

DarkRP.createEntity("Portable Mining Drill", {
    ent = "frontier_ore_node",
    model = "models/props_lab/reciever01d.mdl",
    price = 500,
    max = 2,
    cmd = "buydrill",
    allowed = {TEAM_MINER},
    category = "Resource Equipment"
})

DarkRP.createEntity("Portable Generator", {
    ent = "frontier_generator",
    model = "models/props_vehicles/generatortrailer01.mdl",
    price = 750,
    max = 1,
    cmd = "buygenerator",
    allowed = {TEAM_ENGINEER},
    category = "Resource Equipment"
})

DarkRP.createEntity("Hydroponic Planter", {
    ent = "frontier_crop_node",
    model = "models/props_junk/garbage_plasticbottle003a.mdl",
    price = 400,
    max = 3,
    cmd = "buyplanter",
    allowed = {TEAM_FARMER},
    category = "Resource Equipment"
})

--[[
    DEFENSE ITEMS
]]

DarkRP.createEntity("Defense Turret", {
    ent = "frontier_turret",
    model = "models/combine_turrets/floor_turret.mdl",
    price = 2500,
    max = 2,
    cmd = "buyturret",
    allowed = {TEAM_SECURITY, TEAM_CHIEF, TEAM_DIRECTOR},
    category = "Defense"
})

DarkRP.createEntity("Barricade", {
    ent = "prop_physics",
    model = "models/props_c17/concrete_barrier001a.mdl",
    price = 200,
    max = 5,
    cmd = "buybarricade",
    allowed = {TEAM_SECURITY, TEAM_CHIEF},
    category = "Defense"
})

--[[
    COLONY UPGRADES
    These affect colony-wide stats
]]

DarkRP.createEntity("Power Cell Crate", {
    ent = "frontier_power_crate",
    model = "models/items/car_battery01.mdl",
    price = 300,
    max = 3,
    cmd = "buypowercell",
    category = "Colony Supplies"
})

DarkRP.createEntity("Food Supply Crate", {
    ent = "frontier_food_crate",
    model = "models/props_junk/wood_crate001a.mdl",
    price = 200,
    max = 3,
    cmd = "buyfoodcrate",
    category = "Colony Supplies"
})

DarkRP.createEntity("Shield Capacitor", {
    ent = "frontier_shield_crate",
    model = "models/props_lab/reciever01b.mdl",
    price = 500,
    max = 2,
    cmd = "buyshieldcap",
    category = "Colony Supplies"
})

--[[
    MEDICAL SUPPLIES
]]

DarkRP.createEntity("Medical Kit", {
    ent = "item_healthkit",
    model = "models/items/healthkit.mdl",
    price = 150,
    max = 5,
    cmd = "buymedkit",
    allowed = {TEAM_MEDIC},
    category = "Medical"
})

--[[
    ENTITY CATEGORIES
]]

DarkRP.createCategory{
    name = "Resource Equipment",
    categorises = "entities",
    startExpanded = true,
    color = Color(200, 150, 60),
    canSee = function(ply) return true end,
    sortOrder = 1
}

DarkRP.createCategory{
    name = "Colony Supplies",
    categorises = "entities",
    startExpanded = true,
    color = Color(80, 180, 220),
    canSee = function(ply) return true end,
    sortOrder = 2
}

DarkRP.createCategory{
    name = "Defense",
    categorises = "entities",
    startExpanded = true,
    color = Color(220, 80, 80),
    canSee = function(ply) return true end,
    sortOrder = 3
}

DarkRP.createCategory{
    name = "Medical",
    categorises = "entities",
    startExpanded = true,
    color = Color(80, 220, 120),
    canSee = function(ply) return true end,
    sortOrder = 4
}
