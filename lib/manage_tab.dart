import 'package:flutter/material.dart';

class ManageTab extends StatefulWidget {
  const ManageTab({super.key});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  // Estado para el Dropdown
  String _selectedKitchen = 'Principal';
  final List<String> _kitchens = ['Principal', 'Cocina 2', 'Cocina 3', 'Cocina 4'];

  // Función dummy para el tap en Assets/Recetas (por ahora solo imprime)
  void _onSectionTapped(String sectionName) {
    print('Sección "$sectionName" seleccionada');
    // Aquí iría la lógica para navegar o abrir un modal
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding general para el contenido de la pestaña
      child: ListView( // Usamos ListView para que el contenido pueda scroll si es necesario
        children: <Widget>[
          // --- Sección Elegir Cocina ---
          Text(
            'Elegir Cocina:',
            style: textTheme.titleMedium, // Estilo para un título de sección pequeño
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacio entre elementos
            children: [
              // Dropdown para elegir cocina
              Expanded( // Permite que el Dropdown ocupe el espacio disponible
                child: DropdownButtonFormField<String>(
                  value: _selectedKitchen,
                  items: _kitchens.map((String kitchen) {
                    return DropdownMenuItem<String>(
                      value: kitchen,
                      child: Text(kitchen),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedKitchen = newValue;
                      });
                      print('Cocina seleccionada: $_selectedKitchen');
                      // Aquí podrías cargar los datos de la nueva cocina
                    }
                  },
                  decoration: InputDecoration(
                    // Estilo M3 para el Dropdown
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Bordes redondeados M3
                    ),
                    // filled: true, // Opcional: si quieres un fondo relleno
                    // fillColor: colorScheme.surfaceVariant.withOpacity(0.2), // Opcional: color de fondo
                  ),
                ),
              ),
              const SizedBox(width: 12), // Espacio entre dropdown y botón
              // Botón de icono para editar cocina (sin funcionalidad por ahora)
              IconButton.filled( // Opcional: IconButton.filled para un look M3 con fondo
                onPressed: () {
                  print('Botón Editar Cocina presionado');
                  // Funcionalidad de edición de cocina aquí
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Cocina Actual',
              ),
            ],
          ),
          const SizedBox(height: 30), // Espacio grande entre secciones

          // --- Sección Administrar Assets ---
          Text(
            'Administrar Assets',
            style: textTheme.titleLarge, // Estilo para un título de sección principal (serif)
          ),
          const SizedBox(height: 16),
          Row( // Fila para las 3 secciones seleccionables
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Espacio equitativo
            children: [
              // Sección Ingredientes
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.restaurant_menu, // Icono para ingredientes
                  text: 'Ingredientes',
                  onTap: () => _onSectionTapped('Ingredientes'),
                ),
              ),
              const SizedBox(width: 12), // Espacio entre secciones
              // Sección Trabajadores
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.person, // Icono para trabajadores
                  text: 'Trabajadores',
                  onTap: () => _onSectionTapped('Trabajadores'),
                ),
              ),
              const SizedBox(width: 12), // Espacio entre secciones
              // Sección Utensilios
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.kitchen, // Icono para utensilios (o Icons.cutlery)
                  text: 'Utensilios',
                  onTap: () => _onSectionTapped('Utensilios'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30), // Espacio grande entre secciones

          // --- Sección Administrar Recetas ---
           Text(
            'Administrar Recetas',
            style: textTheme.titleLarge, // Estilo para un título de sección principal (serif)
          ),
          const SizedBox(height: 16),
          Row( // Fila para la sección seleccionable (solo una)
            children: [
              Expanded(
                 child: _buildAssetSection( // Reutilizamos la misma estructura de widget
                  icon: Icons.menu_book, // Icono para recetas/libro
                  text: 'Recetas',
                  onTap: () => _onSectionTapped('Recetas'),
                ),
              ),
              // No hay más elementos en esta fila, el Expanded ocupará el espacio restante
            ],
          ),
          // Puedes añadir más SizedBox al final si necesitas espacio extra para el scroll
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Widget auxiliar para construir las secciones seleccionables de Assets/Recetas
  Widget _buildAssetSection({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell( // Hace que la sección sea clicable y muestre feedback visual (splash)
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0), // Bordes redondeados para el feedback visual
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0), // Padding interno
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.2), // Un color de fondo suave de M3
          borderRadius: BorderRadius.circular(12.0), // Bordes redondeados del contenedor
          // Opcional: añadir un borde sutil
          // border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajustar al contenido
          children: [
            Icon(
              icon,
              size: 40,
              color: colorScheme.primary, // Color primario de M3 para los iconos
            ),
            const SizedBox(height: 8), // Espacio entre icono y texto
            Text(
              text,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant), // Estilo de texto pequeño (sans-serif)
              maxLines: 2, // Permitir 2 líneas si el texto es largo
              overflow: TextOverflow.ellipsis, // Añadir puntos suspensivos si el texto es demasiado largo
            ),
          ],
        ),
      ),
    );
  }
}