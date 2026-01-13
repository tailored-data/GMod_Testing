--[[
    Frontier Colony - Colony HUD (Client)
    Displays colony status on screen
]]

include("modules/colony/sh/config.lua")

FRONTIER.ClientColony = FRONTIER.ClientColony or {}

-- Local colony state (synced from server)
local ColonyState = {
    power = 500,
    food = 250,
    shields = 50,
    morale = 75,
    underAttack = false,
}

-- Tooltip state
local HoveredStat = nil
local TooltipAlpha = 0

--[[
    Network Receivers
]]
net.Receive("Frontier_ColonyUpdate", function()
    ColonyState.power = net.ReadFloat()
    ColonyState.food = net.ReadFloat()
    ColonyState.shields = net.ReadFloat()
    ColonyState.morale = net.ReadFloat()
    ColonyState.underAttack = net.ReadBool()
end)

net.Receive("Frontier_ColonyAttack", function()
    local starting = net.ReadBool()
    local wave = net.ReadInt(8)
    local count = net.ReadInt(8)

    if starting then
        surface.PlaySound("ambient/alarms/warningbell1.wav")
        chat.AddText(Color(255, 50, 50), "[ALERT] ", Color(255, 255, 255), "Wave " .. wave .. " attack incoming! " .. count .. " hostiles detected!")
    else
        surface.PlaySound("buttons/button9.wav")
        chat.AddText(Color(50, 255, 50), "[VICTORY] ", Color(255, 255, 255), "Wave " .. wave .. " defeated! " .. count .. " enemies eliminated!")
    end
end)

net.Receive("Frontier_ResourceGathered", function()
    local resourceType = net.ReadString()
    local amount = net.ReadInt(16)

    surface.PlaySound("items/ammo_pickup.wav")
end)

--[[
    HUD Configuration
]]
local HUDConfig = {
    padding = 16,
    barHeight = 20,
    barWidth = 180,
    cornerRadius = 6,
    font = "DermaDefault",
}

-- Create fonts
surface.CreateFont("FrontierHUD", {
    font = "Arial",
    size = 16,
    weight = 600,
})

surface.CreateFont("FrontierHUDSmall", {
    font = "Arial",
    size = 12,
    weight = 500,
})

surface.CreateFont("FrontierHUDTitle", {
    font = "Arial",
    size = 18,
    weight = 700,
})

--[[
    Stat Tooltips
]]
local StatTooltips = {
    power = {
        title = "Colony Power",
        desc = "Powers colony infrastructure.\nDrains over time.\nEngineers contribute +50%.\nAt 0, colony systems fail."
    },
    food = {
        title = "Food Supply",
        desc = "Feeds all colonists.\nDrains based on population.\nFarmers harvest +50%.\nAt 0, morale drops fast."
    },
    shields = {
        title = "Colony Shields",
        desc = "Protects during attacks.\nAbsorbs enemy damage.\nDrains during combat.\nBuy capacitors to recharge."
    },
    morale = {
        title = "Colony Morale",
        desc = "Overall colony happiness.\nAffected by resources & attacks.\nHigh morale = bonuses.\nLow morale = penalties."
    },
}

--[[
    Draw Rounded Box Helper
]]
local function DrawRoundedBox(x, y, w, h, color, radius)
    draw.RoundedBox(radius or HUDConfig.cornerRadius, x, y, w, h, color)
end

--[[
    Draw Progress Bar
]]
local function DrawProgressBar(x, y, w, h, value, maxValue, color, bgColor)
    -- Background
    DrawRoundedBox(x, y, w, h, bgColor or Color(40, 40, 40, 200))

    -- Progress
    local progress = math.Clamp(value / maxValue, 0, 1)
    local progressWidth = (w - 4) * progress

    if progressWidth > 0 then
        DrawRoundedBox(x + 2, y + 2, progressWidth, h - 4, color, HUDConfig.cornerRadius - 2)
    end

    -- Text
    draw.SimpleText(math.floor(value) .. "/" .. maxValue, "FrontierHUDSmall",
        x + w / 2, y + h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

--[[
    Check Mouse Hover
]]
local function IsMouseOver(x, y, w, h)
    local mx, my = gui.MousePos()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

--[[
    Draw Colony Status HUD
]]
local function DrawColonyHUD()
    local scrW, scrH = ScrW(), ScrH()
    local padding = HUDConfig.padding
    local barW = HUDConfig.barWidth
    local barH = HUDConfig.barHeight

    -- Panel position (top right)
    local panelW = barW + padding * 2
    local panelH = 140
    local panelX = scrW - panelW - padding
    local panelY = padding

    -- Panel background
    DrawRoundedBox(panelX, panelY, panelW, panelH, Color(20, 20, 30, 220))

    -- Title
    local titleY = panelY + padding / 2
    draw.SimpleText("COLONY STATUS", "FrontierHUDTitle",
        panelX + panelW / 2, titleY, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Attack warning
    if ColonyState.underAttack then
        local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
        draw.SimpleText("!! UNDER ATTACK !!", "FrontierHUD",
            panelX + panelW / 2, titleY + 18,
            Color(255, 50, 50, 150 + pulse * 105), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Stats
    local statsY = panelY + 45
    local statSpacing = 24

    -- Reset hovered stat
    HoveredStat = nil

    -- Power
    local powerY = statsY
    draw.SimpleText("Power", "FrontierHUD", panelX + padding, powerY, Color(255, 200, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawProgressBar(panelX + padding, powerY + 8, barW, barH - 4,
        ColonyState.power, FRONTIER.Config.MaxPower, Color(255, 200, 60))
    if IsMouseOver(panelX, powerY, panelW, statSpacing) then HoveredStat = "power" end

    -- Food
    local foodY = statsY + statSpacing
    draw.SimpleText("Food", "FrontierHUD", panelX + padding, foodY, Color(100, 200, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawProgressBar(panelX + padding, foodY + 8, barW, barH - 4,
        ColonyState.food, FRONTIER.Config.MaxFood, Color(100, 200, 60))
    if IsMouseOver(panelX, foodY, panelW, statSpacing) then HoveredStat = "food" end

    -- Shields
    local shieldsY = statsY + statSpacing * 2
    draw.SimpleText("Shields", "FrontierHUD", panelX + padding, shieldsY, Color(80, 150, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawProgressBar(panelX + padding, shieldsY + 8, barW, barH - 4,
        ColonyState.shields, FRONTIER.Config.MaxShields, Color(80, 150, 255))
    if IsMouseOver(panelX, shieldsY, panelW, statSpacing) then HoveredStat = "shields" end

    -- Morale
    local moraleY = statsY + statSpacing * 3
    local moraleColor = ColonyState.morale > 50 and Color(150, 100, 255) or Color(255, 100, 100)
    draw.SimpleText("Morale", "FrontierHUD", panelX + padding, moraleY, moraleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawProgressBar(panelX + padding, moraleY + 8, barW, barH - 4,
        ColonyState.morale, FRONTIER.Config.MaxMorale, moraleColor)
    if IsMouseOver(panelX, moraleY, panelW, statSpacing) then HoveredStat = "morale" end
end

--[[
    Draw Tooltip
]]
local function DrawTooltip()
    if not HoveredStat then
        TooltipAlpha = math.Approach(TooltipAlpha, 0, FrameTime() * 500)
        if TooltipAlpha <= 0 then return end
    else
        TooltipAlpha = math.Approach(TooltipAlpha, 255, FrameTime() * 500)
    end

    local tooltip = StatTooltips[HoveredStat or "power"]
    if not tooltip then return end

    local mx, my = gui.MousePos()
    local padding = 12
    local maxWidth = 200

    -- Calculate text height
    surface.SetFont("FrontierHUDSmall")
    local lines = string.Explode("\n", tooltip.desc)
    local textHeight = #lines * 14 + 22

    local tooltipW = maxWidth + padding * 2
    local tooltipH = textHeight + padding * 2
    local tooltipX = mx - tooltipW - 10
    local tooltipY = my - tooltipH / 2

    -- Keep on screen
    tooltipX = math.max(10, tooltipX)
    tooltipY = math.Clamp(tooltipY, 10, ScrH() - tooltipH - 10)

    -- Background
    local alpha = TooltipAlpha
    DrawRoundedBox(tooltipX, tooltipY, tooltipW, tooltipH, Color(30, 30, 40, alpha * 0.9))
    DrawRoundedBox(tooltipX, tooltipY, tooltipW, 24, Color(50, 50, 70, alpha * 0.9))

    -- Title
    draw.SimpleText(tooltip.title, "FrontierHUD",
        tooltipX + padding, tooltipY + padding / 2,
        Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Description
    local lineY = tooltipY + 28
    for _, line in ipairs(lines) do
        draw.SimpleText(line, "FrontierHUDSmall",
            tooltipX + padding, lineY,
            Color(200, 200, 200, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        lineY = lineY + 14
    end
end

--[[
    Main HUD Hook
]]
hook.Add("HUDPaint", "Frontier_ColonyHUD", function()
    DrawColonyHUD()
    DrawTooltip()
end)

--[[
    Getters for Other Client Scripts
]]
function FRONTIER.ClientColony.GetPower()
    return ColonyState.power
end

function FRONTIER.ClientColony.GetFood()
    return ColonyState.food
end

function FRONTIER.ClientColony.GetShields()
    return ColonyState.shields
end

function FRONTIER.ClientColony.GetMorale()
    return ColonyState.morale
end

function FRONTIER.ClientColony.IsUnderAttack()
    return ColonyState.underAttack
end

print("[Frontier] Client HUD loaded")
