# ML Kit face detection uses reflection-free APIs; keep its model classes to
# be safe under R8.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_face** { *; }
