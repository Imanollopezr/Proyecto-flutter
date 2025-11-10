import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'img/Perroacceso.png',
              fit: BoxFit.cover,
            ),
          ),

          // Botón "Explorar catálogo" en esquina superior derecha con mejor ubicación y estilo
          Positioned(
            top: 30, // bajamos el botón
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/CatalogGuest');
                },
                borderRadius: BorderRadius.circular(30),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.travel_explore, color: Colors.black87, size: 18),
                      SizedBox(width: 5),
                      Text(
                        'Explorar catálogo',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido central
          Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                  'img/logopet.png',
                  width: 180,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signin');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCC52C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text(
                  '¿Aún no tienes cuenta? Regístrate',
                  style: TextStyle(
                    color: Color.fromARGB(255, 40, 40, 40),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
