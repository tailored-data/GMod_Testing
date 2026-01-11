--[[
    Frontier Colony - Client Initialization
    A cooperative space colony survival RPG
]]

-- Include shared
include("shared.lua")

-- Include client files
include("cl_hud.lua")
include("cl_menus.lua")

-- Initialize client
function GM:Initialize()
    print("==========================================")
    print("  FRONTIER COLONY")
    print("  Welcome to the colony, survivor!")
    print("==========================================")

    self:CreateTeams()

    print("[Frontier] Client initialized!")
end

-- Initial spawn message
function GM:InitPostEntity()
    timer.Simple(2, function()
        chat.AddText(
            Color(80, 150, 255), "[Frontier] ",
            Color(255, 255, 255), "Welcome to ",
            Color(255, 215, 0), "Frontier Colony",
            Color(255, 255, 255), "!"
        )
        chat.AddText(
            Color(80, 150, 255), "[Frontier] ",
            Color(200, 200, 200), "Press ",
            Color(255, 255, 100), "F4",
            Color(200, 200, 200), " to select a job, ",
            Color(255, 255, 100), "F3",
            Color(200, 200, 200), " for the shop."
        )
    end)
end

-- Disable some rendering for performance
function GM:PreDrawHalos()
    return false
end

-- Custom chat formatting
function GM:OnPlayerChat(ply, text, teamChat, isDead)
    if not IsValid(ply) then
        -- Server message
        chat.AddText(Color(150, 150, 150), "[Server] ", Color(255, 255, 255), text)
        return true
    end

    local job = GetJobByID(ply:Team()) or JOBS[1]
    local prefix = isDead and "*DEAD* " or ""
    local teamPrefix = teamChat and "(TEAM) " or ""

    chat.AddText(
        Color(150, 150, 150), prefix,
        Color(150, 150, 150), teamPrefix,
        job.color, "[" .. job.name .. "] ",
        team.GetColor(ply:Team()), ply:Nick(),
        Color(255, 255, 255), ": " .. text
    )

    return true
end

-- Draw player info above their heads
function GM:PostDrawOpaqueRenderables()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and p:GetPos():Distance(ply:GetPos()) < 1500 then
            local pos = p:GetPos() + Vector(0, 0, 80)
            local screenPos = pos:ToScreen()

            if screenPos.visible then
                local dist = ply:GetPos():Distance(p:GetPos())
                local alpha = math.Clamp(255 - (dist / 8), 50, 255)
                local job = GetJobByID(p:Team()) or JOBS[1]

                -- Name
                draw.SimpleText(p:Nick(), "Frontier_Small", screenPos.x, screenPos.y,
                    Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Job
                draw.SimpleText(job.name, "Frontier_Tiny", screenPos.x, screenPos.y + 18,
                    Color(job.color.r, job.color.g, job.color.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Health bar
                local barWidth = 60
                local barHeight = 6
                local healthPercent = p:Health() / p:GetMaxHealth()

                surface.SetDrawColor(0, 0, 0, alpha)
                surface.DrawRect(screenPos.x - barWidth/2 - 1, screenPos.y + 32, barWidth + 2, barHeight + 2)

                local healthColor = healthPercent > 0.3 and Color(80, 220, 120, alpha) or Color(255, 80, 80, alpha)
                surface.SetDrawColor(healthColor)
                surface.DrawRect(screenPos.x - barWidth/2, screenPos.y + 33, barWidth * healthPercent, barHeight)
            end
        end
    end
end

-- Crosshair
function GM:HUDShouldDraw(name)
    -- Hide default crosshair, we draw our own in HUD
    if name == "CHudCrosshair" then
        return true -- Keep default crosshair for aiming
    end

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

-- Create derma skin for consistent look
hook.Add("ForceDermaSkin", "Frontier_DermaSkin", function()
    return "Default"
end)

-- Scoreboard override
function GM:ScoreboardShow()
    if IsValid(FRONTIER_SCOREBOARD) then
        FRONTIER_SCOREBOARD:Show()
        FRONTIER_SCOREBOARD:MakePopup()
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local boardW, boardH = 600, 400

    local board = vgui.Create("DFrame")
    board:SetSize(boardW, boardH)
    board:Center()
    board:SetTitle("")
    board:SetDraggable(false)
    board:MakePopup()
    board:ShowCloseButton(false)
    FRONTIER_SCOREBOARD = board

    board.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, Color(15, 15, 20, 240))
        draw.RoundedBox(16, 0, 0, w, 50, Color(25, 25, 35, 240))
        draw.SimpleText("COLONISTS", "Frontier_Large", w/2, 25, Color(240, 240, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(60, 60, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local scroll = vgui.Create("DScrollPanel", board)
    scroll:SetPos(10, 60)
    scroll:SetSize(boardW - 20, boardH - 70)

    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(80, 150, 255))
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    board.Think = function()
        scroll:Clear()

        local yOffset = 0
        for _, p in ipairs(player.GetAll()) do
            local row = vgui.Create("DPanel", scroll)
            row:SetPos(0, yOffset)
            row:SetSize(boardW - 40, 40)

            local job = GetJobByID(p:Team()) or JOBS[1]

            row.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 35, 240))
                draw.RoundedBox(6, 0, 0, 4, h, job.color)

                draw.SimpleText(p:Nick(), "Frontier_Medium", 20, h/2, Color(240, 240, 245), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(job.name, "Frontier_Small", 250, h/2, job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(p:Ping() .. "ms", "Frontier_Small", w - 20, h/2, Color(150, 150, 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            yOffset = yOffset + 45
        end
    end
end

function GM:ScoreboardHide()
    if IsValid(FRONTIER_SCOREBOARD) then
        FRONTIER_SCOREBOARD:Hide()
    end
end

print("[Frontier] Client initialization complete.")
