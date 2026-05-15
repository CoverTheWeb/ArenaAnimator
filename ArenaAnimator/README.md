# 🎬 Arena Animator

A powerful, free Roblox Studio animation plugin built to rival Moon Animator.

## ✨ Features

| Icon | Feature | What it does |
|------|---------|--------------|
| 🎬 | **Motion Builder** | Multi-track timeline editor for rigs, props, cameras and audio with keyframe interpolation |
| 🎥 | **Cutscene Exporter** | Export your full sequence to a `Folder` of `KeyframeSequence`s + a runnable `Cutscene.lua` script |
| 🖐️ | **Prop Attach / Detach** | Weld any tool or model to a limb mid-animation, then release it on a future frame |
| 😊 | **Face Preset Creator** | Save Dynamic-Head FACS presets and re-apply them as single keys |
| 🔊 | **Audio Timeline** | Drop Sound assets onto the timeline with per-track volume, pitch and trim |
| 🎮 | **First-Person & Cinematic Cameras** | Switch render style per shot (FPS / Over-the-shoulder / Cinematic / Free-cam) |
| ⚡ | **Trackball Controls** | Maya-style orbit / pan / dolly viewport gizmo |
| 📝 | **Subtitles & Transitions** | Lower-third text with fade / typewriter / slide effects |
| 🚶 | **Auto-Movement** | Generate a walk/run path animation from two waypoints with foot-IK guess |
| 🎞️ | **Full Cutscene Creation** | Combine tracks, cameras, audio, subs and props into one playable timeline |
| 🎥 | **Camera Effects + Follow Target** | Shake, zoom, dolly-zoom and auto-follow any rig with offset and look-at |

## 📦 Installation

### Option A — Rojo (recommended)
```bash
rojo build -o ArenaAnimator.rbxmx
```
Then in Studio: `Plugins → Manage Plugins → Install Local Plugin → ArenaAnimator.rbxmx`

### Option B — Single-file installer
1. Open Studio → View → Command Bar
2. Paste the contents of `Install.lua` and press Enter — it installs the plugin into your local plugins folder.

### Option C — Manual
Drop the `src` folder into `%LocalAppData%/Roblox/Plugins/ArenaAnimator/` (Windows) or `~/Documents/Roblox/Plugins/ArenaAnimator/` (Mac).

## 🚀 Quick Start

1. Click the **🎬 Arena Animator** toolbar button.
2. Select a rig in the workspace and press **+ Add Rig** in the panel.
3. Scrub the timeline, pose the rig, hit **K** to set a keyframe.
4. Press **▶ Play** to preview, **💾 Export** to save a `KeyframeSequence`, or **🎞 Export Cutscene** to bake the full timeline into a runnable script.

## ⌨️ Hotkeys

| Key | Action |
|-----|--------|
| `K` | Set keyframe at current time |
| `Shift+K` | Delete keyframe |
| `Space` | Play / Pause |
| `←` / `→` | Step frame |
| `Shift+←` / `Shift+→` | Jump to prev/next key |
| `F` | Frame selected in viewport |
| `Alt+LMB` | Trackball orbit |
| `Alt+MMB` | Trackball pan |
| `Alt+RMB` | Trackball dolly |

## 🧱 Project Layout

```
src/
├── init.server.lua          -- Plugin entry point
├── Constants.lua
├── State.lua                -- Reactive state store
├── Modules/
│   ├── Timeline.lua
│   ├── Keyframes.lua
│   ├── RigManager.lua
│   ├── Playback.lua
│   ├── Exporter.lua
│   └── Features/
│       ├── MotionBuilder.lua
│       ├── PropAttachment.lua
│       ├── FacePresets.lua
│       ├── AudioTimeline.lua
│       ├── CameraSystem.lua
│       ├── Trackball.lua
│       ├── Subtitles.lua
│       ├── AutoMovement.lua
│       └── CameraEffects.lua
└── UI/
    ├── Theme.lua
    ├── Widgets.lua
    ├── MainWindow.lua
    ├── TimelinePanel.lua
    ├── PropertiesPanel.lua
    └── Toolbar.lua
```

## 📜 License
MIT — do whatever you want, attribution appreciated.
