-- Constants.lua
-- Shared plugin configuration.

local Constants = {}

Constants.PLUGIN_NAME      = "Arena Animator"
Constants.VERSION          = "1.0.0"
Constants.AUTHOR           = "Arena.ai"

-- Timeline / playback
Constants.DEFAULT_FPS      = 30
Constants.DEFAULT_LENGTH   = 5      -- seconds
Constants.MIN_LENGTH       = 0.1
Constants.MAX_LENGTH       = 600
Constants.PIXELS_PER_SEC   = 120    -- timeline zoom default

-- Easing styles supported in keyframe interpolation
Constants.EASING = {
    "Linear", "Cubic", "Quad", "Sine", "Bounce", "Back", "Elastic", "Constant",
}

-- Track kinds
Constants.TRACK_KIND = {
    Rig       = "Rig",
    Camera    = "Camera",
    Audio     = "Audio",
    Prop      = "Prop",
    Subtitle  = "Subtitle",
    Effect    = "Effect",
}

-- Camera modes (used by CameraSystem)
Constants.CAMERA_MODE = {
    Free        = "Free",
    FirstPerson = "FirstPerson",
    OverShoulder= "OverShoulder",
    Cinematic   = "Cinematic",
    Follow      = "Follow",
}

-- Subtitle transitions
Constants.SUBTITLE_FX = {
    "None", "Fade", "Typewriter", "SlideUp", "SlideDown", "Pop",
}

return Constants
