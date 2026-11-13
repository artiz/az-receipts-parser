# R8 rules for the release build (minify on: Google Play asks for
# obfuscated DEX code). Plugins and AndroidX bring their own rules; these
# cover what they miss.

# The embedding finds the plugin registrant by name (Class.forName).
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Referenced by the Flutter embedding for deferred components, which the app
# does not use; not on the classpath.
-dontwarn com.google.android.play.core.**

# Compile-time annotations of Tink (flutter_secure_storage), not shipped.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
