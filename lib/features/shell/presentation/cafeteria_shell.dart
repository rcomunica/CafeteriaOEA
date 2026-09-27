import 'package:cafeteria_oea/features/admin/presentation/admin_page.dart';
// import 'package:cafeteria_oea/features/orders/data/orders_repository.dart';
// import 'package:cafeteria_oea/features/admin/presentation/scanner_page.dart';
import 'package:cafeteria_oea/features/profile/data/profile_repository.dart';
import 'package:cafeteria_oea/features/profile/domain/profile_item.dart';
import 'package:flutter/material.dart';

import '../../cart/presentation/cart_page.dart';
import '../../auth/data/auth_repository.dart';
import '../../menu/data/product_repository.dart';
import '../../menu/domain/menu_item.dart';
import '../../menu/presentation/menu_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../profile/presentation/profile_page.dart';

class CafeteriaShell extends StatefulWidget {
  const CafeteriaShell({
    required this.session,
    this.menuFuture,
    this.profileFuture,
    super.key,
  });

  final AuthSession session;
  final Future<List<MenuItem>>? menuFuture;
  final Future<ProfileItem>? profileFuture;

  @override
  State<CafeteriaShell> createState() => _CafeteriaShellState();
}

class _CafeteriaShellState extends State<CafeteriaShell> {
  int _selectedIndex = 0;
  final List<MenuItem> _cart = [];
  late Future<List<MenuItem>> _menuFuture;
  Future<ProfileItem>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture =
        widget.menuFuture ?? ProductRepository(widget.session.token).readAll();
    _profileFuture = widget.profileFuture;
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3 && _profileFuture == null) {
        _profileFuture = ProfileRepository(widget.session.token).readProfile();
      }
    });
  }

  void _addToCart(MenuItem item) {
    setState(() => _cart.add(item));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} agregado al carrito')));
  }

  void _createOrder() {
    if (_cart.isEmpty) return;

    // int totalPrice = _cart.fold<int>(0, (sum, item) => sum + item.price);

    // OrdersRepository(widget.session.token).createOrder(totalPrice, notes)

    setState(() {
      _cart.clear();
      _selectedIndex = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orden mock creada. El pago aún está pendiente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FutureBuilder<List<MenuItem>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('No se pudo cargar el menú: ${snapshot.error}'),
            );
          }
          return MenuPage(items: snapshot.data ?? const [], onAdd: _addToCart);
        },
      ),
      CartPage(items: _cart, session: widget.session),
      const OrdersPage(),
      FutureBuilder<ProfileItem>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (_profileFuture == null ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('No se pudo cargar el perfil: ${snapshot.error}'),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('No hay información de perfil'));
          }
          return ProfilePage(profile: profile);
        },
      ),
      const AdminPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            label: 'Menú',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text('${_cart.length}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text('${_cart.length}'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
