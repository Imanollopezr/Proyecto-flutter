import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_love_app/config/api_config.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> marcas = [];
  List<Map<String, dynamic>> medidas = [];
  bool isLoading = true;
  String? errorMessage;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  MediaType _mediaTypeFromFilename(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('application', 'octet-stream');
  }

  // Helper: convertir a ruta relativa si apunta al mismo host
  String _toRelativePath(String url) {
    final base = ApiConfig.baseUrl;
    final u = url.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http')) {
      if (u.startsWith(base)) {
        final rel = u.substring(base.length);
        return rel.startsWith('/') ? rel : '/$rel';
      }
      return u; // URL externa: dejar tal cual
    }
    return u.startsWith('/') ? u : '/$u';
  }

  // Helper: fallback robusto para imagenUrl en productos
  String _extractProductImageUrl(Map<String, dynamic> p) {
    final candidates = [
      p['imagenUrl'],
      p['ImagenUrl'], 
      p['urlImagen'],
      p['URLImagen'],
      (p['fkImagenNavigation'] is Map ? p['fkImagenNavigation']['urlImagen'] : null),
    ];
    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) return c.toString();
    }
    return '';
  }

  // Seleccionar imagen desde galería (para diálogos)
  Future<void> _pickProductImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // bajar calidad para evitar >5MB
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setDialogState(() {
      selectedImage = picked;
      selectedImageBytes = bytes;
    });
  }

  // Subir imagen del producto (PUT /api/productos/{id}/imagen)
  Future<void> _uploadProductImage(int productId) async {
    if (selectedImage == null || selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen primero')),
      );
      return;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/productos/$productId/imagen');
      final mediaType = _mediaTypeFromFilename(selectedImage!.name);
      final request = http.MultipartRequest('PUT', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'Imagen',
          selectedImageBytes!,
          filename: selectedImage!.name,
          contentType: mediaType,
        ));

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      if (resp.statusCode == 200) {
        final data = json.decode(body);
        final nuevaUrl = data['imagenUrl']?.toString() ??
            data['ImagenUrl']?.toString() ?? '';
        setState(() {
          imageUrlController.text = nuevaUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada')),
        );
        await _fetchProducts();
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  int? selectedCategoryId;
  int? selectedMarcaId;
  int? selectedMedidaId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchProducts(),
      _fetchCategories(),
      _fetchMarcas(),
      _fetchMedidas(),
    ]);
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/productos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        products = data.map<Map<String, dynamic>>((product) {
          // Extraer IDs de relaciones si vienen en el DTO
          final categoriaIdRaw = product['categoria']?['id'];
          final marcaIdRaw = product['marca']?['id'];
          final medidaIdRaw = product['medida']?['id'];

          final categoriaId = categoriaIdRaw is int ? categoriaIdRaw : int.tryParse(categoriaIdRaw?.toString() ?? '') ?? 0;
          final marcaId = marcaIdRaw is int ? marcaIdRaw : int.tryParse(marcaIdRaw?.toString() ?? '') ?? 0;
          final medidaId = medidaIdRaw is int ? medidaIdRaw : int.tryParse(medidaIdRaw?.toString() ?? '') ?? 0;

          return {
            'id': product['id'],
            'nombre': product['nombre'],
            'descripcion': product['descripcion'] ?? '',
            'precio': product['precio'],
            'stock': product['stock'],
            'imagenUrl': _extractProductImageUrl(product),
            'categoria': product['categoria']?['nombre'] ?? 'Sin categoría',
            'marca': product['marca']?['nombre'] ?? 'Sin marca',
            'medida': product['medida']?['nombre'] ?? 'Sin medida',
            'categoriaId': categoriaId,
            'marcaId': marcaId,
            'medidaId': medidaId,
          };
        }).toList();

        _filterProducts(searchController.text);
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/categorias'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Mapear correctamente el ID de la categoría desde la API
          categories = data.map<Map<String, dynamic>>((category) {
            final rawId = category['idCategoriaProducto'] ?? category['IdCategoriaProducto'] ?? category['id'];
            final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
            return {
              'id': intId,
              'nombre': category['nombre'] ?? category['Nombre'] ?? '',
            };
          })
          // Filtrar cualquier categoría con id inválido (<= 0)
          .where((cat) => (cat['id'] as int) > 0)
          .toList();
        });
        print('Categorías cargadas: ${categories.length}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchMarcas() async {
    try {
      print('Fetching marcas from: ${ApiConfig.baseUrl}/api/marcas');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/marcas'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Marcas response status: ${response.statusCode}');
      print('Marcas response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          marcas = data.map<Map<String, dynamic>>((marca) {
            return {
              'id': marca['idMarca'] is int ? marca['idMarca'] : int.tryParse(marca['idMarca'].toString()) ?? 0,
              'nombre': marca['nombre'],
            };
          }).toList();
        });
        print('Marcas loaded: ${marcas.length} items');
      } else {
        print('Error fetching marcas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching marcas: $e');
    }
  }

  Future<void> _fetchMedidas() async {
    try {
      print('Fetching medidas from: ${ApiConfig.baseUrl}/api/medidas');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/medidas'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Medidas response status: ${response.statusCode}');
      print('Medidas response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          medidas = data.map<Map<String, dynamic>>((medida) {
            return {
              'id': medida['idMedida'] is int ? medida['idMedida'] : int.tryParse(medida['idMedida'].toString()) ?? 0,
              'nombre': medida['nombre'],
            };
          }).toList();
        });
        print('Medidas loaded: ${medidas.length} items');
      } else {
        print('Error fetching medidas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching medidas: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products
            .where((p) =>
                (p['nombre'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
                (p['categoria'] ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addProduct() async {
    final nombre = nameController.text.trim();
    final descripcion = descriptionController.text.trim();
    final precio = double.tryParse(priceController.text.trim());
    final stock = int.tryParse(stockController.text.trim());
    final imagenUrl = imageUrlController.text.trim();

    if (nombre.isEmpty || precio == null || stock == null || selectedCategoryId == null || selectedMarcaId == null || selectedMedidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      // Si hay imagen seleccionada, usar multipart/form-data con bytes
      if (selectedImage != null && selectedImageBytes != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/api/productos/con-imagen');
        final request = http.MultipartRequest('POST', uri);
  
        request.fields['Nombre'] = nombre;
        if (descripcion.isNotEmpty) request.fields['Descripcion'] = descripcion;
        request.fields['Precio'] = precio.toString();
        request.fields['Stock'] = stock.toString();
        request.fields['IdCategoriaProducto'] = selectedCategoryId!.toString();
        request.fields['IdMarcaProducto'] = selectedMarcaId!.toString();
        request.fields['IdMedidaProducto'] = selectedMedidaId!.toString();
  
        final mediaType = _mediaTypeFromFilename(selectedImage!.name);
    request.files.add(
      http.MultipartFile.fromBytes(
        'Imagen',
        selectedImageBytes!,
        filename: selectedImage!.name,
        contentType: mediaType,
      ),
    );
  
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
  
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto agregado exitosamente (con imagen)')),
          );
          _clearForm();
          Navigator.of(context).pop();
          _fetchProducts();
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorData['message'] ?? 'Error desconocido'}')),
          );
        }
      } else {
        // fallback sin imagen: JSON al endpoint normal
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/productos'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nombre': nombre,
            'descripcion': descripcion,
            'precio': precio,
            'stock': stock,
            'imagenUrl': _toRelativePath(imagenUrl),
            'idCategoriaProducto': selectedCategoryId,
            'idMarcaProducto': selectedMarcaId,
            'idMedidaProducto': selectedMedidaId,
            'activo': true,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto agregado exitosamente')),
          );
          _clearForm();
          Navigator.of(context).pop();
          _fetchProducts();
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorData['message'] ?? 'Error desconocido'}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProduct(int id) async {
    final nombre = nameController.text.trim();
    final descripcion = descriptionController.text.trim();
    final precio = double.tryParse(priceController.text.trim());
    final stock = int.tryParse(stockController.text.trim());
    final imagenUrl = imageUrlController.text.trim();

    if (nombre.isEmpty || precio == null || stock == null || selectedCategoryId == null || selectedMarcaId == null || selectedMedidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final body = {
        'Id': id, // El backend valida que el Id del body coincida con el de la URL
        'Nombre': nombre,
        if (descripcion.isNotEmpty) 'Descripcion': descripcion,
        'Precio': precio,
        'Stock': stock,
        'IdCategoriaProducto': selectedCategoryId,
        'IdMarcaProducto': selectedMarcaId,
        'IdMedidaProducto': selectedMedidaId,
        if (imagenUrl.isNotEmpty) 'ImagenUrl': imagenUrl,
        'Activo': true,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/productos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado correctamente')),
        );
        _clearForm();
        Navigator.of(context).pop();
        await _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    stockController.clear();
    imageUrlController.clear();
    setState(() {
      selectedCategoryId = null;
      selectedMarcaId = null;
      selectedMedidaId = null;
      selectedImage = null;          // NUEVO
      selectedImageBytes = null;     // NUEVO
    });
  }

  void _showAddDialog() async {
    // Asegurar que los datos estén cargados antes de mostrar el diálogo
    if (categories.isEmpty || marcas.isEmpty || medidas.isEmpty) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Cargando datos...'),
            ],
          ),
        ),
      );
      
      await _fetchInitialData();
      
      // Cerrar el indicador de carga
      Navigator.of(context).pop();
      
      // Si aún no hay datos, mostrar error y no abrir el diálogo
      if (categories.isEmpty || marcas.isEmpty || medidas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudieron cargar los datos necesarios. Verifica la conexión al servidor.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Limpiar formulario
    _clearForm();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Vista previa de imagen (seleccionada o por URL)
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedImageBytes != null
                      ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                      : Builder(
                          builder: (_) {
                            final raw = imageUrlController.text.trim();
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _pickProductImage(setDialogState),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Seleccionar imagen'),
                  ),
                ),
                const SizedBox(height: 16),
                // Selector de Categoría personalizado
                GestureDetector(
                  onTap: () {
                    _showCategorySelector(context, setDialogState);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCategoryId != null 
                            ? categories.firstWhere((cat) => cat['id'] == selectedCategoryId, orElse: () => {'nombre': 'Seleccionar categoría'})['nombre']
                            : 'Seleccionar categoría *',
                          style: TextStyle(
                            color: selectedCategoryId != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selector de Marca personalizado
                GestureDetector(
                  onTap: () {
                    _showMarcaSelector(context, setDialogState);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedMarcaId != null 
                            ? marcas.firstWhere((marca) => marca['id'] == selectedMarcaId)['nombre']
                            : 'Seleccionar marca *',
                          style: TextStyle(
                            color: selectedMarcaId != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selector de Medida personalizado
                GestureDetector(
                  onTap: () {
                    _showMedidaSelector(context, setDialogState);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedMedidaId != null 
                            ? medidas.firstWhere((medida) => medida['id'] == selectedMedidaId)['nombre']
                            : 'Seleccionar medida *',
                          style: TextStyle(
                            color: selectedMedidaId != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            StatefulBuilder(
              builder: (context, setButtonState) => ElevatedButton(
                onPressed: () {
                  // Debug prints
                  print('Validando formulario:');
                  print('selectedCategoryId: $selectedCategoryId');
                  print('selectedMarcaId: $selectedMarcaId');
                  print('selectedMedidaId: $selectedMedidaId');
                  print('nameController.text: ${nameController.text}');
                  print('priceController.text: ${priceController.text}');
                  print('stockController.text: ${stockController.text}');
                  
                  if (selectedCategoryId != null && 
                      selectedMarcaId != null && 
                      selectedMedidaId != null &&
                      nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      stockController.text.isNotEmpty) {
                    _addProduct();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor completa todos los campos obligatorios'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (selectedCategoryId != null && 
                                   selectedMarcaId != null && 
                                   selectedMedidaId != null &&
                                   nameController.text.isNotEmpty &&
                                   priceController.text.isNotEmpty &&
                                   stockController.text.isNotEmpty) 
                    ? Colors.blue 
                    : Colors.grey,
                ),
                child: const Text('Agregar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) {
        // Lista filtrada local y controlador de búsqueda
        List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(categories);
        final TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Seleccionar Categoría'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar categoría',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                    ),
                    onChanged: (q) {
                      setLocalState(() {
                        final query = q.trim().toLowerCase();
                        if (query.isEmpty) {
                          filtered = List<Map<String, dynamic>>.from(categories);
                        } else {
                          filtered = categories.where((c) {
                            final name = (c['nombre'] ?? c['name'] ?? '').toString().toLowerCase();
                            return name.contains(query);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No hay categorías que coincidan'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final category = filtered[index];
                              final categoryId = (category['id'] as int?) ?? 0;
                              if (categoryId <= 0) return const SizedBox.shrink();
                              final nombre = (category['nombre'] ?? category['name'] ?? '').toString();

                              return ListTile(
                                title: Text(nombre),
                                leading: Radio<int>(
                                  value: categoryId,
                                  groupValue: selectedCategoryId,
                                  onChanged: (value) {
                                    if (value == null || value <= 0) return;
                                    setDialogState(() {
                                      selectedCategoryId = value;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                                onTap: () {
                                  if (categoryId <= 0) return;
                                  setDialogState(() {
                                    selectedCategoryId = categoryId;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMarcaSelector(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(marcas);
        final TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Seleccionar Marca'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar marca',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                    ),
                    onChanged: (q) {
                      setLocalState(() {
                        final query = q.trim().toLowerCase();
                        if (query.isEmpty) {
                          filtered = List<Map<String, dynamic>>.from(marcas);
                        } else {
                          filtered = marcas.where((m) {
                            final name = (m['nombre'] ?? m['name'] ?? '').toString().toLowerCase();
                            return name.contains(query);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No hay marcas que coincidan'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final marca = filtered[index];
                              final marcaId = (marca['id'] as int?) ?? 0;
                              if (marcaId <= 0) return const SizedBox.shrink();
                              final nombre = (marca['nombre'] ?? marca['name'] ?? '').toString();

                              return ListTile(
                                title: Text(nombre),
                                leading: Radio<int>(
                                  value: marcaId,
                                  groupValue: selectedMarcaId,
                                  onChanged: (value) {
                                    if (value == null || value <= 0) return;
                                    setDialogState(() {
                                      selectedMarcaId = value;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                                onTap: () {
                                  if (marcaId <= 0) return;
                                  setDialogState(() {
                                    selectedMarcaId = marcaId;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMedidaSelector(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(medidas);
        final TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Seleccionar Medida'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar medida',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                    ),
                    onChanged: (q) {
                      setLocalState(() {
                        final query = q.trim().toLowerCase();
                        if (query.isEmpty) {
                          filtered = List<Map<String, dynamic>>.from(medidas);
                        } else {
                          filtered = medidas.where((md) {
                            final name = (md['nombre'] ?? md['name'] ?? '').toString().toLowerCase();
                            return name.contains(query);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No hay medidas que coincidan'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final medida = filtered[index];
                              final medidaId = (medida['id'] as int?) ?? 0;
                              if (medidaId <= 0) return const SizedBox.shrink();
                              final nombre = (medida['nombre'] ?? medida['name'] ?? '').toString();

                              return ListTile(
                                title: Text(nombre),
                                leading: Radio<int>(
                                  value: medidaId,
                                  groupValue: selectedMedidaId,
                                  onChanged: (value) {
                                    if (value == null || value <= 0) return;
                                    setDialogState(() {
                                      selectedMedidaId = value;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                                onTap: () {
                                  if (medidaId <= 0) return;
                                  setDialogState(() {
                                    selectedMedidaId = medidaId;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> product) {
    // Precargar campos con datos del producto
    nameController.text = product['nombre'] ?? '';
    descriptionController.text = product['descripcion'] ?? '';
    priceController.text = (product['precio'] is num)
        ? product['precio'].toString()
        : (double.tryParse(product['precio']?.toString() ?? '')?.toString() ?? '');
    stockController.text = (product['stock'] is num)
        ? product['stock'].toString()
        : (int.tryParse(product['stock']?.toString() ?? '')?.toString() ?? '');
    imageUrlController.text = product['imagenUrl'] ?? '';

    // Precargar selecciones (si hay IDs válidos)
    selectedCategoryId = (product['categoriaId'] is int && product['categoriaId'] > 0) ? product['categoriaId'] : null;
    selectedMarcaId = (product['marcaId'] is int && product['marcaId'] > 0) ? product['marcaId'] : null;
    selectedMedidaId = (product['medidaId'] is int && product['medidaId'] > 0) ? product['medidaId'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de imagen (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Vista previa
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          : Builder(
                              builder: (_) {
                                final raw = imageUrlController.text.trim();
                                if (raw.isEmpty) {
                                  return const Center(child: Icon(Icons.image_not_supported));
                                }
                                final previewUrl = ApiConfig.getImageUrl(raw);
                                return Image.network(
                                  previewUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickProductImage(setDialogState),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Seleccionar imagen'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _uploadProductImage(product['id'] as int),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Subir imagen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Selectores de categoría, marca y medida
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showCategorySelector(context, setDialogState),
                            child: Text(selectedCategoryId != null
                                ? 'Categoría: ${categories.firstWhere((c) => c['id'] == selectedCategoryId, orElse: () => {'nombre': 'Seleccionar'})['nombre']}'
                                : 'Seleccionar Categoría *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showMarcaSelector(context, setDialogState),
                            child: Text(selectedMarcaId != null
                                ? 'Marca: ${marcas.firstWhere((m) => m['id'] == selectedMarcaId, orElse: () => {'nombre': 'Seleccionar'})['nombre']}'
                                : 'Seleccionar Marca *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showMedidaSelector(context, setDialogState),
                            child: Text(selectedMedidaId != null
                                ? 'Medida: ${medidas.firstWhere((md) => md['id'] == selectedMedidaId, orElse: () => {'nombre': 'Seleccionar'})['nombre']}'
                                : 'Seleccionar Medida *'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCategoryId != null &&
                        selectedMarcaId != null &&
                        selectedMedidaId != null &&
                        nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty &&
                        stockController.text.isNotEmpty) {
                      _updateProduct(product['id'] as int);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor completa todos los campos obligatorios'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (selectedCategoryId != null &&
                                      selectedMarcaId != null &&
                                      selectedMedidaId != null &&
                                      nameController.text.isNotEmpty &&
                                      priceController.text.isNotEmpty &&
                                      stockController.text.isNotEmpty)
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: const Color(0xFFFFC928),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterProducts,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC928),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : filteredProducts.isEmpty
                        ? const Center(child: Text('No hay productos disponibles'))
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final raw = (product['imagenUrl'] as String?) ?? '';
                              final previewUrl = ApiConfig.getImageUrl(raw);
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: raw.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            previewUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.inventory),
                                        ),
                                  title: Text(
                                    product['nombre'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Categoría: ${product['categoria']}'),
                                      Text('Precio: \$${product['precio']}'),
                                      Text('Stock: ${product['stock']}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showEditDialog(product);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          // TODO: Implementar eliminación
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}