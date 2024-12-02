fx_version 'cerulean'
game 'gta5'

name 'fivem-tts'
description 'Text to Speech system using OpenAI API'
version '1.0.0'
author 'joker5928'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}
