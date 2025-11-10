import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_love_app/config/api_config.dart';

class Categoria {
  final int? id;
  final String nombre;
  final String imagen;

  Categoria({
    this.id,
    required this.nombre,
    required this.imagen,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['idCategoria'],
      nombre: json['nombre'],
      imagen: json['urlImagen'] != null
          ? '${ApiConfig.baseUrl}${json['urlImagen']}'
          : 'https://via.placeholder.com/150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'urlImagen': imagen.replaceFirst(ApiConfig.baseUrl, ''),
    };
  }
}

class ApiService {
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static Future<List<Categoria>> getCategorias() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/categorias'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar categorías: ${response.statusCode}');
    }
  }

  static Future<void> createCategoria(Categoria categoria) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/categorias'),
      headers: headers,
      body: json.encode(categoria.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear categoría: ${response.body}');
    }
  }

  static Future<void> updateCategoria(Categoria categoria) async {
    if (categoria.id == null) throw Exception('ID no válido');
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/categorias/${categoria.id}'),
      headers: headers,
      body: json.encode(categoria.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al actualizar: ${response.body}');
    }
  }

  static Future<void> deleteCategoria(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/categorias/$id'),
      headers: headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Error al eliminar categoría');
    }
  }
}

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Categoria> categories = [];
  List<Categoria> _filteredCategories = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _searchController.addListener(() {
      _filterCategories(_searchController.text);
    });
  }

  Future<void> _loadCategorias() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final categorias = await ApiService.getCategorias();
      setState(() {
        categories = categorias;
        _filteredCategories = categorias;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _filterCategories(String query) {
    final filtered = categories
        .where((cat) =>
            cat.nombre.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _filteredCategories = filtered;
    });
  }

  Future<void> _addCategoria() async {
    final nuevaCategoria = Categoria(
      nombre: _nombreController.text,
      imagen: _imagenController.text,
    );

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.createCategoria(nuevaCategoria);
      await _loadCategorias();
      _nombreController.clear();
      _imagenController.clear();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _editCategoria(Categoria categoria) async {
    final updatedCategoria = Categoria(
      id: categoria.id,
      nombre: _nombreController.text,
      imagen: _imagenController.text,
    );

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.updateCategoria(updatedCategoria);
      await _loadCategorias();
      _nombreController.clear();
      _imagenController.clear();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteCategoria(int id) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.deleteCategoria(id);
      await _loadCategorias();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _showAddCategoryDialog() {
    _nombreController.clear();
    _imagenController.clear();
    _showDialog(isEdit: false);
  }

  void _showEditCategoryDialog(Categoria categoria) {
    _nombreController.text = categoria.nombre;
    _imagenController.text = categoria.imagen;
    _showDialog(isEdit: true, categoria: categoria);
  }

  void _showDialog({required bool isEdit, Categoria? categoria}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Categoría' : 'Agregar Categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imagenController,
                decoration: const InputDecoration(
                  labelText: 'URL Imagen',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (isEdit && categoria != null) {
                      await _editCategoria(categoria);
                    } else {
                      await _addCategoria();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC928),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Guardar cambios' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la categoría "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategoria(id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC928),
        elevation: 0,
        title: const Text('Admin Categorías'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar categoría',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                ),
              )
            else if (_filteredCategories.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay categorías disponibles',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final categoria = _filteredCategories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              categoria.imagen,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              categoria.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditCategoryDialog(categoria);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              if (categoria.id != null) {
                                _showDeleteConfirmation(
                                  categoria.id!,
                                  categoria.nombre,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC928),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _showAddCategoryDialog,
      ),
    );
  }
}
