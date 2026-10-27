Locales = Locales or {}

Locales.en = {
  muted = 'You are muted. Reason: %s',
  mutedUntil = 'You are muted for %d more minutes. Reason: %s',
  noReason = 'none given',
  locked = '%s is locked by staff.',
  slowmode = 'Slow mode is on, wait %ds.',
  tooFast = 'You are sending messages too fast.',
  readOnly = 'You cannot send messages in %s.',
  staffOnly = 'Only staff can use %s.',
  adCooldown = 'You can post another advertisement in %ds.',
  unknownCommand = 'Unknown command /%s',
  usageWhisper = 'Usage: /%s [id] [message]',
  usageText = 'Usage: /%s [text]',
  playerNotFound = 'No player with ID %s.',
  whisperTo = 'to %s',
  noPermission = 'You do not have permission to do that.',
  invalidRequest = 'Invalid request.',
  cannotMuteSelf = 'You cannot mute yourself.',
  cannotMuteStaff = 'You cannot mute a staff member.',
  mutedTarget = '%s was muted %s by %s. Reason: %s',
  mutedForever = 'permanently',
  mutedFor = 'for %d minutes',
  unmutedTarget = '%s was unmuted by %s.',
  notMuted = 'That player is not muted.',
  youWereMuted = 'You were muted %s. Reason: %s',
  youWereUnmuted = 'You were unmuted.',
  chatCleared = 'Chat was cleared by staff.',
  filter = {
    slur = 'Your message was blocked because it contains a slur.',
    ipLogger = 'Your message was blocked because it contains an IP logger link.',
    ipAddress = 'Your message was blocked because it contains an IP address.',
    discordInvite = 'Discord invites are not allowed in chat.',
    link = 'Links are not allowed in chat.',
    flood = 'You are sending messages too quickly, slow down.',
    duplicate = 'You already sent that message.',
    autoMuted = 'You were muted for %d minutes by the chat filter.',
    autoMuteReason = 'Repeated chat filter violations',
    autoModerator = 'Auto moderation',
    staffNotice = 'Chat filter blocked a message from %s (%d): %s',
    kind = {
      slur = 'slur',
      ipLogger = 'IP logger link',
      ipAddress = 'IP address',
      discordInvite = 'Discord invite',
      link = 'link'
    }
  },
  key = {
    open = 'Open chat',
    command = 'Open chat with a command'
  },
  help = {
    me = 'Describe an action',
    meParam = 'What your character does',
    ['do'] = 'Describe the scene',
    doParam = 'What others can see',
    ooc = 'Out of character chat',
    whisper = 'Whisper to a player',
    whisperId = 'Server ID',
    ad = 'Post an advertisement',
    clear = 'Clear your chat',
    settings = 'Open chat settings'
  }
}
