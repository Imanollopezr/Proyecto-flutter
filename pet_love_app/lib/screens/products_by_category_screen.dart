// import section
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_love_app/config/api_config.dart';
import 'package:pet_love_app/screens/ProductoDetalleScreen.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/main.dart' show CartModel, CartItem;
import 'package:pet_love_app/screens/shoppingcart_screen.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ProductsByCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProductsByCategoryScreen> createState() => _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchAndFilterProducts();
  }

  Future<void> _fetchAndFilterProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getProductosUrl()),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final parsed = data.map<Map<String, dynamic>>((p) {
          final rawProductId = p['id'] ?? p['idProducto'];
          final productId = rawProductId is int
              ? rawProductId
              : int.tryParse(rawProductId?.toString() ?? '') ?? 0;

          final rawCatId = p['idCategoriaProducto'] ??
              p['idCategoria'] ??
              p['categoriaId'] ??
              p['Categoria']?['IdCategoriaProducto'] ??
              p['categoria']?['id'] ??
              p['fkCategoria'] ??
              p['fkCategoriaNavigation']?['id'];
          final categoryId = rawCatId is int
              ? rawCatId
              : int.tryParse(rawCatId?.toString() ?? '') ?? 0;

          final nombre = p['nombre'] ?? p['Nombre'] ?? 'Sin nombre';
          final descripcion = p['descripcion'] ?? '';
          final rawPrice = p['precio'];
          final precio = rawPrice is num
              ? rawPrice.toDouble()
              : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

          final rawImage =
              p['imagenUrl'] ?? p['ImagenUrl'] ?? p['fkImagenNavigation']?['urlImagen'] ?? '';
          final imagenUrl = rawImage is String ? ApiConfig.getImageUrl(rawImage) : '';

          // NUEVO: parsear stock
          final rawStock = p['stock'] ?? p['Stock'];
          final stock = rawStock is int
              ? rawStock
              : int.tryParse(rawStock?.toString() ?? '') ?? 0;

          return {
            'id': productId,
            'categoriaId': categoryId,
            'nombre': nombre,
            'descripcion': descripcion,
            'precio': precio,
            'imagenUrl': imagenUrl,
            'stock': stock, // NUEVO
          };
        }).where((prod) => (prod['categoriaId'] as int) == widget.categoryId && (prod['id'] as int) > 0).toList();

        setState(() {
          products = parsed;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar productos: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  // MODO SELECCIÓN MÚLTIPLE
  bool multiSelect = false;
  final Map<int, int> selectedQty = {}; // productoId -> cantidad

  double _totalSelectedPrice() {
    double total = 0.0;
    selectedQty.forEach((id, qty) {
      final p = products.firstWhere((e) => e['id'] == id);
      total += (p['precio'] as double) * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos: ${widget.categoryName}'),
        backgroundColor: const Color(0xFFFFC928),
        actions: [
          IconButton(
            tooltip: multiSelect ? 'Salir de selección múltiple' : 'Seleccionar varios',
            icon: Icon(multiSelect ? Icons.checklist_rtl : Icons.playlist_add),
            onPressed: () {
              setState(() {
                multiSelect = !multiSelect;
                if (!multiSelect) selectedQty.clear();
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : products.isEmpty
                  ? const Center(child: Text('No hay productos disponibles en esta categoría'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (_, index) {
                              final item = products[index];
                              final id = item['id'] as int;
                              final nombre = item['nombre'] as String;
                              final precio = item['precio'] as double;
                              final imagenUrl = (item['imagenUrl'] as String?) ?? '';
                              final stock = item['stock'] as int;
                              final qty = selectedQty[id] ?? 0;
                              final isSelected = selectedQty.containsKey(id);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: imagenUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imagenUrl,
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
                                  title: Text(nombre),
                                  subtitle: Text('\$${precio.toStringAsFixed(2)}  •  Stock: $stock'),
                                  onTap: multiSelect
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductoDetalleScreen(
                                                productId: id,
                                                titulo: nombre,
                                                imagen: imagenUrl,
                                                descripcion: item['descripcion'] as String? ?? '',
                                                precio: precio,
                                                stock: stock,
                                                categoryId: widget.categoryId,
                                                categoryName: widget.categoryName,
                                              ),
                                            ),
                                          );
                                        },
                                  trailing: multiSelect
                                      ? SizedBox(
                                          width: 180,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: (checked) {
                                                  setState(() {
                                                    if (checked == true) {
                                                      selectedQty[id] = (selectedQty[id] ?? 1).clamp(1, stock);
                                                    } else {
                                                      selectedQty.remove(id);
                                                    }
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline),
                                                onPressed: isSelected && qty > 1
                                                    ? () {
                                                        setState(() {
                                                          selectedQty[id] = (qty - 1).clamp(1, stock);
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              Text(isSelected ? '$qty' : '0', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline),
                                                onPressed: isSelected && qty < stock
                                                    ? () {
                                                        setState(() {
                                                          selectedQty[id] = (qty + 1).clamp(1, stock);
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward_ios),
                                ),
                              );
                            },
                          ),
                        ),
                        if (multiSelect && selectedQty.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Seleccionados: ${selectedQty.length}', style: const TextStyle(fontSize: 16)),
                                    Text('\$${_totalSelectedPrice().toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFC928),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () {
                                      final cart = Provider.of<CartModel>(context, listen: false);
                                      selectedQty.forEach((id, qty) {
                                        final p = products.firstWhere((e) => e['id'] == id);
                                        cart.addItem(CartItem(
                                          productId: id,
                                          title: p['nombre'] as String,
                                          image: (p['imagenUrl'] as String?) ?? '',
                                          price: p['precio'] as double,
                                          quantity: qty,
                                          availableStock: p['stock'] as int,
                                          categoryId: widget.categoryId,
                                          categoryName: widget.categoryName,
                                        ));
                                      });
                                      setState(() {
                                        selectedQty.clear();
                                        multiSelect = false;
                                      });
                                      // Ir al carrito de compras
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const ShoppingCartScreen()),
                                      );
                                    },
                                    label: const Text('Agregar seleccionados'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}