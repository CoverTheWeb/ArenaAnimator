-- Timeline.lua
-- Track / clip data model. Pure data; rendering lives in UI/TimelinePanel.

local Constants = require(script.Parent.Parent.Constants)

local Timeline = {}

local function newId()
    return string.format("%x%x", math.random(0, 0xFFFFFF), tick() * 1000 % 0xFFFFFF)
end

function Timeline.newRigTrack(rig)
    return {
        id     = newId(),
        kind   = Constants.TRACK_KIND.Rig,
        name   = rig.Name,
        target = rig,
        muted  = false,
        solo   = false,
        -- per-motor key arrays: motorName -> { {time,value,easing}, ... }
        motors = {},
    }
end

function Timeline.newCameraTrack()
    return {
        id     = newId(),
        kind   = Constants.TRACK_KIND.Camera,
        name   = "Camera",
        muted  = false,
        mode   = Constants.CAMERA_MODE.Cinematic,
        keys   = {},   -- {time, value=CFrame, easing}
        fovKeys= {},   -- {time, value=number, easing}
        followTarget = nil,
        followOffset = Vector3.new(0, 4, 10),
    }
end

function Timeline.newAudioTrack(soundId, name)
    return {
        id      = newId(),
        kind    = Constants.TRACK_KIND.Audio,
        name    = name or "Audio",
        soundId = soundId,
        start   = 0,
        length  = 5,
        volume  = 1,
        pitch   = 1,
        trimIn  = 0,
        trimOut = 0,
    }
end

function Timeline.newPropTrack(prop)
    return {
        id     = newId(),
        kind   = Constants.TRACK_KIND.Prop,
        name   = prop.Name,
        target = prop,
        muted  = false,
        events = {}, -- { {time, type="Attach"|"Detach", limb=name, offset=CFrame} }
        keys   = {}, -- prop CFrame keys when detached and animated independently
    }
end

function Timeline.newSubtitleTrack()
    return {
        id    = newId(),
        kind  = Constants.TRACK_KIND.Subtitle,
        name  = "Subtitles",
        muted = false,
        clips = {}, -- { {time, length, text, fx="Fade", color=Color3} }
    }
end

function Timeline.newEffectTrack()
    return {
        id    = newId(),
        kind  = Constants.TRACK_KIND.Effect,
        name  = "Camera Effects",
        muted = false,
        clips = {}, -- { {time, length, type="Shake"|"Zoom"|"DollyZoom"|"Flash", params={}} }
    }
end

return Timeline
