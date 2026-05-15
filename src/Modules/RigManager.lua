-- RigManager.lua
-- Discovers Motor6D joints in a rig and stores/restores poses.

local RigManager = {}

function RigManager.findMotors(rig)
    local motors = {}
    for _, d in ipairs(rig:GetDescendants()) do
        if d:IsA("Motor6D") then
            table.insert(motors, d)
        end
    end
    table.sort(motors, function(a, b) return a.Name < b.Name end)
    return motors
end

function RigManager.snapshot(rig)
    -- Return a map [motorName] -> CFrame (Transform)
    local snap = {}
    for _, m in ipairs(RigManager.findMotors(rig)) do
        snap[m.Name] = m.Transform
    end
    return snap
end

function RigManager.applyPose(rig, snap)
    if not snap then return end
    for _, m in ipairs(RigManager.findMotors(rig)) do
        local cf = snap[m.Name]
        if cf then m.Transform = cf end
    end
end

function RigManager.resetPose(rig)
    for _, m in ipairs(RigManager.findMotors(rig)) do
        m.Transform = CFrame.new()
    end
end

function RigManager.isAnimatable(inst)
    if not inst or not inst.Parent then return false end
    return inst:IsA("Model") and #RigManager.findMotors(inst) > 0
end

return RigManager
