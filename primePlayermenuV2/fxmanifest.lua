fx_version 'cerulean'
game 'gta5'

author 'primeScripts'
description 'primePlayermenuV2 - Discord: https://dsc.gg/primescripts'
version '1.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

escrow_ignore {
    'NativeUI/NativeUIReloaded.lua',
    'config.lua',
    'client.lua',
}

client_scripts {
    'NativeUI/NativeUIReloaded.lua',
    'config.lua',
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/headbag.png'
}