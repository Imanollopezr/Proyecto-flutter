import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({Key? key}) : super(key: key);

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  List<Map<String, dynamic>> marcas = [];
  List<Map<String, dynamic>> filteredMarcas = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  Future<void> _fetchMarcas() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMarcasUrl()),
        headers: ApiConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        marcas = data.map<Map<String, dynamic>>((m) {
          return {
            'idMarca': m['idMarca'],
            'nombre': m['nombre'] ?? '',
            'descripcion': m['descripcion'] ?? '',
            'activo': m['activo'] ?? true,
          };
        }).toList();
        _filterMarcas(searchController.text);
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

  void _filterMarcas(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMarcas = List.from(marcas);
      } else {
        final q = query.toLowerCase();
        filteredMarcas = marcas.where((m) => (m['nombre'] as String).toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _addMarca(String nombre, String descripcion) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getMarcasUrl()),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim(),
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca creada correctamente')));
        await _fetchMarcas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateMarca(int idMarca, String nombre, String descripcion, bool activo) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.getMarcasUrl()}/$idMarca'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim(),
          'activo': activo,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca actualizada correctamente')));
        await _fetchMarcas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteMarca(int idMarca) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.getMarcasUrl()}/$idMarca'),
        headers: ApiConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca eliminada correctamente')));
        await _fetchMarcas();
      } else {
        // Mostrar mensaje de error que envía el backend (por asociaciones con productos)
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

  Future<void> _showMarcaDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final TextEditingController nombreCtrl = TextEditingController(text: existing?['nombre'] ?? '');
    final TextEditingController descripcionCtrl = TextEditingController(text: existing?['descripcion'] ?? '');
    bool activo = existing?['activo'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Editar Marca' : 'Agregar Marca'),
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
                  if (nombreCtrl.text.trim().isEmpty || nombreCtrl.text.trim().length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido y debe tener al menos 2 caracteres')));
                    return;
                  }
                  if (isEdit) {
                    await _updateMarca(existing!['idMarca'] as int, nombreCtrl.text, descripcionCtrl.text, activo);
                  } else {
                    await _addMarca(nombreCtrl.text, descripcionCtrl.text);
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
        title: const Text('Gestión de Marcas'),
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
                      labelText: 'Buscar marcas...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterMarcas,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showMarcaDialog(),
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
                      : filteredMarcas.isEmpty
                          ? const Center(child: Text('No hay marcas disponibles'))
                          : ListView.separated(
                              itemBuilder: (_, index) {
                                final marca = filteredMarcas[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: marca['activo'] == true ? Colors.green.shade100 : Colors.red.shade100,
                                    child: Icon(marca['activo'] == true ? Icons.check : Icons.remove, color: Colors.black54),
                                  ),
                                  title: Text(marca['nombre'] ?? ''),
                                  subtitle: Text(marca['descripcion'] ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showMarcaDialog(existing: marca),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteMarca(marca['idMarca'] as int),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemCount: filteredMarcas.length,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}