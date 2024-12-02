local display = false
local audioRange = Config.Audio.DefaultRange
local maxVolume = Config.Audio.DefaultVolume
local speakingPlayers = {}
local activeRadioChannel = 0
local isPlayingAnimation = false

local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function playAnimation(type)
    local ped = PlayerPedId()
    local anim = Config.Animations[type]
    if not anim then return end
    loadAnimDict(anim.Dict)
    TaskPlayAnim(ped, anim.Dict, anim.Name, 8.0, -8.0, -1, anim.Flag, 0, false, false, false)
    isPlayingAnimation = true
end

local function stopAnimation()
    if isPlayingAnimation then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        isPlayingAnimation = false
    end
end

local function getCurrentRadioChannel()
    return activeRadioChannel
end

local function isPlayerOnRadio()
    return activeRadioChannel > 0
end

RegisterNetEvent('mm_radio:client:radioListUpdate', function(players, channel)
    local myServerId = GetPlayerServerId(PlayerId())
    if players and players[tostring(myServerId)] then
        activeRadioChannel = tonumber(channel) or 0
    else
        if activeRadioChannel == tonumber(channel) then
            activeRadioChannel = 0
        end
    end
end)

RegisterCommand(Config.Commands.Main, function()
    SetDisplay(not display)
end)

RegisterCommand(Config.Commands.Range, function(source, args)
    if args[1] and tonumber(args[1]) then
        audioRange = tonumber(args[1])
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            args = {"TTS", "Range set to " .. audioRange}
        })
    end
end)

RegisterCommand(Config.Commands.Volume, function(source, args)
    if args[1] and tonumber(args[1]) then
        maxVolume = tonumber(args[1])
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            args = {"TTS", "Volume multiplier set to " .. maxVolume}
        })
    end
end)

RegisterCommand("ttsstatus", function()
    local channel = getCurrentRadioChannel()
    local onRadio = isPlayerOnRadio()
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"TTS Status", string.format([[Radio Channel: %s
On Radio: %s]], tostring(channel), onRadio and "Yes" or "No")}
    })
end)

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
        config = Config.UI,
        radioData = {
            channel = getCurrentRadioChannel(),
            onRadio = isPlayerOnRadio()
        }
    })
end

RegisterNUICallback("exit", function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback("submit", function(data, cb)
    if data.text then
        local playerPos = GetEntityCoords(PlayerPedId())
        local playerName = GetPlayerName(PlayerId())
        local radioChannel = getCurrentRadioChannel()
        local onRadio = isPlayerOnRadio()
        local radioData = {
            channel = radioChannel,
            onRadio = onRadio and data.useRadio
        }
        TriggerServerEvent("tts:generateAudioStream", data.text, playerPos, playerName, radioData)
        SetDisplay(false)
    end
    cb('ok')
end)

RegisterCommand("ttstest", function(source, args)
    local text = table.concat(args, " ")
    if text == "" then text = "This is a test message" end
    local playerPos = GetEntityCoords(PlayerPedId())
    local playerName = GetPlayerName(PlayerId())
    TriggerServerEvent("tts:generateAudioStream", text, playerPos, playerName, {
        channel = 0,
        onRadio = false
    })
end)

RegisterNetEvent('tts:playStreamForAll')
AddEventHandler('tts:playStreamForAll', function(audioData, sourcePos, speakerName, duration, radioData)
    local playerPos = GetEntityCoords(PlayerPedId())
    local distance = #(playerPos - sourcePos)
    local inRange = false
    local volume = Config.Audio.DefaultVolume

    if radioData and radioData.onRadio and radioData.channel > 0 then
        if getCurrentRadioChannel() == radioData.channel and isPlayerOnRadio() then
            inRange = true
            volume = Config.Audio.DefaultVolume
            playAnimation('Radio')
        end
    else
        if distance <= audioRange then
            inRange = true
            volume = (maxVolume - (distance / audioRange))
            volume = math.max(Config.Audio.MinVolume, volume)
            playAnimation('Normal')
        end
    end

    if inRange then
        SendNUIMessage({
            type = "playAudio",
            audioData = audioData,
            volume = volume,
            isRadio = radioData and radioData.onRadio
        })

        speakingPlayers[speakerName] = {
            endTime = GetGameTimer() + (duration * 1000),
            sourcePos = sourcePos,
            isRadio = radioData and radioData.onRadio
        }

        SetTimeout(duration * 1000, function()
            if isPlayingAnimation then
                stopAnimation()
            end
        end)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local anyoneSpeaking = false
        local currentTime = GetGameTimer()

        for name, data in pairs(speakingPlayers) do
            if currentTime < data.endTime then
                for _, player in ipairs(GetActivePlayers()) do
                    if GetPlayerName(player) == name then
                        local ped = GetPlayerPed(player)
                        local pos = GetEntityCoords(ped)
                        local onScreen, x, y = World3dToScreen2d(pos.x, pos.y, pos.z + Config.Visual.IndicatorHeight)
                        if onScreen then
                            anyoneSpeaking = true
                            SendNUIMessage({
                                type = "drawSpeaking",
                                display = true,
                                text = data.isRadio and "Speaking(radio)..." or Config.Visual.IndicatorText,
                                x = x,
                                y = y,
                                isRadio = data.isRadio
                            })
                        end
                    end
                end
            else
                speakingPlayers[name] = nil
            end
        end

        if not anyoneSpeaking then
            SendNUIMessage({
                type = "drawSpeaking",
                display = false
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SendNUIMessage({
            type = "drawSpeaking",
            display = false
        })
        stopAnimation()
    end
end)
