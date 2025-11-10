import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AdminMeasuresScreen extends StatefulWidget {
  const AdminMeasuresScreen({Key? key}) : super(key: key);

  @override
  State<AdminMeasuresScreen> createState() => _AdminMeasuresScreenState();
}

class _AdminMeasuresScreenState extends State<AdminMeasuresScreen> {
  List<Map<String, dynamic>> medidas = [];
  List<Map<String, dynamic>> filteredMedidas = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMedidas();
  }

  Future<void> _fetchMedidas() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMedidasUrl()),
        headers: ApiConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        medidas = data.map<Map<String, dynamic>>((m) {
          return {
            'idMedida': m['idMedida'],
            'nombre': m['nombre'] ?? '',
            'abreviatura': m['abreviatura'] ?? '',
            'descripcion': m['descripcion'] ?? '',
            'activo': m['activo'] ?? true,
          };
        }).toList();
        _filterMedidas(searchController.text);
      } else {
        errorMessage = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterMedidas(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMedidas = List.from(medidas);
      } else {
        final q = query.toLowerCase();
        filteredMedidas = medidas.where((m) => (m['nombre'] as String).toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _addMedida(String nombre, String abreviatura, String descripcion) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getMedidasUrl()),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'nombre': nombre.trim(),
          'abreviatura': abreviatura.trim(),
          'descripcion': descripcion.trim(),
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medida creada correctamente')));
        await _fetchMedidas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateMedida(int idMedida, String nombre, String abreviatura, String descripcion, bool activo) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.getMedidasUrl()}/$idMedida'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'nombre': nombre.trim(),
          'abreviatura': abreviatura.trim(),
          'descripcion': descripcion.trim(),
          'activo': activo,
        }),
      );
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medida actualizada correctamente')));
        await _fetchMedidas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteMedida(int idMedida) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.getMedidasUrl()}/$idMedida'),
        headers: ApiConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medida eliminada correctamente')));
        await _fetchMedidas();
      } else {
        String msg = 'Error al eliminar: ${response.statusCode}';
        try {
          final body = json.decode(response.body);
          if (body is Map && body['message'] is String) {
            msg = body['message'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showMedidaDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final TextEditingController nombreCtrl = TextEditingController(text: existing?['nombre'] ?? '');
    final TextEditingController abreviaturaCtrl = TextEditingController(text: existing?['abreviatura'] ?? '');
    final TextEditingController descripcionCtrl = TextEditingController(text: existing?['descripcion'] ?? '');
    bool activo = existing?['activo'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Editar Medida' : 'Agregar Medida'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: abreviaturaCtrl,
                    decoration: const InputDecoration(labelText: 'Abreviatura *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descripcionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Activo'),
                      value: activo,
                      onChanged: (v) => setDialogState(() => activo = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty || abreviaturaCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre y abreviatura son requeridos')));
                    return;
                  }
                  if (isEdit) {
                    await _updateMedida(existing!['idMedida'] as int, nombreCtrl.text, abreviaturaCtrl.text, descripcionCtrl.text, activo);
                  } else {
                    await _addMedida(nombreCtrl.text, abreviaturaCtrl.text, descripcionCtrl.text);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'Guardar' : 'Agregar'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Medidas'),
        backgroundColor: const Color(0xFFFFC928),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar medidas...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterMedidas,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showMedidaDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : filteredMedidas.isEmpty
                          ? const Center(child: Text('No hay medidas disponibles'))
                          : ListView.separated(
                              itemBuilder: (_, index) {
                                final medida = filteredMedidas[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: medida['activo'] == true ? Colors.green.shade100 : Colors.red.shade100,
                                    child: Text((medida['abreviatura'] ?? '??').toString(), style: const TextStyle(fontSize: 12, color: Colors.black)),
                                  ),
                                  title: Text(medida['nombre'] ?? ''),
                                  subtitle: Text(medida['descripcion'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showMedidaDialog(existing: medida),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteMedida(medida['idMedida'] as int),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: filteredMedidas.length,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}