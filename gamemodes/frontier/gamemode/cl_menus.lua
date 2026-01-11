--[[
    Frontier Colony - Client Menus
    Clean VGUI menus with 3D model previews
]]

-- Cached player data
local CachedCredits = 0
local CachedAlloy = 0
local CachedJob = 1

-- UI Theme (matching HUD)
local UI = {
    bg = Color(20, 22, 28),
    bgPanel = Color(28, 32, 40),
    bgCard = Color(35, 40, 50),
    bgHover = Color(45, 52, 65),
    border = Color(50, 55, 70),
    accent = Color(90, 140, 220),
    accentHover = Color(110, 160, 240),
    text = Color(230, 232, 240),
    textDim = Color(140, 145, 160),
    textMuted = Color(90, 95, 110),
    success = Color(80, 190, 120),
    successHover = Color(100, 210, 140),
    warning = Color(230, 180, 60),
    danger = Color(220, 80, 80),
    credits = Color(110, 190, 80),
    alloy = Color(150, 110, 210)
}

local PAD = 16
local PAD_SM = 10
local RADIUS = 8

-- Update cache from network
net.Receive("Frontier_PlayerData", function()
    CachedCredits = net.ReadInt(32)
    CachedAlloy = net.ReadInt(32)
    CachedJob = net.ReadInt(8)
    net.ReadInt(32)
    net.ReadInt(8)
end)

-- Create styled frame
local function CreateFrame(title, w, h)
    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(RADIUS, 0, 0, w, h, UI.bg)
        draw.RoundedBoxEx(RADIUS, 0, 0, w, 48, UI.bgPanel, true, true, false, false)
        draw.SimpleText(title, "FrontierUI_Large", PAD, 24, UI.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(UI.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.DrawLine(0, 48, w, 48)
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(w - 40, 8)
    closeBtn:SetSize(32, 32)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and UI.danger or UI.textDim
        draw.SimpleText("X", "FrontierUI_Bold", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end

    return frame
end

-- Create styled button
local function CreateButton(parent, text, x, y, w, h, color, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetPos(x, y)
    btn:SetSize(w, h)
    btn:SetText("")

    btn.BaseColor = color or UI.accent
    btn.HoverColor = color and Color(color.r + 20, color.g + 20, color.b + 20) or UI.accentHover

    btn.Paint = function(self, w, h)
        local col = self:IsHovered() and self.HoverColor or self.BaseColor
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText(text, "FrontierUI_Bold", w/2, h/2, UI.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = onClick
    return btn
end

-- Create scroll panel with styled scrollbar
local function CreateScrollPanel(parent, x, y, w, h)
    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:SetPos(x, y)
    scroll:SetSize(w, h)

    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, UI.bg)
    end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, UI.accent)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    return scroll
end

--[[ JOBS MENU ]]--

local function OpenJobsMenu()
    if IsValid(FRONTIER_JOBS) then FRONTIER_JOBS:Remove() end

    local frame = CreateFrame("SELECT JOB", 700, 520)
    FRONTIER_JOBS = frame

    -- Currency display
    local currY = 12
    draw.SimpleText = draw.SimpleText -- Ensure available
    frame.PaintOver = function(self, w, h)
        draw.SimpleText(FormatMoney(CachedCredits), "FrontierUI", w - 140, currY + 12, UI.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.Comma(CachedAlloy) .. " A", "FrontierUI", w - 140, currY + 30, UI.alloy, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = CreateScrollPanel(frame, PAD, 60, 700 - PAD * 2, 520 - 70)

    local cardH = 100
    local cardW = 700 - PAD * 2 - 20

    for id, job in pairs(JOBS) do
        local card = vgui.Create("DPanel", scroll)
        card:SetSize(cardW, cardH)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, PAD_SM)

        local isCurrentJob = (CachedJob == id)

        card.Paint = function(self, w, h)
            local bg = self:IsHovered() and UI.bgHover or UI.bgCard
            draw.RoundedBox(RADIUS, 0, 0, w, h, bg)

            -- Color accent bar
            draw.RoundedBoxEx(RADIUS, 0, 0, 4, h, job.color, true, false, true, false)

            -- Job name
            draw.SimpleText(job.name, "FrontierUI_Large", 120, 20, job.color)

            -- Description
            draw.SimpleText(job.description, "FrontierUI_Small", 120, 45, UI.textDim)

            -- Stats
            draw.SimpleText("Salary: " .. FormatMoney(job.salary), "FrontierUI_Small", 120, 70, UI.credits)

            if job.alloyBonus > 0 then
                draw.SimpleText("+" .. job.alloyBonus .. "% Alloy", "FrontierUI_Small", 250, 70, UI.alloy)
            end

            if job.maxPlayers > 0 then
                draw.SimpleText("Slots: " .. job.maxPlayers, "FrontierUI_Small", 380, 70, UI.textMuted)
            end

            -- Current job badge
            if isCurrentJob then
                draw.RoundedBox(4, w - 100, 38, 80, 24, UI.success)
                draw.SimpleText("CURRENT", "FrontierUI_Small", w - 60, 50, UI.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- 3D Model Preview
        local modelPanel = vgui.Create("DModelPanel", card)
        modelPanel:SetPos(20, 10)
        modelPanel:SetSize(80, 80)
        modelPanel:SetModel(job.model)
        modelPanel:SetFOV(45)

        local mn, mx = modelPanel.Entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
        size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
        size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

        modelPanel:SetCamPos(Vector(size, size, size * 0.5))
        modelPanel:SetLookAt((mn + mx) / 2)

        modelPanel.LayoutEntity = function(ent)
            ent:SetAngles(Angle(0, RealTime() * 30, 0))
        end

        -- Select button
        if not isCurrentJob then
            local selectBtn = CreateButton(card, "SELECT", cardW - 110, 30, 90, 40, nil, function()
                net.Start("Frontier_ChangeJob")
                net.WriteInt(id, 8)
                net.SendToServer()
                timer.Simple(0.1, function()
                    if IsValid(frame) then frame:Close() end
                    OpenJobsMenu()
                end)
            end)
        end
    end
end

--[[ SHOP MENU ]]--

local function OpenShopMenu()
    if IsValid(FRONTIER_SHOP) then FRONTIER_SHOP:Remove() end

    local frame = CreateFrame("COLONY SHOP", 650, 500)
    FRONTIER_SHOP = frame

    -- Currency display in header
    frame.PaintOver = function(self, w, h)
        draw.SimpleText(FormatMoney(CachedCredits), "FrontierUI", w - 180, 24, UI.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.Comma(CachedAlloy) .. " Alloy", "FrontierUI", w - 80, 24, UI.alloy, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Tab buttons
    local activeTab = "personal"
    local tabY = 60

    local tabPersonal = CreateButton(frame, "Personal Items", PAD, tabY, 140, 32, nil, function() end)
    local tabColony = CreateButton(frame, "Colony Upgrades", PAD + 150, tabY, 140, 32, UI.alloy, function() end)

    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:SetPos(PAD, tabY + 45)
    contentPanel:SetSize(650 - PAD * 2, 500 - tabY - 60)
    contentPanel.Paint = function() end

    local function PopulateItems(items, isColony)
        contentPanel:Clear()

        local scroll = CreateScrollPanel(contentPanel, 0, 0, contentPanel:GetWide(), contentPanel:GetTall())

        for _, item in ipairs(items) do
            local card = vgui.Create("DPanel", scroll)
            card:SetSize(contentPanel:GetWide() - 20, 70)
            card:Dock(TOP)
            card:DockMargin(0, 0, 0, PAD_SM)

            local canAfford = (item.currency == CURRENCY_CREDITS and CachedCredits >= item.price) or
                              (item.currency == CURRENCY_ALLOY and CachedAlloy >= item.price)

            card.Paint = function(self, w, h)
                local bg = self:IsHovered() and UI.bgHover or UI.bgCard
                draw.RoundedBox(RADIUS, 0, 0, w, h, bg)

                draw.SimpleText(item.name, "FrontierUI_Bold", PAD, 18, UI.text)
                draw.SimpleText(item.description, "FrontierUI_Small", PAD, 42, UI.textDim)

                local priceCol = canAfford and CURRENCY_COLORS[item.currency] or UI.danger
                draw.SimpleText(FormatCurrency(item.price, item.currency), "FrontierUI_Bold", PAD, 60, priceCol)
            end

            local buyBtn = CreateButton(card, "BUY", card:GetWide() - 100, 15, 80, 40,
                canAfford and UI.success or Color(60, 60, 70),
                function()
                    if canAfford then
                        if isColony then
                            net.Start("Frontier_BuyUpgrade")
                        else
                            net.Start("Frontier_BuyItem")
                        end
                        net.WriteString(item.id)
                        net.SendToServer()
                        timer.Simple(0.2, function()
                            if IsValid(frame) then
                                PopulateItems(items, isColony)
                            end
                        end)
                    end
                end)

            if not canAfford then
                buyBtn.BaseColor = Color(50, 50, 60)
                buyBtn.HoverColor = Color(50, 50, 60)
            end
        end
    end

    tabPersonal.DoClick = function()
        activeTab = "personal"
        tabPersonal.BaseColor = UI.accent
        tabColony.BaseColor = Color(50, 55, 70)
        PopulateItems(SHOP_ITEMS, false)
    end

    tabColony.DoClick = function()
        activeTab = "colony"
        tabColony.BaseColor = UI.alloy
        tabPersonal.BaseColor = Color(50, 55, 70)
        PopulateItems(COLONY_UPGRADES, true)
    end

    tabPersonal.DoClick()
end

--[[ HOUSING MENU ]]--

local function OpenHousingMenu()
    if IsValid(FRONTIER_HOUSING) then FRONTIER_HOUSING:Remove() end

    local frame = CreateFrame("PROPERTY DEALER", 600, 450)
    FRONTIER_HOUSING = frame

    frame.PaintOver = function(self, w, h)
        draw.SimpleText(FormatMoney(CachedCredits), "FrontierUI", w - 140, 24, UI.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = CreateScrollPanel(frame, PAD, 60, 600 - PAD * 2, 450 - 70)

    -- Info text
    local infoPanel = vgui.Create("DPanel", scroll)
    infoPanel:SetSize(560, 50)
    infoPanel:Dock(TOP)
    infoPanel:DockMargin(0, 0, 0, PAD)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(RADIUS, 0, 0, w, h, UI.bgCard)
        draw.SimpleText("Properties are doors on the map. Own a property to lock its doors.", "FrontierUI_Small", PAD, h/2, UI.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Would populate with actual property data from server
    -- For now, show placeholder
    local placeholder = vgui.Create("DPanel", scroll)
    placeholder:SetSize(560, 80)
    placeholder:Dock(TOP)
    placeholder.Paint = function(self, w, h)
        draw.RoundedBox(RADIUS, 0, 0, w, h, UI.bgCard)
        draw.SimpleText("Interact with Property Dealer NPCs", "FrontierUI", w/2, h/2 - 10, UI.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("on the map to browse available properties.", "FrontierUI_Small", w/2, h/2 + 12, UI.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

--[[ VEHICLE MENU ]]--

local function OpenVehicleMenu()
    if IsValid(FRONTIER_VEHICLES) then FRONTIER_VEHICLES:Remove() end

    local frame = CreateFrame("VEHICLE DEALER", 700, 480)
    FRONTIER_VEHICLES = frame

    frame.PaintOver = function(self, w, h)
        draw.SimpleText(FormatMoney(CachedCredits), "FrontierUI", w - 140, 24, UI.credits, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = CreateScrollPanel(frame, PAD, 60, 700 - PAD * 2, 480 - 70)

    for _, vehicle in ipairs(VEHICLES) do
        local card = vgui.Create("DPanel", scroll)
        card:SetSize(660, 110)
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, PAD_SM)

        local canAfford = CachedCredits >= vehicle.price

        card.Paint = function(self, w, h)
            local bg = self:IsHovered() and UI.bgHover or UI.bgCard
            draw.RoundedBox(RADIUS, 0, 0, w, h, bg)

            -- Vehicle info
            draw.SimpleText(vehicle.name, "FrontierUI_Large", 130, 25, UI.text)
            draw.SimpleText(vehicle.description, "FrontierUI_Small", 130, 55, UI.textDim)

            local priceCol = canAfford and UI.credits or UI.danger
            draw.SimpleText(FormatMoney(vehicle.price), "FrontierUI_Bold", 130, 85, priceCol)
        end

        -- 3D Model Preview
        local modelPanel = vgui.Create("DModelPanel", card)
        modelPanel:SetPos(15, 15)
        modelPanel:SetSize(100, 80)
        modelPanel:SetModel(vehicle.model)
        modelPanel:SetFOV(60)

        local mn, mx = modelPanel.Entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
        size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
        size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

        modelPanel:SetCamPos(Vector(size * 1.5, size * 1.5, size * 0.5))
        modelPanel:SetLookAt((mn + mx) / 2)

        modelPanel.LayoutEntity = function(ent)
            ent:SetAngles(Angle(0, RealTime() * 20, 0))
        end

        -- Buy button
        local buyBtn = CreateButton(card, "BUY", card:GetWide() - 110, 35, 90, 40,
            canAfford and UI.success or Color(60, 60, 70),
            function()
                if canAfford then
                    net.Start("Frontier_BuyVehicle")
                    net.WriteString(vehicle.id)
                    net.SendToServer()
                    timer.Simple(0.2, function()
                        if IsValid(frame) then
                            frame:Close()
                            OpenVehicleMenu()
                        end
                    end)
                end
            end)

        if not canAfford then
            buyBtn.BaseColor = Color(50, 50, 60)
            buyBtn.HoverColor = Color(50, 50, 60)
        end
    end
end

--[[ KEY BINDINGS ]]--

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
    elseif menuType == "housing" then
        OpenHousingMenu()
    elseif menuType == "vehicles" then
        OpenVehicleMenu()
    end
end)

-- Console commands
concommand.Add("frontier_jobs", OpenJobsMenu)
concommand.Add("frontier_shop", OpenShopMenu)
concommand.Add("frontier_housing", OpenHousingMenu)
concommand.Add("frontier_vehicles", OpenVehicleMenu)
