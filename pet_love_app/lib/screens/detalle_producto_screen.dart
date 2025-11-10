import 'package:flutter/material.dart';

class DetalleProductoScreen extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;

  const DetalleProductoScreen({
    super.key,
    required this.title,
    required this.price,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomHeader(title: 'Detalle del Producto'),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(2, 2)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset(imagePath, height: 180),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Producto de excelente calidad ideal para mascotas. ¡Perfecto para su bienestar!',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomHeader extends StatelessWidget {
  final String title;

  const CustomHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: CurvedBottomClipper(),
          child: Container(
            height: 160,
            color: const Color(0xFFFFC928),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ← Flecha para regresar
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 28),
              ),
              Image.asset('img/logopet.png', height: 40),
              const SizedBox(width: 28), // Espacio para balancear el layout
            ],
          ),
        ),
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
