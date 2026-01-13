--[[
    Frontier Colony - Custom Vehicles
    Purchasable vehicles for the F4 menu
]]

-- Note: DarkRP.createVehicle uses the vehicle ID from the Vehicles table
-- These must match entries in the game's vehicle list

DarkRP.createVehicle("Colony Rover", {
    price = 2500,
    model = "models/buggy.mdl",
    label = "Colony Rover",
    VehicleScriptName = "Jeep",
    category = "Land Vehicles"
})

DarkRP.createVehicle("Hover Skiff", {
    price = 3500,
    model = "models/airboat.mdl",
    label = "Hover Skiff",
    VehicleScriptName = "Airboat",
    category = "Land Vehicles"
})

DarkRP.createVehicle("Transport Pod", {
    price = 1500,
    model = "models/vehicles/prisoner_pod.mdl",
    label = "Transport Pod",
    VehicleScriptName = "Prisoner_Pod",
    category = "Land Vehicles"
})

--[[
    VEHICLE CATEGORIES
]]

DarkRP.createCategory{
    name = "Land Vehicles",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(100, 150, 200),
    canSee = function(ply) return true end,
    sortOrder = 1
}
