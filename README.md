# Proyecto: Sistema de Gestión de Cocina Virtual

## Descripción
Aplicación Flutter para la gestión integral de una cocina profesional. Permite administrar ingredientes, trabajadores, utensilios, recetas y tareas, con una estructura modular y escalable, lista para integración con backend.

---

## Instalación y ejecución

1. **Clona el repositorio:**
   ```sh
   git clone <URL_DEL_REPOSITORIO>
   cd <NOMBRE_DEL_PROYECTO>
   ```
2. **Instala las dependencias:**
   ```sh
   flutter pub get
   ```
3. **Ejecuta la app:**
   ```sh
   flutter run
   ```

---

## Estructura del Proyecto

```
lib/
  features/
    ingredientes/
      ingredientes_menu.dart
      ingrediente_model.dart
      crear_ingrediente_page.dart
    trabajadores/
      trabajadores_menu.dart
      trabajador_model.dart
      trabajadores_page.dart
    utensilios/
      utensilios_menu.dart
      utensilio_model.dart
    recetas/
      administrar_recetas_menu.dart
      administrar_recetas_page.dart
      receta_model.dart
      receta_detalle_page.dart
    usuario/
      usuario_model.dart
      perfil_page.dart
      login_page.dart
  shared/
    widgets/
    utils/
  main.dart
  home_page.dart
  manage_tab.dart
  social_tab.dart
  work_tab.dart
  virtualKitchen.dart
```

---

## Funcionalidades implementadas

- **Gestión de ingredientes:**  Agregar, editar, eliminar y listar ingredientes desde un menú modal.
- **Gestión de trabajadores:**  Ver trabajadores, asignar tareas con cronómetro, editar y eliminar.
- **Gestión de utensilios:**  Agregar, editar, eliminar, asignar estados y usuarios a utensilios.
- **Gestión de recetas:**  Crear, editar, eliminar, compartir y preparar recetas desde un menú modal.
- **Estructura modular:**  Cada feature tiene su propia carpeta y archivos, facilitando el mantenimiento y la escalabilidad.
- **Navegación clara:**  Menús modales para cada feature, tabs principales para navegación global.

---

## Pendiente / Próximos pasos

- Integración real con backend (API REST o Firebase).
- Implementar historial de acciones del usuario.
- Completar panel visual de cocina virtual y estaciones.
- Implementar gestión de usuario (login, perfil, autenticación).
- Mejorar documentación y agregar ejemplos de uso.

---

## Buenas prácticas seguidas

- Commits frecuentes y descriptivos.
- Estructura de carpetas por dominio/feature.
- Código modular y reutilizable.
- Uso de datos simulados para desarrollo independiente del backend.
- Menús y diálogos visualmente consistentes.

---

## Instrucciones de uso

- Navega por los tabs principales para acceder a cada sección.
- Usa los menús modales para gestionar ingredientes, trabajadores, utensilios y recetas.
- Asigna tareas a trabajadores y visualiza el estado de cada recurso.
- (Próximamente) Accede al historial de acciones y gestiona tu perfil de usuario.

---

## Recomendaciones para el equipo

- Mantener la estructura modular y los imports limpios.
- Documentar cambios importantes en este archivo o en un `CHANGELOG.md`.
- Usar ramas y pull requests para integrar cambios.
- Comunicar decisiones de arquitectura y estructura en el equipo.

---

## Créditos

Desarrollado por el equipo de cocina virtual Kefa, 2025.
