-- Playback.lua
-- Per-frame engine that renders all tracks at the current state.time.

local RunService = game:GetService("RunService")

local Constants  = require(script.Parent.Parent.Constants)
local Keyframes  = require(script.Parent.Keyframes)
local RigManager = require(script.Parent.RigManager)

local Playback = {}
Playback.__index = Playback

function Playback.new(state, services)
    local self = setmetatable({}, Playback)
    self.state    = state
    self.services = services    -- { CameraSystem, AudioTimeline, Subtitles, PropAttachment, CameraEffects }
    self._conn    = nil
    self._lastTime= 0
    return self
end

function Playback:start()
    if self._conn then return end
    self._lastTime = os.clock()
    self._conn = RunService.Heartbeat:Connect(function()
        self:_tick()
    end)
end

function Playback:stop()
    if self._conn then self._conn:Disconnect() self._conn = nil end
end

function Playback:_tick()
    local now = os.clock()
    local dt  = now - self._lastTime
    self._lastTime = now

    local data = self.state.data
    if data.playing then
        local t = data.time + dt
        if t >= data.length then
            if data.looping then
                t = t % data.length
            else
                t = data.length
                self.state:set("playing", false)
            end
        end
        self.state:set("time", t)
    end

    self:render(data.time)
end

-- Render a single frame at time `t` (used by playback AND scrubbing).
function Playback:render(t)
    local data = self.state.data

    -- 1. Rig tracks
    for _, track in ipairs(data.tracks) do
        if track.kind == Constants.TRACK_KIND.Rig and not track.muted and track.target and track.target.Parent then
            for _, motor in ipairs(RigManager.findMotors(track.target)) do
                local keys = track.motors[motor.Name]
                if keys and #keys > 0 then
                    local cf = Keyframes.evaluate(keys, t)
                    if cf then motor.Transform = cf end
                end
            end
        end
    end

    -- 2. Camera track + mode
    if self.services.CameraSystem then
        self.services.CameraSystem:render(t, data)
    end

    -- 3. Camera effects
    if self.services.CameraEffects then
        self.services.CameraEffects:render(t, data)
    end

    -- 4. Audio
    if self.services.AudioTimeline then
        self.services.AudioTimeline:render(t, data)
    end

    -- 5. Subtitles
    if self.services.Subtitles then
        self.services.Subtitles:render(t, data)
    end

    -- 6. Prop attachments / animation
    if self.services.PropAttachment then
        self.services.PropAttachment:render(t, data)
    end
end

return Playback
