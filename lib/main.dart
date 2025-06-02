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

  // PASAMOS EL CONTEXTO DEL SCAFFOLD EXPLÍCITAMENTE PARA EVITAR ERRORES
  void _editarNombreRestaurante(BuildContext scaffoldContext) {
    String nuevoNombre = _nombreRestaurante;
    showDialog(
      context: scaffoldContext,
      builder: (dialogContext) => AlertDialog(
        title: Text("Editar nombre del restaurante"),
        content: TextField(
          decoration: InputDecoration(labelText: "Nuevo nombre"),
          onChanged: (valor) {
            nuevoNombre = valor;
          },
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: Text("Guardar"),
            onPressed: () {
              setState(() {
                _nombreRestaurante = nuevoNombre;
              });
              Navigator.pop(dialogContext);
              // Aquí usamos el contexto original del Scaffold para mostrar snackbar
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('Nombre actualizado')),
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
      PlaceholderWidget("Gestión"),
      PlaceholderWidget("Perfil"),
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
                title: Text('Crear $titulo'),
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
                title: Text('Editar $titulo'),
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
                title: Text('Eliminar $titulo'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  confirmarEliminacion(context, titulo);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cerrar'),
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
        content: Text('¿Estás seguro de que deseas eliminar $titulo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Usamos el contexto original del Scaffold para mostrar SnackBar
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('$titulo eliminado correctamente.')),
              );
            },
            child: Text('Confirmar'),
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
            Expanded(child: Text(nombreRestaurante)),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => onEditNombre(context),
              tooltip: "Editar nombre",
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fila centrada horizontalmente con los 3 botones
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => mostrarOpciones(context, 'Cocineros'),
                  child: Text('Cocineros'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => mostrarOpciones(context, 'Utensilios'),
                  child: Text('Utensilios'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => mostrarOpciones(context, 'Cocinas'),
                  child: Text('Cocinas'),
                ),
              ],
            ),
            SizedBox(height: 40),
            // Botón de recetas centrado
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PantallaRecetas()),
                );
              },
              child: Text('Recetas'),
            ),
          ],
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Formulario para $titulo'),
            TextField(decoration: InputDecoration(labelText: 'Nombre')),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Descripción')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$titulo guardado')),
                );
              },
              child: Text('Guardar'),
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
      appBar: AppBar(title: Text('Recetas')),
      body: Center(
        child: Text('Aquí van las recetas 🍲', style: TextStyle(fontSize: 20)),
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
      body: Center(child: Text('Sección: $texto')),
    );
  }
}
