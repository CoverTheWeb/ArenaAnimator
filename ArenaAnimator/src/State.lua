-- State.lua
-- Tiny reactive store. Subscribers fire on State:set() / State:patch().

local Constants = require(script.Parent.Constants)

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self._listeners = {}
    self.data = {
        time          = 0,
        playing       = false,
        looping       = false,
        fps           = Constants.DEFAULT_FPS,
        length        = Constants.DEFAULT_LENGTH,
        zoom          = Constants.PIXELS_PER_SEC,
        selectedTrack = nil,
        selectedKey   = nil,
        tracks        = {},   -- array of track tables
        cameraMode    = Constants.CAMERA_MODE.Free,
        followTarget  = nil,
        subtitle      = nil,
        facePresets   = {},   -- name -> {[ControlName]=number}
    }
    return self
end

function State:subscribe(fn)
    table.insert(self._listeners, fn)
    return function()
        for i, v in ipairs(self._listeners) do
            if v == fn then table.remove(self._listeners, i) break end
        end
    end
end

function State:_emit(reason)
    for _, fn in ipairs(self._listeners) do
        task.spawn(fn, self.data, reason)
    end
end

function State:set(key, value)
    self.data[key] = value
    self:_emit(key)
end

function State:patch(tbl)
    for k, v in pairs(tbl) do self.data[k] = v end
    self:_emit("patch")
end

function State:addTrack(track)
    table.insert(self.data.tracks, track)
    self:_emit("tracks")
    return track
end

function State:removeTrack(track)
    for i, t in ipairs(self.data.tracks) do
        if t == track then table.remove(self.data.tracks, i) break end
    end
    self:_emit("tracks")
end

return State
