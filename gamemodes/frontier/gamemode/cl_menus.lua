--[[
    Frontier Colony - Client Menus
    Beautiful VGUI menus for jobs, shop, and colony upgrades
]]

-- Local player data reference (from cl_hud.lua)
local function GetLocalData()
    return {
        credits = LocalPlayer():GetNWInt("credits", 0),
        alloy = LocalPlayer():GetNWInt("alloy", 0),
        job = LocalPlayer():Team() or 1
    }
end

-- UI Colors (matching HUD)
local COLORS = {
    bg = Color(15, 15, 20, 250),
    bgLight = Color(25, 25, 35, 250),
    bgLighter = Color(40, 40, 55, 250),
    bgHover = Color(50, 50, 70, 250),
    accent = Color(80, 150, 255),
    accentDark = Color(50, 100, 180),
    text = Color(240, 240, 245),
    textDim = Color(150, 150, 160),
    success = Color(80, 220, 120),
    warning = Color(255, 200, 80),
    danger = Color(255, 80, 80),
    credits = Color(100, 220, 100),
    alloy = Color(180, 130, 255),
    border = Color(60, 60, 80)
}

-- Cached player data for menus
local CachedCredits = 0
local CachedAlloy = 0
local CachedJob = 1

-- Update cache from network
net.Receive("Frontier_PlayerData", function()
    CachedCredits = net.ReadInt(32)
    CachedAlloy = net.ReadInt(32)
    CachedJob = net.ReadInt(8)
    net.ReadInt(32) -- xp
    net.ReadInt(8) -- level
end)

-- Create a styled button
local function CreateStyledButton(parent, text, x, y, w, h, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetPos(x, y)
    btn:SetSize(w, h)
    btn:SetText("")

    btn.Label = text
    btn.BGColor = COLORS.bgLighter
    btn.HoverColor = COLORS.bgHover
    btn.AccentColor = COLORS.accent

    btn.Paint = function(self, w, h)
        local bgCol = self:IsHovered() and self.HoverColor or self.BGColor
        draw.RoundedBox(8, 0, 0, w, h, bgCol)

        if self:IsHovered() then
            draw.RoundedBox(8, 0, h - 3, w, 3, self.AccentColor)
        end

        draw.SimpleText(self.Label, "Frontier_Medium", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = onClick
    return btn
end

-- Create the Jobs Menu
local function OpenJobsMenu()
    if IsValid(FRONTIER_JOBMENU) then
        FRONTIER_JOBMENU:Remove()
    end

    local scrW, scrH = ScrW(), ScrH()
    local menuW, menuH = 700, 500

    local frame = vgui.Create("DFrame")
    frame:SetSize(menuW, menuH)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:ShowCloseButton(false)
    FRONTIER_JOBMENU = frame

    frame.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(16, 0, 0, w, h, COLORS.bg)
        draw.RoundedBox(16, 0, 0, w, 50, COLORS.bgLight)

        -- Title
        draw.SimpleText("SELECT YOUR JOB", "Frontier_Large", w/2, 25, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Border
        surface.SetDrawColor(COLORS.border)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(menuW - 45, 10)
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and COLORS.danger or COLORS.textDim
        draw.SimpleText("X", "Frontier_Medium", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end

    -- Job list scroll panel
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(20, 60)
    scroll:SetSize(menuW - 40, menuH - 80)

    local sbar = scroll:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.accent)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    -- Create job cards
    local yOffset = 0
    for id, job in pairs(JOBS) do
        local card = vgui.Create("DPanel", scroll)
        card:SetPos(0, yOffset)
        card:SetSize(menuW - 60, 90)

        local isCurrentJob = (CachedJob == id)

        card.Paint = function(self, w, h)
            local bgCol = isCurrentJob and COLORS.bgLighter or COLORS.bgLight
            draw.RoundedBox(10, 0, 0, w, h, bgCol)

            -- Job color bar
            draw.RoundedBox(10, 0, 0, 6, h, job.color)

            -- Job name
            draw.SimpleText(job.name, "Frontier_Large", 20, 15, job.color)

            -- Description
            draw.SimpleText(job.description, "Frontier_Small", 20, 45, COLORS.textDim)

            -- Salary
            draw.SimpleText("Salary: " .. FormatCurrency(job.salary, CURRENCY_CREDITS), "Frontier_Small", 20, 68, COLORS.credits)

            -- Max players
            if job.maxPlayers > 0 then
                draw.SimpleText("Slots: " .. job.maxPlayers, "Frontier_Small", 200, 68, COLORS.textDim)
            end

            -- Current job indicator
            if isCurrentJob then
                draw.SimpleText("CURRENT", "Frontier_Small", w - 100, h/2, COLORS.success, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        -- Select button
        if not isCurrentJob then
            local selectBtn = vgui.Create("DButton", card)
            selectBtn:SetPos(menuW - 180, 25)
            selectBtn:SetSize(100, 40)
            selectBtn:SetText("")

            selectBtn.Paint = function(self, w, h)
                local col = self:IsHovered() and COLORS.accent or COLORS.accentDark
                draw.RoundedBox(8, 0, 0, w, h, col)
                draw.SimpleText("SELECT", "Frontier_Small", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            selectBtn.DoClick = function()
                net.Start("Frontier_ChangeJob")
                net.WriteInt(id, 8)
                net.SendToServer()
                frame:Close()
            end
        end

        yOffset = yOffset + 100
    end
end

-- Create the Shop Menu
local function OpenShopMenu()
    if IsValid(FRONTIER_SHOPMENU) then
        FRONTIER_SHOPMENU:Remove()
    end

    local scrW, scrH = ScrW(), ScrH()
    local menuW, menuH = 800, 550

    local frame = vgui.Create("DFrame")
    frame:SetSize(menuW, menuH)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:ShowCloseButton(false)
    FRONTIER_SHOPMENU = frame

    frame.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(16, 0, 0, w, h, COLORS.bg)
        draw.RoundedBox(16, 0, 0, w, 50, COLORS.bgLight)

        -- Title
        draw.SimpleText("COLONY SHOP", "Frontier_Large", w/2, 25, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Currency display
        draw.SimpleText(CURRENCY_SYMBOLS[CURRENCY_CREDITS] .. string.Comma(CachedCredits), "Frontier_Medium", 20, 25, COLORS.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(CURRENCY_SYMBOLS[CURRENCY_ALLOY] .. string.Comma(CachedAlloy), "Frontier_Medium", 150, 25, COLORS.alloy, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Border
        surface.SetDrawColor(COLORS.border)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(menuW - 45, 10)
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and COLORS.danger or COLORS.textDim
        draw.SimpleText("X", "Frontier_Medium", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end

    -- Tab buttons
    local tabY = 60
    local activeTab = "personal"

    local tabPersonal = CreateStyledButton(frame, "Personal Items", 20, tabY, 150, 35, function()
        activeTab = "personal"
    end)

    local tabColony = CreateStyledButton(frame, "Colony Upgrades", 180, tabY, 150, 35, function()
        activeTab = "colony"
    end)

    -- Content area
    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:SetPos(20, 110)
    contentPanel:SetSize(menuW - 40, menuH - 130)
    contentPanel.Paint = function() end

    -- Function to populate items
    local function PopulateItems(items, isColony)
        contentPanel:Clear()

        local scroll = vgui.Create("DScrollPanel", contentPanel)
        scroll:Dock(FILL)

        local sbar = scroll:GetVBar()
        sbar:SetWide(8)
        sbar.Paint = function() end
        sbar.btnGrip.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.accent)
        end
        sbar.btnUp.Paint = function() end
        sbar.btnDown.Paint = function() end

        local yOffset = 0
        for _, item in ipairs(items) do
            local card = vgui.Create("DPanel", scroll)
            card:SetPos(0, yOffset)
            card:SetSize(menuW - 80, 80)

            local canAfford = (item.currency == CURRENCY_CREDITS and CachedCredits >= item.price) or
                              (item.currency == CURRENCY_ALLOY and CachedAlloy >= item.price)

            card.Paint = function(self, w, h)
                draw.RoundedBox(10, 0, 0, w, h, COLORS.bgLight)

                -- Item name
                draw.SimpleText(item.name, "Frontier_Medium", 20, 15, COLORS.text)

                -- Description
                draw.SimpleText(item.description, "Frontier_Small", 20, 42, COLORS.textDim)

                -- Price
                local priceColor = canAfford and CURRENCY_COLORS[item.currency] or COLORS.danger
                draw.SimpleText(FormatCurrency(item.price, item.currency), "Frontier_Medium", 20, 62, priceColor)
            end

            -- Buy button
            local buyBtn = vgui.Create("DButton", card)
            buyBtn:SetPos(menuW - 200, 20)
            buyBtn:SetSize(100, 40)
            buyBtn:SetText("")

            buyBtn.Paint = function(self, w, h)
                local col
                if not canAfford then
                    col = COLORS.bgLighter
                elseif self:IsHovered() then
                    col = COLORS.success
                else
                    col = Color(60, 160, 80)
                end

                draw.RoundedBox(8, 0, 0, w, h, col)

                local textCol = canAfford and COLORS.text or COLORS.textDim
                draw.SimpleText("BUY", "Frontier_Small", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            buyBtn.DoClick = function()
                if canAfford then
                    if isColony then
                        net.Start("Frontier_BuyUpgrade")
                    else
                        net.Start("Frontier_BuyItem")
                    end
                    net.WriteString(item.id)
                    net.SendToServer()

                    -- Refresh after short delay
                    timer.Simple(0.2, function()
                        if IsValid(frame) then
                            PopulateItems(items, isColony)
                        end
                    end)
                end
            end

            yOffset = yOffset + 90
        end
    end

    -- Tab click handlers
    tabPersonal.DoClick = function()
        PopulateItems(SHOP_ITEMS, false)
        tabPersonal.AccentColor = COLORS.accent
        tabColony.AccentColor = COLORS.bgLighter
    end

    tabColony.DoClick = function()
        PopulateItems(COLONY_UPGRADES, true)
        tabColony.AccentColor = COLORS.accent
        tabPersonal.AccentColor = COLORS.bgLighter
    end

    -- Default to personal items
    tabPersonal.DoClick()
end

-- Keybinds
hook.Add("PlayerButtonDown", "Frontier_MenuKeys", function(ply, key)
    if key == KEY_F3 then
        OpenShopMenu()
    elseif key == KEY_F4 then
        OpenJobsMenu()
    end
end)

-- Network receive for menu open commands
net.Receive("Frontier_OpenMenu", function()
    local menuType = net.ReadString()

    if menuType == "jobs" then
        OpenJobsMenu()
    elseif menuType == "shop" then
        OpenShopMenu()
    end
end)

-- Console commands
concommand.Add("frontier_jobs", OpenJobsMenu)
concommand.Add("frontier_shop", OpenShopMenu)
