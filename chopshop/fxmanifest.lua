fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'NB Scripts'
description 'Criminal chopshop with React/Vite/Tailwind/shadcn NUI'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/locale.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
