import 'package:flutter/material.dart';

class PlatoEstacion {
  final String nombre;
  final String estado; // 'En proceso', 'Por iniciar', 'Terminado'
  final String cocinero;

  PlatoEstacion({required this.nombre, required this.estado, required this.cocinero});
}

class Estacion {
  final String nombre;
  final List<PlatoEstacion> platos;

  Estacion({required this.nombre, required this.platos});
}

class PanelEstacionesPage extends StatelessWidget {
  PanelEstacionesPage({Key? key}) : super(key: key);

  final List<Estacion> estaciones = [
    Estacion(
      nombre: 'Parrilla',
      platos: [
        PlatoEstacion(nombre: 'Bife', estado: 'En proceso', cocinero: 'Juan'),
        PlatoEstacion(nombre: 'Pollo BBQ', estado: 'Por iniciar', cocinero: 'Ana'),
      ],
    ),
    Estacion(
      nombre: 'Fríos',
      platos: [
        PlatoEstacion(nombre: 'Ensalada César', estado: 'Terminado', cocinero: 'Luis'),
        PlatoEstacion(nombre: 'Ceviche', estado: 'En proceso', cocinero: 'María'),
      ],
    ),
    Estacion(
      nombre: 'Pastas',
      platos: [
        PlatoEstacion(nombre: 'Spaghetti', estado: 'Por iniciar', cocinero: 'Pedro'),
      ],
    ),
  ];

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'En proceso':
        return Colors.orange;
      case 'Por iniciar':
        return Colors.grey;
      case 'Terminado':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Control por Estaciones')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: estaciones.map((estacion) {
            return Container(
              width: 250,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(estacion.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...estacion.platos.map((plato) => Card(
                        color: _estadoColor(plato.estado).withOpacity(0.2),
                        child: ListTile(
                          title: Text(plato.nombre),
                          subtitle: Text('Cocinero: ${plato.cocinero}'),
                          trailing: Text(
                            plato.estado,
                            style: TextStyle(
                              color: _estadoColor(plato.estado),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
