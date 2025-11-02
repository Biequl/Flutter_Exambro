# ========================
# Flutter & Dart
# ========================
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Keep Dart classes
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ========================
# Google Play Services / Firebase
# ========================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ========================
# ML Kit
# ========================
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ========================
# Kotlin
# ========================
-keep class kotlin.Metadata { *; }
-keepclassmembers class ** {
    @kotlin.Metadata *;
}

# ========================
# Annotations
# ========================
-keepattributes *Annotation*

# ========================
# Prevent stripping EntryPoints
# ========================
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Ignore Flutter PlayStoreDeferredComponentManager (not used in normal apps)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

