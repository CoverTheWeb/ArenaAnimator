-- FacePresets.lua
-- Stores Dynamic-Head FACS control values as named presets and applies them.

local FacePresets = {}

local FACS = {
    "JawDrop","LeftLipCornerPuller","RightLipCornerPuller","LeftLipStretcher",
    "RightLipStretcher","LipFunneler","LipPucker","LipPressor","LeftEyeClosed",
    "RightEyeClosed","LeftBrowLowerer","RightBrowLowerer","BrowInnerUp",
    "LeftOuterBrowRaiser","RightOuterBrowRaiser","ChinRaiser","NoseWrinkler",
    "LeftCheekPuff","RightCheekPuff","TongueOut",
}

function FacePresets.captureFromHead(head)
    -- head must be a MeshPart with FACS controls (Dynamic Head)
    local preset = {}
    for _, name in ipairs(FACS) do
        local val = head:GetAttribute(name)
        if val == nil then
            -- Some heads expose controls via numeric properties
            local ok, v = pcall(function() return head[name] end)
            if ok and type(v) == "number" then val = v end
        end
        if val then preset[name] = val end
    end
    return preset
end

function FacePresets.applyToHead(head, preset, weight)
    weight = weight or 1
    for name, val in pairs(preset) do
        local current = head:GetAttribute(name) or 0
        head:SetAttribute(name, current * (1 - weight) + val * weight)
    end
end

function FacePresets.findHead(rig)
    for _, d in ipairs(rig:GetDescendants()) do
        if d:IsA("MeshPart") and d.Name == "Head" then return d end
    end
    return nil
end

FacePresets.FACS = FACS
return FacePresets
