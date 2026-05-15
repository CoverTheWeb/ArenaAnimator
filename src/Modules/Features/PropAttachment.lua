-- PropAttachment.lua
-- Welds props to limbs at certain frames, releases them at others, and lets
-- you key the prop's free-motion CFrame for whichever stretches are detached.

local Constants = require(script.Parent.Parent.Parent.Constants)
local Keyframes = require(script.Parent.Parent.Keyframes)

local PropAttachment = {}
PropAttachment.__index = PropAttachment

function PropAttachment.new()
    local self = setmetatable({}, PropAttachment)
    self._welds  = {}   -- propId -> Weld
    self._origin = {}   -- propId -> {CFrame, Anchored}
    return self
end

local function getRoot(prop)
    if prop:IsA("Model") then
        return prop.PrimaryPart or prop:FindFirstChildWhichIsA("BasePart", true)
    end
    return prop
end

function PropAttachment:_remember(prop)
    local id = prop:GetDebugId()
    if self._origin[id] then return end
    local root = getRoot(prop); if not root then return end
    self._origin[id] = { cframe = root.CFrame, anchored = root.Anchored }
end

function PropAttachment:_attach(prop, limbName, offset)
    local id = prop:GetDebugId()
    self:_remember(prop)
    local root = getRoot(prop); if not root then return end

    -- Find limb on any rig in workspace
    local limb
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("BasePart") and m.Name == limbName then limb = m break end
    end
    if not limb then return end

    if self._welds[id] then self._welds[id]:Destroy() end
    root.Anchored = false
    local weld = Instance.new("Weld")
    weld.Part0 = limb
    weld.Part1 = root
    weld.C0   = offset or CFrame.new()
    weld.Parent = root
    self._welds[id] = weld
end

function PropAttachment:_detach(prop)
    local id = prop:GetDebugId()
    if self._welds[id] then
        self._welds[id]:Destroy()
        self._welds[id] = nil
    end
    local root = getRoot(prop)
    if root and self._origin[id] then
        root.Anchored = self._origin[id].anchored
    end
end

-- Render is called every frame: process events whose time crossed playhead.
function PropAttachment:render(time, data)
    for _, track in ipairs(data.tracks) do
        if track.kind == Constants.TRACK_KIND.Prop and track.target and track.target.Parent then
            -- Determine current attachment state by looking at the latest event up to `time`
            local active
            for _, ev in ipairs(track.events) do
                if ev.time <= time then active = ev else break end
            end
            if active then
                if active.type == "Attach" then
                    if not self._welds[track.target:GetDebugId()] then
                        self:_attach(track.target, active.limb, active.offset)
                    end
                elseif active.type == "Detach" then
                    self:_detach(track.target)
                end
            end

            -- If detached, allow free CFrame keys to drive prop
            if not self._welds[track.target:GetDebugId()] and #track.keys > 0 then
                local cf = Keyframes.evaluate(track.keys, time)
                if cf then
                    local root = getRoot(track.target)
                    if root then
                        root.Anchored = true
                        if track.target:IsA("Model") then
                            track.target:PivotTo(cf)
                        else
                            root.CFrame = cf
                        end
                    end
                end
            end
        end
    end
end

function PropAttachment:reset()
    for id, w in pairs(self._welds) do w:Destroy() end
    self._welds  = {}
    self._origin = {}
end

return PropAttachment
