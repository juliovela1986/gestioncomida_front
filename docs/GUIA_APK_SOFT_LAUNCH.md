# Guía — APK soft launch para amigos (Android)

**Fecha:** 2026-10-28  
**Objetivo:** APK instalable fuera de Play Store (sideload) apuntando a prod duckdns.  
**Backend:** `https://api-gestioncomida.duckdns.org` · Auth: `https://auth-gestioncomida.duckdns.org`

---

## Requisitos en el PC

- Flutter estable (`flutter doctor` sin errores bloqueantes Android)
- Android SDK / cmdline-tools
- USB debugging **o** solo generar APK y pasarlo por Drive/WhatsApp
- Repo: `F:\GestionComida\gestioncomida_front`

---

## 1) Config prod (`.env`)

El APK embebe el asset `.env` (`pubspec.yaml` → `assets: - .env`).

Comprueba que **antes del build** el `.env` tenga (sin espacios raros):

```env
BACKEND_URL=https://api-gestioncomida.duckdns.org
KEYCLOAK_URL=https://auth-gestioncomida.duckdns.org
```

Comenta cualquier `BACKEND_URL` de LAN (`192.168.x.x`).  
No subas `.env` con secretos a git; solo úsalo en tu máquina para el build.

Opcional FCM/Groq: deja las claves que ya uses en beta; no hace falta cambiarlas para amigos.

---

## 2) Build release APK

```powershell
cd F:\GestionComida\gestioncomida_front
flutter pub get
flutter clean
flutter build apk --release
```

Salida típica:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Copia a un sitio fácil de enviar:

```powershell
Copy-Item build\app\outputs\flutter-apk\app-release.apk F:\GestionComida\GestionComida-softlaunch.apk
```

**Nota firma:** si release sigue firmado con debug (habitual en soft launch), Android mostrará aviso; para amigos está OK. Para Play Store haréis keystore propio (ver `docs/ideas/ROADMAP_DESPLIEGUE_PLAY_STORE.md`).

APK más ligero (solo arm64, la mayoría de móviles actuales):

```powershell
flutter build apk --release --split-per-abi
# Usar: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

---

## 3) Probar tú primero (antes de mandar)

1. Instala en tu móvil (USB o el APK).
2. Datos móviles **4G/5G** (no solo WiFi casa).
3. Login Keycloak → ticket / inventario / lista.
4. Añade “pechuga” con master vinculado → **Comparar** (sin spamear `forceRefresh`).
5. Espera FCM `COMPARE_READY` o poll; ranking parcial OK.

Si login falla en 4G: Keycloak `KC_HOSTNAME` / redirect URIs duckdns (ya validados en SCRUM-100).

---

## 4) Distribuir a amigos

1. Sube `GestionComida-softlaunch.apk` a Drive / WhatsApp / Telegram.
2. Instrucciones cortas para ellos:

> 1. En Android: Ajustes → Seguridad → permitir instalar apps desconocidas (o “Instalar apps desconocidas” para Files/Chrome).  
> 2. Abre el APK e instala.  
> 3. Crea cuenta / login.  
> 4. Prueba: ticket foto, inventario, lista de la compra → Comparar precios.  
> 5. Si algo falla, captura pantalla + dime qué paso.

3. Límite razonable: 5–15 personas al principio (NAS + Carrefour sensibles a abuso).

---

## 5) Checklist rápido

| Check | OK |
|-------|----|
| `.env` duckdns (api + auth) | |
| `flutter build apk --release` sin error | |
| Install en tu móvil 4G | |
| Login | |
| Compare pechuga ≥1 super | |
| Back redeployado con `SCRAPER_NAS_TARGETS=carrefour` | |
| SOCKS NAS Up (`residential-socks`) | |

---

## Problemas frecuentes

| Síntoma | Qué mirar |
|---------|-----------|
| App apunta a IP local | Rebuild con `.env` duckdns |
| Login redirect error | Cliente Keycloak / HTTPS duckdns |
| Compare vacío | Master product en ítem; back + scraper UP |
| Carrefour vacío | Lubuntu CDP; resto de supers pueden OK |
| “App no instalada” | Desinstalar build debug previo; permitir orígenes desconocidos |

---

## Después del soft launch

- Smoke + feedback → cerrar **SCRUM-98**
- Play Store: AAB + keystore + listing → **SCRUM-136** (`PLAY_STORE_SECURITY_CHECKLIST.md`)
