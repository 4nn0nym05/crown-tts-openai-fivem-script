local display = false
local audioRange = Config.Audio.DefaultRange
local maxVolume = Config.Audio.DefaultVolume
local speakingPlayers = {}

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

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
        config = Config.UI
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
        TriggerServerEvent("tts:generateAudioStream", data.text, playerPos, playerName)
        SetDisplay(false)
    end
    cb('ok')
end)

RegisterNetEvent('tts:playStreamForAll')
AddEventHandler('tts:playStreamForAll', function(audioData, sourcePos, speakerName, duration)
    local playerPos = GetEntityCoords(PlayerPedId())
    local distance = #(playerPos - sourcePos)

    if distance <= audioRange then
        local volume = (maxVolume - (distance / audioRange))
        volume = math.max(Config.Audio.MinVolume, volume)

        if Config.Debug.Enabled then
            print("Playing audio with volume: " .. volume)
        end

        SendNUIMessage({
            type = "playAudio",
            audioData = audioData,
            volume = volume
        })

        speakingPlayers[speakerName] = {
            endTime = GetGameTimer() + (duration * 1000),
            sourcePos = sourcePos
        }
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
                                text = Config.Visual.IndicatorText,
                                x = x,
                                y = y
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
    end
end)