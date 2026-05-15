-- Widgets.lua
-- Tiny declarative wrapper around Instance.new for clean UI code.

local Theme = require(script.Parent.Theme)

local Widgets = {}

local function apply(inst, props)
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            -- set last
        elseif k == "Children" then
            for _, child in ipairs(v) do child.Parent = inst end
        elseif k == "Events" then
            for ev, fn in pairs(v) do inst[ev]:Connect(fn) end
        else
            inst[k] = v
        end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function Widgets.new(class, props)
    return apply(Instance.new(class), props)
end

function Widgets.frame(props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = Theme.Colors.Panel
    return apply(f, props)
end

function Widgets.label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Theme.Font
    l.TextSize = 13
    l.TextColor3 = Theme.Colors.Text
    l.TextXAlignment = Enum.TextXAlignment.Left
    return apply(l, props)
end

function Widgets.button(props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.BackgroundColor3 = Theme.Colors.Header
    b.TextColor3 = Theme.Colors.Text
    b.Font = Theme.Font
    b.TextSize = 13
    b.Text = ""

    -- subtle hover
    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = Theme.Colors.Accent
    end)
    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = Theme.Colors.Header
    end)

    apply(b, props)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Metrics.Corner
    corner.Parent = b
    return b
end

function Widgets.textbox(props)
    local t = Instance.new("TextBox")
    t.BorderSizePixel = 0
    t.BackgroundColor3 = Theme.Colors.Background
    t.TextColor3 = Theme.Colors.Text
    t.Font = Theme.Font
    t.TextSize = 13
    t.ClearTextOnFocus = false
    apply(t, props)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Metrics.Corner
    corner.Parent = t
    return t
end

function Widgets.scroll(props)
    local s = Instance.new("ScrollingFrame")
    s.BorderSizePixel = 0
    s.BackgroundColor3 = Theme.Colors.Panel
    s.ScrollBarThickness = 6
    s.CanvasSize = UDim2.new()
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    return apply(s, props)
end

function Widgets.list(parent, padding, fillDirection)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, padding or 4)
    l.FillDirection = fillDirection or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

function Widgets.padding(parent, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, p)
    pad.PaddingBottom = UDim.new(0, p)
    pad.PaddingLeft   = UDim.new(0, p)
    pad.PaddingRight  = UDim.new(0, p)
    pad.Parent = parent
    return pad
end

return Widgets
