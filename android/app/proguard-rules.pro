# Flutter's embedding and the plugin registrant are reached reflectively.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase/Play Services model classes are populated by reflection from JSON.
-keepattributes Signature,*Annotation*,EnclosingMethod,InnerClasses
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# R8 warns about optional desugaring/annotation classes that are never used
# at runtime on Android. Silencing these keeps the build output readable.
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**

# The Flutter engine references Play Core's deferred-component / split-install
# APIs, but this app never uses deferred components, so that library is not on
# the classpath. R8 treats the dangling references as errors without this.
-dontwarn com.google.android.play.core.**
