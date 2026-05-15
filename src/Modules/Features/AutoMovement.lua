-- AutoMovement.lua
-- Generates a forward-walking animation along a path between two CFrames.
-- It keys the HumanoidRootPart-driving root motor (commonly "RootJoint")
-- and produces a simple swinging gait on the limbs.

local Constants = require(script.Parent.Parent.Parent.Constants)
local Keyframes = require(script.Parent.Parent.Keyframes)

local AutoMovement = {}

local LIMB_PAIRS = {
    -- {motorName, axis, amplitude, phase}
    {"Right Hip",      "Pitch",  25,  0},
    {"Left Hip",       "Pitch", -25,  0},
    {"Right Shoulder", "Pitch", -30,  0},
    {"Left Shoulder",  "Pitch",  30,  0},
}

local function angles(axis, deg)
    local rad = math.rad(deg)
    if axis == "Pitch" then return CFrame.Angles(rad, 0, 0) end
    if axis == "Yaw"   then return CFrame.Angles(0, rad, 0) end
    return CFrame.Angles(0, 0, rad)
end

-- track: a Rig track. startCF/endCF: world-space CFrames for HumanoidRootPart.
function AutoMovement.generate(track, startCF, endCF, length, fps, gait)
    gait = gait or "Walk"
    local frames = math.max(2, math.floor(length * (fps or Constants.DEFAULT_FPS)))
    local strideHz = (gait == "Run") and 2.6 or 1.6
    local amplitude = (gait == "Run") and 1.4 or 1.0

    -- Root motion: many R15 rigs use HumanoidRootPart -> LowerTorso (Root motor)
    -- We instead create keyframes on every motor whose Part0 is HumanoidRootPart.
    local rootMotor
    if track.target then
        for _, m in ipairs(track.target:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part0
            and (m.Part0.Name == "HumanoidRootPart" or m.Name == "RootJoint") then
                rootMotor = m
                break
            end
        end
    end

    track.motors = track.motors or {}

    for i = 0, frames do
        local alpha = i / frames
        local t     = alpha * length

        if rootMotor then
            local rootCF = startCF:Lerp(endCF, alpha)
            -- Convert world CFrame into the motor's local Transform space.
            -- For HumanoidRootPart joint, Transform offsets the descendant; we
            -- approximate by storing the world delta as a relative CFrame.
            local rel = startCF:ToObjectSpace(rootCF)
            track.motors[rootMotor.Name] = track.motors[rootMotor.Name] or {}
            Keyframes.insert(track.motors[rootMotor.Name], t, rel, "Linear")
        end

        for _, info in ipairs(LIMB_PAIRS) do
            local name, axis, amp = info[1], info[2], info[3] * amplitude
            local swing = math.sin(alpha * length * strideHz * math.pi * 2) * amp
            track.motors[name] = track.motors[name] or {}
            Keyframes.insert(track.motors[name], t, angles(axis, swing), "Cubic")
        end
    end
end

return AutoMovement
