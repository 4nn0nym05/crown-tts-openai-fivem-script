RegisterServerEvent('tts:generateAudioStream')
AddEventHandler('tts:generateAudioStream', function(text, sourcePos, playerName)
    if text == nil or text == '' then return end

    if Config.Debug.Enabled then
        print("Attempting TTS generation with text: " .. text)
    end

    local payload = json.encode({
        model = Config.OpenAI.Model,
        voice = Config.OpenAI.Voice,
        input = text,
        speed = Config.OpenAI.Speed,
        response_format = Config.OpenAI.ResponseFormat
    })

    PerformHttpRequest('https://api.openai.com/v1/audio/speech', function(statusCode, response, headers)
        if Config.Debug.Enabled then
            print("OpenAI API Response Status: " .. tostring(statusCode))
        end

        if statusCode == 200 then
            local base64Audio = ""
            for i = 1, #response do
                base64Audio = base64Audio .. string.format("%02x", string.byte(response, i))
            end

            local duration = math.max(2, math.ceil(#text / Config.Audio.CharactersPerSecond))

            if Config.Debug.PrintResponses then
                print("Audio generated successfully. Duration: " .. duration)
            end

            TriggerClientEvent('tts:playStreamForAll', -1, base64Audio, sourcePos, playerName, duration)
        else
            print("Failed to generate TTS. Status: " .. tostring(statusCode))
            if Config.Debug.PrintResponses and response then
                print("Response: " .. tostring(response))
            end
        end
    end, 'POST', payload, {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. Config.OpenAI.ApiKey
    })
end)