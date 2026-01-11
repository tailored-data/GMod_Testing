--[[
    Ragdoll Boxing - Third Person Camera
    Provides smooth third-person camera from above and behind the ragdoll
]]

-- Camera settings - positioned high and behind for overhead view
local CAMERA_DISTANCE = 250
local CAMERA_HEIGHT = 150 -- Much higher for overhead view
local CAMERA_PITCH = 35 -- Downward angle in degrees
local CAMERA_SMOOTH = 0.12
local CAMERA_COLLISION_PADDING = 10

-- Stored camera position for smoothing
local smoothedPos = nil
local smoothedAng = nil

-- CalcView hook for third-person camera from above/behind
function GM:CalcView(ply, origin, angles, fov)
    -- Get the ragdoll we're following
    local ragdoll = ply.Ragdoll
    if not IsValid(ragdoll) then
        -- Fall back to default view if no ragdoll
        return self.BaseClass:CalcView(ply, origin, angles, fov)
    end

    -- Get ragdoll center position
    local ragdollPos = ragdoll:GetPos()

    -- Try to get the spine/torso position for better camera focus
    local spineBone = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
    if spineBone then
        local bonePos = ragdoll:GetBonePosition(spineBone)
        if bonePos then
            ragdollPos = bonePos
        end
    end

    -- Get player's horizontal view angle (yaw only for camera orbit)
    local viewYaw = angles.y

    -- Calculate camera position - high above and behind the ragdoll
    local cameraYaw = Angle(0, viewYaw, 0)
    local forward = cameraYaw:Forward()

    -- Position camera behind and above
    -- The camera looks down at the ragdoll from behind
    local cameraPos = ragdollPos
        - forward * CAMERA_DISTANCE -- Behind
        + Vector(0, 0, CAMERA_HEIGHT) -- Above

    -- Calculate the angle to look at the ragdoll (looking down at it)
    local lookDir = (ragdollPos - cameraPos):GetNormalized()
    local cameraAngles = lookDir:Angle()

    -- Collision detection to prevent camera going through walls
    local trace = util.TraceLine({
        start = ragdollPos + Vector(0, 0, 30), -- Start from ragdoll chest
        endpos = cameraPos,
        filter = {ply, ragdoll, ply.WalkingWheel},
        mask = MASK_SOLID_BRUSHONLY
    })

    if trace.Hit then
        -- Move camera closer to avoid clipping
        cameraPos = trace.HitPos + trace.HitNormal * CAMERA_COLLISION_PADDING

        -- Recalculate look angle
        lookDir = (ragdollPos - cameraPos):GetNormalized()
        cameraAngles = lookDir:Angle()
    end

    -- Smooth camera movement
    if smoothedPos == nil then
        smoothedPos = cameraPos
        smoothedAng = cameraAngles
    else
        smoothedPos = LerpVector(CAMERA_SMOOTH, smoothedPos, cameraPos)
        smoothedAng = LerpAngle(CAMERA_SMOOTH, smoothedAng, cameraAngles)
    end

    -- Build the view table
    local view = {
        origin = smoothedPos,
        angles = smoothedAng, -- Camera looks down at ragdoll
        fov = fov,
        drawviewer = false
    }

    return view
end

-- Override to allow free mouse look for camera orbit
function GM:InputMouseApply(cmd, x, y, angle)
    -- Allow normal mouse input for orbiting camera
    return false
end

-- Handle client-side ragdoll reference
hook.Add("Think", "RagBox_UpdateRagdollRef", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Get ragdoll from server via spectate entity or network
    local spectating = ply:GetObserverTarget()
    if IsValid(spectating) and spectating:GetClass() == "prop_ragdoll" then
        ply.Ragdoll = spectating
    end
end)

-- Allow adjusting camera distance and height with scroll wheel
local cameraZoom = CAMERA_DISTANCE
local cameraHeightZoom = CAMERA_HEIGHT

hook.Add("PlayerBindPress", "RagBox_CameraZoom", function(ply, bind, pressed)
    if not pressed then return end

    if bind == "invprev" then
        -- Scroll up - zoom in (closer and lower)
        cameraZoom = math.max(100, cameraZoom - 25)
        cameraHeightZoom = math.max(80, cameraHeightZoom - 15)
        CAMERA_DISTANCE = cameraZoom
        CAMERA_HEIGHT = cameraHeightZoom
        return true
    elseif bind == "invnext" then
        -- Scroll down - zoom out (further and higher)
        cameraZoom = math.min(500, cameraZoom + 25)
        cameraHeightZoom = math.min(300, cameraHeightZoom + 15)
        CAMERA_DISTANCE = cameraZoom
        CAMERA_HEIGHT = cameraHeightZoom
        return true
    end
end)

-- Console command to adjust camera settings
concommand.Add("ragbox_camdist", function(ply, cmd, args)
    if args[1] then
        local dist = tonumber(args[1])
        if dist then
            CAMERA_DISTANCE = math.Clamp(dist, 50, 600)
            cameraZoom = CAMERA_DISTANCE
            print("[RagBox] Camera distance set to " .. CAMERA_DISTANCE)
        end
    else
        print("[RagBox] Current camera distance: " .. CAMERA_DISTANCE)
        print("[RagBox] Usage: ragbox_camdist <50-600>")
    end
end)

concommand.Add("ragbox_camheight", function(ply, cmd, args)
    if args[1] then
        local height = tonumber(args[1])
        if height then
            CAMERA_HEIGHT = math.Clamp(height, 30, 400)
            cameraHeightZoom = CAMERA_HEIGHT
            print("[RagBox] Camera height set to " .. CAMERA_HEIGHT)
        end
    else
        print("[RagBox] Current camera height: " .. CAMERA_HEIGHT)
        print("[RagBox] Usage: ragbox_camheight <30-400>")
    end
end)

-- Reset camera smoothing when player respawns
hook.Add("OnReloaded", "RagBox_ResetCamera", function()
    smoothedPos = nil
    smoothedAng = nil
end)

-- Reset on spawn
hook.Add("InitPostEntity", "RagBox_InitCamera", function()
    smoothedPos = nil
    smoothedAng = nil
end)
