-- Keyframes.lua
-- Easing + interpolation helpers for tracks of any value type.

local Keyframes = {}

local TweenService = game:GetService("TweenService")

local STYLE_MAP = {
    Linear   = Enum.EasingStyle.Linear,
    Cubic    = Enum.EasingStyle.Cubic,
    Quad     = Enum.EasingStyle.Quad,
    Sine     = Enum.EasingStyle.Sine,
    Bounce   = Enum.EasingStyle.Bounce,
    Back     = Enum.EasingStyle.Back,
    Elastic  = Enum.EasingStyle.Elastic,
    Constant = Enum.EasingStyle.Linear, -- treated specially below
}

function Keyframes.alpha(t, easing)
    if easing == "Constant" then return 0 end
    local style = STYLE_MAP[easing] or Enum.EasingStyle.Linear
    return TweenService:GetValue(math.clamp(t, 0, 1), style, Enum.EasingDirection.InOut)
end

local function lerpValue(a, b, t)
    local typ = typeof(a)
    if typ == "number"   then return a + (b - a) * t end
    if typ == "Vector3"  then return a:Lerp(b, t) end
    if typ == "Vector2"  then return a:Lerp(b, t) end
    if typ == "CFrame"   then return a:Lerp(b, t) end
    if typ == "Color3"   then return a:Lerp(b, t) end
    if typ == "UDim2"    then return a:Lerp(b, t) end
    if typ == "boolean"  then return (t < 1) and a or b end
    if typ == "string"   then return (t < 1) and a or b end
    return (t < 1) and a or b
end

-- keys = { {time = n, value = any, easing = "Cubic"}, ... } sorted by time.
function Keyframes.evaluate(keys, time)
    if #keys == 0 then return nil end
    if time <= keys[1].time then return keys[1].value end
    if time >= keys[#keys].time then return keys[#keys].value end

    for i = 1, #keys - 1 do
        local a, b = keys[i], keys[i + 1]
        if time >= a.time and time <= b.time then
            local span = b.time - a.time
            if span <= 0 then return b.value end
            local raw   = (time - a.time) / span
            local alpha = Keyframes.alpha(raw, a.easing or "Cubic")
            return lerpValue(a.value, b.value, alpha)
        end
    end
    return keys[#keys].value
end

function Keyframes.insert(keys, time, value, easing)
    -- Replace if key at exactly this time exists
    for _, k in ipairs(keys) do
        if math.abs(k.time - time) < 1e-4 then
            k.value  = value
            k.easing = easing or k.easing
            return k
        end
    end
    local key = {time = time, value = value, easing = easing or "Cubic"}
    table.insert(keys, key)
    table.sort(keys, function(a, b) return a.time < b.time end)
    return key
end

function Keyframes.remove(keys, time)
    for i, k in ipairs(keys) do
        if math.abs(k.time - time) < 1e-4 then
            table.remove(keys, i)
            return true
        end
    end
    return false
end

return Keyframes
