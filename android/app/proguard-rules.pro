# Flutter/Dart ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth + Core + Firestore
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.recaptcha.** { *; }
-dontwarn com.google.android.recaptcha.**


# HTTP client
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Gson
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
