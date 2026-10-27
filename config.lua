Config = {}

Config.Locale = 'en'

Config.Debug = false

Config.Chat = {
  maxLength = 256,
  minGapMs = 750,
  legacyChannel = 'local',
  nameSource = 'character'
}

Config.Channels = {
  {
    id = 'local',
    label = 'Local',
    color = '#ffffff',
    kind = 'chat',
    range = 25.0
  },
  {
    id = 'ooc',
    label = 'OOC',
    color = '#9e9e9e',
    kind = 'ooc'
  },
  {
    id = 'advertise',
    label = 'Advertise',
    color = '#a3e635',
    kind = 'ad',
    cooldownSeconds = 60
  },
  {
    id = 'staff',
    label = 'Staff',
    color = '#c77dff',
    kind = 'staff',
    staffOnly = true
  },
  {
    id = 'announcements',
    label = 'Announcements',
    color = '#ffb020',
    readOnly = true
  }
}

Config.Commands = {
  me = {
    enabled = true,
    name = 'me',
    channel = 'local'
  },
  ['do'] = {
    enabled = true,
    name = 'do',
    channel = 'local'
  },
  ooc = {
    enabled = true,
    name = 'ooc',
    channel = 'ooc'
  },
  whisper = {
    enabled = true,
    name = 'w',
    channel = 'local'
  },
  ad = {
    enabled = true,
    name = 'ad',
    channel = 'advertise'
  },
  clear = {
    enabled = true,
    name = 'clear'
  },
  settings = {
    enabled = true,
    name = 'chatsettings'
  }
}

Config.Permissions = {
  staff = 'fearx.chat.staff',
  admin = 'fearx.chat.admin',
  packPrefix = 'fearx.chat.pack.',
  tagPrefix = 'fearx.chat.tag.',
  decorationPrefix = 'fearx.chat.decoration.'
}

Config.Levels = {
  {
    permission = 'fearx.chat.level.owner',
    level = 50
  },
  {
    permission = 'fearx.chat.staff',
    level = 20
  }
}

Config.Keys = {
  open = 'T',
  command = 'SLASH'
}

Config.Ui = {
  logo = 'FX',
  logoImage = '',
  styles = {},
  locked = {},
  defaults = {
    style = 'cards'
  }
}

Config.Discord = {
  avatars = true,
  cacheMinutes = 60
}

Config.JobTags = {
  police = {
    label = 'LSPD',
    color = '#7cb8ff',
    background = 'rgba(91, 167, 255, 0.14)',
    requireDuty = true
  },
  ambulance = {
    label = 'EMS',
    color = '#ff6b6b',
    background = 'rgba(255, 107, 107, 0.14)',
    requireDuty = true
  }
}

Config.Cosmetics = {
  maxTags = 3,
  packs = {
    { id = 'base', label = 'Base', color = 'rgba(255, 255, 255, 0.5)' },
    { id = 'starter', label = 'Starter', color = '#33bbff' },
    { id = 'neon', label = 'Neon', color = '#a8ff2d' },
    { id = 'sakura', label = 'Sakura', color = '#ff5aa0' },
    { id = 'prestige', label = 'Prestige', color = '#ffb020' },
    { id = 'gifter', label = 'Gifter', color = '#ff8fc0' },
    { id = 'staff', label = 'Staff', color = '#c77dff', permission = 'fearx.chat.staff' }
  },
  tags = {
    { id = 'civilian', pack = 'base', tag = { label = 'Civilian', logo = true } },
    { id = 'member', pack = 'base', tag = { label = 'Member', color = 'rgba(255, 255, 255, 0.7)' } },
    { id = 'verified', pack = 'base', tag = { label = 'Verified', color = '#33bbff', background = 'rgba(8, 55, 88, 0.3)', effect = 'shine' } },
    { id = 'aurora', pack = 'starter', tag = { label = 'Aurora', gradient = 'linear-gradient(90deg, #ff5aa0, #a855f7, #38bdf8, #ff5aa0)', effect = 'ring' } },
    { id = 'wave', pack = 'starter', tag = { label = 'Wave', gradient = 'linear-gradient(90deg, #00aaff, #ffffff, #008a99, #00aaff)', effect = 'flow' } },
    { id = 'menace', pack = 'neon', tag = { label = 'Menace', color = '#c77dff' } },
    { id = 'sweat', pack = 'neon', tag = { label = 'Sweat', color = '#a8ff2d', effect = 'pulse' } },
    { id = 'baddie', pack = 'sakura', tag = { label = 'Baddie', color = '#ff5aa0', gradient = 'linear-gradient(90deg, #ff78be, #ffffff, #ff5aa0, #ff78be)', effect = 'flow' } },
    { id = 'goat', pack = 'prestige', tag = { label = 'GOAT', color = '#ffb020', background = 'rgba(98, 66, 18, 0.35)', effect = 'shine' } },
    { id = 'og', pack = 'prestige', tag = { label = 'OG', color = '#ff2b2b', background = 'rgba(48, 7, 8, 0.4)', effect = 'glow' } },
    { id = 'staffteam', pack = 'staff', minLevel = 20, tag = { label = 'Staff', color = '#c77dff', effect = 'glow' } },
    { id = 'owner', pack = 'staff', minLevel = 50, tag = { label = 'Owner', gradient = 'linear-gradient(90deg, #ff2b2b, #ffb020, #ff2b2b)', effect = 'ring' } }
  },
  decorations = {
    { id = 'cat-ears', label = 'Cat Ears', pack = 'base', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/cat-ears_decoration.png' },
    { id = 'shocked', label = 'Shocked', pack = 'base', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/shocked_decoration.png' },
    { id = 'straw-hat', label = 'Straw Hat', pack = 'starter', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/straw-hat_decoration.png' },
    { id = 'snowglobe', label = 'Snowglobe', pack = 'starter', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/snowglobe_decoration.png' },
    { id = 'astronaut-helmet', label = 'Astronaut', pack = 'starter', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/astronaut-helmet_decoration.png' },
    { id = 'black-hole', label = 'Black Hole', pack = 'neon', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/black-hole_decoration.png' },
    { id = 'ufo', label = 'UFO', pack = 'neon', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/ufo_decoration.png' },
    { id = 'blade-storm', label = 'Blade Storm', pack = 'neon', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/blade-storm_decoration.png' },
    { id = 'sakura-pink', label = 'Sakura', pack = 'sakura', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/sakura-pink_decoration.png' },
    { id = 'spirit-embers', label = 'Spirit Embers', pack = 'prestige', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/spirit-embers_decoration.png' },
    { id = 'chun-li', label = 'Chun-Li', pack = 'prestige', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/chun-li_decoration.png' },
    { id = 'clown', label = 'Clown', pack = 'gifter', image = 'https://pub-7c3f99a085d345459c882b982c2df824.r2.dev/clown_decoration.png' }
  }
}
