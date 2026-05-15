-- AudioTimeline.lua
-- Plays Sound clips at the right point on the timeline during preview.

local Constants    = require(script.Parent.Parent.Parent.Constants)
local SoundService = game:GetService("SoundService")

local AudioTimeline = {}
AudioTimeline.__index = AudioTimeline

function AudioTimeline.new()
    local self = setmetatable({}, AudioTimeline)
    self._sounds = {}  -- trackId -> Sound
    return self
end

function AudioTimeline:_getSound(track)
    local s = self._sounds[track.id]
    if s and s.Parent then return s end
    s = Instance.new("Sound")
    s.SoundId = track.soundId
    s.Volume  = track.volume
    s.PlaybackSpeed = track.pitch
    s.Parent  = SoundService
    self._sounds[track.id] = s
    return s
end

function AudioTimeline:render(time, data)
    for _, track in ipairs(data.tracks) do
        if track.kind == Constants.TRACK_KIND.Audio and track.soundId and track.soundId ~= "" then
            local sound = self:_getSound(track)
            sound.SoundId = track.soundId
            sound.Volume  = track.volume
            sound.PlaybackSpeed = track.pitch

            local startT = track.start
            local endT   = track.start + track.length

            if data.playing and time >= startT and time < endT and not track.muted then
                if not sound.IsPlaying then
                    sound.TimePosition = (time - startT) + (track.trimIn or 0)
                    sound:Play()
                end
            else
                if sound.IsPlaying then sound:Pause() end
                if not data.playing then
                    sound.TimePosition = math.clamp(
                        (time - startT) + (track.trimIn or 0), 0, math.max(0.01, sound.TimeLength)
                    )
                end
            end
        end
    end
end

function AudioTimeline:stopAll()
    for _, s in pairs(self._sounds) do
        if s and s.Parent then s:Stop() end
    end
end

function AudioTimeline:cleanup()
    for _, s in pairs(self._sounds) do
        if s and s.Parent then s:Destroy() end
    end
    self._sounds = {}
end

return AudioTimeline
