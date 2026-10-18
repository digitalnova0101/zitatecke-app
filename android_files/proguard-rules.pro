# Release build (R8) plugins ka code na hataye – warna app white screen pe atak jaati hai.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.dexterous.** { *; }

# flutter_local_notifications (Gson)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

-dontwarn com.google.android.play.core.**
