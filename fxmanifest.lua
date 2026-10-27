fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'FearX Chat'
author 'FearX Scripts'
description 'FearX Chat'
version '1.0.0'

provide 'chat'

ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/**/*'
}

shared_scripts {
  'config.lua',
  'locales/*.lua',
  'shared/locale.lua',
  'shared/utils.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  'config_moderation.lua',
  'bridge/server.lua',
  'server/profile.lua',
  'server/staff.lua',
  'server/moderation.lua',
  'server/main.lua'
}

escrow_ignore {
  'config.lua',
  'config_moderation.lua',
  'locales/*.lua',
  'bridge/server.lua'
}
