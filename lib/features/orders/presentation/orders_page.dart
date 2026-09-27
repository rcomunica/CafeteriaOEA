import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Mis pedidos',
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
              'Aquí aparecerán tus órdenes y sus comprobantes.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
          sliver: SliverToBoxAdapter(child: _EmptyOrders(colors: colors)),
        ),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.colors});

  final ColorScheme colors;

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
            const Text(
              'Cuando generes una orden, podrás consultar aquí su estado y referencia.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
