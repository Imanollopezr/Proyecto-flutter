import 'package:flutter/material.dart';
import 'package:pet_love_app/admin_sales_screen.dart';
import 'package:pet_love_app/screens/catalog_guest_screen.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/login_screen.dart' show LoginScreen;
import 'screens/sign_in_screen.dart' show SignInScreen;
import 'screens/register_screen.dart';
import 'screens/RecoverPasswordScreen.dart';
import 'screens/catalog_screen.dart';
import 'screens/category_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shoppingcart_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/detalle_producto_screen.dart';
import 'screens/code_sent_screen.dart';
import 'screens/recovery_code_input_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/AdminHomeScreen.dart';
import 'screens/admin_category_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_brands_screen.dart';
import 'screens/admin_measures_screen.dart';
import 'package:pet_love_app/screens/ProductoDetalleScreen.dart';
import 'package:pet_love_app/services/user_session.dart';

class CartItem {
  final int productId;
  final String title;
  final String image;
  final double price;
  int quantity;
  final int availableStock; // stock disponible al momento de agregar
  final int? categoryId; // ID de la categoría del producto
  final String? categoryName; // Nombre de la categoría del producto

  CartItem({
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
    required this.availableStock,
    this.categoryId,
    this.categoryName,
  });
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addItem(CartItem newItem) {
    // Unificar por productId (mismo producto)
    final index = _items.indexWhere((item) => item.productId == newItem.productId);
    if (index >= 0) {
      final maxStock = _items[index].availableStock;
      _items[index].quantity = (_items[index].quantity + newItem.quantity).clamp(1, maxStock);
    } else {
      final initialQty = newItem.quantity.clamp(1, newItem.availableStock);
      _items.add(CartItem(
        productId: newItem.productId,
        title: newItem.title,
        image: newItem.image,
        price: newItem.price,
        quantity: initialQty,
        availableStock: newItem.availableStock,
        categoryId: newItem.categoryId,
        categoryName: newItem.categoryName,
      ));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int newQuantity) {
    final maxStock = _items[index].availableStock;
    _items[index].quantity = newQuantity.clamp(1, maxStock);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Agrupa los productos del carrito por categoría
  Map<String, List<CartItem>> get itemsByCategory {
    final Map<String, List<CartItem>> grouped = {};
    
    for (final item in _items) {
      final categoryName = item.categoryName ?? 'Sin categoría';
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(item);
    }
    
    return grouped;
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        ChangeNotifierProvider(create: (context) => UserSession()),
      ],
      child: const PetLoveApp(),
    ),
  );
}

class PetLoveApp extends StatelessWidget {
  const PetLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const SignInScreen(),
        '/register': (context) => const RegisterScreen(),
        '/recover': (context) => const RecoverPasswordScreen(),
        '/catalog': (context) => const CatalogScreen(),
        '/categories': (context) => const CategoryScreen(),
        '/home': (context) => const HomeScreen(),
        '/shoppingcart': (context) => const ShoppingCartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/code': (context) => const CodeSentScreen(),
        '/recovery-code': (context) => const RecoveryCodeInputScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/adminhome': (context) => const AdminHomeScreen(),
        '/admincategories': (context) => const AdminCategoryScreen(),
        '/adminproducts': (context) => const AdminProductsScreen(),
        '/adminsales': (context) => const AdminSalesScreen(),
        '/CatalogGuest': (context) => const CatalogGuestScreen(),
        '/adminbrands': (context) => const AdminBrandsScreen(),
        '/adminmeasures': (context) => const AdminMeasuresScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detalle_producto') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => DetalleProductoScreen(
              title: args['title'],
              price: args['price'],
              imagePath: args['image'],
            ),
          );
        }
        return null;
      },
    );
  }
}