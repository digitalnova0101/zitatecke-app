/// Yahan app ki basic settings badlo.
library;

/// App ka naam (app ke andar dikhta hai).
const String kAppName = 'Zitatecke';

/// Play Store wala poora title (max 30 characters).
const String kStoreTitle = 'Zitatecke: Sprüche & Grüße';

/// Website.
const String kWebsite = 'zitatecke.de';

/// Har share ki gayi image ke neeche chhota sa text (free promotion).
const String kWatermark = 'zitatecke.de';

/// Play Store link. App publish hone ke baad yahan daalo,
/// phir har share ke saath link bhi jayega. Khali rakho to link nahi jayega.
/// Example: 'https://play.google.com/store/apps/details?id=de.zitatecke.app'
const String kPlayStoreLink = 'https://play.google.com/store/apps/details?id=de.zitatecke.app';

/// App-Version (pubspec.yaml ke saath badalna).
const String kAppVersion = '1.6.0';

/// Feedback / Support E-Mail.
const String kSupportEmail = 'kontakt@zitatecke.de';

/// Rechtliches (Play Store braucht die Datenschutz-URL).
const String kPrivacyUrl = 'https://zitatecke.moezzadigital.com/datenschutz.html';
const String kImprintUrl = 'https://zitatecke.moezzadigital.com/impressum.html';

/// Kitne din aage tak notifications schedule karni hain.
const int kNotificationDays = 21;

/// Roz ke AI quotes + photos yahan se aate hain (GitHub job upload karta hai).
const String kContentBase = 'https://zitatecke.moezzadigital.com/';
const String kFeedUrl = '${kContentBase}feed.json';

/// Feed kitni der baad dobara check ho.
const Duration kFeedRefreshEvery = Duration(hours: 3);

/// Phone mein max kitni online photos rakhni hain.
const int kMaxCachedPhotos = 120;
