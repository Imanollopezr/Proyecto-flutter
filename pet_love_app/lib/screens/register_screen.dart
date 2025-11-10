import 'package:flutter/material.dart';
import 'package:pet_love_app/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prellenar email si llega desde inicio de sesión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['prefillEmail'] is String) {
        emailController.text = (args['prefillEmail'] as String);
      }
    });
  }

  void _register() async {
    final nombre = nombreController.text.trim();
    final apellidos = apellidosController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final pass = passwordController.text;
    final confirm = confirmController.text;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese sus nombres')));
      return;
    }
    if (apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese sus apellidos')));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un correo válido')));
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')));
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }

    try {
      await ApiService.register(
        nombres: nombre,
        apellidos: apellidos,
        correo: email,
        clave: pass,
        confirmarClave: confirm,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro completado. Ahora inicia sesión.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (route) => false,
        arguments: {
          'prefillEmail': email,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC928),
      body: Column(
        children: [
          // Encabezado con logo y engranaje
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

          // Imagen del perro con borde
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
              child: Image.asset(
                'img/perroacceso1.png',
                fit: BoxFit.cover,
              ),
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
                    // Título con flecha
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Ingrese sus nombres',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Apellidos
                    TextField(
                      controller: apellidosController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Ingrese sus apellidos',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Correo
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
                    const SizedBox(height: 12),

                    // Contraseña
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
                    const SizedBox(height: 12),

                    // Confirmar contraseña
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Repita su contraseña',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ¿Ya tienes cuenta?
                    Center(
                      child: Column(
                        children: [
                          const Text('¿Ya tienes una cuenta?'),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 140,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
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

                    const SizedBox(height: 30),

                    // Botón registrarse
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCC52C),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
