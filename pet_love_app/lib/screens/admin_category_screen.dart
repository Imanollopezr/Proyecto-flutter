import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_love_app/config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filtered = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    searchController.addListener(() {
      _filter(searchController.text);
    });
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        filtered = List.from(categories);
      } else {
        filtered = categories
            .where((c) => (c['name'] as String).toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    });
  }

  MediaType _mediaTypeFromFilename(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('application', 'octet-stream');
  }

  String _toRelativePath(String url) {
    final base = ApiConfig.baseUrl;
    final u = url.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http')) {
      if (u.startsWith(base)) {
        final rel = u.substring(base.length);
        return rel.startsWith('/') ? rel : '/$rel';
      }
      // Es una URL externa, la enviamos tal cual
      return u;
    }
    // Asegurar "/" inicial
    return u.startsWith('/') ? u : '/$u';
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getCategoriaProductosUrl()),
        headers: ApiConfig.defaultHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map<Map<String, dynamic>>((category) {
          final rawId = category['idCategoriaProducto'] ??
              category['IdCategoriaProducto'] ??
              category['idCategoria'] ??
              category['id'];
          final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

          final rawImage = category['imagenUrl'] ??
              category['ImagenUrl'] ??
              category['urlImagen'] ??
              category['fkImagenNavigation']?['urlImagen'] ??
              '';

          return {
            'id': intId,
            'name': category['nombre']?.toString() ?? category['Nombre']?.toString() ?? 'Sin nombre',
            'imageUrl': ApiConfig.getImageUrl(rawImage?.toString() ?? ''),
            'descripcion': category['descripcion']?.toString() ?? '',
          };
        }).where((c) => (c['id'] as int) > 0).toList();

        setState(() {
          categories = list;
          filtered = List.from(list);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar categorías: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error de conexión: $e';
      });
    }
  }

  Future<void> _addCategory() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final imagenRel = _toRelativePath(imageController.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre requerido')));
      return;
    }
    setState(() => isLoading = true);
    try {
      final body = json.encode({
        'nombre': name,
        'descripcion': description,
        'imagenUrl': imagenRel,
      });
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/categorias'),
        headers: ApiConfig.defaultHeaders,
        body: body,
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        await _fetchCategories();
        nameController.clear();
        descriptionController.clear();
        imageController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría creada')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateCategory(int id) async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final imagenRel = _toRelativePath(imageController.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre requerido')));
      return;
    }
    setState(() => isLoading = true);
    try {
      final body = json.encode({
        'nombre': name,
        'descripcion': description,
        'imagenUrl': imagenRel,
      });
      final resp = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/categorias/$id'),
        headers: ApiConfig.defaultHeaders,
        body: body,
      );
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _fetchCategories();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría actualizada')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteCategory(int id) async {
    setState(() => isLoading = true);
    try {
      final resp = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/categorias/$id'),
        headers: ApiConfig.defaultHeaders,
      );
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: ${resp.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadCategoryImage(int categoryId) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo')),
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      final mediaType = _mediaTypeFromFilename(picked.name);

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categorias/$categoryId/imagen');
      final request = http.MultipartRequest('PUT', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: picked.name,
          contentType: mediaType,
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(body);
        final nuevaUrl = data['imagenUrl']?.toString() ?? '';
        setState(() {
          imageController.text = nuevaUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada')),
        );
        await _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $body')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createCategoryWithImage() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre de la categoría')),
      );
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo')),
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      final mediaType = _mediaTypeFromFilename(picked.name);

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categorias/con-imagen');
      final request = http.MultipartRequest('POST', uri)
        ..fields['nombre'] = name
        ..fields['descripcion'] = description
        ..files.add(http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: picked.name,
          contentType: mediaType,
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        nameController.clear();
        descriptionController.clear();
        imageController.clear();
        await _fetchCategories();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría creada con imagen')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $body')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDialog({required bool isEdit, int? categoryId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Categoría' : 'Agregar Categoría'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'URL Imagen (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Builder(
                    builder: (_) {
                      final raw = imageController.text.trim();
                      if (raw.isEmpty) {
                        return const Center(child: Icon(Icons.image_not_supported));
                      }
                      final previewUrl = ApiConfig.getImageUrl(raw);
                      return Image.network(
                        previewUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) =>
                            const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isEdit && categoryId != null)
                    TextButton.icon(
                      onPressed: () => _uploadCategoryImage(categoryId),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Subir imagen'),
                    )
                  else
                    TextButton.icon(
                      onPressed: _createCategoryWithImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Crear con imagen'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEdit && categoryId != null) {
                _updateCategory(categoryId);
              } else {
                _addCategory();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC928)),
            child: Text(isEdit ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    nameController.clear();
    descriptionController.clear();
    imageController.clear();
    _showDialog(isEdit: false);
  }

  void _showEditDialog(Map<String, dynamic> cat) {
    nameController.text = (cat['name'] as String?) ?? '';
    descriptionController.text = (cat['descripcion'] as String?) ?? '';
    imageController.text = (cat['imageUrl'] as String?) ?? '';
    final id = cat['id'] as int;
    _showDialog(isEdit: true, categoryId: id);
  }

  void _showDeleteConfirm(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la categoría "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(id);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar categoría',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (errorMessage != null)
              Expanded(child: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))))
            else if (filtered.isEmpty)
              const Expanded(child: Center(child: Text('No hay categorías disponibles')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cat = filtered[index];
                    final img = (cat['imageUrl'] as String?) ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              img,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (cat['name'] as String?) ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirm(cat['id'] as int, (cat['name'] as String?) ?? ''),
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
        onPressed: _showAddDialog,
      ),
    );
  }
}
