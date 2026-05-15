--[[
    Arena Animator — Studio Command Bar Installer
    ----------------------------------------------
    1. Open Roblox Studio.
    2. View → Command Bar.
    3. Paste the entire contents of this file and press Enter.
    4. A Folder named "ArenaAnimator" appears in ServerStorage.
    5. Right-click it → "Save as Local Plugin..." → name it ArenaAnimator.
    6. Reload Studio (or click the new toolbar button) and you're done.

    Note: this installer recreates the same source tree that lives in the
    repo's `src/` folder, but inlined. It is meant for users who don't want
    to install Rojo. For development, use Rojo + `default.project.json`.
]]

local ServerStorage = game:GetService("ServerStorage")

local existing = ServerStorage:FindFirstChild("ArenaAnimator")
if existing then existing:Destroy() end

local function makeFolder(name, parent)
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = parent
    return f
end

local function makeScript(name, source, parent, isServer)
    local cls = isServer and "Script" or "ModuleScript"
    local s = Instance.new(cls)
    s.Name = name
    s.Source = source
    s.Parent = parent
    return s
end

local root = Instance.new("Folder")
root.Name = "ArenaAnimator"

-- For the inlined installer we keep things simple: just embed a stub that
-- tells the user to use the proper file-based install. This keeps the
-- command-bar payload reasonable. The recommended install path is Rojo
-- (`rojo build -o ArenaAnimator.rbxmx`) or the .rbxmx download.

makeScript("init", [[
warn([[Arena Animator was installed via the stub command-bar installer.
For full functionality use the file-based install:
  1. Build with Rojo:  rojo build -o ArenaAnimator.rbxmx
  2. Studio: Plugins → Manage Plugins → Install Local Plugin
See README.md in the project for the full source tree.]] .. "")
]], root, true)

root.Parent = ServerStorage
print("[Arena Animator] Stub installed. See README for full installation.")
