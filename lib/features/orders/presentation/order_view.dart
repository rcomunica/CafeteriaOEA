import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/config/wompi_config.dart';
import '../domain/order_item.dart';
import '../domain/order_line_item.dart';
import '../domain/order_status.dart';

class OrderView extends StatefulWidget {
  const OrderView({
    required this.order,
    this.canUpdateStatus = false,
    this.onStatusChanged,
    this.onPaymentRequested,
    super.key,
  });

  final OrderItem order;
  final bool canUpdateStatus;
  final Future<void> Function(OrderStatus status)? onStatusChanged;
  final Future<void> Function(OrderItem order, String transactionReference)?
  onPaymentRequested;

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  late OrderItem _order;
  bool _isUpdating = false;
  bool _isPaying = false;
  bool _isEditingStatus = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(OrderStatus? status) async {
    if (status == null ||
        status == _order.status ||
        widget.onStatusChanged == null ||
        _isUpdating) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await widget.onStatusChanged!(status);
      if (!mounted) return;
      setState(() {
        _order = _order.copyWith(status: status);
        _isUpdating = false;
        _isEditingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a ${status.label}.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el estado: $error')),
      );
    }
  }

  Future<void> _goToPayment() async {
    if (!WompiConfig.isConfigured || widget.onPaymentRequested == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configura la llave pública y el secreto de integridad de Wompi.',
          ),
        ),
      );
      return;
    }

    setState(() => _isPaying = true);
    final transactionReference =
        'ORDER-${_order.id}-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await widget.onPaymentRequested!(_order, transactionReference);
      if (!mounted) return;
      final launched = await launchUrl(
        WompiConfig.checkoutUri(
          _order,
          transactionReference: transactionReference,
        ),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el checkout de Wompi.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo preparar el pago: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _OrderQrCard(order: _order, colors: colors),
          const SizedBox(height: 24),
          Text(
            'Productos',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _order.orderItems.length;
                  index++
                ) ...[
                  _ProductTile(
                    product: _order.orderItems[index],
                    colors: colors,
                  ),
                  if (index < _order.orderItems.length - 1)
                    Divider(height: 1, color: colors.outlineVariant),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Detalles del pedido',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  if (widget.canUpdateStatus &&
                      widget.onStatusChanged != null &&
                      _isEditingStatus)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Estado',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<OrderStatus>(
                            initialValue: _order.status,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar estado',
                            ),
                            items: [
                              for (final status in OrderStatus.values)
                                DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                            ],
                            onChanged: _isUpdating ? null : _updateStatus,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancelar edición',
                          icon: const Icon(Icons.close),
                          onPressed: _isUpdating
                              ? null
                              : () => setState(() => _isEditingStatus = false),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _DetailRow(
                            label: 'Estado',
                            value: _order.status.label,
                            valueColor: colors.primary,
                          ),
                        ),
                        if (widget.canUpdateStatus &&
                            widget.onStatusChanged != null)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _isEditingStatus = true),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                      ],
                    ),
                  _DetailRow(label: 'Fecha', value: _order.createdAtLabel),
                  _DetailRow(
                    label: 'Código de recogida',
                    value: _order.pickupCode.isEmpty
                        ? 'Pendiente'
                        : _order.pickupCode,
                  ),
                  _DetailRow(
                    label: 'Notas',
                    value: _order.notes.isEmpty
                        ? 'Sin notas adicionales'
                        : _order.notes,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Total',
                    value: '\$${_order.total}',
                    emphasized: true,
                  ),
                  if (_order.status == OrderStatus.pendingPayment) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isPaying ? null : _goToPayment,
                        icon: const Icon(Icons.payment_outlined),
                        label: _isPaying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Ir a pagar'),
                      ),
                    ),
                  ],
                  if (_isUpdating) ...[
                    const Divider(height: 24),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderQrCard extends StatelessWidget {
  const _OrderQrCard({required this.order, required this.colors});

  final OrderItem order;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          children: [
            Text(
              'Presenta este código al recoger',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: _QrImagePainter(pickupCode: order.id),
            ),
            const SizedBox(height: 18),
            Text(
              'Pedido #${order.id}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.colors});

  final OrderLineItem product;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        child: Icon(
          Icons.fastfood_outlined,
          color: colors.onSecondaryContainer,
        ),
      ),
      title: Text(
        product.productName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('Cantidad: ${product.quantity}'),
      trailing: Text(
        '\$${product.subtotal}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style?.copyWith(
                color: valueColor,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
                fontSize: emphasized ? 20 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrImagePainter extends StatelessWidget {
  final String pickupCode;
  const _QrImagePainter({required this.pickupCode});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: pickupCode,
      version: QrVersions.auto,
      size: 178,
      gapless: false,
      backgroundColor: Colors.white,
    );
  }
}
