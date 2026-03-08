# Ignorar advertencias de librerías comunes que causan conflictos con R8
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.j2objc.annotations.**

# Si usas Tink o librerías de Google Crypto (que parece que sí por el log)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**