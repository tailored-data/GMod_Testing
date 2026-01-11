--[[
    Ragdoll Boxing - Third Person Camera
    Provides smooth third-person camera following the player's ragdoll
]]

-- Camera settings
local CAMERA_DISTANCE = 200
local CAMERA_HEIGHT = 50
local CAMERA_SMOOTH = 0.15
local CAMERA_COLLISION_PADDING = 10

-- Stored camera position for smoothing
local smoothedPos = nil
local smoothedAng = nil

-- CalcView hook for third-person camera
function GM:CalcView(ply, origin, angles, fov)
    -- Get the ragdoll we're following
    local ragdoll = ply.Ragdoll
    if not IsValid(ragdoll) then
        -- Fall back to default view if no ragdoll
        return self.BaseClass:CalcView(ply, origin, angles, fov)
    end

    -- Get ragdoll position (use center of mass)
    local ragdollPos = ragdoll:GetPos()

    -- Try to get the head bone position for better camera focus
    local headBone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
    if headBone then
        local bonePos = ragdoll:GetBonePosition(headBone)
        if bonePos then
            ragdollPos = bonePos
        end
    end

    -- Add height offset
    local targetPos = ragdollPos + Vector(0, 0, CAMERA_HEIGHT)

    -- Calculate camera position based on player view angles
    local viewAngles = angles
    local forward = viewAngles:Forward()
    local right = viewAngles:Right()
    local up = viewAngles:Up()

    -- Position camera behind and above the ragdoll
    local cameraOffset = -forward * CAMERA_DISTANCE + up * 20
    local cameraPos = targetPos + cameraOffset

    -- Collision detection to prevent camera going through walls
    local trace = util.TraceLine({
        start = targetPos,
        endpos = cameraPos,
        filter = {ply, ragdoll},
        mask = MASK_SOLID_BRUSHONLY
    })

    if trace.Hit then
        -- Move camera closer to avoid clipping
        cameraPos = trace.HitPos + trace.HitNormal * CAMERA_COLLISION_PADDING
    end

    -- Calculate angle to look at ragdoll
    local lookDir = (targetPos - cameraPos):GetNormalized()
    local cameraAngles = lookDir:Angle()

    -- Smooth camera movement
    if smoothedPos == nil then
        smoothedPos = cameraPos
        smoothedAng = cameraAngles
    else
        smoothedPos = LerpVector(CAMERA_SMOOTH, smoothedPos, cameraPos)
        -- Smooth angle interpolation
        smoothedAng = LerpAngle(CAMERA_SMOOTH, smoothedAng, cameraAngles)
    end

    -- Build the view table
    local view = {
        origin = smoothedPos,
        angles = viewAngles, -- Use player's view angles for aiming
        fov = fov,
        drawviewer = false
    }

    return view
end

-- Input modification to keep mouse control smooth
function GM:InputMouseApply(cmd, x, y, angle)
    -- Allow normal mouse input
    return false
end

-- Adjust player's aim angles for the ragdoll
function GM:CreateMove(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) or not IsValid(ply.Ragdoll) then return end

    -- Store the view angles for the server to use
    local viewAngles = cmd:GetViewAngles()

    -- The movement is handled server-side in StartCommand
    -- This just ensures client-side prediction is smooth
end

-- Allow adjusting camera distance with scroll wheel
local cameraZoom = CAMERA_DISTANCE

hook.Add("PlayerBindPress", "RagBox_CameraZoom", function(ply, bind, pressed)
    if not pressed then return end

    if bind == "invprev" then
        -- Scroll up - zoom in
        cameraZoom = math.max(100, cameraZoom - 20)
        CAMERA_DISTANCE = cameraZoom
        return true
    elseif bind == "invnext" then
        -- Scroll down - zoom out
        cameraZoom = math.min(400, cameraZoom + 20)
        CAMERA_DISTANCE = cameraZoom
        return true
    end
end)

-- Console command to adjust camera distance
concommand.Add("ragbox_camdist", function(ply, cmd, args)
    if args[1] then
        local dist = tonumber(args[1])
        if dist then
            CAMERA_DISTANCE = math.Clamp(dist, 50, 500)
            cameraZoom = CAMERA_DISTANCE
            print("[RagBox] Camera distance set to " .. CAMERA_DISTANCE)
        end
    else
        print("[RagBox] Current camera distance: " .. CAMERA_DISTANCE)
        print("[RagBox] Usage: ragbox_camdist <50-500>")
    end
end)

-- Reset camera when player respawns
hook.Add("OnReloaded", "RagBox_ResetCamera", function()
    smoothedPos = nil
    smoothedAng = nil
end)
