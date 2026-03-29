# Rules to prevent R8/ProGuard from obfuscating generics/classes needed for Local Notifications plugin

# Keep attributes that preserve Types and Signatures for GSON deserialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep Gson TypeToken from being mangled
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep FlutterLocalNotificationsPlugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
