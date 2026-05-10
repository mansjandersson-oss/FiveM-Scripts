fx_version 'cerulean'
game 'gta5'

name 'nb-fishing'
author 'Codex'
description 'Omfattande konfigurerbart fiskesystem med Stardew-inspirerat minispel, skills och topplista'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'skilltree.lua',
    'locales/locale.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
