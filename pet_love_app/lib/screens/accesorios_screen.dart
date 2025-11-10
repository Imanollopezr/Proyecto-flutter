import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/ProductoDetalleScreen.dart';

class AccesoriosScreen extends StatefulWidget {
  const AccesoriosScreen({super.key});

  @override
  State<AccesoriosScreen> createState() => _AccesoriosScreenState();
}

class _AccesoriosScreenState extends State<AccesoriosScreen> {
  List<dynamic> _accesorios = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAccesorios();
  }

    Future<void> _fetchAccesorios() async {
    final url = Uri.parse('http://petloveapi.somee.com/Productos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // SIN FILTRO - TRAE TODOS LOS PRODUCTOS
        setState(() {
          _accesorios = data;
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
                  height: 180,
                  color: const Color(0xFFFFC928),
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
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  'ACCESORIOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage))
                        : _accesorios.isEmpty
                            ? const Center(child: Text('No hay accesorios disponibles'))
                            : ListView.builder(
                                itemCount: _accesorios.length,
                                itemBuilder: (context, index) {
                                  final item = _accesorios[index];
                                  
                                  // Construir URL de la imagen
                                  final imagenPath = item['fkImagenNavigation']?['urlImagen'] ?? '';
                                  final imagenUrl = imagenPath.isNotEmpty
                                      ? 'http://petloveapi.somee.com${imagenPath.startsWith('/') ? '' : '/'}$imagenPath'
                                      : 'https://via.placeholder.com/150';
                                  // NUEVO: obtener stock
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
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imagenUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.image_not_supported, size: 40),
                                          ),
                                        ),
                                        title: Text(
                                          item['nombre'] ?? 'Sin nombre',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'S/.${item['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            if (item['descripcion'] != null && item['descripcion'].isNotEmpty)
                                              Text(
                                                item['descripcion'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductoDetalleScreen(
                                                productId: item['idProducto'] ?? 0,
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