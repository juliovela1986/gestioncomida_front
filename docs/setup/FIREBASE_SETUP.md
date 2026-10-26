# Configuración de Firebase

## Pasos para configurar Firebase:

### 1. Crear proyecto en Firebase Console
- Ir a https://console.firebase.google.com/
- Crear nuevo proyecto: "GestionComida"
- Habilitar Google Analytics (opcional)

### 2. Añadir app Android
- En Project Settings → Add app → Android
- Package name: `com.gestioncomida.gestioncomida_front`
- Descargar `google-services.json`
- Colocar en: `android/app/google-services.json`

### 3. Añadir app iOS (si aplica)
- En Project Settings → Add app → iOS
- Bundle ID: `com.gestioncomida.gestioncomidaFront`
- Descargar `GoogleService-Info.plist`
- Colocar en: `ios/Runner/GoogleService-Info.plist`

### 4. Configurar Android
Editar `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Editar `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21  // Firebase requiere mínimo 21
    }
}
```

### 5. Habilitar Cloud Messaging
- En Firebase Console → Cloud Messaging
- Copiar Server Key para el backend

### 6. Ejecutar
```bash
flutter pub get
flutter run
```

## Archivos necesarios (NO commitear):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Variables de entorno para backend:
- `FIREBASE_SERVER_KEY` - Para enviar notificaciones
- O usar Firebase Admin SDK con archivo de credenciales JSON
