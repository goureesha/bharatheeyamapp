# Flutter/Dart ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# Google Sign-In + Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase (Auth, Core, Firestore)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.recaptcha.** { *; }
-dontwarn com.google.android.recaptcha.**

# Google APIs
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**

# HTTP client / Guava
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Gson
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# gRPC (used by Firestore)
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Protobuf (used by Firebase)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# OkHttp (used internally by Firebase)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# Suppress warnings for missing optional classes
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.**
-dontwarn com.google.errorprone.**
-dontwarn com.google.j2objc.**
-dontwarn java.lang.invoke.**
-dontwarn sun.misc.**
