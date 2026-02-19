
fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'


author 'Tucan'
description 'Advance Hud For Tpz Metabolism !! Keep the resource free !'
version '1.0.0'
repository 'https://github.com/tucan1312/tpz_advancehud' 


ui_page 'html/index.html'


lua54 'yes' 


files {
    'html/**/*',
}


shared_scripts {
    'config.lua'
}

client_scripts {
    'client/dataview.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

my_discord 'tucan_99'
