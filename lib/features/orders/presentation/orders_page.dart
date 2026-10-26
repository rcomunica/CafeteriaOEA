import 'package:cafeteria_oea/features/orders/domain/order_status.dart';
import 'package:cafeteria_oea/features/orders/presentation/order_view.dart';
import 'package:flutter/material.dart';

import '../domain/order_item.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    required this.ordersFuture,
    required this.onRefresh,
    this.title = 'Mis pedidos',
    this.description = 'Aquí aparecerán tus órdenes y sus comprobantes.',
    this.errorMessage = 'No se pudieron cargar tus pedidos',
    this.emptyDescription = 'Cuando generes una orden, podrás consultar aquí su estado y referencia.',
    this.canUpdateStatus = false,
    this.onStatusChanged,
    super.key,
  });

  final Future<List<OrderItem>> ordersFuture;
  final Future<List<OrderItem>> Function() onRefresh;
  final String title;
  final String description;
  final String errorMessage;
  final String emptyDescription;
  final bool canUpdateStatus;
  final Future<void> Function(OrderItem order, OrderStatus status)?
  onStatusChanged;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderItem>> _ordersFuture;
  List<OrderItem> _orders = const [];

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.ordersFuture;
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ordersFuture != widget.ordersFuture) {
      _ordersFuture = widget.ordersFuture;
    }
  }

  Future<void> _refreshOrders() async {
    final future = widget.onRefresh();
    setState(() {
      _ordersFuture = future;
    });
    await future.then((orders) {
      if (mounted) setState(() => _orders = orders);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<OrderItem>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
        }
        if (snapshot.hasError) {
          if (_orders.isEmpty) {
            return _OrdersError(
              message: '${widget.errorMessage}: ${snapshot.error}',
              onRetry: _refreshOrders,
            );
          }
        }

        if (snapshot.hasData) {
          _orders = snapshot.data!;
        }
        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: _orders.isEmpty
                      ? _EmptyOrders(
                          colors: colors,
                          description: widget.emptyDescription,
                        )
                      : _OrdersList(
                          orders: _orders,
                          canUpdateStatus: widget.canUpdateStatus,
                          onStatusChanged: widget.onStatusChanged,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.canUpdateStatus,
    required this.onStatusChanged,
  });

  final List<OrderItem> orders;
  final bool canUpdateStatus;
  final Future<void> Function(OrderItem order, OrderStatus status)?
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final order in orders)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Card(
              color: order.status.containerColor(scheme),
              child: InkWell(
                onTap: () {
                  debugPrint(
                    'Tapped order ${order.id} with status ${order.status}',
                  );
                  // Navigate to order details page or perform any other action
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderView(
                        order: order,
                        canUpdateStatus: canUpdateStatus,
                        onStatusChanged: onStatusChanged == null
                            ? null
                            : (status) => onStatusChanged!(order, status),
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 0,
                  children: [
                    ListTile(
                      leading: order.status.icon(scheme),
                      title: Text(
                        order.status.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text('Creado: ${order.createdAtLabel}'),
                    ),
                    ListTile(
                      title: Text('Pedido #${order.id}'),
                      subtitle: Text('Código de recogida: ${order.pickupCode}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

extension OrderStatusUi on OrderStatus {
  Color containerColor(ColorScheme s) => switch (this) {
    OrderStatus.cancelled => s.errorContainer,
    OrderStatus.claimed =>
      s.brightness == Brightness.light
          ? const Color(0xFFC8E6C9) // verde claro (Colors.green.shade100)
          : const Color(0xFF1B5E20), // verde oscuro (Colors.green.shade900)
    OrderStatus.ready => s.inversePrimary,
    OrderStatus.paid =>
      s.brightness == Brightness.light
          ? const Color(0xFFC8E6C9) // verde claro (Colors.green.shade100)
          : const Color(0xFF1B5E20),
    _ => s.primaryContainer,
  };

  Icon icon(ColorScheme s) => switch (this) {
    OrderStatus.pendingPayment => Icon(
      Icons.monetization_on_outlined,
      color: s.onPrimaryContainer,
    ),

    OrderStatus.paid => Icon(
      Icons.payment_outlined,
      color: s.onPrimaryContainer,
    ),

    OrderStatus.cancelled => Icon(
      Icons.cancel_outlined,
      color: s.onErrorContainer,
    ),

    OrderStatus.ready => Icon(
      Icons.check_circle_outline,
      color: s.onPrimaryContainer,
    ),

    OrderStatus.claimed => Icon(Icons.check_circle, color: s.onInverseSurface),
  };
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.colors, required this.description});

  final ColorScheme colors;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _buildEmptyState(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.receipt_long_outlined,
                color: colors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos todavía',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
