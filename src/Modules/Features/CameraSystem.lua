-- CameraSystem.lua
-- Drives workspace.CurrentCamera based on the camera track + chosen mode
-- (Free, FirstPerson, OverShoulder, Cinematic, Follow).

local Constants  = require(script.Parent.Parent.Parent.Constants)
local Keyframes  = require(script.Parent.Parent.Keyframes)

local CameraSystem = {}
CameraSystem.__index = CameraSystem

function CameraSystem.new()
    local self = setmetatable({}, CameraSystem)
    self._originalType = nil
    self._originalCFrame = nil
    self._originalFOV = nil
    self._owned = false
    return self
end

function CameraSystem:takeover()
    if self._owned then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    self._originalType   = cam.CameraType
    self._originalCFrame = cam.CFrame
    self._originalFOV    = cam.FieldOfView
    cam.CameraType       = Enum.CameraType.Scriptable
    self._owned          = true
end

function CameraSystem:release()
    if not self._owned then return end
    local cam = workspace.CurrentCamera
    if cam and self._originalType then
        cam.CameraType = self._originalType
        if self._originalCFrame then cam.CFrame = self._originalCFrame end
        if self._originalFOV then cam.FieldOfView = self._originalFOV end
    end
    self._owned = false
end

local function findHumanoidRoot(target)
    if not target then return nil end
    if target:IsA("Model") then
        return target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
    end
    return target
end

function CameraSystem:render(time, data)
    local camTrack
    for _, t in ipairs(data.tracks) do
        if t.kind == Constants.TRACK_KIND.Camera then camTrack = t break end
    end
    if not camTrack then return end

    self:takeover()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local mode = camTrack.mode or data.cameraMode or Constants.CAMERA_MODE.Cinematic
    local target = camTrack.followTarget or data.followTarget

    if mode == Constants.CAMERA_MODE.Cinematic or mode == Constants.CAMERA_MODE.Free then
        local cf = Keyframes.evaluate(camTrack.keys, time)
        if cf then cam.CFrame = cf end

    elseif mode == Constants.CAMERA_MODE.FirstPerson then
        local root = findHumanoidRoot(target)
        if root then
            local head = target and target:FindFirstChild("Head") or root
            cam.CFrame = head.CFrame * CFrame.new(0, 0.4, -0.2)
        end

    elseif mode == Constants.CAMERA_MODE.OverShoulder then
        local root = findHumanoidRoot(target)
        if root then
            cam.CFrame = root.CFrame * CFrame.new(1.2, 1.6, 4)
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, root.Position + Vector3.new(0, 1.5, 0))
        end

    elseif mode == Constants.CAMERA_MODE.Follow then
        local root = findHumanoidRoot(target)
        if root then
            local offset = camTrack.followOffset or Vector3.new(0, 4, 10)
            local pos = root.Position + offset
            cam.CFrame = CFrame.lookAt(pos, root.Position)
        end
    end

    local fov = Keyframes.evaluate(camTrack.fovKeys, time)
    if fov then cam.FieldOfView = fov end
end

return CameraSystem
