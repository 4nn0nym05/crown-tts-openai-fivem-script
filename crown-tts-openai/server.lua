local radioChannels = {}

RegisterNetEvent('mm_radio:server:addToRadioChannel', function(channel, username)
    if not radioChannels[channel] then
        radioChannels[channel] = {}
    end
    radioChannels[channel][tostring(source)] = true
end)

RegisterNetEvent('mm_radio:server:removeFromRadioChannel', function(channel)
    if radioChannels[channel] then
        radioChannels[channel][tostring(source)] = nil
    end
end)

RegisterServerEvent('tts:generateAudioStream')
AddEventHandler('tts:generateAudioStream', function(text, sourcePos, playerName, radioData)
    if text == nil or text == '' then return end

    local payload = json.encode({
        model = Config.OpenAI.Model,
        voice = Config.OpenAI.Voice,
        input = text,
        response_format = Config.OpenAI.ResponseFormat
    })

    PerformHttpRequest('https://api.openai.com/v1/audio/speech', function(statusCode, response, headers)
        if statusCode == 200 then
            local base64Audio = ""
            for i = 1, #response do
                base64Audio = base64Audio .. string.format("%02x", string.byte(response, i))
            end

            local duration = math.max(2, math.ceil(#text / Config.Audio.CharactersPerSecond))

            if radioData and radioData.onRadio and radioData.channel > 0 then
                local channelMembers = {}

                if radioChannels[radioData.channel] then
                    for playerId, _ in pairs(radioChannels[radioData.channel]) do
                        table.insert(channelMembers, tonumber(playerId))
                    end
                end

                if #channelMembers > 0 then
                    for _, playerId in ipairs(channelMembers) do
                        TriggerClientEvent('tts:playStreamForAll', playerId, base64Audio, sourcePos, playerName, duration, radioData)
                    end
                end
            else
                TriggerClientEvent('tts:playStreamForAll', -1, base64Audio, sourcePos, playerName, duration, radioData)
            end
        end
    end, 'POST', payload, {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. Config.OpenAI.ApiKey
    })
end)

AddEventHandler('playerDropped', function()
    local playerId = tostring(source)
    for channel, members in pairs(radioChannels) do
        if members[playerId] then
            members[playerId] = nil
        end
    end
end)