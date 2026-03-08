# Guía de Uso - Nuevas Funcionalidades

## 🎯 Flujo Principal: Procesar Ticket con Fechas de Caducidad

### 1. Subir PDF del Ticket
1. Desde el **Home**, presiona **"Subir PDF"**
2. Selecciona el archivo PDF del ticket
3. Presiona **"Subir PDF"**
4. Espera mientras se procesa (OCR + IA)

### 2. Revisar Ticket Procesado
- Automáticamente navegarás a la pantalla de **Detalle del Ticket**
- Verás:
  - Información del ticket (fecha, número, supermercado)
  - Lista de productos con cantidades y precios
- Si necesitas editar, usa los botones de edición (funcionalidad existente)

### 3. Sincronizar a Inventario
1. Presiona el botón **"Añadir al inventario"**
2. El sistema:
   - Crea/actualiza productos en el catálogo
   - Añade items al inventario con cantidades
3. Automáticamente navegarás a **Gestión de Fechas de Caducidad**

### 4. Asignar Fechas de Caducidad
- Verás los productos **uno a uno**
- Para cada producto:
  - **Nombre del producto** y **cantidad** destacados
  - Si ya existe en inventario, verás un **banner naranja**
  - Contador de progreso: **(1/5, 2/5, etc.)**

#### Opciones por producto:
1. **📅 Seleccionar fecha manualmente**
   - Abre un calendario
   - Selecciona la fecha de caducidad
   - Se guarda automáticamente

2. **📷 Escanear fecha del producto**
   - (Por ahora abre el calendario)
   - En el futuro: captura foto y extrae fecha con OCR

3. **⏭️ Saltar (sin caducidad)**
   - Para productos no perecederos
   - Pasa al siguiente item sin asignar fecha

### 5. Finalizar
- Después del último producto, vuelves al **Home**
- Todos los items están en el inventario con sus fechas

---

## 📍 Gestión de Ubicaciones

### Acceder
- Desde el **Home**, presiona **"Gestionar Ubicaciones"**

### Crear Nueva Ubicación
1. Presiona el botón **+** (FloatingActionButton)
2. Ingresa:
   - **Nombre**: Ej. "Nevera", "Congelador", "Despensa"
   - **Tipo**: Ej. "Cocina", "Garaje", "Habitación"
3. Presiona **"Crear"**

### Editar Ubicación
1. Presiona el icono **✏️** junto a la ubicación
2. Modifica nombre o tipo
3. Presiona **"Guardar"**

### Eliminar Ubicación
1. Presiona el icono **🗑️** junto a la ubicación
2. Confirma la eliminación
3. La ubicación se elimina permanentemente

### Usar Ubicaciones
- Al procesar un ticket, puedes seleccionar ubicación destino
- Al añadir items manualmente, selecciona la ubicación
- Filtra tu inventario por ubicación

---

## 🔔 Notificaciones de Caducidad

### Ver Notificaciones
- En el **Home**, verás un **badge rojo** con el número de notificaciones sin leer
- Presiona el icono **🔔** para ver todas

### Tipos de Alertas
- **Próximo a caducar**: 3 días antes de la fecha
- **Caducado**: Productos vencidos
- **Stock bajo**: Cantidad mínima alcanzada

### Marcar como Leída
- Al abrir una notificación, se marca automáticamente como leída
- El contador se actualiza

---

## 📦 Inventario

### Ver Inventario
- Desde el **Home**, presiona **"Ver Inventario"**
- Verás todos tus productos con:
  - Nombre y marca
  - Cantidad actual
  - Fecha de caducidad
  - Ubicación

### Editar Item
- Presiona sobre un item
- Modifica cantidad, fecha, ubicación o notas
- Guarda los cambios

### Eliminar Item
- Desliza el item o presiona el icono de eliminar
- Confirma la eliminación

---

## 🎨 Ejemplos de Uso

### Ejemplo 1: Compra Semanal
```
1. Llegas del supermercado con el ticket
2. Subes el PDF desde la app
3. Revisas que los productos estén correctos
4. Sincronizas a inventario
5. Asignas fechas de caducidad:
   - Leche: 7 días
   - Pan: 3 días
   - Arroz: Saltar (no caduca)
6. ¡Listo! Todo en tu inventario
```

### Ejemplo 2: Organizar Ubicaciones
```
1. Vas a "Gestionar Ubicaciones"
2. Creas:
   - "Nevera" (Cocina)
   - "Congelador" (Cocina)
   - "Despensa" (Cocina)
   - "Congelador Grande" (Garaje)
3. Al añadir productos, seleccionas la ubicación
4. Filtras tu inventario por ubicación
```

### Ejemplo 3: Alertas de Caducidad
```
1. El sistema detecta productos próximos a caducar
2. Recibes notificación automática
3. Abres la app y ves el badge rojo
4. Revisas las notificaciones
5. Decides qué hacer con cada producto:
   - Consumir pronto
   - Congelar
   - Descartar si ya caducó
```

---

## 🐛 Solución de Problemas

### El PDF no se procesa
- Verifica que sea un PDF válido
- Asegúrate de tener conexión a internet
- El ticket debe tener texto legible (no imagen escaneada borrosa)

### No aparecen items sin fecha
- Verifica que sincronizaste el ticket primero
- Algunos productos pueden tener fecha automática del catálogo
- Revisa el inventario para confirmar

### Error al crear ubicación
- Verifica que el nombre no esté vacío
- Asegúrate de tener conexión a internet
- Cierra sesión y vuelve a iniciar

### Las notificaciones no aparecen
- Verifica que tengas productos con fecha de caducidad
- Las alertas se generan 3 días antes
- Refresca la pantalla de notificaciones

---

## 📱 Atajos y Tips

- **Saltar múltiples items**: Si tienes muchos productos sin caducidad, usa "Saltar" rápidamente
- **Fechas comunes**: La leche suele ser 7 días, el pan 3 días, yogures 15-30 días
- **Ubicaciones predefinidas**: Crea tus ubicaciones más usadas al inicio
- **Revisar antes de sincronizar**: Siempre revisa el ticket antes de añadir al inventario
- **Notificaciones diarias**: Revisa las notificaciones cada mañana

---

## 🚀 Próximas Mejoras

- OCR de fechas desde foto del producto
- Sugerencias de fechas basadas en el tipo de producto
- Compartir inventario con familia
- Listas de compra automáticas
- Estadísticas de consumo
