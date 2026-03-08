fx_version 'cerulean'
game 'gta5'

name 'interactive_carheist'
author 'Codex'
description 'Interaktiv bilstöld med dekryptering och GPS-ping till polis'
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
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
