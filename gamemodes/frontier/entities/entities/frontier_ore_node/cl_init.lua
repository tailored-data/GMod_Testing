--[[
    Frontier Colony - Ore Node Entity (Client)
]]

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Draw label above
    local pos = self:GetPos() + Vector(0, 0, 30)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText("ORE NODE", "DermaLarge", 0, 0, Color(200, 140, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Press E to mine", "DermaDefault", 0, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
