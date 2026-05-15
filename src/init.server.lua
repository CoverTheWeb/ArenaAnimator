-- Arena Animator — main plugin entry point.
-- Wires together state, services, UI, and Studio integration.

if not plugin then
    error("Arena Animator must be installed as a Studio plugin.")
end

local Constants = require(script.Constants)
local State     = require(script.State)

local RigManager   = require(script.Modules.RigManager)
local Playback     = require(script.Modules.Playback)
local Exporter     = require(script.Modules.Exporter)
local MotionBuilder= require(script.Modules.Features.MotionBuilder)

local CameraSystem  = require(script.Modules.Features.CameraSystem)
local CameraEffects = require(script.Modules.Features.CameraEffects)
local AudioTimeline = require(script.Modules.Features.AudioTimeline)
local Subtitles     = require(script.Modules.Features.Subtitles)
local Trackball     = require(script.Modules.Features.Trackball)
local PropAttachment= require(script.Modules.Features.PropAttachment)

local MainWindow    = require(script.UI.MainWindow)

------------------------------------------------------------------
-- 1. Build state and services
------------------------------------------------------------------

local state    = State.new()
local services = {
    plugin         = plugin,
    CameraSystem   = CameraSystem.new(),
    CameraEffects  = CameraEffects.new(),
    AudioTimeline  = AudioTimeline.new(),
    Subtitles      = Subtitles.new(),
    Trackball      = Trackball.new(),
    PropAttachment = PropAttachment.new(),
}

local playback = Playback.new(state, services)
playback:start()
services.Playback = playback

------------------------------------------------------------------
-- 2. Trackball controls feed the camera when in Free mode
------------------------------------------------------------------

services.Trackball:onChange(function(cf)
    if state.data.cameraMode == Constants.CAMERA_MODE.Free then
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = cf end
    end
end)

------------------------------------------------------------------
-- 3. Toolbar button + main window
------------------------------------------------------------------

local toolbar     = plugin:CreateToolbar("Arena Animator")
local toggleBtn   = toolbar:CreateButton(
    "Open Animator",
    "Open the Arena Animator window",
    "rbxasset://textures/AnimationEditor/icon_animation.png"
)
toggleBtn.ClickableWhenViewportHidden = true

local window = MainWindow.new(plugin, state, services)
window:setEnabled(false)

local function refreshButton()
    toggleBtn:SetActive(window:isEnabled())
end
refreshButton()

toggleBtn.Click:Connect(function()
    window:setEnabled(not window:isEnabled())
    refreshButton()
end)
window.gui:GetPropertyChangedSignal("Enabled"):Connect(refreshButton)

------------------------------------------------------------------
-- 4. Hotkeys via PluginActions
------------------------------------------------------------------

local function action(id, label, hint, icon, hotkey)
    local act = plugin:CreatePluginAction("ArenaAnim_"..id, label, hint, icon, true)
    return act
end

local actKey   = action("KeyHere", "Set Keyframe", "Insert key on every rig at the playhead")
local actDel   = action("DelKey",  "Delete Keyframe", "Remove keys at playhead")
local actPlay  = action("Play",    "Play/Pause",   "Toggle preview playback")
local actNext  = action("NextKey", "Next Keyframe","Jump to next key")
local actPrev  = action("PrevKey", "Prev Keyframe","Jump to previous key")
local actFocus = action("Focus",   "Focus Selected","Frame selection in trackball")

actKey.Triggered:Connect(function()
    for _, t in ipairs(state.data.tracks) do
        if t.kind == Constants.TRACK_KIND.Rig then
            MotionBuilder.captureKeyframe(t, state.data.time)
        end
    end
    state:_emit("tracks")
end)
actDel.Triggered:Connect(function()
    for _, t in ipairs(state.data.tracks) do
        if t.kind == Constants.TRACK_KIND.Rig then
            MotionBuilder.deleteKeyframe(t, state.data.time)
        end
    end
    state:_emit("tracks")
end)
actPlay.Triggered:Connect(function()
    state:patch({ playing = not state.data.playing })
end)
actNext.Triggered:Connect(function()
    for _, t in ipairs(state.data.tracks) do
        if t.kind == Constants.TRACK_KIND.Rig then
            local nxt = MotionBuilder.nextKeyframe(t, state.data.time)
            if nxt then state:patch({ time = nxt, playing = false }) return end
        end
    end
end)
actPrev.Triggered:Connect(function()
    for _, t in ipairs(state.data.tracks) do
        if t.kind == Constants.TRACK_KIND.Rig then
            local prv = MotionBuilder.prevKeyframe(t, state.data.time)
            if prv then state:patch({ time = prv, playing = false }) return end
        end
    end
end)
actFocus.Triggered:Connect(function()
    local sel = game:GetService("Selection"):Get()[1]
    if sel then services.Trackball:focus(sel) end
end)

------------------------------------------------------------------
-- 5. Cleanup on unload
------------------------------------------------------------------

plugin.Unloading:Connect(function()
    playback:stop()
    services.AudioTimeline:cleanup()
    services.Subtitles:cleanup()
    services.PropAttachment:reset()
    services.Trackball:disable()
    services.CameraSystem:release()
end)

print(("[%s v%s] loaded — click the toolbar button to open."):format(Constants.PLUGIN_NAME, Constants.VERSION))
