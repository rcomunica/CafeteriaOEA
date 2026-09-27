import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:cafeteria_oea/features/auth/data/auth_repository.dart';
import 'package:cafeteria_oea/features/orders/data/orders_repository.dart';
import 'package:flutter/material.dart';

import '../../menu/domain/menu_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({required this.items, required this.session, super.key});

  final List<MenuItem> items;
  final AuthSession session;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Controllers and state variables
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  List<MenuItem> get items => widget.items;

  Future<void> _removeItem(MenuItem item) async {
    setState(() => items.remove(item));
  }

  int get totalPrice => items.fold<int>(0, (sum, item) => sum + item.price);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (items.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      OrdersRepository(
        items: items,
        token: widget.session.token,
      ).createOrder(totalPrice, _notesController.text.trim());

      setState(() {
        items.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden mock creada. El pago aún está pendiente.'),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible conectarse con la API.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Tu carrito',
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
            'Revisa tu selección antes de generar la orden.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ),
    ];

    if (items.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('Aún no has seleccionado productos.')),
        ),
      );
    } else {
      slivers.addAll([
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(Icons.fastfood_outlined, color: colors.primary),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    item.price == 0 ? 'Precio pendiente' : '\$${item.price}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeItem(item),
                    tooltip: 'Quitar del carrito',
                    icon: const Icon(Icons.close),
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas adicionales',
                          hintText: 'Ej. Sin picante, sin cebolla...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Resumen de compra',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Total'), Text('\$$totalPrice')],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _createOrder,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_cart_checkout_outlined,
                                ),
                          label: const Text('Generar orden'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    return CustomScrollView(slivers: slivers);
  }
}
