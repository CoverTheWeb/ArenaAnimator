-- Theme.lua
-- Centralised colours, fonts and metrics. Auto-respects Studio's theme.

local Studio = settings():GetService("Studio")

local Theme = {}

Theme.Font     = Enum.Font.Gotham
Theme.FontBold = Enum.Font.GothamBold
Theme.FontMono = Enum.Font.Code

Theme.Metrics = {
    HeaderHeight   = 28,
    ToolbarHeight  = 36,
    TrackHeight    = 28,
    TimeRulerHeight= 22,
    Padding        = 6,
    Corner         = UDim.new(0, 4),
    KeyframeSize   = 10,
}

local function color(studioGuide, fallback)
    local ok, c = pcall(function()
        return Studio.Theme:GetColor(studioGuide)
    end)
    if ok and c then return c end
    return fallback
end

function Theme.refresh()
    Theme.Colors = {
        Background    = color(Enum.StudioStyleGuideColor.MainBackground, Color3.fromRGB(40, 40, 40)),
        Panel         = color(Enum.StudioStyleGuideColor.ViewPortBackground, Color3.fromRGB(46, 46, 46)),
        Header        = color(Enum.StudioStyleGuideColor.Titlebar, Color3.fromRGB(30, 30, 30)),
        Border        = color(Enum.StudioStyleGuideColor.Border, Color3.fromRGB(20, 20, 20)),
        Text          = color(Enum.StudioStyleGuideColor.MainText, Color3.fromRGB(235, 235, 235)),
        SubText       = color(Enum.StudioStyleGuideColor.SubText, Color3.fromRGB(180, 180, 180)),
        Accent        = Color3.fromRGB(255, 120, 60),
        AccentDim     = Color3.fromRGB(180, 80, 40),
        Good          = Color3.fromRGB(80, 200, 120),
        Warn          = Color3.fromRGB(240, 200, 80),
        Bad           = Color3.fromRGB(230, 90, 90),
        TrackRig      = Color3.fromRGB(100, 170, 255),
        TrackCamera   = Color3.fromRGB(255, 200,  80),
        TrackAudio    = Color3.fromRGB(180, 120, 255),
        TrackProp     = Color3.fromRGB(120, 220, 160),
        TrackSubtitle = Color3.fromRGB(255, 140, 200),
        TrackEffect   = Color3.fromRGB(220, 220, 220),
        Playhead      = Color3.fromRGB(255, 80, 80),
        Ruler         = Color3.fromRGB(60, 60, 60),
    }
end

Theme.refresh()
Studio.ThemeChanged:Connect(Theme.refresh)

function Theme.colorForKind(kind)
    return Theme.Colors["Track" .. kind] or Theme.Colors.TrackEffect
end

return Theme
