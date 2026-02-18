fx_version 'cerulean'
game 'gta5'

name 'qb-boozebiz'
author 'Codex'
description 'QBCore booze manufacturing: farm to liquor store with ox_inventory + ox_target'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
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
    'ox_inventory',
    'ox_target',
    'ox_lib'
}
