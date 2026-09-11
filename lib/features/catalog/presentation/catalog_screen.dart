import 'package:flutter/material.dart';

import '../../inventory/presentation/inventory_screen.dart';

/// Compatibilidad: el catálogo fino se reemplazó por inventario.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) => const InventoryScreen();
}
