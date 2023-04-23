fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_script 'shared/config.lua'

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', --⚠️PLEASE READ⚠️; Unhash this line if you use 'oxmysql'.⚠️
    'server/*.lua'
}

escrow_ignore {
    'shared/config.lua', 
}