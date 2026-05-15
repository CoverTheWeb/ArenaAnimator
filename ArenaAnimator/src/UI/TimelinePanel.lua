-- TimelinePanel.lua
-- The horizontal multi-track timeline at the bottom of the main window.

local Theme    = require(script.Parent.Theme)
local Widgets  = require(script.Parent.Widgets)
local Constants= require(script.Parent.Parent.Constants)
local MotionBuilder = require(script.Parent.Parent.Modules.Features.MotionBuilder)

local TimelinePanel = {}
TimelinePanel.__index = TimelinePanel

function TimelinePanel.new(state)
    local self = setmetatable({}, TimelinePanel)
    self.state = state
    self:_build()
    state:subscribe(function() self:_render() end)
    return self
end

function TimelinePanel:_build()
    local root = Widgets.frame({
        Name             = "Timeline",
        BackgroundColor3 = Theme.Colors.Panel,
        Size             = UDim2.new(1, 0, 1, 0),
    })
    self.root = root

    -- Top ruler
    self.ruler = Widgets.frame({
        Parent           = root,
        BackgroundColor3 = Theme.Colors.Header,
        Size             = UDim2.new(1, 0, 0, Theme.Metrics.TimeRulerHeight),
        Position         = UDim2.new(0, 0, 0, 0),
        Name             = "Ruler",
    })

    -- Scroll container for tracks
    self.scroll = Widgets.scroll({
        Parent           = root,
        Position         = UDim2.new(0, 0, 0, Theme.Metrics.TimeRulerHeight),
        Size             = UDim2.new(1, 0, 1, -Theme.Metrics.TimeRulerHeight),
        BackgroundColor3 = Theme.Colors.Background,
        CanvasSize       = UDim2.new(0, 4000, 0, 0),
    })
    Widgets.list(self.scroll, 2)

    -- Playhead overlay
    self.playhead = Widgets.frame({
        Parent           = root,
        BackgroundColor3 = Theme.Colors.Playhead,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 2, 1, 0),
        Position         = UDim2.new(0, 160, 0, 0),
        ZIndex           = 10,
        Name             = "Playhead",
    })

    -- Click ruler to scrub
    self.ruler.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        self._scrubbing = true
        self:_scrubTo(input.Position.X)
    end)
    self.ruler.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._scrubbing = false
        end
    end)
    self.ruler.InputChanged:Connect(function(input)
        if self._scrubbing and input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_scrubTo(input.Position.X)
        end
    end)
end

function TimelinePanel:_scrubTo(mouseX)
    local rulerAbsX = self.ruler.AbsolutePosition.X
    local labelW = 160
    local x = mouseX - rulerAbsX - labelW + self.scroll.CanvasPosition.X
    local secs = math.max(0, x / self.state.data.zoom)
    secs = math.min(secs, self.state.data.length)
    self.state:patch({ time = secs, playing = false })
end

local function makeTrackRow(state, track)
    local row = Widgets.frame({
        Size             = UDim2.new(1, 0, 0, Theme.Metrics.TrackHeight),
        BackgroundColor3 = Theme.Colors.Panel,
        Name             = "Track_" .. track.id,
    })

    -- Left label
    local label = Widgets.frame({
        Parent           = row,
        Size             = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Theme.colorForKind(track.kind):Lerp(Color3.new(), 0.4),
    })
    Widgets.label({
        Parent  = label,
        Size    = UDim2.new(1, -28, 1, 0),
        Position= UDim2.new(0, 8, 0, 0),
        Text    = string.format("[%s] %s", track.kind:sub(1,3), track.name),
        TextColor3 = Theme.Colors.Text,
        Font    = Theme.FontBold,
    })

    -- Mute / Solo toggles
    Widgets.button({
        Parent = label,
        Size = UDim2.new(0, 22, 0, 18),
        Position = UDim2.new(1, -26, 0, 5),
        Text = track.muted and "M" or "•",
        BackgroundColor3 = track.muted and Theme.Colors.Bad or Theme.Colors.Header,
        Events = {
            MouseButton1Click = function()
                track.muted = not track.muted
                state:_emit("tracks")
            end,
        },
    })

    -- Track lane (right side)
    local lane = Widgets.frame({
        Parent           = row,
        Size             = UDim2.new(1, -160, 1, 0),
        Position         = UDim2.new(0, 160, 0, 0),
        BackgroundColor3 = Theme.Colors.Background,
    })

    -- Draw keyframe diamonds / clips
    local function renderMarkers()
        for _, c in ipairs(lane:GetChildren()) do
            if c.Name == "Marker" then c:Destroy() end
        end
        local zoom = state.data.zoom

        if track.kind == Constants.TRACK_KIND.Rig then
            local times = MotionBuilder.allTimes(track)
            for _, t in ipairs(times) do
                local m = Widgets.frame({
                    Name   = "Marker",
                    Parent = lane,
                    BackgroundColor3 = Theme.Colors.Accent,
                    Size   = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0, t * zoom - 4, 0.5, -4),
                    Rotation = 45,
                })
                local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0,1) corner.Parent = m
            end

        elseif track.kind == Constants.TRACK_KIND.Camera then
            for _, k in ipairs(track.keys) do
                Widgets.frame({
                    Name="Marker", Parent=lane,
                    BackgroundColor3 = Theme.Colors.TrackCamera,
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0, k.time * zoom - 4, 0.5, -4),
                    Rotation = 45,
                })
            end

        elseif track.kind == Constants.TRACK_KIND.Audio then
            Widgets.frame({
                Name="Marker", Parent=lane,
                BackgroundColor3 = Theme.colorForKind("Audio"),
                BackgroundTransparency = 0.4,
                Size = UDim2.new(0, track.length * zoom, 0, 18),
                Position = UDim2.new(0, track.start * zoom, 0.5, -9),
            })

        elseif track.kind == Constants.TRACK_KIND.Subtitle then
            for _, c in ipairs(track.clips) do
                local clip = Widgets.frame({
                    Name="Marker", Parent=lane,
                    BackgroundColor3 = Theme.colorForKind("Subtitle"),
                    BackgroundTransparency = 0.3,
                    Size = UDim2.new(0, c.length * zoom, 0, 18),
                    Position = UDim2.new(0, c.time * zoom, 0.5, -9),
                })
                Widgets.label({
                    Parent=clip, Size=UDim2.new(1,-4,1,0), Position=UDim2.new(0,4,0,0),
                    Text=c.text or "", TextColor3=Color3.new(1,1,1), TextSize=11,
                })
            end

        elseif track.kind == Constants.TRACK_KIND.Effect then
            for _, c in ipairs(track.clips) do
                local clip = Widgets.frame({
                    Name="Marker", Parent=lane,
                    BackgroundColor3 = Theme.colorForKind("Effect"),
                    BackgroundTransparency = 0.5,
                    Size = UDim2.new(0, c.length * zoom, 0, 18),
                    Position = UDim2.new(0, c.time * zoom, 0.5, -9),
                })
                Widgets.label({
                    Parent=clip, Size=UDim2.new(1,-4,1,0), Position=UDim2.new(0,4,0,0),
                    Text=c.type or "", TextColor3=Color3.new(0,0,0), TextSize=11,
                })
            end

        elseif track.kind == Constants.TRACK_KIND.Prop then
            for _, ev in ipairs(track.events) do
                Widgets.frame({
                    Name="Marker", Parent=lane,
                    BackgroundColor3 = (ev.type=="Attach") and Theme.Colors.Good or Theme.Colors.Warn,
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0, ev.time * zoom - 5, 0.5, -5),
                    Rotation = 45,
                })
            end
        end
    end

    renderMarkers()
    track._renderMarkers = renderMarkers
    return row
end

function TimelinePanel:_render()
    local data = self.state.data

    -- Update playhead position
    local labelW = 160
    local x = labelW + (data.time * data.zoom) - self.scroll.CanvasPosition.X
    self.playhead.Position = UDim2.new(0, x, 0, 0)

    -- Update ruler ticks
    for _, c in ipairs(self.ruler:GetChildren()) do
        if c.Name == "Tick" then c:Destroy() end
    end
    local ticks = math.ceil(data.length) + 1
    for i = 0, ticks do
        local px = labelW + i * data.zoom - self.scroll.CanvasPosition.X
        Widgets.label({
            Parent = self.ruler, Name = "Tick",
            Text   = tostring(i) .. "s",
            Position = UDim2.new(0, px + 2, 0, 2),
            Size   = UDim2.new(0, 30, 1, -2),
            TextColor3 = Theme.Colors.SubText,
            TextSize = 11,
        })
        Widgets.frame({
            Parent = self.ruler, Name = "Tick",
            BackgroundColor3 = Theme.Colors.Border,
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(0, px, 0, 0),
        })
    end

    -- Diff tracks
    local existing = {}
    for _, c in ipairs(self.scroll:GetChildren()) do
        if c.Name:sub(1,6) == "Track_" then existing[c.Name] = c end
    end
    for _, t in ipairs(data.tracks) do
        local key = "Track_" .. t.id
        if existing[key] then
            existing[key] = nil
            if t._renderMarkers then t._renderMarkers() end
        else
            local row = makeTrackRow(self.state, t)
            row.Parent = self.scroll
        end
    end
    for _, dead in pairs(existing) do dead:Destroy() end

    -- Canvas size grows with content
    self.scroll.CanvasSize = UDim2.new(0, math.max(2000, data.length * data.zoom + 200), 0, 0)
end

return TimelinePanel
