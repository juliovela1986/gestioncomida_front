# Ignorar advertencias de librerías comunes que causan conflictos con R8
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.j2objc.annotations.**

# Si usas Tink o librerías de Google Crypto
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ── Reglas para Google ML Kit Text Recognition ──────────────────────────────
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**

# Ignorar las opciones de idiomas específicos que no estamos usando directamente
# Esto soluciona el error de "Missing classes detected while running R8"
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
