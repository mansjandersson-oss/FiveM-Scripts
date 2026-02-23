fx_version 'cerulean'
game 'gta5'

name 'chopshop'
author 'VikingStickarn'
description 'Chop Shop: criminal vehicle contracts and civilian dismantling with OX-Inventory, skill checks and animations'
version '1.0.0'

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
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'ox_target',
    'ox_lib'
}
