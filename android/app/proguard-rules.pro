# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart SSH2
-keep class com.jcraft.jsch.** { *; }

# Custom rules to prevent R8 from removing code that might be used via reflection (if any)
# or specific model classes if they are serialized inappropriately (though we use dart:convert)
