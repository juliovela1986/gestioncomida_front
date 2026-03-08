# Configuración del Backend Spring Boot

## Problema actual
El backend rechaza los tokens porque no está configurado correctamente para validar tokens de Keycloak.

## Configuración necesaria en application.yml

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          # IMPORTANTE: Usa la URL externa para que funcione desde cualquier lugar
          issuer-uri: http://julio86.myqnapcloud.com:8180/realms/gestioncomida
          jwk-set-uri: http://julio86.myqnapcloud.com:8180/realms/gestioncomida/protocol/openid-connect/certs

# Configuración de audiencia (importante para validar el token)
jwt:
  auth:
    converter:
      resource-id: gestioncomida-backend-client
      principal-attribute: preferred_username
```

## Configuración de SecurityConfig.java

Asegúrate de que tu SecurityConfig tenga:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors().and()
            .csrf().disable()
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
        grantedAuthoritiesConverter.setAuthoritiesClaimName("roles");
        grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
        return jwtAuthenticationConverter;
    }
}
```

## CORS Configuration

```java
@Configuration
public class CorsConfig {
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(false);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

## Pasos para aplicar

1. Actualiza el `application.yml` con la URL externa de Keycloak
2. Reinicia el contenedor Docker del backend
3. Verifica que el backend pueda acceder a Keycloak en `http://julio86.myqnapcloud.com:8180`

## Verificación

Prueba que el backend puede acceder a Keycloak:
```bash
curl http://julio86.myqnapcloud.com:8180/realms/gestioncomida/.well-known/openid-configuration
```

Debe devolver la configuración de OpenID Connect.
