import 'package:flutter/material.dart';
import 'administrar_recetas_page.dart';

class AdministrarRecetasMenu extends StatefulWidget {
  const AdministrarRecetasMenu({super.key});

  @override
  State<AdministrarRecetasMenu> createState() => _AdministrarRecetasMenuState();
}

class _AdministrarRecetasMenuState extends State<AdministrarRecetasMenu> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        height: 450,
        child: AdministrarRecetasPage(),
      ),
    );
  }
}
