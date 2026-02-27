# Especificación de Funcionalidades - Módulo de Inventario

## 📋 Resumen
Sistema de gestión inteligente de inventario de alimentos con control de consumo, alertas de caducidad y limpieza automática.

---

## 🎯 Funcionalidades Principales

### 1. Gestión de Cantidad de Productos

#### 1.1 Formulario de Edición de Inventario
- **Objetivo**: Permitir al usuario actualizar la cantidad de productos conforme los consume
- **Campos editables**:
  - Cantidad actual
  - Notas de consumo
  - Estado del producto (disponible, abierto, consumido)
  
#### 1.2 Actualización de Consumo
- Interfaz simple para reducir cantidad
- Botones rápidos: -1, -0.5, consumir todo
- Historial de consumo por producto
- Cálculo automático de cantidad restante

---

### 2. Sistema de Alertas de Caducidad

#### 2.1 Tipos de Fechas
- **Fecha de Aviso**: Notificación preventiva (ej: 3 días antes)
- **Fecha de Caducidad**: Fecha límite de consumo recomendada

#### 2.2 Notificaciones
- **Alerta Preventiva**: 
  - Se activa en la fecha de aviso
  - Mensaje: "El producto X caduca en N días"
  - Acción: Recordatorio para consumir pronto

- **Alerta de Caducidad**:
  - Se activa en la fecha de caducidad
  - Mensaje: "El producto X ha caducado"
  - Acciones disponibles:
    - ✅ "Aún es consumible" → Extender fecha
    - 🗑️ "Descartar producto" → Eliminar del inventario
    - ⏰ "Recordar más tarde" → Posponer notificación

#### 2.3 Gestión Post-Caducidad
- **Productos caducados pero consumibles**:
  - Algunos productos pueden consumirse después de caducar
  - Usuario puede marcar como "aún consumible"
  - Sistema pregunta si desea extender la fecha o eliminar

---

### 3. Limpieza Automática de Inventario

#### 3.1 Tarea Cron de Limpieza
- **Frecuencia**: Diaria (ej: 3:00 AM)
- **Criterios de eliminación**:
  - Productos caducados hace más de X días (configurable, ej: 30 días)
  - Productos con cantidad = 0 y sin movimiento en Y días
  - Productos marcados como "descartados"

#### 3.2 Reglas de Limpieza
```
SI (fechaCaducidad + 30 días < fechaActual) 
   Y (estado != "consumible_extendido")
ENTONCES eliminar_producto
```

#### 3.3 Notificación de Limpieza
- Email semanal con resumen de productos eliminados
- Opción de recuperar productos eliminados (papelera temporal de 7 días)

---

### 4. Estados del Producto en Inventario

| Estado | Descripción | Color | Acciones |
|--------|-------------|-------|----------|
| `DISPONIBLE` | Producto sin abrir, lejos de caducar | 🟢 Verde | Editar, Consumir |
| `PROXIMO_CADUCAR` | Dentro del período de aviso | 🟡 Amarillo | Editar, Consumir, Extender |
| `CADUCADO` | Pasó la fecha de caducidad | 🔴 Rojo | Descartar, Marcar consumible |
| `ABIERTO` | Producto abierto, vida útil reducida | 🟠 Naranja | Editar, Consumir |
| `CONSUMIDO` | Producto totalmente consumido | ⚫ Gris | Ver historial |

---

### 5. Pantalla de Inventario (UI/UX)

#### 5.1 Vista Principal
```
┌─────────────────────────────────────┐
│  🏠 Inventario                  🔔 3 │
├─────────────────────────────────────┤
│  Filtros: [Ubicación ▼] [Estado ▼] │
├─────────────────────────────────────┤
│  🟡 Leche Entera                    │
│     Nevera • Caduca en 2 días       │
│     Cantidad: 0.5L / 1L             │
│     [Editar] [Consumir]             │
├─────────────────────────────────────┤
│  🔴 Yogur Natural                   │
│     Nevera • Caducado hace 1 día    │
│     Cantidad: 2 unidades            │
│     [¿Consumible?] [Descartar]      │
├─────────────────────────────────────┤
│  🟢 Pasta                           │
│     Despensa • Caduca en 180 días   │
│     Cantidad: 500g                  │
│     [Editar] [Consumir]             │
└─────────────────────────────────────┘
```

#### 5.2 Formulario de Edición
- Cantidad actual (con slider o input numérico)
- Fecha de caducidad (date picker)
- Fecha de aviso (calculada automáticamente o manual)
- Ubicación (dropdown)
- Notas adicionales

---

### 6. Flujo de Trabajo

#### 6.1 Flujo de Consumo
```
Usuario abre app
    ↓
Ve notificación de producto próximo a caducar
    ↓
Accede al producto
    ↓
Reduce cantidad consumida
    ↓
Sistema actualiza inventario
    ↓
Si cantidad = 0 → Marcar como CONSUMIDO
```

#### 6.2 Flujo de Caducidad
```
Tarea Cron diaria
    ↓
Revisa productos con fecha de caducidad = hoy
    ↓
Genera notificación push/email
    ↓
Usuario recibe alerta
    ↓
Usuario decide: Consumir / Extender / Descartar
    ↓
Sistema actualiza estado
```

#### 6.3 Flujo de Limpieza
```
Tarea Cron semanal
    ↓
Identifica productos caducados > 30 días
    ↓
Mueve a papelera temporal
    ↓
Notifica al usuario
    ↓
Después de 7 días → Eliminación permanente
```

---

## 🔧 Implementación Técnica

### Backend (Spring Boot)
- **Scheduled Tasks**: `@Scheduled(cron = "0 0 3 * * *")` para limpieza
- **Notificaciones**: Sistema de notificaciones push/email
- **Estados**: Enum `InventoryItemStatus`
- **Soft Delete**: Campo `deletedAt` para papelera temporal

### Frontend (Flutter)
- **Pantalla de Inventario**: `InventoryScreen`
- **Formulario de Edición**: `EditInventoryItemScreen`
- **Notificaciones locales**: Plugin `flutter_local_notifications`
- **Filtros**: Por ubicación, estado, fecha de caducidad

### Base de Datos
```sql
-- Campos adicionales en inventory_item
alert_date DATE,           -- Fecha de aviso
expiration_date DATE,      -- Fecha de caducidad
status VARCHAR(50),        -- Estado del producto
quantity DECIMAL(10,2),    -- Cantidad actual
initial_quantity DECIMAL(10,2), -- Cantidad inicial
deleted_at TIMESTAMP       -- Soft delete
```

---

## 📊 Métricas y Reportes

### Estadísticas para el Usuario
- Productos próximos a caducar (7 días)
- Productos caducados sin gestionar
- Tasa de desperdicio mensual
- Productos más consumidos
- Ahorro estimado vs desperdicio

### Control Financiero

#### Gasto Total
- **Cálculo**: Suma de todos los tickets sincronizados
- **Visualización**: Gráfico mensual/anual de gastos
- **Desglose por**:
  - Categoría de producto (lácteos, carnes, verduras, etc.)
  - Supermercado
  - Mes/Semana
  - Ubicación de almacenamiento

#### Ahorro por Prevención de Merma
- **Cálculo**: Valor de productos que se consumieron antes de caducar gracias a las alertas
- **Fórmula**: `Ahorro = Σ(precio_producto × cantidad_consumida_antes_caducidad)`
- **Indicadores**:
  - 💰 Dinero ahorrado este mes
  - 📈 Tendencia de ahorro (mejorando/empeorando)
  - 🎯 Objetivo de ahorro mensual

#### Pérdida por Merma
- **Cálculo**: Valor de productos descartados por caducidad
- **Fórmula**: `Pérdida = Σ(precio_producto × cantidad_descartada)`
- **Análisis**:
  - Productos más desperdiciados
  - Razones de desperdicio
  - Recomendaciones de compra

#### Comparativa Mensual
```
┌─────────────────────────────────────┐
│  💰 Resumen Financiero - Diciembre  │
├─────────────────────────────────────┤
│  Gasto Total:           450.00€     │
│  Ahorro por alertas:     45.00€ ✅  │
│  Pérdida por merma:      12.00€ ❌  │
│  ─────────────────────────────────  │
│  Eficiencia:            97.3% 📊    │
│  vs mes anterior:       +2.1% 📈    │
└─────────────────────────────────────┘
```

### Dashboard
```
┌─────────────────────────────────────┐
│  📊 Resumen del Mes                 │
├─────────────────────────────────────┤
│  ✅ Productos consumidos: 45        │
│  🗑️ Productos descartados: 3        │
│  💰 Ahorro estimado: 120€           │
│  ⚠️ Próximos a caducar: 5           │
└─────────────────────────────────────┘
```

---

## 🚀 Roadmap de Implementación

### Fase 1: Gestión Básica de Inventario ✅
- [x] Modelo de datos
- [x] CRUD de inventario
- [x] Sincronización desde tickets

### Fase 2: Sistema de Alertas (Próximo)
- [ ] Implementar fechas de aviso y caducidad
- [ ] Sistema de notificaciones
- [ ] Pantalla de inventario con filtros
- [ ] Formulario de edición de cantidad

### Fase 3: Gestión de Caducidad
- [ ] Diálogos de decisión (consumible/descartar)
- [ ] Estados de productos
- [ ] Extensión de fechas

### Fase 4: Limpieza Automática
- [ ] Tarea cron de limpieza
- [ ] Papelera temporal (soft delete)
- [ ] Notificaciones de limpieza
- [ ] Recuperación de productos

### Fase 5: Reportes y Estadísticas
- [ ] Dashboard de métricas
- [ ] Reportes mensuales
- [ ] Gráficos de consumo
- [ ] Análisis de desperdicio

---

## 💡 Ideas Adicionales

### Funcionalidades Futuras
1. **Sugerencias de Recetas**: Basadas en productos próximos a caducar 🍳
   - Integración con API de recetas (Spoonacular, Edamam)
   - Filtrado por ingredientes disponibles
   - Priorización de productos próximos a caducar
   - Generación de menú semanal
   - Lista de compras automática para ingredientes faltantes
   
2. **Lista de Compras Inteligente**: Generada automáticamente según consumo
3. **Compartir Inventario**: Entre miembros de la familia
4. **Escaneo de Códigos de Barras**: Para añadir productos rápidamente
5. **Integración con Supermercados**: Precios actualizados y ofertas
6. **Modo Offline**: Sincronización cuando haya conexión
7. **Análisis Predictivo**: Predicción de consumo y sugerencias de compra
8. **Gamificación**: Logros por reducir desperdicio y ahorrar dinero

### Mejoras de UX
- Widgets de inicio rápido
- Accesos directos a productos frecuentes
- Modo oscuro
- Personalización de alertas por tipo de producto
- Recordatorios personalizados

---

## 📝 Notas de Desarrollo

### Consideraciones Importantes
- **Privacidad**: Los datos de inventario son sensibles
- **Performance**: Optimizar consultas con índices en fechas
- **Escalabilidad**: Preparar para múltiples usuarios por hogar
- **Localización**: Formatos de fecha según región
- **Accesibilidad**: Colores y textos accesibles

### Testing
- Unit tests para lógica de caducidad
- Integration tests para tarea cron
- E2E tests para flujo completo de consumo
- Tests de notificaciones

---

**Versión**: 1.0  
**Fecha**: 2024-12-27  
**Autor**: Equipo GestionComida  
**Estado**: En Desarrollo
