import 'package:flutter/material.dart';

// Enum definido previamente
enum AssetAction {
  create,
  edit,
  delete,
  // Podrías añadir 'view' o 'manageList' si editar/eliminar implican ir a una lista primero
}

// Función para mostrar el modal de acciones de gestión de assets
Future<void> _showAssetManagementActionsModal(BuildContext context, String assetType) async {
  final AssetAction? selectedAction = await showModalBottomSheet<AssetAction>(
    context: context,
    // isScrollControlled: true, // No es necesario para este contenido corto
    builder: (BuildContext sheetContext) {
      // Construimos el contenido del Bottom Sheet
      return SafeArea( // Envuelve en SafeArea para evitar la barra de navegación inferior (en iOS)
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hace que el Column ocupe solo el espacio necesario
          children: <Widget>[
            // Título del Modal
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Text(
                'Gestionar $assetType', // Título dinámico
                style: Theme.of(sheetContext).textTheme.titleLarge, // Estilo de título M3
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1), // Separador visual

            // Opción Crear
            _buildActionItem( // Usamos una función auxiliar para cada ítem
              context: sheetContext,
              icon: Icons.add_circle_outline, // Icono para Crear
              text: 'Crear $assetType',
              action: AssetAction.create,
            ),
            const Divider(height: 1), // Separador visual

            // Opción Editar
             _buildActionItem(
              context: sheetContext,
              icon: Icons.edit_outlined, // Icono para Editar
              text: 'Editar $assetType',
              action: AssetAction.edit,
            ),
            const Divider(height: 1), // Separador visual

            // Opción Eliminar
             _buildActionItem(
              context: sheetContext,
              icon: Icons.delete_outline, // Icono para Eliminar
              text: 'Eliminar $assetType',
              action: AssetAction.delete,
            ),
            // No añadimos un Divider al final
          ],
        ),
      );
    },
  );

  // Este código se ejecuta DESPUÉS de que el modal se cierra
  // selectedAction será el valor que pasamos a Navigator.pop() dentro del modal
  if (selectedAction != null) {
    print('Acción seleccionada para $assetType: $selectedAction');
    // Aquí puedes implementar la lógica para cada acción
    switch (selectedAction) {
      case AssetAction.create:
        print('Lógica para Crear $assetType...');
        // Podrías llamar a _showAssetFormModal(context, assetType);
        break;
      case AssetAction.edit:
        print('Lógica para Editar $assetType...');
         // Esto probablemente implicaría navegar a una lista o seleccionar de una lista primero
        break;
      case AssetAction.delete:
        print('Lógica para Eliminar $assetType...');
         // Esto probablemente implicaría navegar a una lista o seleccionar de una lista primero
        break;
    }
  } else {
    // El modal se cerró sin seleccionar una acción (ej: tocando fuera)
    print('Modal de gestión de $assetType cerrado sin seleccionar acción.');
  }
}

// --- Widget auxiliar para cada ítem seleccionable ---
Widget _buildActionItem({
  required BuildContext context,
  required IconData icon,
  required String text,
  required AssetAction action,
}) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;

  return InkWell( // Usamos InkWell para que sea clicable y tenga feedback visual
    onTap: () {
      // Al tocar, cerramos el modal y pasamos la acción seleccionada
      Navigator.of(context).pop(action);
    },
    child: Padding( // Añadimos padding interno al InkWell
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface), // Icono con color del tema
          const SizedBox(width: 16), // Espacio entre icono y texto
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface, // Color de texto del tema
            ),
          ),
        ],
      ),
    ),
  );
}