# Zitatecke: Sprüche & Grüße – Flutter App (v1)

Play Store title: **Zitatecke: Sprüche & Grüße** · Phone pe naam: **Zitatecke** · Package ID: **de.zitatecke.app**

German audience ke liye Guten Morgen, Gute Nacht aur Motivation quotes app.

## Features (v1)
- 8 categories, 141 German Sprüche (offline): Guten Morgen, Gute Nacht, Motivation, Wochentage, Wochenende, Freundschaft, Geburtstag, Feiertage
- **Spruch des Tages** – time ke hisaab se (subah Morgen, din mein Motivation, raat Nacht)
- Quote ko **1080×1080 image** bana ke WhatsApp / kisi bhi app pe share
- 17 background designs, swipe karke agla quote
- Favoriten (phone mein save)
- Roz subah aur raat **notification** (time badal sakte ho)
- "Heute ist Montag" – aaj ke din ke Sprüche
- Poora UI German mein, bade buttons (older users ke liye)

## Chalane ke steps

Zaroori: Flutter SDK (3.27 ya naya) + Android Studio / Android phone.

```bash
# 1. Zip extract karo, folder mein jao
cd zitatecke_app

# 2. Android folder banao
flutter create --project-name guten_morgen_app --org de.zitatecke --platforms android .

# 3. Packages
flutter pub get

# 4. Notifications + package ID "de.zitatecke.app" setup (ek baar)
dart run tool/setup_android.dart

# 5. Phone connect karo aur chalao
flutter run
```

Release APK / Play Store bundle:
```bash
flutter build appbundle
```

### Agar step 4 fail ho
`android/app/build.gradle.kts` mein khud ye do cheezein add karo:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // ye line add
        ...
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
Aur `android_files/AndroidManifest.xml` ko `android/app/src/main/AndroidManifest.xml` pe copy kar do.

## Content kaise badlein / badhayein
- Quotes: `assets/quotes.json` – naya quote add karo (har `id` unique hona chahiye).
- Naya background design: `lib/theme/card_styles.dart`
- App naam, watermark, Play Store link: `lib/config.dart`
- Publish se pehle **kisi native German speaker se saare texts check karwa lo.**

## Files
```
lib/
  main.dart                 app start, bottom tabs
  config.dart               naam, watermark, Play Store link
  app_state.dart            favorites + notification settings
  data/quote_repository.dart  quotes load, Spruch des Tages
  services/                 notifications, image share
  screens/                  Start, Kategorie, Detail, Favoriten, Einstellungen
  widgets/quote_card.dart   share hone wali image ka design
assets/quotes.json          saare German Sprüche
```

## Next steps (v2)
- AdMob ads + GDPR consent (UMP)
- App icon (`flutter_launcher_icons`)
- Apni photo pe Spruch likhna
- Home screen widget
- Firebase se naya content bina app update ke

## APK bina Flutter install kiye (GitHub se)
1. github.com pe free account banao → **New repository** (naam: zitatecke-app, Private chalega).
2. "uploading an existing file" pe click karke is folder ki saari files/folders drag & drop karo → **Commit changes**.
   - Agar `.github` folder upload na ho: **Add file → Create new file**, naam `.github/workflows/build-apk.yml` likho aur us file ka content paste karo.
3. Repo mein **Actions** tab kholo → "Build APK" chalega (~8–10 min).
4. Green ✓ aane par us run pe click karo → neeche **Artifacts → zitatecke-apk** download karo (zip ke andar `app-release.apk`).
5. Phone pe APK kholo → "Unknown apps install" allow karo → Install.

Note: Ye APK testing ke liye hai. Play Store ke liye apni signing key (upload key) banani padegi – wo hum baad mein karenge.
