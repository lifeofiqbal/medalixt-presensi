fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'medalixt_presensi'
description 'ID Tag & NEW Player Detection'
author 'MEDALIXT'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql',
}
