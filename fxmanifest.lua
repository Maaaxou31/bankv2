fx_version 'cerulean'
game 'gta5'

author 'BankV2'
description 'Système bancaire avancé avec comptes personnel et professionnel'
version '2.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/salary.lua',
    'server/business.lua'
}

client_scripts {
    'client/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png'
}

lua54 'yes'
