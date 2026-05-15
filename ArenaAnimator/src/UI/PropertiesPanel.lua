-- PropertiesPanel.lua
-- Right side inspector. Shows context-sensitive controls for the selected
-- track / object, plus all "Add Feature" buttons.

local Selection = game:GetService("Selection")

local Theme   = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local Constants = require(script.Parent.Parent.Constants)
local Timeline      = require(script.Parent.Parent.Modules.Timeline)
local MotionBuilder = require(script.Parent.Parent.Modules.Features.MotionBuilder)
local FacePresets   = require(script.Parent.Parent.Modules.Features.FacePresets)
local AutoMovement  = require(script.Parent.Parent.Modules.Features.AutoMovement)
local RigManager    = require(script.Parent.Parent.RigManager)

local PropertiesPanel = {}
PropertiesPanel.__index = PropertiesPanel

function PropertiesPanel.new(state, services)
    local self = setmetatable({}, PropertiesPanel)
    self.state = state
    self.services = services
    self:_build()
    state:subscribe(function() self:_render() end)
    return self
end

local function section(parent, title)
    local f = Widgets.frame({
        Parent = parent,
        BackgroundColor3 = Theme.Colors.Header,
        Size = UDim2.new(1, 0, 0, 24),
    })
    Widgets.label({
        Parent = f,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = title,
        Font = Theme.FontBold,
        TextColor3 = Theme.Colors.Accent,
        TextSize = 13,
    })
    return f
end

local function row(parent)
    return Widgets.frame({
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
end

function PropertiesPanel:_build()
    self.root = Widgets.scroll({
        Name = "Properties",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Panel,
    })
    Widgets.list(self.root, 6)
    Widgets.padding(self.root, 8)
end

local function clearChildrenExcept(parent, keep)
    for _, c in ipairs(parent:GetChildren()) do
        if not keep[c.ClassName] then c:Destroy() end
    end
end

function PropertiesPanel:_render()
    clearChildrenExcept(self.root, { UIListLayout = true, UIPadding = true })

    section(self.root, "🎬 Tracks")

    -- Add rig from selection
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Add Rig from Selection",
        Events = {
            MouseButton1Click = function()
                for _, sel in ipairs(Selection:Get()) do
                    if RigManager.isAnimatable(sel) then
                        self.state:addTrack(Timeline.newRigTrack(sel))
                    end
                end
            end,
        },
    })

    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Add Camera Track",
        Events = {
            MouseButton1Click = function()
                self.state:addTrack(Timeline.newCameraTrack())
            end,
        },
    })

    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Add Subtitle Track",
        Events = {
            MouseButton1Click = function()
                self.state:addTrack(Timeline.newSubtitleTrack())
            end,
        },
    })

    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Add Camera Effects Track",
        Events = {
            MouseButton1Click = function()
                self.state:addTrack(Timeline.newEffectTrack())
            end,
        },
    })

    -- Audio: requires a sound id
    local audioRow = row(self.root)
    local audioBox = Widgets.textbox({
        Parent = audioRow,
        Size = UDim2.new(0.6, -4, 1, -4),
        Position = UDim2.new(0, 0, 0, 2),
        PlaceholderText = "rbxassetid://...",
        Text = "",
    })
    Widgets.button({
        Parent = audioRow,
        Size = UDim2.new(0.4, 0, 1, -4),
        Position = UDim2.new(0.6, 4, 0, 2),
        Text = "+ Audio",
        Events = {
            MouseButton1Click = function()
                if audioBox.Text == "" then return end
                self.state:addTrack(Timeline.newAudioTrack(audioBox.Text, "Audio"))
            end,
        },
    })

    -- Prop track from selection
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Add Prop Track from Selection",
        Events = {
            MouseButton1Click = function()
                for _, sel in ipairs(Selection:Get()) do
                    if sel:IsA("Model") or sel:IsA("BasePart") then
                        self.state:addTrack(Timeline.newPropTrack(sel))
                    end
                end
            end,
        },
    })

    section(self.root, "⚙ Playback")
    do
        local r = row(self.root)
        Widgets.label({ Parent=r, Size=UDim2.new(0.4,0,1,0), Text="Length (s)" })
        local box = Widgets.textbox({
            Parent=r, Size=UDim2.new(0.55,0,1,-4), Position=UDim2.new(0.45,0,0,2),
            Text=tostring(self.state.data.length),
        })
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then self.state:patch({ length = math.clamp(n, Constants.MIN_LENGTH, Constants.MAX_LENGTH) }) end
        end)
    end
    do
        local r = row(self.root)
        Widgets.label({ Parent=r, Size=UDim2.new(0.4,0,1,0), Text="FPS" })
        local box = Widgets.textbox({
            Parent=r, Size=UDim2.new(0.55,0,1,-4), Position=UDim2.new(0.45,0,0,2),
            Text=tostring(self.state.data.fps),
        })
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then self.state:patch({ fps = math.clamp(math.floor(n), 1, 240) }) end
        end)
    end
    do
        local r = row(self.root)
        Widgets.label({ Parent=r, Size=UDim2.new(0.4,0,1,0), Text="Zoom" })
        local box = Widgets.textbox({
            Parent=r, Size=UDim2.new(0.55,0,1,-4), Position=UDim2.new(0.45,0,0,2),
            Text=tostring(self.state.data.zoom),
        })
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then self.state:patch({ zoom = math.clamp(n, 20, 600) }) end
        end)
    end

    section(self.root, "🚶 Auto Movement")
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "Generate Walk on Selected Rig",
        Events = {
            MouseButton1Click = function()
                local rigTrack
                for _, t in ipairs(self.state.data.tracks) do
                    if t.kind == Constants.TRACK_KIND.Rig then rigTrack = t break end
                end
                if not rigTrack or not rigTrack.target then return end
                local root = rigTrack.target:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local startCF = root.CFrame
                local endCF   = startCF + startCF.LookVector * 16
                AutoMovement.generate(rigTrack, startCF, endCF, self.state.data.length, self.state.data.fps, "Walk")
                self.state:_emit("tracks")
            end,
        },
    })
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "Generate Run on Selected Rig",
        Events = {
            MouseButton1Click = function()
                local rigTrack
                for _, t in ipairs(self.state.data.tracks) do
                    if t.kind == Constants.TRACK_KIND.Rig then rigTrack = t break end
                end
                if not rigTrack or not rigTrack.target then return end
                local root = rigTrack.target:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local startCF = root.CFrame
                local endCF   = startCF + startCF.LookVector * 32
                AutoMovement.generate(rigTrack, startCF, endCF, self.state.data.length, self.state.data.fps, "Run")
                self.state:_emit("tracks")
            end,
        },
    })

    section(self.root, "😊 Face Presets")
    do
        local r = row(self.root)
        local nameBox = Widgets.textbox({
            Parent = r,
            Size = UDim2.new(0.55, -4, 1, -4),
            Position = UDim2.new(0, 0, 0, 2),
            PlaceholderText = "Preset name...",
            Text = "",
        })
        Widgets.button({
            Parent = r,
            Size = UDim2.new(0.45, 0, 1, -4),
            Position = UDim2.new(0.55, 4, 0, 2),
            Text = "Save from Selection",
            Events = {
                MouseButton1Click = function()
                    if nameBox.Text == "" then return end
                    for _, sel in ipairs(Selection:Get()) do
                        local head = sel:IsA("Model") and FacePresets.findHead(sel) or
                                     (sel:IsA("MeshPart") and sel.Name == "Head" and sel)
                        if head then
                            self.state.data.facePresets[nameBox.Text] = FacePresets.captureFromHead(head)
                            self.state:_emit("facePresets")
                            break
                        end
                    end
                end,
            },
        })
    end
    -- List presets
    for name, preset in pairs(self.state.data.facePresets) do
        local r = row(self.root)
        Widgets.label({ Parent=r, Size=UDim2.new(0.5,0,1,0), Text="• "..name, TextColor3=Theme.Colors.Good })
        Widgets.button({
            Parent = r,
            Size = UDim2.new(0.5, 0, 1, -4),
            Position = UDim2.new(0.5, 0, 0, 2),
            Text = "Apply",
            Events = {
                MouseButton1Click = function()
                    for _, sel in ipairs(Selection:Get()) do
                        local head = sel:IsA("Model") and FacePresets.findHead(sel) or sel
                        if head then FacePresets.applyToHead(head, preset, 1) end
                    end
                end,
            },
        })
    end

    section(self.root, "📝 Add Subtitle")
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "+ Subtitle 'Hello!' at playhead",
        Events = {
            MouseButton1Click = function()
                local subTrack
                for _, t in ipairs(self.state.data.tracks) do
                    if t.kind == Constants.TRACK_KIND.Subtitle then subTrack = t break end
                end
                if not subTrack then
                    subTrack = self.state:addTrack(Timeline.newSubtitleTrack())
                end
                table.insert(subTrack.clips, {
                    time = self.state.data.time,
                    length = 2,
                    text = "Hello!",
                    fx = "Fade",
                })
                self.state:_emit("tracks")
            end,
        },
    })

    section(self.root, "🎥 Camera Effects")
    for _, kind in ipairs({"Shake", "Zoom", "DollyZoom", "Flash"}) do
        Widgets.button({
            Parent = self.root,
            Size = UDim2.new(1, 0, 0, 26),
            Text = "+ "..kind.." at playhead",
            Events = {
                MouseButton1Click = function()
                    local efxTrack
                    for _, t in ipairs(self.state.data.tracks) do
                        if t.kind == Constants.TRACK_KIND.Effect then efxTrack = t break end
                    end
                    if not efxTrack then efxTrack = self.state:addTrack(Timeline.newEffectTrack()) end
                    table.insert(efxTrack.clips, {
                        time = self.state.data.time, length = 1, type = kind, params = {},
                    })
                    self.state:_emit("tracks")
                end,
            },
        })
    end

    section(self.root, "🖐 Prop Attach")
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "Attach selected prop to RightHand",
        Events = {
            MouseButton1Click = function()
                local propTrack
                for _, t in ipairs(self.state.data.tracks) do
                    if t.kind == Constants.TRACK_KIND.Prop then propTrack = t break end
                end
                if not propTrack then return end
                table.insert(propTrack.events, {
                    time = self.state.data.time, type = "Attach",
                    limb = "RightHand", offset = CFrame.new(),
                })
                table.sort(propTrack.events, function(a,b) return a.time < b.time end)
                self.state:_emit("tracks")
            end,
        },
    })
    Widgets.button({
        Parent = self.root,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "Detach prop at playhead",
        Events = {
            MouseButton1Click = function()
                local propTrack
                for _, t in ipairs(self.state.data.tracks) do
                    if t.kind == Constants.TRACK_KIND.Prop then propTrack = t break end
                end
                if not propTrack then return end
                table.insert(propTrack.events, {
                    time = self.state.data.time, type = "Detach",
                })
                table.sort(propTrack.events, function(a,b) return a.time < b.time end)
                self.state:_emit("tracks")
            end,
        },
    })
end

return PropertiesPanel
