Config.Moderation = {
  enabled = true,
  notifyStaff = true,
  logToConsole = true,
  staffBypassLinks = true,
  staffBypassSpam = true,

  slurs = {
    enabled = true,
    words = {
      'nigger',
      'nigga',
      'faggot',
      'fag',
      'retard',
      'tranny',
      'chink',
      'spic',
      'kike',
      'wetback',
      'gook',
      'beaner'
    },
    allowWords = {
      'snigger',
      'sniggers',
      'sniggered',
      'sniggering',
      'retardant',
      'retardants'
    }
  },

  links = {
    blockIpLoggers = true,
    blockDiscordInvites = true,
    blockIpAddresses = true,
    blockAllLinks = false,
    allowedDomains = {
      'youtube.com',
      'youtu.be',
      'twitch.tv',
      'medal.tv',
      'imgur.com'
    },
    allowedInviteCodes = {},
    ipLoggerDomains = {
      'grabify.link',
      'grabify.world',
      'grabify.icu',
      'iplogger.org',
      'iplogger.com',
      'iplogger.ru',
      'iplogger.co',
      'iplogger.info',
      '2no.co',
      'yip.su',
      'iplis.ru',
      'ezstat.ru',
      'blasze.tk',
      'blasze.com',
      'ps3cfw.com',
      'lovebird.guru',
      'trulove.guru',
      'dateing.club',
      'otherhalf.life',
      'shrekis.life',
      'datasig.io',
      'datauth.io',
      'headshot.monster',
      'gaming-at-my.best',
      'progaming.monster',
      'yourmy.monster',
      'screenshare.host',
      'imageshare.best',
      'screenshot.best',
      'gamingfun.me',
      'catsnthing.com',
      'catsnthings.fun',
      'curiouscat.club',
      'joinmy.site',
      'fortnitechat.site',
      'fortnight.space',
      'freegiftcards.co',
      'stopify.co',
      'leancoding.co',
      'bmwforum.co',
      'whatstheirip.com',
      'ipgrabber.ru',
      'iplogger.cn'
    },
    ipLoggerKeywords = {
      'grabify',
      'iplogger',
      'blasze',
      'ipgrabber',
      'whatstheirip'
    }
  },

  spam = {
    enabled = true,
    burstMessages = 5,
    burstSeconds = 8,
    duplicateSeconds = 20
  },

  autoMute = {
    enabled = true,
    strikes = 3,
    windowMinutes = 10,
    muteMinutes = 15
  }
}
