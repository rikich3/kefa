# Funcionalidad de Recetas - Guía de Uso

## Descripción
Se ha implementado un sistema completo para gestionar recetas como una serie de pasos ordenados. Cada paso incluye trabajadores necesarios, utensilios con cantidades, y tiempo de realización.

## Cómo usar la nueva funcionalidad

### 1. Acceder al módulo de Recetas
1. Abrir la aplicación kefa
2. Ir a la pestaña "Manage" 
3. En la sección "Administrar Recetas", hacer clic en "Recetas"
4. Se abrirá un modal con las opciones de gestión

### 2. Crear una nueva receta
1. En el modal de recetas, hacer clic en "Crear Nueva Receta"
2. Llenar la información general:
   - Nombre de la receta
   - Descripción
3. Agregar pasos haciendo clic en "Agregar Paso"

### 3. Configurar cada paso
Cada paso permite configurar:
- **Descripción**: Qué se debe hacer en este paso
- **Tiempo**: Duración en segundos
- **Trabajadores**: Seleccionar qué tipos de trabajadores se necesitan (de los ya creados)
- **Utensilios**: Seleccionar qué utensilios se necesitan y en qué cantidades

### 4. Gestionar pasos
- **Editar**: Hacer clic en el icono de edición junto a cada paso
- **Eliminar**: Hacer clic en el icono de eliminación
- **Reordenar**: Los pasos se muestran en el orden que se agregaron

### 5. Guardar la receta
- Una vez agregados todos los pasos, hacer clic en "Guardar Receta"
- El tiempo total se calcula automáticamente sumando todos los pasos
- La receta se guardará en la base de datos local (Hive)

## Estructura de datos

### Paso
```dart
{
  trabajadores: ["Cocinero", "Ayudante"], // Tipos de trabajadores
  utensilioTipos: ["Sartén", "Cuchillo"], // Tipos de utensilios
  utensilioCantidades: [1, 2], // Cantidad de cada utensilio
  tiempoSegundos: 300, // 5 minutos
  descripcion: "Cortar las verduras en cubos pequeños"
}
```

### Receta
```dart
{
  id: 1,
  nombre: "Verduras salteadas",
  descripcion: "Receta saludable de verduras",
  pasos: [/* lista de pasos */],
  tiempoTotalSegundos: 900, // Calculado automáticamente
  fechaCreacion: DateTime.now()
}
```

## Prerequisitos
Para usar la funcionalidad completa es recomendable tener:
1. Trabajadores creados (diferentes tipos/funciones)
2. Instrumentos/utensilios creados
3. Esto permite seleccionar opciones al crear pasos

## Validaciones implementadas
- Nombre y descripción de receta obligatorios
- Al menos un paso requerido
- Descripción y tiempo de paso obligatorios
- Al menos un trabajador por paso
- Cantidades válidas para utensilios

## Próximas mejoras sugeridas
- Edición de recetas existentes
- Duplicar recetas
- Búsqueda y filtrado de recetas
- Exportar/importar recetas
- Estimación de recursos totales necesarios
