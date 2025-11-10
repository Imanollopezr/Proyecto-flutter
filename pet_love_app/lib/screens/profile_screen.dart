import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_love_app/services/user_session.dart';
import 'package:pet_love_app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickProfilePhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // comprime un poco
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      Provider.of<UserSession>(context, listen: false).setFoto(bytes: bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    final nombre = session.nombre ?? 'Usuario';
    final email = session.email ?? 'Sin correo';
    final telefono = session.telefono ?? 'Sin teléfono';
    final direccion = session.direccion ?? 'Sin dirección';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const _HeaderProfile(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.purpleAccent,
                            backgroundImage: session.fotoBytes != null
                                ? MemoryImage(session.fotoBytes!)
                                : (session.fotoUrl != null && session.fotoUrl!.isNotEmpty)
                                    ? (session.fotoUrl!.startsWith('http')
                                        ? NetworkImage(session.fotoUrl!)
                                        : AssetImage(session.fotoUrl!) as ImageProvider)
                                    : null,
                            child: (session.fotoBytes == null &&
                                    (session.fotoUrl == null || session.fotoUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          IconButton(
                            onPressed: () => _pickProfilePhoto(context),
                            icon: const Icon(Icons.edit, color: Colors.black87),
                            tooltip: 'Cambiar foto',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Información de cuenta',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(email),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(telefono),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(direccion),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC928),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () async {
                            final nombreCtrl = TextEditingController(text: session.nombre ?? '');
                            final telCtrl = TextEditingController(text: session.telefono ?? '');
                            final dirCtrl = TextEditingController(text: session.direccion ?? '');
                            final formKey = GlobalKey<FormState>();

                            final datos = await showDialog<Map<String, String>?>(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Editar datos'),
                                  content: Form(
                                    key: formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: nombreCtrl,
                                          decoration: const InputDecoration(labelText: 'Nombre'),
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese su nombre' : null,
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: telCtrl,
                                          decoration: const InputDecoration(labelText: 'Teléfono'),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: dirCtrl,
                                          decoration: const InputDecoration(labelText: 'Dirección'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState?.validate() != true) return;
                                        Navigator.pop(ctx, {
                                          'nombre': nombreCtrl.text.trim(),
                                          'telefono': telCtrl.text.trim(),
                                          'direccion': dirCtrl.text.trim(),
                                        });
                                      },
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (datos == null) return;

                            try {
                              final emailSesion = session.email;
                              if (emailSesion == null || emailSesion.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debe iniciar sesión para actualizar datos'), backgroundColor: Colors.red),
                                );
                                return;
                              }

                              await ApiService.oauthSync(
                                email: emailSesion,
                                nombre: datos['nombre'],
                                telefono: (datos['telefono']?.isNotEmpty == true) ? datos['telefono'] : null,
                                direccion: (datos['direccion']?.isNotEmpty == true) ? datos['direccion'] : null,
                              );

                              Provider.of<UserSession>(context, listen: false).setSession(
                                email: emailSesion,
                                nombre: datos['nombre'],
                                telefono: datos['telefono'],
                                direccion: datos['direccion'],
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Datos actualizados')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar datos'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC928),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderProfile extends StatelessWidget {
  const _HeaderProfile();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _CurvedClipper(),
          child: Container(
            height: 140,
            color: const Color(0xFFFFC928),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
              ),
              Image.asset('img/logopet.png', height: 40),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'PERFIL',
              style: TextStyle(
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

class _CurvedClipper extends CustomClipper<Path> {
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
