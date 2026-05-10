fx_version 'cerulean'
game 'gta5'

name 'nb-destil'
author 'NB Scripts / VikingStickarn'
description 'NB Destil - QBCore distillery production with ox_inventory, ox_target and React NUI'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'ox_target',
    'ox_lib'
}
