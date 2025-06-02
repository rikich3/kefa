import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// App principal
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cocina',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat', // Fuente moderna
          ),
          elevation: 4, // Sombra para un look más moderno
        ),
        textTheme: TextTheme(
          displaySmall: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Montserrat'),
          headlineSmall: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Montserrat'),
          bodyLarge: TextStyle(fontSize: 17.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 15.0, color: Colors.black54),
          labelLarge: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat'),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordes más redondeados
            ),
            elevation: 3, // Sombra para los botones
            textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Semibold
                fontFamily: 'Montserrat'),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepOrange,
            textStyle: TextStyle(fontSize: 15, fontFamily: 'Montserrat'),
          ),
        ),
        dialogTheme: DialogTheme(
          titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
              fontFamily: 'Montserrat'),
          contentTextStyle: TextStyle(fontSize: 16, color: Colors.black87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Diálogos más redondeados
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle:
              TextStyle(color: Colors.deepOrange, fontFamily: 'Montserrat'),
          floatingLabelStyle: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados para inputs
            borderSide: BorderSide(color: Colors.orangeAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepOrange, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.orange.shade200, width: 1.0),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, // Snackbar flotante
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green.shade600,
          contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
      ),
      home: HomeWithBottomNav(),
    );
  }
}

// Home con BottomNavigationBar
class HomeWithBottomNav extends StatefulWidget {
  @override
  _HomeWithBottomNavState createState() => _HomeWithBottomNavState();
}

class _HomeWithBottomNavState extends State<HomeWithBottomNav> {
  int _selectedIndex = 0;
  String _nombreRestaurante = "Restaurante Puchy 🍽️";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _editarNombreRestaurante(BuildContext scaffoldContext) {
    String nuevoNombre = _nombreRestaurante;
    showDialog(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: Text("Editar nombre del restaurante"),
        content: TextField(
          decoration: InputDecoration(
            labelText: "Nuevo nombre",
            hintText: "Ej. La Cocina de María",
          ),
          onChanged: (valor) {
            nuevoNombre = valor;
          },
          autofocus: true,
          controller: TextEditingController(text: _nombreRestaurante), // Pre-llenar con el nombre actual
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton( // Usamos ElevatedButton para el botón de guardar
            child: const Text("Guardar"),
            onPressed: () {
              setState(() {
                _nombreRestaurante = nuevoNombre.isEmpty ? "Mi Restaurante" : nuevoNombre;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('Nombre actualizado a "${_nombreRestaurante}"')),
              );
            },
          ),
        ],
      ),
    );
  }

  final List<Widget> _pantallas = [];

  @override
  void initState() {
    super.initState();
    _pantallas.addAll([
      PantallaPrincipal(
        onEditNombre: _editarNombreRestaurante,
        nombreRestaurante: _nombreRestaurante,
      ),
      const PlaceholderWidget("Gestión"),
      const PlaceholderWidget("Perfil"),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Actualizamos la pantalla principal con el nuevo nombre
    _pantallas[0] = PantallaPrincipal(
      onEditNombre: _editarNombreRestaurante,
      nombreRestaurante: _nombreRestaurante,
    );

    return Scaffold(
      body: _pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8, // Sombra para la barra de navegación
        type: BottomNavigationBarType.fixed, // Mantiene el tamaño de los ítems
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Principal'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Gestión'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// Pantalla principal
class PantallaPrincipal extends StatelessWidget {
  final Function(BuildContext) onEditNombre;
  final String nombreRestaurante;

  PantallaPrincipal({
    required this.onEditNombre,
    required this.nombreRestaurante,
  });

  void mostrarOpciones(BuildContext context, String titulo) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Opciones para $titulo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                title: Text('Crear $titulo', style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormularioPage(titulo: 'Crear $titulo'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text('Editar $titulo', style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormularioPage(titulo: 'Editar $titulo'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Eliminar $titulo', style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(dialogContext);
                  confirmarEliminacion(context, titulo);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  void confirmarEliminacion(BuildContext scaffoldContext, String titulo) {
    showDialog(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Eliminar $titulo?'),
        content: Text('¿Está seguro de que desea eliminar $titulo de forma permanente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('$titulo eliminado correctamente.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), // Rojo más oscuro para eliminar
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                nombreRestaurante,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => onEditNombre(context),
              tooltip: "Editar nombre",
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido al Sistema de Gestión de Cocina',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 50),
              // Grupo de botones principales
              Wrap( // Usamos Wrap para que los botones se adapten al espacio
                spacing: 15.0, // Espacio horizontal entre botones
                runSpacing: 15.0, // Espacio vertical entre filas de botones
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => mostrarOpciones(context, 'Cocineros'),
                    icon: const Icon(Icons.people),
                    label: const Text('Cocineros'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => mostrarOpciones(context, 'Utensilios'),
                    icon: const Icon(Icons.kitchen),
                    label: const Text('Utensilios'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => mostrarOpciones(context, 'Cocinas'),
                    icon: const Icon(Icons.countertops),
                    label: const Text('Cocinas'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Botón de Recetas
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PantallaRecetas()),
                  );
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Recetas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent, // Un color diferente para destacar
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Página de formulario
class FormularioPage extends StatelessWidget {
  final String titulo;

  const FormularioPage({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SingleChildScrollView( // Permite desplazamiento si el contenido es largo
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete los detalles para $titulo:',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ingrese el nombre',
                prefixIcon: Icon(Icons.short_text), // Icono en el TextField
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Añada una breve descripción',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true, // Etiqueta alineada con el hint
              ),
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$titulo guardado exitosamente.')),
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Página de recetas
class PantallaRecetas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recetas de Cocina')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu,
                  size: 100, color: Colors.deepOrangeAccent.shade400),
              const SizedBox(height: 25),
              Text('Aquí podrá gestionar todas sus recetas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 15),
              Text(
                'Cree, edite y explore un mundo de sabores a su alcance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica para ir a crear una nueva receta
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abriendo formulario de nueva receta...')),
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FormularioPage(titulo: 'Nueva Receta')));
                },
                icon: const Icon(Icons.add),
                label: const Text('Añadir Nueva Receta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder para otras secciones
class PlaceholderWidget extends StatelessWidget {
  final String texto;

  const PlaceholderWidget(this.texto);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(texto)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Sección de $texto',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Esta sección está en desarrollo. ¡Vuelve pronto para más novedades!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}