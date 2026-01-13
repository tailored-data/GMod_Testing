--[[
    Frontier Colony - Shield Capacitor Entity (Client)
]]

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 25)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, ang, 0.05)
        draw.SimpleText("SHIELD CAPACITOR", "DermaLarge", 0, 0, Color(80, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Press E to use", "DermaDefault", 0, 30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
