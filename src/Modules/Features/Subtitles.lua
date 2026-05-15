-- Subtitles.lua
-- Renders a single ScreenGui in CoreGui (preview only) showing whatever
-- subtitle clip is active at `time`, applying the chosen transition fx.

local CoreGui = game:GetService("CoreGui")
local Constants = require(script.Parent.Parent.Parent.Constants)

local Subtitles = {}
Subtitles.__index = Subtitles

function Subtitles.new()
    local self = setmetatable({}, Subtitles)
    self:_buildGui()
    return self
end

function Subtitles:_buildGui()
    local existing = CoreGui:FindFirstChild("ArenaAnimatorSubtitles")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ArenaAnimatorSubtitles"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.7, 0, 0, 70)
    frame.Position = UDim2.new(0.15, 0, 0.78, 0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.new()
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6) corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 1, -10)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 22
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextWrapped = true
    label.Text = ""
    label.Parent = frame

    self._gui   = gui
    self._frame = frame
    self._label = label
    gui.Enabled = false
end

function Subtitles:render(time, data)
    local active
    for _, track in ipairs(data.tracks) do
        if track.kind == Constants.TRACK_KIND.Subtitle and not track.muted then
            for _, c in ipairs(track.clips) do
                if time >= c.time and time <= c.time + c.length then
                    active = c
                    break
                end
            end
        end
        if active then break end
    end

    if not active then
        self._gui.Enabled = false
        return
    end

    self._gui.Enabled = true
    local localT = (time - active.time) / math.max(0.001, active.length)
    local text   = active.text or ""

    if active.fx == "Typewriter" then
        local n = math.floor(#text * math.min(localT * 1.5, 1))
        self._label.Text = text:sub(1, n)
        self._label.TextTransparency = 0
        self._frame.Position = UDim2.new(0.15, 0, 0.78, 0)
    elseif active.fx == "Fade" then
        self._label.Text = text
        local fadeIn  = math.min(localT / 0.15, 1)
        local fadeOut = math.min((1 - localT) / 0.15, 1)
        self._label.TextTransparency = 1 - math.min(fadeIn, fadeOut)
        self._frame.BackgroundTransparency = 0.4 + (1 - math.min(fadeIn, fadeOut)) * 0.6
        self._frame.Position = UDim2.new(0.15, 0, 0.78, 0)
    elseif active.fx == "SlideUp" then
        self._label.Text = text
        local slide = math.clamp(localT / 0.2, 0, 1)
        local y = 0.92 - 0.14 * slide
        self._frame.Position = UDim2.new(0.15, 0, y, 0)
        self._label.TextTransparency = 0
    elseif active.fx == "SlideDown" then
        self._label.Text = text
        local slide = math.clamp(localT / 0.2, 0, 1)
        local y = 0.65 + 0.13 * slide
        self._frame.Position = UDim2.new(0.15, 0, y, 0)
        self._label.TextTransparency = 0
    elseif active.fx == "Pop" then
        self._label.Text = text
        local pop = math.min(localT * 4, 1)
        self._label.TextSize = math.floor(8 + 14 * pop)
        self._label.TextTransparency = 0
    else
        self._label.Text = text
        self._label.TextTransparency = 0
        self._frame.Position = UDim2.new(0.15, 0, 0.78, 0)
    end
end

function Subtitles:cleanup()
    if self._gui then self._gui:Destroy() end
end

return Subtitles
