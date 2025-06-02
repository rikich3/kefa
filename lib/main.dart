import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// Punto de entrada de la app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cocina',
      home: HomeWithBottomNav(),
    );
  }
}

// Widget principal que maneja el BottomNavigationBar
class HomeWithBottomNav extends StatefulWidget {
  @override
  _HomeWithBottomNavState createState() => _HomeWithBottomNavState();
}

class _HomeWithBottomNavState extends State<HomeWithBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _pantallas = [
    PantallaPrincipal(),
    PlaceholderWidget('Gestión'),
    PlaceholderWidget('Perfil'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Principal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Gestión'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// Pantalla principal con AppBar y 4 botones
class PantallaPrincipal extends StatelessWidget {
  void mostrarOpciones(BuildContext context, String titulo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Opciones para $titulo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text('Crear $titulo')),
              ListTile(title: Text('Editar $titulo')),
              ListTile(title: Text('Eliminar $titulo')),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurante Puchy 🍽️'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Cocineros'),
              child: Text('Cocineros'),
            ),
            ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Utensilios'),
              child: Text('Utensilios'),
            ),
            ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Cocinas'),
              child: Text('Cocinas'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
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

// Pantalla nueva para recetas
class PantallaRecetas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recetas'),
      ),
      body: Center(
        child: Text(
          'Aquí van las recetas 🍲',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// Pantallas vacías para "Gestión" y "Perfil"
class PlaceholderWidget extends StatelessWidget {
  final String texto;

  const PlaceholderWidget(this.texto);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(texto),
      ),
      body: Center(
        child: Text('Sección: $texto'),
      ),
    );
  }
}
