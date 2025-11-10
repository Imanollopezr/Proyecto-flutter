import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/ProductoDetalleScreen.dart';

class JuguetesScreen extends StatefulWidget {
  const JuguetesScreen({super.key});

  @override
  State<JuguetesScreen> createState() => _JuguetesScreenState();
}

class _JuguetesScreenState extends State<JuguetesScreen> {
  List<dynamic> _productos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProductos();
  }

  Future<void> _fetchProductos() async {
    final url = Uri.parse('http://petloveapi.somee.com/Productos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // SIN FILTRO - TRAE TODOS LOS PRODUCTOS
        setState(() {
          _productos = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar productos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Stack(
        children: [
          Column(
            children: [
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  color: const Color(0xFFFFC928),
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Image.asset('img/logopet.png', height: 50),
                        const Icon(Icons.shopping_cart),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  'PRODUCTOS', // Cambiado a PRODUCTOS
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage))
                        : _productos.isEmpty
                            ? const Center(child: Text('No hay productos disponibles'))
                            : ListView.builder(
                                itemCount: _productos.length,
                                itemBuilder: (context, index) {
                                  final item = _productos[index];
                                  // Construir URL completa para imágenes
                                  final imagenPath = item['fkImagenNavigation']?['urlImagen'] ?? '';
                                  final imagenUrl = imagenPath.isNotEmpty
                                      ? 'http://petloveapi.somee.com${imagenPath.startsWith('/') ? '' : '/'}$imagenPath'
                                      : 'https://via.placeholder.com/150';
                                  // NUEVO: obtener stock si viene en el JSON
                                  final rawStock = item['stock'] ?? item['Stock'];
                                  final stock = rawStock is int
                                      ? rawStock
                                      : int.tryParse(rawStock?.toString() ?? '') ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 4,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Image.network(
                                          imagenUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.image_not_supported, size: 50),
                                        ),
                                        title: Text(
                                          item['nombre'] ?? 'Sin nombre',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['fkCategoriaNavigation']?['nombre'] ?? 'Sin categoría',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                            Text(
                                              'S/.${item['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductoDetalleScreen(
                                                // Añadido el parámetro productId
                                                productId: item['idProducto'] ?? item['id'] ?? 0,
                                                titulo: item['nombre'] ?? '',
                                                imagen: imagenUrl,
                                                descripcion: item['descripcion'] ?? 'Sin descripción',
                                                precio: (item['precio'] is num)
                                                    ? item['precio'].toDouble()
                                                    : double.tryParse(item['precio'].toString()) ?? 0.0,
                                                stock: stock, // NUEVO: pasar stock
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}