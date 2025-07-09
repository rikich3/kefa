# Sistema de Realización de Recetas - Documentación

## Descripción General

Se ha implementado un sistema completo para la realización automatizada de recetas que incluye:

1. **Preprocesamiento**: Calcula las agendas óptimas para trabajadores y utensilios
2. **Ejecución en Tiempo Real**: Cronómetro que coordina las tareas y notifica a los trabajadores
3. **Interfaz de Usuario**: Pantalla completa con controles intuitivos

## Arquitectura del Sistema

### Modelos de Datos (`lib/back/system/agenda_models.dart`)

- **`EntradaAgenda`**: Representa una tarea específica con tiempo de inicio, paso, receta e instancia
- **`Agenda`**: Contiene todas las tareas asignadas a un requisito (trabajador o utensilio)
- **`ConjuntoRequisitos`**: Grupo de requisitos evaluados juntos en el algoritmo
- **`TipoRequisito`**: Enum que diferencia entre trabajadores y utensilios

### Sistema de Preprocesamiento (`lib/back/system/sistema_preprocesamiento.dart`)

**Funcionalidades principales:**
- Inicializa agendas vacías para todos los trabajadores y utensilios disponibles
- Ejecuta el algoritmo de optimización para asignar tareas
- Calcula tiempos de origen y overhead para optimizar la asignación
- Genera la cronología completa de todas las tareas

**Algoritmo implementado:**
1. Para cada paso de cada receta (multiplicado por cantidad):
   - Calcula `ori_min` (origen mínimo entre trabajadores necesarios)
   - Forma conjuntos de requisitos disponibles
   - Ordena conjuntos por origen mínimo
   - Encuentra conjunto con menor overhead
   - Asigna el paso al conjunto óptimo

### Sistema de Ejecución (`lib/back/system/sistema_ejecucion.dart`)

**Estados del sistema:**
- `detenido`: Estado inicial, sin ejecución
- `ejecutando`: Cronómetro activo, notificaciones activas
- `pausado`: Ejecución pausada temporalmente
- `completado`: Todas las tareas terminadas

**Funcionalidades:**
- Cronómetro interno con precisión de segundos
- Notificaciones automáticas al inicio de cada tarea
- Seguimiento de progreso en tiempo real
- Control de tareas activas, próximas y completadas

## Interfaz de Usuario

### Pantalla Principal (`lib/realizar_tab.dart`)

**Secciones:**
1. **Selección de Recetas**: Permite elegir recetas y cantidades
2. **Control de Ejecución**: Botones de inicio/pausa/detener y estado actual
3. **Vista de Agendas**: Visualización cronológica y por requisito

### Widgets Principales

#### `SeleccionRecetasWidget` (`lib/widgets/seleccion_recetas_widget.dart`)
- Modal para seleccionar recetas de la base de datos
- Selector de cantidad (1-10 instancias por receta)
- Lista visual de recetas seleccionadas con tiempo estimado
- Opción para eliminar recetas antes del preprocesamiento

#### `ControlEjecucionWidget` (`lib/widgets/control_ejecucion_widget.dart`)
- Estado visual del sistema con colores distintivos
- Barra de progreso con porcentaje y tiempo restante
- Controles de reproducción (iniciar/pausar/detener/reiniciar)
- Vista de tareas actuales y próximas tareas

#### `VistaAgendasWidget` (`lib/widgets/vista_agendas_widget.dart`)
- **Cronología General**: Todas las tareas ordenadas temporalmente
- **Vista por Trabajadores**: Agendas individuales de cada trabajador
- **Vista por Utensilios**: Agendas individuales de cada utensilio
- Indicadores visuales de estado (completada/en ejecución/pendiente)

## Flujo de Uso

### 1. Preparación
1. Asegurarse de tener trabajadores y utensilios creados en la base de datos
2. Crear recetas con pasos detallados que especifiquen:
   - Tipos de trabajadores necesarios
   - Utensilios requeridos y cantidades
   - Tiempo estimado de ejecución

### 2. Selección
1. Ir a la pestaña "Realizar"
2. Hacer clic en "Agregar Receta"
3. Seleccionar receta del dropdown
4. Especificar cantidad de instancias (1-10)
5. Repetir para múltiples recetas si es necesario

### 3. Preprocesamiento
1. Hacer clic en "Ejecutar Preprocesamiento"
2. El sistema calcula automáticamente:
   - Asignación óptima de tareas a trabajadores
   - Asignación de utensilios disponibles
   - Cronología completa optimizada
   - Tiempo total estimado

### 4. Ejecución
1. Hacer clic en "Iniciar" para comenzar el cronómetro
2. El sistema notifica automáticamente:
   - Inicio de cada tarea con nombre del trabajador
   - Descripción del paso a realizar
   - Duración estimada
3. Usar controles para pausar/reanudar/detener según necesidad

### 5. Monitoreo
- **Cronología General**: Ver todas las tareas en orden temporal
- **Vista por Trabajadores**: Monitorear carga de trabajo individual
- **Vista por Utensilios**: Verificar disponibilidad de herramientas
- **Progreso**: Seguir avance general y tiempo restante

## Características Técnicas

### Optimización del Algoritmo
- **Objetivo**: Minimizar tiempo total y balancear carga de trabajo
- **Criterio principal**: Overhead mínimo entre requisitos
- **Criterio secundario**: Mantener trabajadores ocupados (ori_min)
- **Escalabilidad**: Funciona con múltiples recetas e instancias

### Notificaciones de Audio
- Mensajes personalizados por tarea
- Incluye nombres de trabajadores específicos
- Contexto completo: receta, instancia, duración
- Sistema extensible para integrar TTS real

### Persistencia y Estado
- Manejo de estado reactivo con Provider/ChangeNotifier
- Integración completa con base de datos Hive existente
- Recuperación automática de datos al iniciar

### Manejo de Errores
- Validaciones de datos de entrada
- Mensajes informativos al usuario
- Manejo graceful de estados inconsistentes
- Prevención de errores de concurrencia

## Extensiones Futuras Sugeridas

1. **Audio Real**: Integración con TTS (Text-to-Speech)
2. **Notificaciones Push**: Alertas en dispositivos móviles
3. **Métricas**: Análisis de eficiencia y tiempos reales vs estimados
4. **Ajustes Dinámicos**: Modificación de tiempos durante ejecución
5. **Plantillas**: Guardado de configuraciones de recetas favoritas
6. **Integración IoT**: Conexión con dispositivos de cocina inteligentes

## Archivos Principales

```
lib/
├── back/system/
│   ├── agenda_models.dart          # Modelos de datos del sistema
│   ├── sistema_preprocesamiento.dart  # Lógica de optimización
│   └── sistema_ejecucion.dart      # Cronómetro y ejecución
├── widgets/
│   ├── seleccion_recetas_widget.dart   # Selección de recetas
│   ├── control_ejecucion_widget.dart   # Controles de ejecución
│   └── vista_agendas_widget.dart       # Visualización de agendas
├── realizar_tab.dart               # Pantalla principal
└── work_tab.dart                   # Integración con navegación
```

El sistema está completamente implementado y listo para usar, proporcionando una solución robusta para la automatización de tareas de cocina.
