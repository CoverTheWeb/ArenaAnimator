-- CameraEffects.lua
-- Applies time-windowed camera FX on top of whatever CameraSystem produced.
-- Effects: Shake, Zoom, DollyZoom, Flash. Applied in evaluation order.

local Constants = require(script.Parent.Parent.Parent.Constants)

local CameraEffects = {}
CameraEffects.__index = CameraEffects

function CameraEffects.new()
    local self = setmetatable({}, CameraEffects)
    return self
end

local function applyShake(cam, alpha, params)
    local intensity = (params.intensity or 0.5) * (1 - alpha) -- decays
    local offset = Vector3.new(
        (math.random() - 0.5) * intensity,
        (math.random() - 0.5) * intensity,
        (math.random() - 0.5) * intensity
    )
    cam.CFrame = cam.CFrame + offset
end

local function applyZoom(cam, alpha, params)
    local startFov = params.startFov or 70
    local endFov   = params.endFov   or 30
    cam.FieldOfView = startFov + (endFov - startFov) * alpha
end

local function applyDollyZoom(cam, alpha, params)
    -- Move camera forward while widening FOV (or vice versa)
    local startFov = params.startFov or 70
    local endFov   = params.endFov   or 25
    local dist     = params.distance or -8
    cam.FieldOfView = startFov + (endFov - startFov) * alpha
    cam.CFrame = cam.CFrame + cam.CFrame.LookVector * (dist * alpha)
end

local function applyFlash(cam, alpha, params)
    -- A ScreenGui-based flash would be cleaner; in editor preview we just spike FOV briefly.
    local pulse = math.sin(alpha * math.pi)
    cam.FieldOfView = (cam.FieldOfView or 70) + pulse * (params.strength or 8)
end

local DISPATCH = {
    Shake     = applyShake,
    Zoom      = applyZoom,
    DollyZoom = applyDollyZoom,
    Flash     = applyFlash,
}

function CameraEffects:render(time, data)
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _, track in ipairs(data.tracks) do
        if track.kind == Constants.TRACK_KIND.Effect and not track.muted then
            for _, clip in ipairs(track.clips) do
                if time >= clip.time and time <= clip.time + clip.length then
                    local alpha = (time - clip.time) / math.max(0.001, clip.length)
                    local fn = DISPATCH[clip.type]
                    if fn then fn(cam, alpha, clip.params or {}) end
                end
            end
        end
    end
end

return CameraEffects
