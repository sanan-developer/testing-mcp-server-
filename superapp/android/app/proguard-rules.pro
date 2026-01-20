# Proguard rules for Superwall and Google Play Billing
-keep class com.superwall.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.superwall.**
-dontwarn com.android.billingclient.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
