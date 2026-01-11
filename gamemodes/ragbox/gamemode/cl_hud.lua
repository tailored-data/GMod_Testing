--[[
    Ragdoll Boxing - Client HUD
    Draws health, timer, and game state information
]]

-- Colors
local COLOR_HEALTH_BG = Color(0, 0, 0, 200)
local COLOR_HEALTH_FG = Color(220, 50, 50, 255)
local COLOR_HEALTH_LOW = Color(255, 0, 0, 255)
local COLOR_TIMER_BG = Color(0, 0, 0, 200)
local COLOR_TIMER_FG = Color(255, 255, 255, 255)
local COLOR_TIMER_LOW = Color(255, 100, 100, 255)
local COLOR_STATE_BG = Color(0, 0, 0, 180)
local COLOR_STATE_FG = Color(255, 215, 0, 255)

-- HUD fonts
surface.CreateFont("RagBoxHUDLarge", {
    font = "Arial",
    size = 48,
    weight = 700,
    antialias = true,
})

surface.CreateFont("RagBoxHUDMedium", {
    font = "Arial",
    size = 32,
    weight = 600,
    antialias = true,
})

surface.CreateFont("RagBoxHUDSmall", {
    font = "Arial",
    size = 24,
    weight = 500,
    antialias = true,
})

-- Draw the HUD
function GM:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local scrW, scrH = ScrW(), ScrH()

    -- Draw health bar
    self:DrawHealthBar(ply, scrW, scrH)

    -- Draw timer
    self:DrawTimer(scrW, scrH)

    -- Draw game state
    self:DrawGameState(scrW, scrH)

    -- Draw crosshair
    self:DrawCrosshair(scrW, scrH)

    -- Draw controls help
    self:DrawControls(scrW, scrH)
end

-- Draw health bar
function GM:DrawHealthBar(ply, scrW, scrH)
    local health = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    local healthPercent = math.Clamp(health / maxHealth, 0, 1)

    local barWidth = 300
    local barHeight = 30
    local barX = 20
    local barY = scrH - 60

    -- Background
    draw.RoundedBox(8, barX, barY, barWidth, barHeight, COLOR_HEALTH_BG)

    -- Health fill
    local healthColor = healthPercent > 0.3 and COLOR_HEALTH_FG or COLOR_HEALTH_LOW
    if healthPercent > 0 then
        draw.RoundedBox(8, barX + 2, barY + 2, (barWidth - 4) * healthPercent, barHeight - 4, healthColor)
    end

    -- Health text
    draw.SimpleText(health .. " / " .. maxHealth, "RagBoxHUDSmall", barX + barWidth / 2, barY + barHeight / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Label
    draw.SimpleText("HEALTH", "RagBoxHUDSmall", barX, barY - 25, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- Draw timer
function GM:DrawTimer(scrW, scrH)
    local timeLeft = self.RoundTimeLeft or 0

    local minutes = math.floor(timeLeft / 60)
    local seconds = math.floor(timeLeft % 60)
    local timeStr = string.format("%d:%02d", minutes, seconds)

    local timerWidth = 150
    local timerHeight = 60
    local timerX = (scrW - timerWidth) / 2
    local timerY = 20

    -- Background
    draw.RoundedBox(8, timerX, timerY, timerWidth, timerHeight, COLOR_TIMER_BG)

    -- Timer text
    local timerColor = timeLeft > 30 and COLOR_TIMER_FG or COLOR_TIMER_LOW

    -- Pulse effect when low on time
    if timeLeft <= 10 and timeLeft > 0 then
        local pulse = math.abs(math.sin(CurTime() * 4))
        timerColor = Color(255, 100 + 155 * pulse, 100 + 155 * pulse)
    end

    draw.SimpleText(timeStr, "RagBoxHUDLarge", timerX + timerWidth / 2, timerY + timerHeight / 2, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Draw game state indicator
function GM:DrawGameState(scrW, scrH)
    local stateText = ""
    local stateColor = COLOR_STATE_FG

    if self.GameState == GAMESTATE_WAITING then
        stateText = "WAITING FOR PLAYERS..."
        stateColor = Color(255, 255, 100)
    elseif self.GameState == GAMESTATE_PLAYING then
        stateText = "FIGHT!"
        stateColor = Color(100, 255, 100)
    elseif self.GameState == GAMESTATE_ROUNDEND then
        stateText = "ROUND OVER"
        stateColor = Color(255, 100, 100)
    end

    if stateText ~= "" then
        local boxWidth = 300
        local boxHeight = 40
        local boxX = (scrW - boxWidth) / 2
        local boxY = 90

        draw.RoundedBox(8, boxX, boxY, boxWidth, boxHeight, COLOR_STATE_BG)
        draw.SimpleText(stateText, "RagBoxHUDMedium", scrW / 2, boxY + boxHeight / 2, stateColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Draw custom crosshair
function GM:DrawCrosshair(scrW, scrH)
    local cx, cy = scrW / 2, scrH / 2
    local size = 15
    local gap = 5
    local thickness = 2

    surface.SetDrawColor(255, 255, 255, 200)

    -- Top
    surface.DrawRect(cx - thickness / 2, cy - gap - size, thickness, size)
    -- Bottom
    surface.DrawRect(cx - thickness / 2, cy + gap, thickness, size)
    -- Left
    surface.DrawRect(cx - gap - size, cy - thickness / 2, size, thickness)
    -- Right
    surface.DrawRect(cx + gap, cy - thickness / 2, size, thickness)

    -- Center dot
    surface.DrawRect(cx - 2, cy - 2, 4, 4)
end

-- Draw controls help
function GM:DrawControls(scrW, scrH)
    local helpText = {
        "WASD - Move ragdoll",
        "SPACE - Jump",
        "LEFT CLICK - Punch",
        "MOUSE - Look around"
    }

    local startY = scrH - 150
    local startX = scrW - 220

    draw.RoundedBox(8, startX - 10, startY - 10, 220, #helpText * 22 + 20, Color(0, 0, 0, 150))

    for i, text in ipairs(helpText) do
        draw.SimpleText(text, "RagBoxHUDSmall", startX, startY + (i - 1) * 22, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

-- Draw player names above ragdolls
function GM:PostDrawOpaqueRenderables()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and IsValid(p.Ragdoll) then
            local ragdoll = p.Ragdoll
            local pos = ragdoll:GetPos() + Vector(0, 0, 60)

            local screenPos = pos:ToScreen()
            if screenPos.visible then
                local dist = ply:GetPos():Distance(ragdoll:GetPos())
                local alpha = math.Clamp(255 - (dist / 5), 50, 255)

                -- Draw name
                draw.SimpleText(p:Nick(), "RagBoxHUDSmall", screenPos.x, screenPos.y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Draw health bar
                local healthPercent = (p:Health() / p:GetMaxHealth())
                local barWidth = 60
                local barHeight = 6

                surface.SetDrawColor(0, 0, 0, alpha)
                surface.DrawRect(screenPos.x - barWidth / 2 - 1, screenPos.y + 15, barWidth + 2, barHeight + 2)

                local healthColor = healthPercent > 0.3 and Color(100, 255, 100, alpha) or Color(255, 100, 100, alpha)
                surface.SetDrawColor(healthColor)
                surface.DrawRect(screenPos.x - barWidth / 2, screenPos.y + 16, barWidth * healthPercent, barHeight)
            end
        end
    end
end
