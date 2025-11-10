import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RecoveryCodeInputScreen extends StatefulWidget {
  const RecoveryCodeInputScreen({super.key});

  @override
  State<RecoveryCodeInputScreen> createState() => _RecoveryCodeInputScreenState();
}

class _RecoveryCodeInputScreenState extends State<RecoveryCodeInputScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  String get enteredCode => _controllers.map((c) => c.text).join();

  // Enmascarar correo para mostrarlo en el texto
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
    final maskedEmail = (routeEmail != null && routeEmail.isNotEmpty)
        ? _maskEmail(routeEmail)
        : 'tu correo';

    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('img/logopet.png', width: 120),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const Icon(Icons.settings, size: 30, color: Colors.black),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flecha funcional para volver a la página anterior
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'RECUPERACIÓN DE LA CUENTA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hemos enviado un código de verificación\na tu correo $maskedEmail',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 55,
                        height: 65,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.grey[300],
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFCC52C),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      text: '¿No has recibido tu código? ',
                      children: [
                        TextSpan(
                          text: 'Reenviar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        final code = enteredCode;
                        // Validación: exactamente 6 dígitos
                        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El código debe tener exactamente 6 dígitos')),
                          );
                          return;
                        }
                        if (routeEmail == null || routeEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se ha recibido el correo. Regresa e inténtalo de nuevo.')),
                          );
                          return;
                        }
                      
                        try {
                          // Verificar código en backend antes de continuar
                          final ok = await ApiService.verifyCode(correo: routeEmail, codigo: code);
                          if (ok) {
                            Navigator.pushNamed(
                              context,
                              '/new-password',
                              arguments: {'email': routeEmail, 'code': code},
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCC52C),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Confirmar'),
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
          ),
        ],
      ),
    );
  }
}
