-- config.lua
Config = {
    -- OpenAI Configuration
    OpenAI = {
        ApiKey = "Your key HERE",
        Model = "tts-1",
        Voice = "nova", -- Options: alloy, echo, fable, onyx, nova, shimmer
        Speed = "1.0",  -- 0.25 - 4.0
        ResponseFormat = "mp3"
    },

    -- Audio Settings
    Audio = {
        DefaultRange = 20.0,
        DefaultVolume = 2.0,
        MinVolume = 0.5,
        CharactersPerSecond = 15 -- Used for duration calculation
    },

    -- Commands
    Commands = {
        Main = "tts",
        Range = "ttsrange",
        Volume = "ttsvolume"
    },

    -- Visual Settings
    Visual = {
        TextScale = 0.45,
        TextFont = 0,
        TextColor = {r = 1, g = 1, b = 1, a = 1},
        IndicatorText = "Speaking ...",
        IndicatorHeight = 1.0 -- Height above player
    },

    -- UI Settings
    UI = {
        MaxInputLength = 200,
        InputPlaceholder = "Input text...",
        ButtonText = "Speak",
        Font = "Fira Sans"
    },

    -- Debug
    Debug = {
        Enabled = false,
        PrintResponses = false -- prints in server console
    }
}