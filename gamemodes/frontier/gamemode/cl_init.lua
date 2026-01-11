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
    print("")
    print("========================================")
    print("  FRONTIER COLONY")
    print("  Welcome to the colony!")
    print("========================================")
    print("")

    self:CreateTeams()

    print("[Frontier] Client initialized.")
end

-- Show welcome message
function GM:InitPostEntity()
    timer.Simple(3, function()
        chat.AddText(
            Color(90, 140, 220), "[Frontier Colony] ",
            Color(255, 255, 255), "Welcome to the colony!"
        )
        chat.AddText(
            Color(140, 145, 160), "Press ",
            Color(230, 180, 60), "F4 ",
            Color(140, 145, 160), "for jobs, ",
            Color(230, 180, 60), "F3 ",
            Color(140, 145, 160), "for shop. Type ",
            Color(230, 180, 60), "/help ",
            Color(140, 145, 160), "for commands."
        )
    end)
end

-- Custom chat formatting
function GM:OnPlayerChat(ply, text, teamChat, isDead)
    if not IsValid(ply) then
        chat.AddText(Color(140, 145, 160), "[Server] ", Color(230, 232, 240), text)
        return true
    end

    local job = GetJobByID(ply:Team()) or JOBS[1]
    local prefix = isDead and "*DEAD* " or ""
    local teamPrefix = teamChat and "(TEAM) " or ""

    chat.AddText(
        Color(140, 145, 160), prefix,
        Color(140, 145, 160), teamPrefix,
        job.color, "[" .. job.name .. "] ",
        Color(230, 232, 240), ply:Nick(),
        Color(140, 145, 160), ": ",
        Color(230, 232, 240), text
    )

    return true
end

-- Scoreboard
function GM:ScoreboardShow()
    if IsValid(FRONTIER_SCOREBOARD) then
        FRONTIER_SCOREBOARD:Show()
        FRONTIER_SCOREBOARD:MakePopup()
        return
    end

    local sw, sh = ScrW(), ScrH()
    local w, h = 500, 350

    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:ShowCloseButton(false)
    FRONTIER_SCOREBOARD = frame

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 22, 28, 245))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(28, 32, 40), true, true, false, false)
        draw.SimpleText("COLONISTS", "FrontierUI_Large", w/2, 20, Color(230, 232, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(50, 55, 70)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(10, 50)
    scroll:SetSize(w - 20, h - 60)

    local sbar = scroll:GetVBar()
    sbar:SetWide(4)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(90, 140, 220))
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    frame.Think = function()
        scroll:Clear()

        for _, p in ipairs(player.GetAll()) do
            local row = vgui.Create("DPanel", scroll)
            row:SetSize(w - 30, 36)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)

            local job = GetJobByID(p:Team()) or JOBS[1]

            row.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(28, 32, 40))
                draw.RoundedBoxEx(6, 0, 0, 3, h, job.color, true, false, true, false)

                draw.SimpleText(p:Nick(), "FrontierUI", 16, h/2, Color(230, 232, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(job.name, "FrontierUI_Small", 200, h/2, job.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(p:Ping() .. " ms", "FrontierUI_Small", w - 16, h/2, Color(140, 145, 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end
end

function GM:ScoreboardHide()
    if IsValid(FRONTIER_SCOREBOARD) then
        FRONTIER_SCOREBOARD:Hide()
    end
end

-- Hide default crosshair (keep for aiming)
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

print("[Frontier] Client script loaded.")
