import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Importar Provider
import 'front/state/ingredientes_provider.dart'; // <-- Importar tu Provider
import 'back/dataModels/ingredientes.dart'; // <-- Importar el modelo Ingrediente (necesario para la lista)
import 'front/state/workers_provider.dart'; // <-- Importar tu Provider
import 'back/dataModels/worker.dart'; // <-- Importar el modelo Ingrediente (necesario para la lista)
import 'front/state/instrumentos_provider.dart'; // <-- Importar tu Provider
import 'back/dataModels/instrumentos.dart'; // <-- Importar el modelo Ingrediente (necesario para la lista)

// Importar las pantallas de destino
import 'crear_ingrediente_page.dart';
import 'front/ui/crear_worker_page.dart';
import 'front/ui/crear_instrumento_page.dart';
import 'trabajadores_page.dart';
// import 'editar_ingrediente_page.dart'; // Necesitarás una pantalla/modal de edición

class ManageTab extends StatefulWidget {
  const ManageTab({super.key});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  // Estado para el Dropdown
  String _selectedKitchen = 'Principal';
  final List<String> _kitchens = ['Principal', 'Cocina 2', 'Cocina 3', 'Cocina 4'];

  // Función para manejar taps en las secciones de Assets/Recetas
  void _onSectionTapped(String sectionName) {
    switch (sectionName) {
      case 'Ingredientes':
      _showIngredientesMenu(context);
      break;
      case 'Workers':
      _showWorkersMenu(context);
      break;
      case 'Utensilios':
      _showInstrumentosMenu(context);
      break;
      case 'Recetas':
      break;
      default:
      // Puedes manejar otros casos aquí si es necesario
      break;
    }
  }

  // Método para mostrar el modal de ingredientes
  void _showIngredientesMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Para permitir que el modal ocupe más espacio y la lista sea scrollable
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        // Usamos el BuildContext proporcionado por showModalBottomSheet builder (ctx)
        // para acceder al Provider que está por encima en el árbol.
        // Podemos usar Consumer o Provider.of
        // Provider.of(ctx) con listen: false si solo llamas métodos
        // Provider.of(ctx) con listen: true o Consumer si lees el estado (como la lista)

        final TextTheme textTheme = Theme.of(ctx).textTheme; // Usar el tema del contexto del modal
        final ColorScheme colorScheme = Theme.of(ctx).colorScheme; // Usar el tema del contexto del modal


        return Container( // Usamos Container para controlar la altura del modal
          // Ocupa una porción de la altura de la pantalla para que la lista sea scrollable
          height: MediaQuery.of(ctx).size.height * 0.7, // Ejemplo: 70% de la altura
          padding: const EdgeInsets.all(24.0), // Padding dentro del modal
          child: Column(
            mainAxisSize: MainAxisSize.min, // El Column debe ajustarse al contenido (pero Expanded forzará tamaño)
            crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los hijos horizontalmente
            children: [
              Text('Administrar Ingredientes', style: textTheme.titleLarge), // Título del modal
              const SizedBox(height: 20),

              // Botón "Crear Nuevo"
              FilledButton.icon( // Usamos FilledButton.icon para un look M3
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Ingrediente'),
                onPressed: () {
                  // Cierra el modal usando el contexto del modal (ctx)
                  Navigator.pop(ctx);
                  // Navega a la pantalla de creación usando el contexto del modal (ctx)
                  // O podrías usar el contexto original del widget si necesitas
                  // mantener el estado de la pestaña, pero ctx es más seguro aquí.
                  Navigator.push(
                    ctx, // Usa el contexto del modal para la navegación
                    MaterialPageRoute(builder: (context) => const CrearIngredientePage()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Título para la lista
              Text('Lista de Ingredientes', style: textTheme.titleMedium),
              const SizedBox(height: 8),

              // --- Sección de la lista que usará el Provider y se reconstruirá ---
              // Usamos Expanded para que el ListView ocupe el espacio restante en la Column
              // Usamos Consumer para escuchar solo los cambios en el IngredientProvider
              Expanded(
                child: Consumer<IngredientesProvider>(
                  builder: (context, ingredientProvider, child) {
                    // El 'context' aquí es el contexto del Consumer
                    // ingredientProvider es la instancia del IngredientProvider
                    // child es el widget opcional 'child' del Consumer (no lo usamos aquí)

                    // Mostrar indicador de carga si está cargando
                    if (ingredientProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Mostrar mensaje de error si hay uno
                    if (ingredientProvider.errorMessage != null) {
                      return Center(
                        child: Text(
                          ingredientProvider.errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Obtener la lista de entradas (key + Ingredient)
                    final List<MapEntry<dynamic, Ingredientes>> ingredientEntries = ingredientProvider.ingredientesEntries;

                    // Mostrar mensaje si la lista está vacía
                    if (ingredientEntries.isEmpty) {
                      return const Center(child: Text('No hay ingredientes guardados aún.'));
                    }

                    // Construir la lista de ingredientes
                    return ListView.builder(
                      itemCount: ingredientEntries.length,
                      itemBuilder: (context, index) {
                        // Obtener la key y el Ingrediente de la entrada actual
                        final MapEntry<dynamic, Ingredientes> entry = ingredientEntries[index];
                        final dynamic ingredientKey = entry.key; // La key de Hive
                        final Ingredientes ingredient = entry.value; // El objeto Ingrediente

                        // Construir el item de la lista ( ListTile es común)
                        return ListTile(
                          title: Text(ingredient.name),
                          subtitle: Text('${ingredient.cantidad} ${ingredient.unidadMedida} - \$${ingredient.precio.toStringAsFixed(2)}'), // Ejemplo de subtítulo
                          trailing: Row( // Fila para los botones de editar y eliminar
                            mainAxisSize: MainAxisSize.min, // Para que la fila solo ocupe el espacio de sus hijos
                            children: [
                              // Botón de Editar
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed: () {
                                  print('Editar ingrediente con key: $ingredientKey');
                                  // TODO: Implementar lógica para editar
                                  // Probablemente mostrar otro modal o navegar a una página de edición
                                  // Pasar `ingredientKey` y/o `ingredient` a la pantalla de edición.
                                  // Si abres otro modal, NO cierres este modal de lista.
                                  // Si navegas a otra página, cierra este modal primero: Navigator.pop(ctx);
                                },
                              ),
                              // Botón de Eliminar
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  print('Eliminar ingrediente con key: $ingredientKey');
                                  // TODO: Implementar lógica para eliminar
                                  // Mostrar un diálogo de confirmación es buena práctica antes de eliminar
                                  // Luego, llamar al método del Provider para eliminar:
                                   ingredientProvider.deleteIngredient(ingredientKey);
                                  // No necesitas llamar notifyListeners() aquí, el método deleteIngredient del Provider lo hará.
                                  // La lista en la UI se actualizará automáticamente cuando el Provider notifique.
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // --- Fin Sección de la lista ---

              // Puedes añadir más SizedBox al final si necesitas espacio extra
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Método dummy para navegar a la página de trabajadores (ya estaba en tu código)
  // Lo dejé comentado en _onSectionTapped porque ahora el onTap del Expanded lo llama directo
  void _navigateToTrabajadoresPage(BuildContext context) {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const TrabajadoresPage(esSuperusuario: true)),
     );
   }

    void _showWorkersMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        final colorScheme = Theme.of(ctx).colorScheme;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Administrar Trabajadores', style: textTheme.titleLarge),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Trabajador'),
                onPressed: () {
                  // Cierra el modal usando el contexto del modal (ctx)
                  Navigator.pop(ctx);
                  // Navega a la pantalla de creación usando el contexto del modal (ctx)
                  // O podrías usar el contexto original del widget si necesitas
                  // mantener el estado de la pestaña, pero ctx es más seguro aquí.
                  Navigator.push(
                    ctx, // Usa el contexto del modal para la navegación
                    MaterialPageRoute(builder: (context) => const CrearWorkerPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text('Lista de Trabajadores', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<WorkersProvider>(
                  builder: (context, workersProvider, child) {
                    if (workersProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (workersProvider.errorMessage != null) {
                      return Center(
                        child: Text(
                          workersProvider.errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final workerEntries = workersProvider.workerEntries;
                    if (workerEntries.isEmpty) {
                      return const Center(child: Text('No hay trabajadores guardados aún.'));
                    }
                    return ListView.builder(
                      itemCount: workerEntries.length,
                      itemBuilder: (context, index) {
                        final entry = workerEntries[index];
                        final key = entry.key;
                        final worker = entry.value;
                        return ListTile(
                          title: Text(worker.nombre),
                          subtitle: Text(worker.funcion),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed: () {
                                  // TODO: Implementar edición
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  workersProvider.deleteWorker(key);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Método para mostrar el modal de instrumentos
  void _showInstrumentosMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        final colorScheme = Theme.of(ctx).colorScheme;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Administrar Instrumentos', style: textTheme.titleLarge),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Instrumento'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(ctx, '/crearInstrumento');
                },
              ),
              const SizedBox(height: 20),
              Text('Lista de Instrumentos', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<InstrumentosProvider>(
                  builder: (context, instrumentosProvider, child) {
                    if (instrumentosProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (instrumentosProvider.errorMessage != null) {
                      return Center(
                        child: Text(
                          instrumentosProvider.errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final instrumentosEntries = instrumentosProvider.instrumentosEntries;
                    if (instrumentosEntries.isEmpty) {
                      return const Center(child: Text('No hay instrumentos guardados aún.'));
                    }
                    return ListView.builder(
                      itemCount: instrumentosEntries.length,
                      itemBuilder: (context, index) {
                        final entry = instrumentosEntries[index];
                        final key = entry.key;
                        final instrumento = entry.value;
                        return ListTile(
                          title: Text(instrumento.nombre),
                          subtitle: Text('Cantidad: ${instrumento.cantidad}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed: () {
                                  // TODO: Implementar edición
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  instrumentosProvider.deleteInstrumento(key);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          // --- Sección Elegir Cocina ---
          Text(
            'Elegir Cocina:',
            style: textTheme.titleMedium,
          ),
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
                      print('Cocina seleccionada: $_selectedKitchen');
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
                onPressed: () {
                  print('Botón Editar Cocina presionado');
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Cocina Actual',
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- Sección Administrar Assets ---
          Text(
            'Administrar Assets',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sección Ingredientes
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.restaurant_menu,
                  text: 'Ingredientes',
                  onTap: () => _onSectionTapped('Ingredientes'), // Llama al método que muestra el modal
                ),
              ),
              const SizedBox(width: 12),
              // Sección Trabajadores - La navegación está aquí directamente en el onTap
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.person,
                  text: 'Trabajadores',
                  onTap: () => _onSectionTapped('Workers')
                ),
              ),
              const SizedBox(width: 12),
              // Sección Utensilios
              Expanded(
                child: _buildAssetSection(
                  icon: Icons.kitchen,
                  text: 'Utensilios',
                   onTap: () => _onSectionTapped('Utensilios'), // Llama al método general
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- Sección Administrar Recetas ---
           Text(
            'Administrar Recetas',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                 child: _buildAssetSection(
                  icon: Icons.menu_book,
                  text: 'Recetas',
                  onTap: () => _onSectionTapped('Recetas'), // Llama al método general
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          // Ya no mostramos la lista de ingredientes aquí, se muestra en el modal
        ],
      ),
    );
  }

  // Widget auxiliar para construir las secciones seleccionables (sin cambios)
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
          color: colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: colorScheme.primary,
            ),
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