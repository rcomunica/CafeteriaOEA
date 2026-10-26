import 'package:cafeteria_oea/features/admin/presentation/admin_page.dart';
import 'package:cafeteria_oea/features/admin/data/user_admin_repository.dart';
import 'package:cafeteria_oea/core/network/api_client.dart';
// import 'package:cafeteria_oea/features/admin/presentation/scanner_page.dart';
import 'package:cafeteria_oea/features/profile/data/profile_repository.dart';
import 'package:cafeteria_oea/features/profile/domain/profile_item.dart';
import 'package:flutter/material.dart';

import '../../cart/presentation/cart_page.dart';
import '../../auth/data/auth_repository.dart';
import '../../menu/data/product_repository.dart';
import '../../menu/domain/menu_item.dart';
import '../../menu/presentation/menu_page.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_item.dart';
import '../../orders/presentation/orders_page.dart';
import '../../payments/data/payments_repository.dart';
import '../../profile/presentation/profile_page.dart';

class CafeteriaShell extends StatefulWidget {
  const CafeteriaShell({
    required this.session,
    this.onTokenExpired,
    required this.onLogout,
    this.menuFuture,
    this.profileFuture,
    super.key,
  });

  final AuthSession session;
  final TokenRefreshCallback? onTokenExpired;
  final Future<void> Function() onLogout;
  final Future<List<MenuItem>>? menuFuture;
  final Future<ProfileItem>? profileFuture;

  @override
  State<CafeteriaShell> createState() => _CafeteriaShellState();
}

class _CafeteriaShellState extends State<CafeteriaShell> {
  int _selectedIndex = 0;
  final List<MenuItem> _cart = [];
  late Future<List<MenuItem>> _menuFuture;
  late final ProductRepository _productRepository;
  Future<ProfileItem>? _profileFuture;
  late final OrdersRepository _ordersRepository;
  Future<List<OrderItem>>? _ordersFuture;

  bool get _canAccessAdmin {
    final role = widget.session.user.role.trim().toLowerCase();
    return role == 'admin' || role == 'employee';
  }

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository(
      widget.session.token,
      onTokenExpired: widget.onTokenExpired,
    );
    _menuFuture = widget.menuFuture ?? _productRepository.readAll();
    _profileFuture = widget.profileFuture;
    _ordersRepository = OrdersRepository(
      items: null,
      token: widget.session.token,
      userId: widget.session.user.id,
      onTokenExpired: widget.onTokenExpired,
    );
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3 && _profileFuture == null) {
        _profileFuture = ProfileRepository(
          widget.session.token,
          onTokenExpired: widget.onTokenExpired,
        ).readProfile();
      }
      if (index == 2) {
        _ordersFuture = _ordersRepository.fetchOrders();
      }
    });
  }

  void _addToCart(MenuItem item) {
    setState(() => _cart.add(item));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} agregado al carrito')));
  }

  Future<void> _refreshMenu() async {
    final future = _productRepository.readAll();
    setState(() {
      _menuFuture = future;
    });
    await future;
  }

  Future<void> _createPayment(OrderItem order, String reference) async {
    final orderId = int.tryParse(order.id);
    if (orderId == null) {
      throw const ApiException('La orden no tiene un id válido para pagar.');
    }
    await PaymentsRepository(
      widget.session.token,
      onTokenExpired: widget.onTokenExpired,
    ).createPayment(
      orderId: orderId,
      transactionReference: reference,
      amount: order.total,
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
          return MenuPage(
            items: snapshot.data ?? const [],
            onAdd: _addToCart,
            onRefresh: _refreshMenu,
          );
        },
      ),
      CartPage(
        items: _cart,
        session: widget.session,
        onTokenExpired: widget.onTokenExpired,
      ),
      OrdersPage(
        ordersFuture: _ordersFuture ?? Future.value(const <OrderItem>[]),
        onRefresh: _ordersRepository.fetchOrders,
        onPaymentRequested: (order, reference) =>
            _createPayment(order, reference),
      ),
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
          return ProfilePage(profile: profile, onLogout: widget.onLogout);
        },
      ),
      if (_canAccessAdmin)
        AdminPage(
          ordersRepository: _ordersRepository,
          productsRepository: ProductRepository(
            widget.session.token,
            onTokenExpired: widget.onTokenExpired,
          ),
          userRole: widget.session.user.role,
          usersRepository: UserAdminRepository(
            widget.session.token,
            onTokenExpired: widget.onTokenExpired,
          ),
        ),
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
          if (_canAccessAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
