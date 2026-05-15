-- Trackball.lua
-- Maya-style viewport navigation. Activated when the user holds Alt and
-- drags the mouse. Drives a "free camera" CFrame which can be sampled or keyed.

local UserInputService = game:GetService("UserInputService")

local Trackball = {}
Trackball.__index = Trackball

function Trackball.new()
    local self = setmetatable({}, Trackball)
    self.enabled = false
    self.pivot   = Vector3.new(0, 5, 0)
    self.distance= 20
    self.yaw     = math.rad(-30)
    self.pitch   = math.rad(20)
    self._connections = {}
    self._dragging = nil   -- "orbit" | "pan" | "dolly" | nil
    self._lastPos = nil
    return self
end

function Trackball:cframe()
    local rot = CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(self.pitch, 0, 0)
    local offset = rot * Vector3.new(0, 0, self.distance)
    local pos = self.pivot + offset
    return CFrame.lookAt(pos, self.pivot)
end

function Trackball:enable(plugin)
    if self.enabled then return end
    self.enabled = true
    self.plugin  = plugin

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
        and not UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then self._dragging = "orbit"
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then self._dragging = "pan"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then self._dragging = "dolly" end
        self._lastPos = input.Position
    end))

    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
            self._dragging = nil
            self._lastPos  = nil
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not self._dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if not self._lastPos then self._lastPos = input.Position; return end
        local delta = input.Position - self._lastPos
        self._lastPos = input.Position
        if self._dragging == "orbit" then
            self.yaw   = self.yaw   - delta.X * 0.005
            self.pitch = math.clamp(self.pitch - delta.Y * 0.005, math.rad(-85), math.rad(85))
        elseif self._dragging == "pan" then
            local cf = self:cframe()
            local right = cf.RightVector
            local up    = cf.UpVector
            local scale = self.distance * 0.0015
            self.pivot = self.pivot - right * delta.X * scale + up * delta.Y * scale
        elseif self._dragging == "dolly" then
            self.distance = math.clamp(self.distance + delta.Y * 0.05 * self.distance * 0.05, 1, 5000)
        end

        if self._onChange then self._onChange(self:cframe()) end
    end))

    -- Mouse wheel zoom (also uses Alt for safety)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
             or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)) then return end
        local dir = -input.Position.Z
        self.distance = math.clamp(self.distance * (1 + dir * 0.1), 1, 5000)
        if self._onChange then self._onChange(self:cframe()) end
    end))
end

function Trackball:onChange(fn)
    self._onChange = fn
end

function Trackball:disable()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    self._connections = {}
    self.enabled = false
end

function Trackball:focus(part)
    if not part then return end
    if part:IsA("Model") then
        local cf, size = part:GetBoundingBox()
        self.pivot    = cf.Position
        self.distance = math.max(size.Magnitude * 1.4, 6)
    elseif part:IsA("BasePart") then
        self.pivot    = part.Position
        self.distance = math.max(part.Size.Magnitude * 1.4, 6)
    end
    if self._onChange then self._onChange(self:cframe()) end
end

return Trackball
