import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/categorias_image_service.dart';
import 'package:http/http.dart' as http;

class CategoriaTile extends StatelessWidget {
  final int idCategoria;
  final CategoriasImageService imageService;

  const CategoriaTile({super.key, required this.idCategoria, required this.imageService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: imageService.obtenerImagenCategoria(idCategoria),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover);
        }
        return const Icon(Icons.image_not_supported, size: 64);
      },
    );
  }
}

const String apiBaseUrl = 'http://localhost:8090'; // ajusta si corre en 8080

Future<Uint8List?> _cargarImagenCategoria(int idCategoria) async {
  final uri = Uri.parse('http://localhost:8090/api/categorias/$idCategoria/imagen');
  final resp = await http.get(uri);
  if (resp.statusCode == 200) return resp.bodyBytes;
  return null; // 404/500: sin imagen
}

// Ejemplo de card/ítem que muestra la imagen con bytes
Widget _categoriaCard({
  required int idCategoria,
  required String nombre,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FutureBuilder<Uint8List?>(
        future: _cargarImagenCategoria(idCategoria),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final bytes = snapshot.data;
          if (bytes != null) {
            return Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover);
          }
          return const Icon(Icons.image_not_supported, size: 64);
        },
      ),
      const SizedBox(height: 8),
      Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}