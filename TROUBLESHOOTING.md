# Troubleshooting - Error 401 en bucle

## Problema
El token se refresca correctamente desde Keycloak pero el backend sigue devolviendo 401.

## Posibles causas

### 1. Configuración de Keycloak en el backend
El backend necesita estar configurado para validar tokens de Keycloak en la nueva IP.

Verifica en tu backend (Spring Boot):
```yaml
# application.yml o application.properties
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://192.168.1.150:8180/realms/gestioncomida
          jwk-set-uri: http://192.168.1.150:8180/realms/gestioncomida/protocol/openid-connect/certs
```

### 2. Cliente de Keycloak
Verifica que el cliente `gestioncomida-mobile` en Keycloak tenga:
- Valid Redirect URIs: `com.gestioncomida.app://callback`
- Web Origins: `*` o la URL específica
- Access Type: `public`
- Standard Flow Enabled: `ON`
- Direct Access Grants Enabled: `ON`

### 3. Roles y permisos
Verifica que el usuario tenga los roles necesarios asignados en Keycloak.

### 4. Sincronización de tiempo
Asegúrate de que el servidor (NAS) y el dispositivo móvil tengan la hora sincronizada.

## Solución temporal
He agregado protección contra bucles infinitos en el código, pero necesitas verificar la configuración del backend.
