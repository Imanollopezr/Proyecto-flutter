import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pet_love_app/services/api_service.dart';
import 'package:pet_love_app/services/user_session.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String adminEmail = 'admin@petlove.com';

  @override
  void initState() {
    super.initState();
    // Prefill del email si viene desde registro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['prefillEmail'] is String) {
        emailController.text = (args['prefillEmail'] as String);
      }
    });
  }

  void _login() async {
    final email = emailController.text.trim().toLowerCase();
    final pass = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un correo válido')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    String? redirect;
    if (args is Map && args['redirect'] is String) {
      redirect = args['redirect'] as String;
    }

    try {
      // Login validando correo + contraseña
      final auth = await ApiService.login(correo: email, clave: pass);
      final token = auth['token'] as String?;
      final usuario = (auth['usuario'] as Map?) ?? {};

      final nombre = usuario['Nombres'] ?? usuario['nombres'];
      final apellido = usuario['Apellidos'] ?? usuario['apellidos'];
      final nombreRol = usuario['NombreRol'] ?? usuario['nombreRol'] ?? '';
      final correoResp = usuario['Correo'] ?? usuario['correo'] ?? email;

      Provider.of<UserSession>(context, listen: false).setSession(
        email: correoResp,
        token: token,
        nombreRol: nombreRol,
        nombre: nombre,
        apellido: apellido,
      );

      if ((nombreRol as String).toLowerCase().contains('admin')) {
        Navigator.pushNamedAndRemoveUntil(context, '/adminhome', (route) => false);
      } else if (redirect != null && redirect.isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, redirect, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correo o contraseña incorrectos: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Column(
        children: [
          // Encabezado: logo y engranaje
          Container(
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('img/logopet.png', width: 120),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                const Icon(Icons.settings, color: Colors.black, size: 30),
              ],
            ),
          ),

          // Imagen perro
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('img/perroacceso1.png', fit: BoxFit.cover),
            ),
          ),

          // Formulario
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Ingrese su correo',
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Ingrese su contraseña',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/recover');
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: '¿Olvidaste tu contraseña? ',
                            children: [
                              TextSpan(
                                text: 'Recuperar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: '¿Aún no tienes cuenta? ',
                            children: [
                              TextSpan(
                                text: 'Regístrate',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCC52C),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          child: const Text('Iniciar Sesión'),
                        ),
                      ),
                    ),
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
