-- config.lua
Config = {
    -- OpenAI Configuration
    OpenAI = {
        ApiKey =
        "YOURKEYHERE",
        Model = "tts-1",
        Voice = "nova", -- Options: alloy, echo, fable, onyx, nova, shimmer
        Speed = "1.0",  -- 0.25 - 4.0
        ResponseFormat = "mp3"
    },

    -- Audio Settings
    Audio = {
        DefaultRange = 20.0,
        DefaultVolume = 2.0,
        MinVolume = 0.1,
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
        TextScale = 0.35,
        TextFont = 0,
        TextColor = { r = 255, g = 255, b = 255, a = 255 },
        IndicatorText = "Mluví znakovou řečí...",
        IndicatorHeight = 1.0 -- Height above player
    },
    -- Animations
    Animations = {
        Normal = {
            Dict = "anim@amb@casino@brawl@fights@argue@",
            Name = "arguement_loop_mp_m_brawler_01",
            Flag = 49
        },
        Radio = {
            Dict = "random@arrests",
            Name = "generic_radio_chatter",
            Flag = 49
        }
    },

    -- UI Settings
    UI = {
        MaxInputLength = 200,
        InputPlaceholder = "Enter text for TTS...",
        ButtonText = "Send",
        Font = "Fira Sans"
    },

    -- Radio Settings
    Radio = {
        Enabled = true,
        DefaultChannel = 1,
        MaxChannel = 100,
        RangeOverride = 10000.0, -- Large range for radio
        Command = "ttsradio",
        UsePMA = true
    },

    -- Debug
    Debug = {
        Enabled = false,
        PrintResponses = false
    }
}
