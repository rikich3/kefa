import 'package:flutter/material.dart';
import 'manage_tab.dart'; // Importar la pestaña de administración
import 'work_tab.dart'; // Importar placeholder
import 'social_tab.dart'; // Importar placeholder

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Índice seleccionado por defecto

  // Lista de widgets para cada pestaña del BottomNavBar
  static const List<Widget> _widgetOptions = <Widget>[
    ManageTab(), // Contenido de la pestaña Administrar
    WorkTabPlaceholder(), // Contenido de la pestaña Realizar (Placeholder)
    SocialTabPlaceholder(), // Contenido de la pestaña Social (Placeholder)
  ];

  // Función que se llama cuando se toca un ítem del BottomNavBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualizar el índice seleccionado
    });
  }

  @override
  Widget build(BuildContext context) {
    // Acceder al ColorScheme y TextTheme definidos en ThemeData
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // Título de la AppBar, usando un estilo de texto del tema (serif)
        title: Text(
          'Bienvenido Usuario',
          style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary), // Usar color contrastante sobre primary
        ),
        backgroundColor: colorScheme.primary, // Color de fondo de la AppBar (del tema)
        foregroundColor: colorScheme.onPrimary, // Color de los iconos y texto en la AppBar (del tema)
      ),
      // El cuerpo usa IndexedStack para mostrar el widget correspondiente al índice seleccionado
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // El BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), // Icono de portapapeles/lista
            label: 'Administrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time), // Icono de reloj
            label: 'Realizar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups), // Icono de grupo/social
            label: 'Social',
          ),
        ],
        currentIndex: _selectedIndex, // Índice seleccionado actualmente
        selectedItemColor: colorScheme.primary, // Color del ítem seleccionado (M3 lo usa así por defecto)
        unselectedItemColor: colorScheme.onSurfaceVariant, // Color de los ítems no seleccionados
        onTap: _onItemTapped, // Función que se llama al tocar un ítem
        // Puedes personalizar el estilo del BottomNavBar aún más si lo deseas,
        // pero con M3 habilitado y ColorScheme definido, ya tiene un buen look por defecto.
      ),
    );
  }
}