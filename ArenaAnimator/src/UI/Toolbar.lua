-- Toolbar.lua
-- Top horizontal toolbar with playback transport + global actions.

local Theme    = require(script.Parent.Theme)
local Widgets  = require(script.Parent.Widgets)
local Constants= require(script.Parent.Parent.Constants)
local MotionBuilder = require(script.Parent.Parent.Modules.Features.MotionBuilder)
local Exporter      = require(script.Parent.Parent.Modules.Exporter)
local Selection     = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Toolbar = {}
Toolbar.__index = Toolbar

function Toolbar.new(state, services)
    local self = setmetatable({}, Toolbar)
    self.state = state
    self.services = services
    self:_build()
    state:subscribe(function() self:_render() end)
    return self
end

local function makeBtn(parent, label, color, fn)
    local b = Widgets.button({
        Parent = parent,
        Size = UDim2.new(0, 90, 1, -8),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = color or Theme.Colors.Header,
        Text = label,
        Events = { MouseButton1Click = fn },
    })
    return b
end

function Toolbar:_build()
    self.root = Widgets.frame({
        Name = "Toolbar",
        Size = UDim2.new(1, 0, 0, Theme.Metrics.ToolbarHeight),
        BackgroundColor3 = Theme.Colors.Header,
    })

    local layout = Widgets.list(self.root, 6, Enum.FillDirection.Horizontal)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Widgets.padding(self.root, 6)

    self.playBtn = makeBtn(self.root, "▶ Play", Theme.Colors.Good, function()
        self.state:patch({ playing = not self.state.data.playing })
    end)

    makeBtn(self.root, "⏮ Start", nil, function()
        self.state:patch({ time = 0, playing = false })
    end)
    makeBtn(self.root, "⏭ End", nil, function()
        self.state:patch({ time = self.state.data.length, playing = false })
    end)

    self.loopBtn = makeBtn(self.root, "⟲ Loop", nil, function()
        self.state:patch({ looping = not self.state.data.looping })
    end)

    makeBtn(self.root, "🎯 Key (K)", Theme.Colors.Accent, function()
        for _, t in ipairs(self.state.data.tracks) do
            if t.kind == Constants.TRACK_KIND.Rig then
                MotionBuilder.captureKeyframe(t, self.state.data.time)
            elseif t.kind == Constants.TRACK_KIND.Camera then
                local cam = workspace.CurrentCamera
                if cam then
                    table.insert(t.keys, { time=self.state.data.time, value=cam.CFrame, easing="Cubic" })
                    table.sort(t.keys, function(a,b) return a.time < b.time end)
                    table.insert(t.fovKeys, { time=self.state.data.time, value=cam.FieldOfView, easing="Cubic" })
                    table.sort(t.fovKeys, function(a,b) return a.time < b.time end)
                end
            end
        end
        self.state:_emit("tracks")
    end)

    makeBtn(self.root, "🗑 Delete Key", Theme.Colors.Bad, function()
        for _, t in ipairs(self.state.data.tracks) do
            if t.kind == Constants.TRACK_KIND.Rig then
                MotionBuilder.deleteKeyframe(t, self.state.data.time)
            end
        end
        self.state:_emit("tracks")
    end)

    -- Camera mode dropdown (cycle button)
    self.modeBtn = makeBtn(self.root, "📷 Cinematic", nil, function()
        local order = { "Free", "FirstPerson", "OverShoulder", "Cinematic", "Follow" }
        local current = self.state.data.cameraMode
        local i = 1
        for k, v in ipairs(order) do if v == current then i = k break end end
        local nxt = order[(i % #order) + 1]
        self.state:patch({ cameraMode = nxt })
        -- Apply to camera tracks too
        for _, t in ipairs(self.state.data.tracks) do
            if t.kind == Constants.TRACK_KIND.Camera then t.mode = nxt end
        end
    end)

    -- Trackball toggle
    self.trackballBtn = makeBtn(self.root, "⚡ Trackball: OFF", nil, function()
        if self.services.Trackball.enabled then
            self.services.Trackball:disable()
            self.trackballBtn.Text = "⚡ Trackball: OFF"
        else
            self.services.Trackball:enable(self.services.plugin)
            self.trackballBtn.Text = "⚡ Trackball: ON"
        end
    end)

    makeBtn(self.root, "💾 Export Anim", Theme.Colors.Warn, function()
        ChangeHistoryService:SetWaypoint("Arena: ExportAnim before")
        local folder = Instance.new("Folder")
        folder.Name = "ArenaAnimExports"
        folder.Parent = workspace
        for _, t in ipairs(self.state.data.tracks) do
            if t.kind == Constants.TRACK_KIND.Rig then
                local seq = Exporter.exportRig(self.state, t)
                seq.Parent = folder
            end
        end
        Selection:Set({folder})
        ChangeHistoryService:SetWaypoint("Arena: ExportAnim after")
    end)

    makeBtn(self.root, "🎞 Export Cutscene", Theme.Colors.Accent, function()
        ChangeHistoryService:SetWaypoint("Arena: ExportCutscene before")
        local folder = Exporter.exportCutscene(self.state)
        folder.Parent = workspace
        Selection:Set({folder})
        ChangeHistoryService:SetWaypoint("Arena: ExportCutscene after")
    end)

    -- Time display (right aligned via spacer)
    Widgets.frame({ Parent = self.root, BackgroundTransparency = 1, Size = UDim2.new(0, 8, 1, 0) })
    self.timeLabel = Widgets.label({
        Parent = self.root, Size = UDim2.new(0, 160, 1, 0),
        Text = "00.00 / 05.00", TextColor3 = Theme.Colors.SubText, TextSize = 13,
        Font = Theme.FontMono,
    })
end

function Toolbar:_render()
    local d = self.state.data
    self.playBtn.Text = d.playing and "⏸ Pause" or "▶ Play"
    self.playBtn.BackgroundColor3 = d.playing and Theme.Colors.Bad or Theme.Colors.Good
    self.loopBtn.BackgroundColor3 = d.looping and Theme.Colors.Accent or Theme.Colors.Header
    self.modeBtn.Text = "📷 " .. d.cameraMode
    self.timeLabel.Text = string.format("%05.2f / %05.2f  •  %d fps", d.time, d.length, d.fps)
end

return Toolbar
