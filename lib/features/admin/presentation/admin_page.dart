import 'package:cafeteria_oea/features/admin/presentation/scanner_page.dart';
import 'package:cafeteria_oea/features/orders/data/orders_repository.dart';
import 'package:cafeteria_oea/features/orders/presentation/order_view.dart';
import 'package:cafeteria_oea/features/orders/presentation/orders_page.dart';
import 'package:flutter/material.dart';

import '../../menu/data/product_repository.dart';
import 'admin_products_page.dart';
import 'admin_users_page.dart';
import '../data/user_admin_repository.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    required this.ordersRepository,
    required this.productsRepository,
    required this.userRole,
    required this.usersRepository,
    super.key,
  });

  final OrdersRepository ordersRepository;
  final ProductRepository productsRepository;
  final String userRole;
  final UserAdminRepository usersRepository;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final silvers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Administración',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: _AdminCards(
            ordersRepository: widget.ordersRepository,
            productsRepository: widget.productsRepository,
            userRole: widget.userRole,
            usersRepository: widget.usersRepository,
          ),
        ),
      ),
    ];
    return CustomScrollView(slivers: silvers);
  }
}

class _AdminCards extends StatelessWidget {
  const _AdminCards({
    required this.ordersRepository,
    required this.productsRepository,
    required this.userRole,
    required this.usersRepository,
  });

  final OrdersRepository ordersRepository;
  final ProductRepository productsRepository;
  final String userRole;
  final UserAdminRepository usersRepository;

  bool get _isAdmin => userRole.trim().toLowerCase() == 'admin';

  bool get _canUpdateStatus {
    final normalizedRole = userRole.trim().toLowerCase();
    return normalizedRole == 'employee' || normalizedRole == 'admin';
  }

  Future<void> _scanOrder(BuildContext context) async {
    final qrValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    if (!context.mounted || qrValue == null || qrValue.trim().isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final order = await ordersRepository.fetchOrderById(qrValue.trim());
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderView(
            order: order,
            canUpdateStatus: _canUpdateStatus,
            onStatusChanged: _canUpdateStatus
                ? (status) =>
                      ordersRepository.updateOrderStatus(order.id, status)
                : null,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la orden: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear QR'),
            onTap: () => _scanOrder(context),
          ),
        ),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.import_contacts),
            title: const Text('Ver Ordenes'),
            onTap: () {
              // Navegar a la página de ordenes
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: SafeArea(
                      child: OrdersPage(
                        ordersFuture: ordersRepository.fetchAllOrders(),
                        onRefresh: ordersRepository.fetchAllOrders,
                        title: 'Todas las órdenes',
                        description: 'Consulta y administra las órdenes de todos los usuarios.',
                        errorMessage: 'No se pudieron cargar las órdenes',
                        emptyDescription: 'Todavía no hay órdenes registradas.',
                        canUpdateStatus: _canUpdateStatus,
                        onStatusChanged: _canUpdateStatus
                            ? (order, status) => ordersRepository
                                  .updateOrderStatus(order.id, status)
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Mis productos'),
            subtitle: const Text('Ver o crear productos del menú'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminProductsPage(repository: productsRepository),
              ),
            ),
          ),
        ),
        if (_isAdmin)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Administrar usuarios'),
              subtitle: const Text('Editar datos, roles y estados'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminUsersPage(repository: usersRepository),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
