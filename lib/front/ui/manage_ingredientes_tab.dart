// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Importar Provider
// import '../state/ingredient_provider.dart'; // Importar tu IngredientProvider
// import '../models/ingredient.dart'; // Importar el modelo si lo necesitas

// class ManageTab extends StatefulWidget {
//   const ManageTab({super.key});

//   @override
//   State<ManageTab> createState() => _ManageTabState();
// }

// class _ManageTabState extends State<ManageTab> {
//   // ... (Parte del selector de cocina igual) ...
//    String _selectedKitchen = 'Principal';
//    final List<String> _kitchens = ['Principal', 'Cocina 2', 'Cocina 3', 'Cocina 4'];
//   // ...

//   // Dummy tap function - Ahora podríamos usar esto para ir a la pantalla de lista de ingredientes
//   void _onSectionTapped(String sectionName) {
//     print('Sección "$sectionName" seleccionada');
//     if (sectionName == 'Ingredientes') {
//       // Navegar a una pantalla para ver/administrar ingredientes específicos
//       // Usar Navigator.push con una nueva pantalla, o showModalBottomSheet
//       // Ejemplo tonto: Añadir un ingrediente de prueba al tocar la sección (Solo para probar el Provider/Hive)
//       final provider = Provider.of<IngredientProvider>(context, listen: false);
//       provider.addIngredient(
//          Ingredient(
//             name: 'Ingrediente de Prueba ${DateTime.now().millisecondsSinceEpoch % 1000}',
//             description: 'Generado automáticamente',
//             unitOfMeasure: 'unidad',
//             quantity: 1,
//             price: 0.0,
//          ),
//       );
//     }
//     // ... lógica para Workers, Tools, Recipes ...
//   }

//   @override
//   Widget build(BuildContext context) {
//     final TextTheme textTheme = Theme.of(context).textTheme;
//     final ColorScheme colorScheme = Theme.of(context).colorScheme;

//     // Escuchar los cambios en el IngredientProvider
//     final ingredientProvider = Provider.of<IngredientProvider>(context);

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: ListView(
//         children: <Widget>[
//           // --- Sección Elegir Cocina ---
//           // ... (tu código de selector de cocina) ...
//            Text(
//             'Elegir Cocina:',
//             style: textTheme.titleMedium,
//            ),
//            const SizedBox(height: 8),
//            Row(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
//              children: [
//                Expanded(
//                  child: DropdownButtonFormField<String>(
//                    value: _selectedKitchen,
//                    items: _kitchens.map((String kitchen) {
//                      return DropdownMenuItem<String>(
//                        value: kitchen,
//                        child: Text(kitchen),
//                      );
//                    }).toList(),
//                    onChanged: (String? newValue) {
//                      if (newValue != null) {
//                        setState(() {
//                          _selectedKitchen = newValue;
//                        });
//                        print('Cocina seleccionada: $_selectedKitchen');
//                      }
//                    },
//                    decoration: InputDecoration(
//                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//                      border: OutlineInputBorder(
//                        borderRadius: BorderRadius.circular(12.0),
//                      ),
//                    ),
//                  ),
//                ),
//                const SizedBox(width: 12),
//                IconButton.filled(
//                  onPressed: () {
//                    print('Botón Editar Cocina presionado');
//                  },
//                  icon: const Icon(Icons.edit),
//                  tooltip: 'Editar Cocina Actual',
//                ),
//              ],
//            ),
//            const SizedBox(height: 30),

//           // --- Sección Administrar Assets ---
//            Text(
//             'Administrar Assets',
//             style: textTheme.titleLarge,
//            ),
//            const SizedBox(height: 16),
//            Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//              children: [
//               Expanded(child: _buildAssetSection(icon: Icons.restaurant_menu, text: 'Ingredientes', onTap: () => _onSectionTapped('Ingredientes'))),
//               const SizedBox(width: 12),
//               Expanded(child: _buildAssetSection(icon: Icons.person, text: 'Trabajadores', onTap: () => _onSectionTapped('Trabajadores'))),
//               const SizedBox(width: 12),
//               Expanded(child: _buildAssetSection(icon: Icons.kitchen, text: 'Utensilios', onTap: () => _onSectionTapped('Utensilios'))),
//              ],
//           ),
//            const SizedBox(height: 30),

//           // --- Sección Administrar Recetas ---
//            Text(
//             'Administrar Recetas',
//             style: textTheme.titleLarge,
//            ),
//            const SizedBox(height: 16),
//            Row(
//              children: [
//                Expanded(
//                   child: _buildAssetSection(
//                    icon: Icons.menu_book,
//                    text: 'Recetas',
//                    onTap: () => _onSectionTapped('Recetas'),
//                  ),
//                ),
//              ],
//            ),
//            const SizedBox(height: 50),

//           // --- Mostrar lista de ingredientes (para probar que funciona Hive/Provider) ---
//           // Aquí puedes añadir widgets para mostrar los datos cargados desde Hive
//           if (ingredientProvider.isLoading)
//             const Center(child: CircularProgressIndicator()),
//           if (ingredientProvider.errorMessage != null)
//             Text(
//               ingredientProvider.errorMessage!,
//               style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
//               textAlign: TextAlign.center,
//             ),
//           if (!ingredientProvider.isLoading && ingredientProvider.ingredients.isNotEmpty)
//             Column( // Mostrar una lista simple de ingredientes cargados
//                crossAxisAlignment: CrossAxisAlignment.start,
//                children: [
//                  Text('Ingredientes Cargados (${ingredientProvider.ingredients.length}):', style: textTheme.titleMedium),
//                  const SizedBox(height: 8),
//                  ...ingredientProvider.ingredients.map((ing) => Text('- ${ing.name}')).toList(),
//                ],
//             ),
//           if (!ingredientProvider.isLoading && ingredientProvider.ingredients.isEmpty && ingredientProvider.errorMessage == null)
//              Text('No hay ingredientes guardados aún.', style: textTheme.bodyMedium),


//         ],
//       ),
//     );
//   }

//   // ... (Tu método _buildAssetSection igual) ...
//    Widget _buildAssetSection({
//      required IconData icon,
//      required String text,
//      required VoidCallback onTap,
//    }) {
//      final ColorScheme colorScheme = Theme.of(context).colorScheme;
//      final TextTheme textTheme = Theme.of(context).textTheme;

//      return InkWell(
//        onTap: onTap,
//        borderRadius: BorderRadius.circular(12.0),
//        child: Container(
//          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
//          decoration: BoxDecoration(
//            color: colorScheme.surfaceVariant.withOpacity(0.2),
//            borderRadius: BorderRadius.circular(12.0),
//          ),
//          child: Column(
//            mainAxisSize: MainAxisSize.min,
//            children: [
//              Icon(
//                icon,
//                size: 40,
//                color: colorScheme.primary,
//              ),
//              const SizedBox(height: 8),
//              Text(
//                text,
//                textAlign: TextAlign.center,
//                style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
//                maxLines: 2,
//                overflow: TextOverflow.ellipsis,
//              ),
//            ],
//          ),
//        ),
//      );
//    }
//   // ...
// }