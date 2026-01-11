--[[
    Frontier Colony - Client HUD
    Clean, modern UI with proper spacing and tooltips
]]

-- Local data cache
local LocalData = {
    credits = 0,
    alloy = 0,
    job = 1,
    xp = 0,
    level = 1
}

local ColonyData = {
    power = 1000,
    food = 500,
    shields = 100,
    morale = 100,
    isUnderAttack = false,
    attackWave = 0,
    prosperity = 0
}

local Notifications = {}
local HoveredElement = nil

-- UI Theme
local UI = {
    bg = Color(20, 22, 28),
    bgPanel = Color(28, 32, 40),
    bgHover = Color(38, 42, 52),
    border = Color(45, 50, 60),
    accent = Color(90, 140, 220),
    text = Color(230, 232, 240),
    textDim = Color(140, 145, 160),
    textMuted = Color(90, 95, 110),
    success = Color(80, 190, 120),
    warning = Color(230, 180, 60),
    danger = Color(220, 80, 80),
    credits = Color(110, 190, 80),
    alloy = Color(150, 110, 210),
    health = Color(200, 70, 70),
    armor = Color(70, 140, 200),
    power = Color(240, 200, 60),
    food = Color(100, 180, 70),
    shields = Color(80, 160, 220),
    morale = Color(220, 130, 180)
}

-- Padding/spacing constants
local PAD = 12
local PAD_SM = 8
local PAD_XS = 4
local RADIUS = 6

-- Create fonts with fallbacks
local function CreateFonts()
    surface.CreateFont("FrontierUI", {
        font = "Arial",
        size = 16,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("FrontierUI_Bold", {
        font = "Arial",
        size = 16,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("FrontierUI_Small", {
        font = "Arial",
        size = 13,
        weight = 400,
        antialias = true
    })

    surface.CreateFont("FrontierUI_Large", {
        font = "Arial",
        size = 22,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("FrontierUI_Title", {
        font = "Arial",
        size = 28,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("FrontierUI_Tiny", {
        font = "Arial",
        size = 11,
        weight = 400,
        antialias = true
    })
end

CreateFonts()

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
    table.insert(Notifications, {
        title = net.ReadString(),
        message = net.ReadString(),
        color = net.ReadColor(),
        startTime = CurTime(),
        duration = net.ReadFloat()
    })
    surface.PlaySound("buttons/button14.wav")
end)

-- Draw rounded box with optional border
local function DrawPanel(x, y, w, h, bgColor, borderColor)
    draw.RoundedBox(RADIUS, x, y, w, h, bgColor or UI.bgPanel)
    if borderColor then
        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(x, y, w, h, 1)
    end
end

-- Draw progress bar
local function DrawBar(x, y, w, h, progress, color, bgColor)
    progress = math.Clamp(progress, 0, 1)

    -- Background
    draw.RoundedBox(h / 2, x, y, w, h, bgColor or UI.bg)

    -- Fill
    if progress > 0 then
        local fillW = math.max(h, (w - 2) * progress)
        draw.RoundedBox(h / 2, x + 1, y + 1, fillW, h - 2, color)
    end
end

-- Check if mouse is over an area
local function IsMouseOver(x, y, w, h)
    local mx, my = gui.MousePos()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Main HUD Paint
function GM:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local sw, sh = ScrW(), ScrH()

    self:DrawPlayerPanel(ply, sw, sh)
    self:DrawCurrencyPanel(sw, sh)
    self:DrawColonyPanel(sw, sh)
    self:DrawNotifications(sw, sh)
    self:DrawTooltip(sw, sh)

    if ColonyData.isUnderAttack then
        self:DrawAttackWarning(sw, sh)
    end
end

-- Player status panel (bottom left)
function GM:DrawPlayerPanel(ply, sw, sh)
    local w, h = 280, 130
    local x, y = PAD, sh - h - PAD

    DrawPanel(x, y, w, h, UI.bgPanel)

    -- Job header
    local job = GetJobByID(LocalData.job) or JOBS[1]
    local headerH = 32

    draw.RoundedBoxEx(RADIUS, x, y, w, headerH, UI.bg, true, true, false, false)
    draw.SimpleText(job.name, "FrontierUI_Bold", x + PAD, y + headerH / 2, job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Level badge
    local lvlW = 50
    draw.RoundedBox(4, x + w - lvlW - PAD_SM, y + 6, lvlW, 20, UI.accent)
    draw.SimpleText("LVL " .. LocalData.level, "FrontierUI_Small", x + w - lvlW / 2 - PAD_SM, y + 16, UI.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Health section
    local barY = y + headerH + PAD
    local labelW = 24
    local barW = w - PAD * 2 - labelW - PAD_SM - 35
    local barH = 14

    -- Health
    draw.SimpleText("HP", "FrontierUI_Small", x + PAD, barY + barH / 2, UI.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawBar(x + PAD + labelW + PAD_SM, barY, barW, barH, ply:Health() / ply:GetMaxHealth(), UI.health)
    draw.SimpleText(ply:Health(), "FrontierUI_Small", x + w - PAD, barY + barH / 2, UI.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- Armor
    barY = barY + barH + PAD_SM
    draw.SimpleText("AP", "FrontierUI_Small", x + PAD, barY + barH / 2, UI.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawBar(x + PAD + labelW + PAD_SM, barY, barW, barH, ply:Armor() / 100, UI.armor)
    draw.SimpleText(ply:Armor(), "FrontierUI_Small", x + w - PAD, barY + barH / 2, UI.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- XP bar
    barY = barY + barH + PAD
    draw.SimpleText("XP", "FrontierUI_Small", x + PAD, barY + barH / 2, UI.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    DrawBar(x + PAD + labelW + PAD_SM, barY, barW + 35, barH, XPProgress(LocalData.xp), UI.accent)

    -- Keybind hints
    local hintY = y + h - 20
    draw.SimpleText("F3 Shop  |  F4 Jobs", "FrontierUI_Tiny", x + w / 2, hintY, UI.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Currency panel (top right)
function GM:DrawCurrencyPanel(sw, sh)
    local w, h = 160, 70
    local x, y = sw - w - PAD, PAD

    DrawPanel(x, y, w, h, UI.bgPanel)

    -- Credits
    local iconSize = 8
    local rowY = y + PAD + 2

    surface.SetDrawColor(UI.credits)
    surface.DrawRect(x + PAD, rowY + 4, iconSize, iconSize)
    draw.SimpleText(FormatMoney(LocalData.credits), "FrontierUI_Bold", x + PAD + iconSize + PAD_SM, rowY + 6, UI.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Alloy
    rowY = rowY + 26
    surface.SetDrawColor(UI.alloy)
    surface.DrawRect(x + PAD, rowY + 4, iconSize, iconSize)
    draw.SimpleText(string.Comma(LocalData.alloy) .. " Alloy", "FrontierUI_Bold", x + PAD + iconSize + PAD_SM, rowY + 6, UI.alloy, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Tooltip area
    if IsMouseOver(x, y, w, h) then
        HoveredElement = {
            x = x,
            y = y + h + 4,
            title = "Your Resources",
            lines = {
                {color = UI.credits, text = "Credits: Earned from paychecks. Spend at shops."},
                {color = UI.alloy, text = "Alloy: Mine ore nodes. Use for colony upgrades."}
            }
        }
    end
end

-- Colony status panel (top center)
function GM:DrawColonyPanel(sw, sh)
    local w, h = 360, 95
    local x, y = (sw - w) / 2, PAD

    DrawPanel(x, y, w, h, UI.bgPanel)

    -- Title
    draw.SimpleText("COLONY STATUS", "FrontierUI_Small", x + w / 2, y + 12, UI.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Resource bars in a grid
    local barW = 70
    local barH = 10
    local spacing = 12
    local startX = x + PAD
    local barY = y + 30

    local resources = {
        {name = "Power", value = ColonyData.power, max = COLONY_MAX_POWER, color = UI.power, tip = "Powers all colony systems. Engineers can refuel generators."},
        {name = "Food", value = ColonyData.food, max = COLONY_MAX_FOOD, color = UI.food, tip = "Feeds colonists. Farmers can harvest crops."},
        {name = "Shields", value = ColonyData.shields, max = COLONY_MAX_SHIELDS, color = UI.shields, tip = "Protects during attacks. Buy capacitors to restore."},
        {name = "Morale", value = ColonyData.morale, max = COLONY_MAX_MORALE, color = UI.morale, tip = "Affects paycheck bonuses. Keep resources high."}
    }

    for i, res in ipairs(resources) do
        local bx = startX + (i - 1) * (barW + spacing)

        -- Label
        draw.SimpleText(res.name, "FrontierUI_Tiny", bx + barW / 2, barY, UI.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        -- Bar
        DrawBar(bx, barY + 4, barW, barH, res.value / res.max, res.color)

        -- Value
        local displayVal = res.name == "Shields" or res.name == "Morale"
            and math.floor(res.value) .. "%"
            or math.floor(res.value)
        draw.SimpleText(displayVal, "FrontierUI_Tiny", bx + barW / 2, barY + barH + 8, UI.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Hover detection for tooltip
        if IsMouseOver(bx, barY - 10, barW, barH + 20) then
            HoveredElement = {
                x = bx,
                y = barY + barH + 24,
                title = res.name,
                lines = {{color = UI.textDim, text = res.tip}}
            }
        end
    end

    -- Prosperity score
    draw.SimpleText("Prosperity: " .. string.Comma(ColonyData.prosperity), "FrontierUI_Small", x + w / 2, y + h - 14, UI.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Panel tooltip
    if IsMouseOver(x, y, w, 22) then
        HoveredElement = {
            x = x + w / 2 - 100,
            y = y + h + 4,
            title = "Colony Resources",
            lines = {
                {color = UI.textDim, text = "Keep Power and Food above zero to survive!"},
                {color = UI.textDim, text = "Work together to maintain these resources."}
            }
        }
    end
end

-- Draw tooltip
function GM:DrawTooltip(sw, sh)
    if not HoveredElement then return end

    local tip = HoveredElement
    local w = 220
    local lineH = 16
    local h = 28 + #tip.lines * lineH

    local x = math.Clamp(tip.x, PAD, sw - w - PAD)
    local y = math.Clamp(tip.y, PAD, sh - h - PAD)

    DrawPanel(x, y, w, h, Color(35, 38, 48), UI.border)

    draw.SimpleText(tip.title, "FrontierUI_Bold", x + PAD_SM, y + PAD_SM, UI.text)

    for i, line in ipairs(tip.lines) do
        draw.SimpleText(line.text, "FrontierUI_Tiny", x + PAD_SM, y + 22 + (i - 1) * lineH, line.color or UI.textDim)
    end

    HoveredElement = nil
end

-- Notifications (right side)
function GM:DrawNotifications(sw, sh)
    local notifW, notifH = 260, 60
    local startX = sw - notifW - PAD
    local startY = 100

    -- Remove expired
    for i = #Notifications, 1, -1 do
        if CurTime() - Notifications[i].startTime > Notifications[i].duration then
            table.remove(Notifications, i)
        end
    end

    -- Draw
    for i, notif in ipairs(Notifications) do
        local elapsed = CurTime() - notif.startTime
        local alpha = 1

        if elapsed < 0.2 then
            alpha = elapsed / 0.2
        elseif elapsed > notif.duration - 0.3 then
            alpha = (notif.duration - elapsed) / 0.3
        end

        local y = startY + (i - 1) * (notifH + PAD_SM)
        local slideX = startX + (1 - alpha) * 30

        local bgCol = Color(UI.bgPanel.r, UI.bgPanel.g, UI.bgPanel.b, 240 * alpha)
        DrawPanel(slideX, y, notifW, notifH, bgCol)

        -- Accent bar
        surface.SetDrawColor(notif.color.r, notif.color.g, notif.color.b, 255 * alpha)
        surface.DrawRect(slideX, y, 3, notifH)

        -- Text
        draw.SimpleText(notif.title, "FrontierUI_Bold", slideX + PAD, y + PAD, Color(notif.color.r, notif.color.g, notif.color.b, 255 * alpha))
        draw.SimpleText(notif.message, "FrontierUI_Small", slideX + PAD, y + PAD + 20, Color(UI.text.r, UI.text.g, UI.text.b, 255 * alpha))
    end
end

-- Attack warning
function GM:DrawAttackWarning(sw, sh)
    local pulse = math.abs(math.sin(CurTime() * 3))

    -- Red border
    surface.SetDrawColor(220, 40, 40, 40 + pulse * 40)
    surface.DrawRect(0, 0, sw, 60)
    surface.DrawRect(0, sh - 60, sw, 60)

    -- Warning text
    local textY = 130
    draw.SimpleText("ALIEN ATTACK", "FrontierUI_Title", sw / 2, textY, Color(220, 60, 60, 200 + pulse * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Wave " .. ColonyData.attackWave .. " - Defend the colony!", "FrontierUI", sw / 2, textY + 32, Color(255, 200, 200, 200 + pulse * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Hide default HUD
function GM:HUDShouldDraw(name)
    local hide = {
        ["CHudHealth"] = true,
        ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
        ["CHudSecondaryAmmo"] = true,
        ["CHudSuitPower"] = true,
        ["CHudDamageIndicator"] = true
    }
    return not hide[name]
end

-- Player name tags
function GM:PostDrawOpaqueRenderables()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() then
            local dist = ply:GetPos():Distance(p:GetPos())
            if dist < 800 then
                local pos = p:GetPos() + Vector(0, 0, 80)
                local screenPos = pos:ToScreen()

                if screenPos.visible then
                    local alpha = math.Clamp(255 - dist / 4, 80, 255)
                    local job = GetJobByID(p:Team()) or JOBS[1]

                    draw.SimpleText(p:Nick(), "FrontierUI", screenPos.x, screenPos.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(job.name, "FrontierUI_Tiny", screenPos.x, screenPos.y + 16, Color(job.color.r, job.color.g, job.color.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    -- Health bar
                    local bw, bh = 50, 4
                    local hpPct = p:Health() / p:GetMaxHealth()

                    surface.SetDrawColor(0, 0, 0, alpha)
                    surface.DrawRect(screenPos.x - bw / 2 - 1, screenPos.y + 28, bw + 2, bh + 2)

                    surface.SetDrawColor(hpPct > 0.3 and UI.success.r or UI.danger.r, hpPct > 0.3 and UI.success.g or UI.danger.g, hpPct > 0.3 and UI.success.b or UI.danger.b, alpha)
                    surface.DrawRect(screenPos.x - bw / 2, screenPos.y + 29, bw * hpPct, bh)
                end
            end
        end
    end
end
