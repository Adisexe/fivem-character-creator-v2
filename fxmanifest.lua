fx_version 'adamant'

game 'gta5'
author 'Adisexe'

client_scripts { 'client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/script.js',
    'nui/style.css'
}

shared_scripts {
    '@es_extended/imports.lua'
}

