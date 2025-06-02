import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// Punto de entrada de la app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cocina',
      theme: ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.deepPurple,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
        fontFamily: 'Serif',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
        fontFamily: 'Serif',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
        ),
        headlineMedium: TextStyle(
        fontFamily: 'Serif',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
        ),
        bodyLarge: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 18,
        color: Colors.black87,
        ),
        bodyMedium: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 14,
        color: Colors.black87,
        ),
        labelLarge: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 16,
        color: Colors.deepPurple,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: 'SansSerif',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        ),
      ),
      ),
      darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
        fontFamily: 'Serif',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
        fontFamily: 'Serif',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple[200],
        ),
        headlineMedium: TextStyle(
        fontFamily: 'Serif',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple[200],
        ),
        bodyLarge: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 18,
        color: Colors.white,
        ),
        bodyMedium: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 14,
        color: Colors.white70,
        ),
        labelLarge: TextStyle(
        fontFamily: 'SansSerif',
        fontSize: 16,
        color: Colors.deepPurple[200],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontFamily: 'SansSerif',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        ),
      ),
      ),
      themeMode: ThemeMode.system,
      home: HomeWithBottomNav(),
    );
  }
}

// Widget principal que maneja el BottomNavigationBar
class HomeWithBottomNav extends StatefulWidget {
  const HomeWithBottomNav({super.key});

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
  const PantallaPrincipal({super.key});

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
        child: Center(
          child: SizedBox(
            width: 250,
            child: ListView(
              shrinkWrap: true,
              children: [
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Cocineros'),
              child: Text('Cocineros'),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Utensilios'),
              child: Text('Utensilios'),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              onPressed: () => mostrarOpciones(context, 'Cocinas'),
              child: Text('Cocinas'),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PantallaRecetas()),
                );
              },
              child: Text('Recetas'),
            ),
          ),
              ],
            ),
          ),
        )
        ),
    );
  }
}

// Pantalla nueva para recetas
class PantallaRecetas extends StatelessWidget {
  const PantallaRecetas({super.key});

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

  const PlaceholderWidget(this.texto, {super.key});

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
