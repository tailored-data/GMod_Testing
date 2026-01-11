--[[
    Ragdoll Boxing - Client Initialization
    Main client-side entry point
]]

include("shared.lua")
include("cl_hud.lua")
include("cl_camera.lua")

-- Client-side game state
GM.GameState = GAMESTATE_WAITING
GM.RoundTimeLeft = 0
GM.RoundEndReason = ""

function GM:Initialize()
    self.BaseClass:Initialize()
    self:CreateTeams()
    print("[RagBox] Client initialized!")
end

-- Receive game state updates
net.Receive("RagBox_GameState", function()
    GAMEMODE.GameState = net.ReadInt(4)
end)

-- Receive round time updates
net.Receive("RagBox_RoundTime", function()
    GAMEMODE.RoundTimeLeft = net.ReadFloat()
end)

-- Receive round end notification
net.Receive("RagBox_RoundEnd", function()
    local winnerName = net.ReadString()
    GAMEMODE.RoundEndReason = winnerName

    -- Display winner notification
    chat.AddText(Color(255, 215, 0), "[RagBox] ", Color(255, 255, 255), "Round Over! Winner: " .. winnerName)
end)

-- Receive hit notification for effects
net.Receive("RagBox_PlayerHit", function()
    local hitPos = net.ReadVector()

    -- Create hit effect
    local effectData = EffectData()
    effectData:SetOrigin(hitPos)
    util.Effect("BloodImpact", effectData)

    -- Play hit sound
    surface.PlaySound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav")
end)

-- Key press handling for punching
function GM:PlayerBindPress(ply, bind, pressed)
    if not pressed then return end

    if bind == "+attack" then
        -- Send punch request to server
        net.Start("RagBox_Punch")
        net.SendToServer()
        return true
    end
end

-- HUD should not draw default elements
function GM:HUDShouldDraw(name)
    local hide = {
        ["CHudHealth"] = true,
        ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
        ["CHudSecondaryAmmo"] = true,
        ["CHudCrosshair"] = true,
        ["CHudDamageIndicator"] = true,
    }

    if hide[name] then
        return false
    end

    return true
end
