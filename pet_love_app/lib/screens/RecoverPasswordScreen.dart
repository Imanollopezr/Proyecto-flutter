import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Column(
        children: [
          // Cabecera con logo centrado
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Image.asset('img/logopet.png', width: 140),
            ),
          ),

          // Formulario de recuperación
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'INGRESA TU CORREO ELECTRÓNICO\nPARA RECUPERAR CONTRASEÑA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Campo de correo
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      hintText: 'Ingresa tu Correo',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón Enviar Código
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          messenger.showSnackBar(const SnackBar(content: Text('Ingresa tu correo')));
                          return;
                        }

                        try {
                          final res = await ApiService.forgotPassword(correo: email);
                          if (!mounted) return;

                          final data = res['data'];
                          if (data is Map && data['Codigo'] != null) {
                            messenger.showSnackBar(SnackBar(content: Text('Código (mock): ${data['Codigo']}')));
                          }

                          nav.pushNamed('/code', arguments: email);
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text('Error al enviar código: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCC52C),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Enviar Código'),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text('¿Ya tienes una cuenta?'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 140,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Iniciar Sesión'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
