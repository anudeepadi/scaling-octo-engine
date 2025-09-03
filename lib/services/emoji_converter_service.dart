class EmojiConverterService {
  static final Map<String, String> _textToEmojiMap = {
    // Basic Smileys
    ':)': '😊',
    ':-)': '😊',
    ':(': '😢',
    ':-(': '😢',
    ':D': '😃',
    ':-D': '😃',
    ';)': '😉',
    ';-)': '😉',
    ':P': '😛',
    ':-P': '😛',
    ':p': '😛',
    ':-p': '😛',
    ':|': '😐',
    ':-|': '😐',
    ':O': '😮',
    ':-O': '😮',
    ':o': '😮',
    ':-o': '😮',
    ':/': '😕',
    ':-/': '😕',
    ':\\': '😕',
    ':-\\': '😕',
    'XD': '😆',
    'xD': '😆',
    ':*': '😘',
    ':-*': '😘',
    '<3': '❤️',
    '</3': '💔',
    
    // Extended Emoticons
    '>:(': '😠',
    '>:-(': '😠',
    ':@': '😡',
    ':-@': '😡',
    'B)': '😎',
    'B-)': '😎',
    '8)': '😎',
    '8-)': '😎',
    ':\$': '😳',
    ':-\$': '😳',
    'O:)': '😇',
    'O:-)': '😇',
    '0:)': '😇',
    '0:-)': '😇',
    '>:)': '😈',
    '>:-)': '😈',
    ':3': '😺',
    ':-3': '😺',
    '^_^': '😊',
    '^.^': '😊',
    '-_-': '😑',
    'T_T': '😭',
    'T.T': '😭',
    'o_O': '🤨',
    'O_o': '🤨',
    'o_o': '😳',
    'O_O': '😱',
    '>.<': '😫',
    
    // Text-based Emoji Names (common ones)
    ':smile:': '😊',
    ':grin:': '😁',
    ':joy:': '😂',
    ':smiley:': '😃',
    ':happy:': '😄',
    ':laughing:': '😆',
    ':wink:': '😉',
    ':blush:': '😊',
    ':yum:': '😋',
    ':stuck_out_tongue:': '😛',
    ':sunglasses:': '😎',
    ':heart_eyes:': '😍',
    ':kiss:': '😘',
    ':kissing:': '😗',
    ':neutral:': '😐',
    ':confused:': '😕',
    ':worried:': '😟',
    ':frowning:': '😔',
    ':cry:': '😢',
    ':sob:': '😭',
    ':angry:': '😠',
    ':rage:': '😡',
    ':triumph:': '😤',
    ':disappointed:': '😞',
    ':pensive:': '😔',
    ':tired:': '😫',
    ':fearful:': '😨',
    ':cold_sweat:': '😰',
    ':persevere:': '😣',
    ':dizzy_face:': '😵',
    ':astonished:': '😲',
    ':open_mouth:': '😮',
    ':hushed:': '😯',
    ':sleeping:': '😴',
    ':relieved:': '😌',
    ':relaxed:': '☺️',
    ':satisfied:': '😆',
    ':mask:': '😷',
    ':innocent:': '😇',
    ':smiling_imp:': '😈',
    ':imp:': '👿',
    
    // Hearts and Love
    ':heart:': '❤️',
    ':yellow_heart:': '💛',
    ':green_heart:': '💚',
    ':blue_heart:': '💙',
    ':purple_heart:': '💜',
    ':black_heart:': '🖤',
    ':white_heart:': '🤍',
    ':orange_heart:': '🧡',
    ':brown_heart:': '🤎',
    ':broken_heart:': '💔',
    ':two_hearts:': '💕',
    ':revolving_hearts:': '💞',
    ':heartbeat:': '💓',
    ':heartpulse:': '💗',
    ':sparkling_heart:': '💖',
    ':cupid:': '💘',
    ':gift_heart:': '💝',
    ':heart_decoration:': '💟',
    ':peace:': '☮️',
    ':love:': '💕',
    
    // Common Gestures
    ':thumbsup:': '👍',
    ':thumbsdown:': '👎',
    ':ok_hand:': '👌',
    ':punch:': '👊',
    ':fist:': '✊',
    ':v:': '✌️',
    ':wave:': '👋',
    ':hand:': '✋',
    ':open_hands:': '👐',
    ':point_up:': '☝️',
    ':point_down:': '👇',
    ':point_left:': '👈',
    ':point_right:': '👉',
    ':clap:': '👏',
    ':pray:': '🙏',
    
    // Common Objects
    ':fire:': '🔥',
    ':star:': '⭐',
    ':star2:': '🌟',
    ':sparkles:': '✨',
    ':boom:': '💥',
    ':collision:': '💥',
    ':anger:': '💢',
    ':sweat_drops:': '💦',
    ':droplet:': '💧',
    ':zzz:': '💤',
    ':dash:': '💨',
    ':ear_of_rice:': '🌾',
    ':gem:': '💎',
    ':crown:': '👑',
    ':lipstick:': '💄',
    ':ring:': '💍',
    ':trophy:': '🏆',
    ':musical_note:': '🎵',
    ':notes:': '🎶',
    ':headphones:': '🎧',
    ':microphone:': '🎤',
    ':guitar:': '🎸',
    ':trumpet:': '🎺',
    ':saxophone:': '🎷',
    ':violin:': '🎻',
    ':cake:': '🍰',
    ':pizza:': '🍕',
    ':hamburger:': '🍔',
    ':beer:': '🍺',
    ':wine:': '🍷',
    ':cocktail:': '🍸',
    ':coffee:': '☕',
    
    // Nature
    ':sun:': '☀️',
    ':moon:': '🌙',
    ':cloud:': '☁️',
    ':umbrella:': '☔',
    ':snowman:': '⛄',
    ':zap:': '⚡',
    ':ocean:': '🌊',
    ':cat:': '🐱',
    ':dog:': '🐶',
    ':mouse:': '🐭',
    ':hamster:': '🐹',
    ':rabbit:': '🐰',
    ':bear:': '🐻',
    ':panda:': '🐼',
    ':koala:': '🐨',
    ':tiger:': '🐯',
    ':lion:': '🦁',
    ':cow:': '🐮',
    ':pig:': '🐷',
    ':frog:': '🐸',
    ':monkey:': '🐵',
    ':chicken:': '🐔',
    ':bird:': '🐦',
    ':baby_chick:': '🐤',
    ':fish:': '🐟',
    ':dolphin:': '🐬',
    ':whale:': '🐋',
    ':horse:': '🐴',
    ':snail:': '🐌',
    ':butterfly:': '🦋',
    ':bug:': '🐛',
    ':ant:': '🐜',
    ':bee:': '🐝',
    ':beetle:': '🪲',
    ':lady_beetle:': '🐞',
    ':spider:': '🕷️',
    ':scorpion:': '🦂',
    ':snake:': '🐍',
    ':turtle:': '🐢',
    ':shell:': '🐚',
    
    // Transport
    ':car:': '🚗',
    ':taxi:': '🚕',
    ':bus:': '🚌',
    ':train:': '🚂',
    ':airplane:': '✈️',
    ':rocket:': '🚀',
    ':bike:': '🚲',
    ':boat:': '⛵',
    ':ship:': '🚢',
    
    // Time
    ':clock:': '🕐',
    ':watch:': '⌚',
    ':hourglass:': '⏳',
    ':alarm_clock:': '⏰',
    ':calendar:': '📅',
    ':date:': '📅',
    
    // Technology
    ':phone:': '📱',
    ':computer:': '💻',
    ':laptop:': '💻',
    ':keyboard:': '⌨️',
    ':mouse_computer:': '🖱️',
    ':printer:': '🖨️',
    ':camera:': '📷',
    ':video_camera:': '📹',
    ':tv:': '📺',
    ':radio:': '📻',
    ':cd:': '💿',
    ':dvd:': '📀',
    ':minidisc:': '💽',
    ':floppy_disk:': '💾',
    ':email:': '✉️',
    ':mailbox:': '📫',
    ':postbox:': '📮',
    ':package:': '📦',
    
    // Symbols
    ':checkmark:': '✅',
    ':check:': '✔️',
    ':x:': '❌',
    ':cross:': '❌',
    ':negative_squared_cross_mark:': '❎',
    ':white_check_mark:': '✅',
    ':question:': '❓',
    ':grey_question:': '❔',
    ':exclamation:': '❗',
    ':grey_exclamation:': '❕',
    ':warning:': '⚠️',
    ':no_entry:': '⛔',
    ':no_entry_sign:': '🚫',
    ':stop_sign:': '🛑',
    ':recycle:': '♻️',
    ':copyright:': '©️',
    ':registered:': '®️',
    ':tm:': '™️',
    ':information_source:': 'ℹ️',
    ':id:': '🆔',
    ':abc:': '🔤',
    ':symbols:': '🔣',
    ':1234:': '🔢',
    ':hash:': '#️⃣',
    ':asterisk:': '*️⃣',
    ':zero:': '0️⃣',
    ':one:': '1️⃣',
    ':two:': '2️⃣',
    ':three:': '3️⃣',
    ':four:': '4️⃣',
    ':five:': '5️⃣',
    ':six:': '6️⃣',
    ':seven:': '7️⃣',
    ':eight:': '8️⃣',
    ':nine:': '9️⃣',
    ':keycap_ten:': '🔟',
    
    // Flags (common ones)
    ':us:': '🇺🇸',
    ':uk:': '🇬🇧',
    ':canada:': '🇨🇦',
    ':australia:': '🇦🇺',
    ':germany:': '🇩🇪',
    ':france:': '🇫🇷',
    ':italy:': '🇮🇹',
    ':spain:': '🇪🇸',
    ':russia:': '🇷🇺',
    ':china:': '🇨🇳',
    ':japan:': '🇯🇵',
    ':india:': '🇮🇳',
    ':brazil:': '🇧🇷',
    ':mexico:': '🇲🇽',
  };
  
  static final Map<String, String> _cacheMap = {};
  
  /// Converts text-based emoticons and emoji names to Unicode emoji symbols
  static String convertTextToEmoji(String text) {
    if (text.isEmpty) return text;
    
    // Check cache first for performance
    if (_cacheMap.containsKey(text)) {
      return _cacheMap[text]!;
    }
    
    String convertedText = text;
    bool hasChanges = false;
    
    // Sort by length in descending order to match longer patterns first
    final sortedKeys = _textToEmojiMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String emoticon in sortedKeys) {
      if (convertedText.contains(emoticon)) {
        convertedText = convertedText.replaceAll(emoticon, _textToEmojiMap[emoticon]!);
        hasChanges = true;
      }
    }
    
    // Cache the result if there were changes
    if (hasChanges) {
      _cacheMap[text] = convertedText;
    }
    
    return convertedText;
  }
  
  /// Converts only the basic emoticons (like :), :D, etc.) to emoji
  static String convertBasicEmoticons(String text) {
    if (text.isEmpty) return text;
    
    String convertedText = text;
    
    // Basic emoticons only
    final basicEmoticons = {
      ':)': '😊',
      ':-)': '😊',
      ':(': '😢',
      ':-(': '😢',
      ':D': '😃',
      ':-D': '😃',
      ';)': '😉',
      ';-)': '😉',
      ':P': '😛',
      ':-P': '😛',
      ':p': '😛',
      ':-p': '😛',
      ':|': '😐',
      ':-|': '😐',
      ':O': '😮',
      ':-O': '😮',
      ':o': '😮',
      ':-o': '😮',
      ':/': '😕',
      ':-/': '😕',
      ':\\': '😕',
      ':-\\': '😕',
      'XD': '😆',
      'xD': '😆',
      ':*': '😘',
      ':-*': '😘',
      '<3': '❤️',
      '</3': '💔',
      '>:(': '😠',
      '>:-(': '😠',
      'B)': '😎',
      'B-)': '😎',
      '8)': '😎',
      '8-)': '😎',
    };
    
    // Sort by length in descending order
    final sortedKeys = basicEmoticons.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (String emoticon in sortedKeys) {
      if (convertedText.contains(emoticon)) {
        convertedText = convertedText.replaceAll(emoticon, basicEmoticons[emoticon]!);
      }
    }
    
    return convertedText;
  }
  
  /// Converts only named emoji (like :smile:, :heart:, etc.) to emoji
  static String convertNamedEmoji(String text) {
    if (text.isEmpty) return text;
    
    String convertedText = text;
    
    // Only process colon-wrapped emoji names
    final RegExp emojiPattern = RegExp(r':([a-zA-Z_]+):');
    final matches = emojiPattern.allMatches(text);
    
    for (final match in matches) {
      final fullMatch = match.group(0)!;
      if (_textToEmojiMap.containsKey(fullMatch)) {
        convertedText = convertedText.replaceAll(fullMatch, _textToEmojiMap[fullMatch]!);
      }
    }
    
    return convertedText;
  }
  
  /// Clears the conversion cache
  static void clearCache() {
    _cacheMap.clear();
  }
  
  /// Gets the size of the conversion cache
  static int getCacheSize() {
    return _cacheMap.length;
  }
  
  /// Gets all available emoticons and their emoji equivalents
  static Map<String, String> getAvailableConversions() {
    return Map.unmodifiable(_textToEmojiMap);
  }
  
  /// Checks if a text contains convertible emoticons
  static bool hasConvertibleText(String text) {
    if (text.isEmpty) return false;
    
    return _textToEmojiMap.keys.any((emoticon) => text.contains(emoticon));
  }
}