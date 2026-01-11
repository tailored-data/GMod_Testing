--[[
    Frontier Colony - Client HUD
    Beautiful, modern UI with all player and colony information
]]

-- Local player data cache
local LocalData = {
    credits = 0,
    alloy = 0,
    job = 1,
    xp = 0,
    level = 1
}

-- Colony data cache
local ColonyData = {
    power = 1000,
    food = 500,
    shields = 100,
    morale = 100,
    isUnderAttack = false,
    attackWave = 0,
    prosperity = 0
}

-- Notification queue
local Notifications = {}

-- UI Colors (modern dark theme)
local COLORS = {
    bg = Color(15, 15, 20, 240),
    bgLight = Color(25, 25, 35, 240),
    bgLighter = Color(35, 35, 50, 240),
    accent = Color(80, 150, 255),
    accentDark = Color(50, 100, 180),
    text = Color(240, 240, 245),
    textDim = Color(150, 150, 160),
    success = Color(80, 220, 120),
    warning = Color(255, 200, 80),
    danger = Color(255, 80, 80),
    credits = Color(100, 220, 100),
    alloy = Color(180, 130, 255),
    health = Color(220, 60, 60),
    armor = Color(60, 140, 220),
    power = Color(255, 220, 80),
    food = Color(120, 200, 80),
    shields = Color(80, 180, 255),
    morale = Color(255, 150, 200)
}

-- Custom fonts
surface.CreateFont("Frontier_Title", {
    font = "Roboto",
    size = 36,
    weight = 700,
    antialias = true,
})

surface.CreateFont("Frontier_Large", {
    font = "Roboto",
    size = 28,
    weight = 600,
    antialias = true,
})

surface.CreateFont("Frontier_Medium", {
    font = "Roboto",
    size = 22,
    weight = 500,
    antialias = true,
})

surface.CreateFont("Frontier_Small", {
    font = "Roboto",
    size = 18,
    weight = 400,
    antialias = true,
})

surface.CreateFont("Frontier_Tiny", {
    font = "Roboto",
    size = 14,
    weight = 400,
    antialias = true,
})

surface.CreateFont("Frontier_Icon", {
    font = "Marlett",
    size = 24,
    weight = 400,
    antialias = true,
})

-- Receive player data
net.Receive("Frontier_PlayerData", function()
    LocalData.credits = net.ReadInt(32)
    LocalData.alloy = net.ReadInt(32)
    LocalData.job = net.ReadInt(8)
    LocalData.xp = net.ReadInt(32)
    LocalData.level = net.ReadInt(8)
end)

-- Receive colony data
net.Receive("Frontier_ColonyData", function()
    ColonyData.power = net.ReadFloat()
    ColonyData.food = net.ReadFloat()
    ColonyData.shields = net.ReadFloat()
    ColonyData.morale = net.ReadFloat()
    ColonyData.isUnderAttack = net.ReadBool()
    ColonyData.attackWave = net.ReadInt(16)
    ColonyData.prosperity = net.ReadInt(32)
end)

-- Receive notifications
net.Receive("Frontier_Notification", function()
    local title = net.ReadString()
    local message = net.ReadString()
    local color = net.ReadColor()
    local duration = net.ReadFloat()

    table.insert(Notifications, {
        title = title,
        message = message,
        color = color,
        startTime = CurTime(),
        duration = duration
    })

    surface.PlaySound("buttons/button14.wav")
end)

-- Draw a rounded box with gradient
local function DrawGradientBox(x, y, w, h, radius, col1, col2)
    draw.RoundedBox(radius, x, y, w, h, col1)
    -- Subtle gradient overlay
    surface.SetDrawColor(col2.r, col2.g, col2.b, 30)
    surface.DrawRect(x, y + h/2, w, h/2)
end

-- Draw a progress bar with glow
local function DrawProgressBar(x, y, w, h, progress, color, bgColor)
    progress = math.Clamp(progress, 0, 1)

    -- Background
    draw.RoundedBox(h/2, x, y, w, h, bgColor or COLORS.bg)

    -- Fill
    if progress > 0 then
        local fillWidth = math.max(h, (w - 4) * progress)
        draw.RoundedBox(h/2 - 1, x + 2, y + 2, fillWidth, h - 4, color)

        -- Glow effect
        surface.SetDrawColor(color.r, color.g, color.b, 50)
        surface.DrawRect(x + 2, y + 2, fillWidth, (h - 4) / 2)
    end
end

-- Draw an icon with a circle background
local function DrawIconCircle(x, y, radius, icon, bgColor, iconColor)
    draw.NoTexture()
    surface.SetDrawColor(bgColor)
    draw.Circle(x, y, radius, 32)

    draw.SimpleText(icon, "Frontier_Icon", x, y, iconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Simple circle function
function draw.Circle(x, y, radius, segments)
    local circle = {}
    for i = 0, segments do
        local angle = math.rad((i / segments) * 360)
        table.insert(circle, {x = x + math.cos(angle) * radius, y = y + math.sin(angle) * radius})
    end
    surface.DrawPoly(circle)
end

-- Main HUD Paint
function GM:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local scrW, scrH = ScrW(), ScrH()

    -- Draw all HUD elements
    self:DrawPlayerStatus(ply, scrW, scrH)
    self:DrawCurrencyPanel(scrW, scrH)
    self:DrawColonyPanel(scrW, scrH)
    self:DrawNotifications(scrW, scrH)

    -- Attack warning overlay
    if ColonyData.isUnderAttack then
        self:DrawAttackWarning(scrW, scrH)
    end
end

-- Player status (health, armor, job)
function GM:DrawPlayerStatus(ply, scrW, scrH)
    local panelW, panelH = 320, 100
    local panelX, panelY = 20, scrH - panelH - 20

    -- Background panel
    draw.RoundedBox(12, panelX, panelY, panelW, panelH, COLORS.bg)
    draw.RoundedBox(12, panelX, panelY, panelW, 3, COLORS.accent)

    -- Job name
    local job = GetJobByID(LocalData.job) or JOBS[1]
    draw.SimpleText(job.name, "Frontier_Medium", panelX + 15, panelY + 12, job.color)

    -- Level badge
    local levelX = panelX + panelW - 50
    draw.RoundedBox(6, levelX, panelY + 8, 40, 24, COLORS.accent)
    draw.SimpleText("Lv." .. LocalData.level, "Frontier_Small", levelX + 20, panelY + 20, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Health bar
    local barY = panelY + 42
    draw.SimpleText("HP", "Frontier_Tiny", panelX + 15, barY + 6, COLORS.textDim)
    DrawProgressBar(panelX + 45, barY, 200, 16, ply:Health() / ply:GetMaxHealth(), COLORS.health, COLORS.bgLight)
    draw.SimpleText(ply:Health(), "Frontier_Tiny", panelX + 250, barY + 6, COLORS.text)

    -- Armor bar
    barY = panelY + 64
    draw.SimpleText("AP", "Frontier_Tiny", panelX + 15, barY + 6, COLORS.textDim)
    DrawProgressBar(panelX + 45, barY, 200, 16, ply:Armor() / 100, COLORS.armor, COLORS.bgLight)
    draw.SimpleText(ply:Armor(), "Frontier_Tiny", panelX + 250, barY + 6, COLORS.text)

    -- XP bar (small, under panel)
    local xpProgress = XPProgress(LocalData.xp)
    DrawProgressBar(panelX, panelY + panelH + 5, panelW, 8, xpProgress, COLORS.accent, COLORS.bgLight)
end

-- Currency panel (top right)
function GM:DrawCurrencyPanel(scrW, scrH)
    local panelW, panelH = 200, 70
    local panelX = scrW - panelW - 20
    local panelY = 20

    -- Background
    draw.RoundedBox(12, panelX, panelY, panelW, panelH, COLORS.bg)

    -- Credits
    draw.SimpleText(CURRENCY_SYMBOLS[CURRENCY_CREDITS], "Frontier_Large", panelX + 20, panelY + 18, COLORS.credits)
    draw.SimpleText(string.Comma(LocalData.credits), "Frontier_Medium", panelX + 50, panelY + 16, COLORS.text)

    -- Alloy
    draw.SimpleText(CURRENCY_SYMBOLS[CURRENCY_ALLOY], "Frontier_Large", panelX + 20, panelY + 44, COLORS.alloy)
    draw.SimpleText(string.Comma(LocalData.alloy), "Frontier_Medium", panelX + 50, panelY + 42, COLORS.text)
end

-- Colony status panel (top center)
function GM:DrawColonyPanel(scrW, scrH)
    local panelW, panelH = 400, 90
    local panelX = (scrW - panelW) / 2
    local panelY = 20

    -- Background
    draw.RoundedBox(12, panelX, panelY, panelW, panelH, COLORS.bg)

    -- Title
    draw.SimpleText("COLONY STATUS", "Frontier_Small", panelX + panelW/2, panelY + 12, COLORS.textDim, TEXT_ALIGN_CENTER)

    -- Prosperity score
    draw.SimpleText("Prosperity: " .. string.Comma(ColonyData.prosperity), "Frontier_Tiny", panelX + panelW/2, panelY + panelH - 12, COLORS.accent, TEXT_ALIGN_CENTER)

    -- Resource bars
    local barW = 85
    local barH = 12
    local barY = panelY + 35
    local startX = panelX + 15

    -- Power
    draw.SimpleText("PWR", "Frontier_Tiny", startX, barY - 12, COLORS.power)
    DrawProgressBar(startX, barY, barW, barH, ColonyData.power / COLONY_MAX_POWER, COLORS.power, COLORS.bgLight)

    -- Food
    startX = startX + barW + 15
    draw.SimpleText("FOOD", "Frontier_Tiny", startX, barY - 12, COLORS.food)
    DrawProgressBar(startX, barY, barW, barH, ColonyData.food / COLONY_MAX_FOOD, COLORS.food, COLORS.bgLight)

    -- Shields
    startX = startX + barW + 15
    draw.SimpleText("SHLD", "Frontier_Tiny", startX, barY - 12, COLORS.shields)
    DrawProgressBar(startX, barY, barW, barH, ColonyData.shields / COLONY_MAX_SHIELDS, COLORS.shields, COLORS.bgLight)

    -- Morale
    startX = startX + barW + 15
    draw.SimpleText("MRL", "Frontier_Tiny", startX, barY - 12, COLORS.morale)
    DrawProgressBar(startX, barY, barW, barH, ColonyData.morale / 100, COLORS.morale, COLORS.bgLight)

    -- Morale percentage affects display
    local moraleColor = COLORS.success
    if ColonyData.morale < 50 then
        moraleColor = COLORS.warning
    elseif ColonyData.morale < 25 then
        moraleColor = COLORS.danger
    end

    -- Numeric values below
    barY = barY + barH + 4
    startX = panelX + 15
    draw.SimpleText(math.floor(ColonyData.power), "Frontier_Tiny", startX + barW/2, barY, COLORS.textDim, TEXT_ALIGN_CENTER)
    startX = startX + barW + 15
    draw.SimpleText(math.floor(ColonyData.food), "Frontier_Tiny", startX + barW/2, barY, COLORS.textDim, TEXT_ALIGN_CENTER)
    startX = startX + barW + 15
    draw.SimpleText(math.floor(ColonyData.shields) .. "%", "Frontier_Tiny", startX + barW/2, barY, COLORS.textDim, TEXT_ALIGN_CENTER)
    startX = startX + barW + 15
    draw.SimpleText(math.floor(ColonyData.morale) .. "%", "Frontier_Tiny", startX + barW/2, barY, moraleColor, TEXT_ALIGN_CENTER)
end

-- Notifications (right side)
function GM:DrawNotifications(scrW, scrH)
    local notifW, notifH = 300, 70
    local startX = scrW - notifW - 20
    local startY = 110

    -- Remove expired notifications
    for i = #Notifications, 1, -1 do
        if CurTime() - Notifications[i].startTime > Notifications[i].duration then
            table.remove(Notifications, i)
        end
    end

    -- Draw notifications
    for i, notif in ipairs(Notifications) do
        local elapsed = CurTime() - notif.startTime
        local alpha = 1

        -- Fade in/out
        if elapsed < 0.3 then
            alpha = elapsed / 0.3
        elseif elapsed > notif.duration - 0.5 then
            alpha = (notif.duration - elapsed) / 0.5
        end

        local y = startY + (i - 1) * (notifH + 10)

        -- Slide in animation
        local slideX = startX
        if elapsed < 0.3 then
            slideX = startX + (1 - alpha) * 50
        end

        -- Background
        local bgColor = Color(COLORS.bg.r, COLORS.bg.g, COLORS.bg.b, COLORS.bg.a * alpha)
        draw.RoundedBox(10, slideX, y, notifW, notifH, bgColor)

        -- Accent bar
        local accentColor = Color(notif.color.r, notif.color.g, notif.color.b, 255 * alpha)
        draw.RoundedBox(10, slideX, y, 4, notifH, accentColor)

        -- Title
        local titleColor = Color(notif.color.r, notif.color.g, notif.color.b, 255 * alpha)
        draw.SimpleText(notif.title, "Frontier_Medium", slideX + 15, y + 12, titleColor)

        -- Message
        local msgColor = Color(COLORS.text.r, COLORS.text.g, COLORS.text.b, 255 * alpha)
        draw.SimpleText(notif.message, "Frontier_Small", slideX + 15, y + 40, msgColor)
    end
end

-- Attack warning overlay
function GM:DrawAttackWarning(scrW, scrH)
    local pulse = math.abs(math.sin(CurTime() * 3))

    -- Red vignette
    surface.SetDrawColor(255, 0, 0, 30 + pulse * 30)
    surface.DrawRect(0, 0, scrW, 100)
    surface.DrawRect(0, scrH - 100, scrW, 100)
    surface.DrawRect(0, 0, 100, scrH)
    surface.DrawRect(scrW - 100, 0, 100, scrH)

    -- Warning text
    local warningY = 130
    local alpha = 180 + pulse * 75

    draw.SimpleText("!! ALIEN ATTACK !!", "Frontier_Title", scrW/2, warningY,
        Color(255, 50, 50, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Wave " .. ColonyData.attackWave .. " - Defend the Colony!", "Frontier_Medium", scrW/2, warningY + 40,
        Color(255, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Hide default HUD elements
function GM:HUDShouldDraw(name)
    local hide = {
        ["CHudHealth"] = true,
        ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
        ["CHudSecondaryAmmo"] = true,
        ["CHudSuitPower"] = true,
        ["CHudDamageIndicator"] = true,
    }

    return not hide[name]
end

-- Controls hint (bottom right)
hook.Add("HUDPaint", "Frontier_ControlsHint", function()
    local scrW, scrH = ScrW(), ScrH()

    local hints = {
        "F3 - Shop",
        "F4 - Jobs"
    }

    local y = scrH - 60
    for i, hint in ipairs(hints) do
        draw.SimpleText(hint, "Frontier_Tiny", scrW - 20, y + (i-1) * 18, COLORS.textDim, TEXT_ALIGN_RIGHT)
    end
end)
