import 'package:flutter/material.dart';
import 'package:pet_love_app/screens/home_screen.dart';
import 'package:pet_love_app/screens/profile_screen.dart';
import 'package:pet_love_app/screens/ProductoDetalleScreen.dart';

class AlimentosScreen extends StatelessWidget {
  const AlimentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alimentos = [
      {
        'id': 1,
        'titulo': 'Croquetas Premium',
        'imagen': 'img/cuido.png',
        'descripcion': 'Croquetas nutritivas para mascotas activas.',
        'precio': 45000.0,
        'stock': 10, // NUEVO
      },
      {
        'id': 2,
        'titulo': 'Comida húmeda',
        'imagen': 'img/bucal.png',
        'descripcion': 'Alimento húmedo rico en sabor y vitaminas.',
        'precio': 20000.0,
        'stock': 8, // NUEVO
      },
      {
        'id': 3,
        'titulo': 'Snacks Naturales',
        'imagen': 'img/comida.png',
        'descripcion': 'Snacks saludables hechos con ingredientes naturales.',
        'precio': 30000.0,
        'stock': 0, // NUEVO (sin stock)
      },
    ];

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
                  'ALIMENTOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: alimentos.length,
                  itemBuilder: (context, index) {
                    final item = alimentos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Image.asset(
                            item['imagen']! as String,
                            width: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          ),
                          title: Text(
                            item['titulo']! as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductoDetalleScreen(
                                  productId: item['id'] as int,
                                  titulo: item['titulo']! as String,
                                  imagen: item['imagen']! as String,
                                  descripcion: item['descripcion']! as String,
                                  precio: item['precio']! as double,
                                  stock: item['stock'] as int, // NUEVO: pasar stock
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