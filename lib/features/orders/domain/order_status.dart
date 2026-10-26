enum OrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  ready('ready'),
  claimed('claimed'),
  cancelled('cancelled');

  const OrderStatus(this.value);

  /// Valor tal cual lo manda/recibe la API
  final String value;

  static OrderStatus fromString(String? raw) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => OrderStatus.pendingPayment, // fallback seguro
    );
  }

  // Helpers útiles para la UI
  bool get isFinal => this == claimed || this == cancelled;
  bool get canCancel => this == pendingPayment || this == paid;

  String get label => switch (this) {
    pendingPayment => 'Pendiente de pago',
    paid => 'Pagado',
    ready => 'Listo para recoger',
    claimed => 'Entregado',
    cancelled => 'Cancelado',
  };
}
