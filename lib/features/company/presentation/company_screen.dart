import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/company_data.dart';
import '../../../core/widgets/local_image.dart';
import 'company_provider.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  late TextEditingController _name;
  late TextEditingController _address;
  late TextEditingController _location;
  late TextEditingController _lat;
  late TextEditingController _lng;
  final Map<int, TextEditingController> _hours = {};
  String _floorPlan = '';
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _address = TextEditingController();
    _location = TextEditingController();
    _lat = TextEditingController();
    _lng = TextEditingController();
    for (var d = 1; d <= 7; d++) {
      _hours[d] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final c = ref.read(companyProvider);
    _name.text = c.name;
    _address.text = c.address;
    _location.text = c.locationText;
    _lat.text = c.latitude?.toString() ?? '';
    _lng.text = c.longitude?.toString() ?? '';
    _floorPlan = c.floorPlanPath;
    for (var d = 1; d <= 7; d++) {
      _hours[d]!.text = c.hours[d] ?? (d <= 5 ? '09:00-18:00' : 'Cerrado');
    }
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _location.dispose();
    _lat.dispose();
    _lng.dispose();
    for (final c in _hours.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final hours = <int, String>{};
    for (final e in _hours.entries) {
      hours[e.key] = e.value.text.trim();
    }
    final data = CompanyData(
      name: _name.text.trim(),
      address: _address.text.trim(),
      locationText: _location.text.trim(),
      latitude: double.tryParse(_lat.text.trim()),
      longitude: double.tryParse(_lng.text.trim()),
      floorPlanPath: _floorPlan,
      hours: hours,
    );
    await ref.read(companyProvider.notifier).save(data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de empresa guardados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(companyProvider, (_, __) {
      if (!_ready) _sync();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de empresa'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Se usan como valores por defecto en publicaciones y respuestas IA.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Dirección'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Ubicación (texto / mapa)',
              helperText: 'Ej. colonia, referencias o enlace de mapa',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitud'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitud'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Croquis / plano', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_floorPlan.isNotEmpty)
            LocalImage(path: _floorPlan, height: 160, fit: BoxFit.contain),
          TextButton.icon(
            onPressed: () async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (file != null) setState(() => _floorPlan = file.path);
            },
            icon: const Icon(Icons.map_outlined),
            label: Text(
              _floorPlan.isEmpty ? 'Agregar croquis' : 'Cambiar croquis',
            ),
          ),
          const Divider(height: 32),
          Text(
            'Horario por día',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...CompanyData.defaultWeekdayLabels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _hours[e.key],
                decoration: InputDecoration(
                  labelText: e.value,
                  helperText: 'Ej. 09:00-18:00 o Cerrado',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar empresa'),
          ),
        ],
      ),
    );
  }
}
