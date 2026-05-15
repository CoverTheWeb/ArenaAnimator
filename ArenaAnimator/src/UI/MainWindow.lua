-- MainWindow.lua
-- Glues Toolbar + Properties + Timeline together inside a DockWidgetPluginGui.

local Theme        = require(script.Parent.Theme)
local Widgets      = require(script.Parent.Widgets)
local Toolbar      = require(script.Parent.Toolbar)
local Properties   = require(script.Parent.PropertiesPanel)
local TimelinePanel= require(script.Parent.TimelinePanel)

local MainWindow = {}
MainWindow.__index = MainWindow

function MainWindow.new(plugin, state, services)
    local self = setmetatable({}, MainWindow)
    self.plugin   = plugin
    self.state    = state
    self.services = services

    local info = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Bottom,
        false,   -- initially enabled
        false,   -- override saved state
        1100, 360,
        700, 240
    )
    self.gui = plugin:CreateDockWidgetPluginGui("ArenaAnimatorMain", info)
    self.gui.Title = "🎬 Arena Animator"
    self.gui.Name  = "ArenaAnimatorMain"
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local root = Widgets.frame({
        Parent = self.gui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Background,
    })

    -- Toolbar
    self.toolbar = Toolbar.new(state, services)
    self.toolbar.root.Parent = root

    -- Body: properties (left) + timeline (right)
    local body = Widgets.frame({
        Parent = root,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -Theme.Metrics.ToolbarHeight),
        Position = UDim2.new(0, 0, 0, Theme.Metrics.ToolbarHeight),
    })

    self.props = Properties.new(state, services)
    self.props.root.Parent = body
    self.props.root.Size = UDim2.new(0, 280, 1, 0)
    self.props.root.Position = UDim2.new(0, 0, 0, 0)

    self.timeline = TimelinePanel.new(state)
    self.timeline.root.Parent = body
    self.timeline.root.Size = UDim2.new(1, -280, 1, 0)
    self.timeline.root.Position = UDim2.new(0, 280, 0, 0)

    return self
end

function MainWindow:setEnabled(on) self.gui.Enabled = on end
function MainWindow:isEnabled() return self.gui.Enabled end

return MainWindow
