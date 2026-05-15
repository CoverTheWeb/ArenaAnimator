-- MotionBuilder.lua
-- Higher-level helpers for adding/removing keyframes across multiple motors at once.

local Constants  = require(script.Parent.Parent.Parent.Constants)
local Keyframes  = require(script.Parent.Parent.Keyframes)
local RigManager = require(script.Parent.Parent.RigManager)

local MotionBuilder = {}

function MotionBuilder.captureKeyframe(track, time, easing)
    if track.kind ~= Constants.TRACK_KIND.Rig then return end
    if not track.target or not track.target.Parent then return end

    for _, motor in ipairs(RigManager.findMotors(track.target)) do
        track.motors[motor.Name] = track.motors[motor.Name] or {}
        Keyframes.insert(track.motors[motor.Name], time, motor.Transform, easing or "Cubic")
    end
end

function MotionBuilder.captureMotor(track, motor, time, easing)
    track.motors[motor.Name] = track.motors[motor.Name] or {}
    Keyframes.insert(track.motors[motor.Name], time, motor.Transform, easing or "Cubic")
end

function MotionBuilder.deleteKeyframe(track, time)
    if track.kind ~= Constants.TRACK_KIND.Rig then return end
    for _, keys in pairs(track.motors) do
        Keyframes.remove(keys, time)
    end
end

-- Returns a sorted, deduplicated list of every keyframe time used across all motors of a track
function MotionBuilder.allTimes(track)
    local set = {}
    for _, keys in pairs(track.motors) do
        for _, k in ipairs(keys) do set[k.time] = true end
    end
    local list = {}
    for t in pairs(set) do table.insert(list, t) end
    table.sort(list)
    return list
end

function MotionBuilder.nextKeyframe(track, time)
    local times = MotionBuilder.allTimes(track)
    for _, t in ipairs(times) do
        if t > time + 1e-4 then return t end
    end
    return nil
end

function MotionBuilder.prevKeyframe(track, time)
    local times = MotionBuilder.allTimes(track)
    local last
    for _, t in ipairs(times) do
        if t < time - 1e-4 then last = t else break end
    end
    return last
end

return MotionBuilder
