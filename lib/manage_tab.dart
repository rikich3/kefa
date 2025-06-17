import 'package:flutter/material.dart';
import 'features/ingredientes/ingredientes_menu.dart';
import 'features/trabajadores/trabajadores_menu.dart';
import 'features/utensilios/utensilios_menu.dart';
import 'features/recetas/administrar_recetas_menu.dart';

class ManageTab extends StatefulWidget {
  const ManageTab({super.key});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  String _selectedKitchen = 'Principal';
  final List<String> _kitchens = ['Principal', 'Cocina 2', 'Cocina 3', 'Cocina 4'];

  void _onSectionTapped(String sectionName) {
    if (sectionName == 'Ingredientes') {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (ctx) => const IngredientesMenu(),
      );
    } else if (sectionName == 'Trabajadores') {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (ctx) => const TrabajadoresMenu(),
      );
    } else if (sectionName == 'Utensilios') {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (ctx) => const UtensiliosMenu(),
      );
    } else if (sectionName == 'Recetas') {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (ctx) => const AdministrarRecetasMenu(),
      );
    } else {
      print('Sección "$sectionName" seleccionada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          Text('Elegir Cocina:', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Cocina Actual',
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Administrar Assets', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.restaurant_menu,
                  text: 'Ingredientes',
                  onTap: () => _onSectionTapped('Ingredientes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.person,
                  text: 'Trabajadores',
                  onTap: () => _onSectionTapped('Trabajadores'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.kitchen,
                  text: 'Utensilios',
                  onTap: () => _onSectionTapped('Utensilios'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Administrar Recetas', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.menu_book,
                  text: 'Recetas',
                  onTap: () => _onSectionTapped('Recetas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildAssetSection({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}