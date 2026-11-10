-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
-keepattributes *Annotation*

# Audio engine & Media bindings
-keep class com.ryanheise.** { *; }
-keep class com.hearable.** { *; }
-dontwarn com.ryanheise.**
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-dontwarn android.support.v4.**
