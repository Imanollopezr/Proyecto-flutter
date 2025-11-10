import 'package:flutter/material.dart';

class CodeSentScreen extends StatelessWidget {
  final String? email;
  const CodeSentScreen({super.key, this.email});

  // Enmascara el correo: muestra 2 caracteres de la parte local y deja el dominio completo
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    final visibleCount = local.length >= 2 ? 2 : (local.isEmpty ? 0 : 1);
    final visible = local.substring(0, visibleCount);
    final maskCount = local.length - visibleCount;
    final maskedLocal = visible + (maskCount > 0 ? List.filled(maskCount, '*').join() : '');
    return '$maskedLocal@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final routeEmail = ModalRoute.of(context)?.settings.arguments as String?;
    final rawEmail = email ?? routeEmail ?? '';
    final displayEmail = rawEmail.isNotEmpty ? rawEmail : 'tu correo';

    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado con logo y engranaje
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Image.asset('img/logopet.png', width: 100),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.settings, color: Colors.black),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Card con mensaje
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CÓDIGO ENVIADO AL CORREO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Reemplaza el texto quemado por el correo dinámico enmascarado
                      Text(
                        displayEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Image.asset('img/verificado.png', width: 90),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Revisa tu Correo Electrónico!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Pasamos el mismo correo a la siguiente pantalla
                          Navigator.pushNamed(context, '/recovery-code', arguments: rawEmail);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFCC52C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Ingresar Código'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
