# Firma release + AAB (ScanTicketFresh)

**applicationId definitivo:** `com.gestioncomida.gestioncomida_front` (no cambiar tras primera publicación).

## 1. Crear keystore (una vez)

```powershell
cd F:\GestionComida\gestioncomida_front\android
.\create_upload_keystore.ps1
```

Genera (gitignored):
- `android/upload-keystore.jks`
- `android/key.properties`

**Backup offline cifrado** del `.jks` + ambas passwords. Sin ellos no hay updates en Play.

Plantilla: `android/key.properties.example`.

## 2. Build AAB

```powershell
cd F:\GestionComida\gestioncomida_front
flutter build appbundle --release
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

Sin `key.properties`, release sigue firmando con **debug** (solo local; no subir a Play).

## 3. Verificar firma

```powershell
jarsigner -verify -verbose -certs build\app\outputs\bundle\release\app-release.aab
```

O con `apksigner` / Play Console tras subir a Internal testing.

## 4. Versionado

En `pubspec.yaml`: `version: X.Y.Z+CODE`  
- `versionName` = X.Y.Z  
- `versionCode` = CODE (entero monótono; cada subida a Play debe incrementarlo)
